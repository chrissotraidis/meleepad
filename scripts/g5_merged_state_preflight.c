// Data-free G5 preflight for keeping guest state live in a single-entry region.
// It models the actual GALE01 slice at 8036C91C..8036C934 without game data.

#include "core/cpu.h"

#include <mach/mach_time.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

PPCMemWriteJournal g_mem_write_journal = NULL;
void* g_mem_write_journal_user = NULL;

enum
{
  PC_ENTRY = 0x8036C91Cu,
  PC_ADDI = 0x8036C920u,
  PC_STORE = 0x8036C924u,
  PC_COMPARE = 0x8036C928u,
  PC_BRANCH = 0x8036C92Cu,
  PC_ARGUMENT = 0x8036C930u,
  PC_CALL = 0x8036C934u,
  PC_CALL_RETURN = 0x8036C938u,
  PC_FINAL = 0x8036C954u,
  PC_CALL_TARGET = 0x8035F070u,
  RAM_ADDRESS = 0x80000100u,
};

#if defined(__GNUC__) || defined(__clang__)
#define NOINLINE __attribute__((noinline))
#else
#define NOINLINE
#endif

#define REPEATS 9u

NOINLINE void canonical_region(CPUState* ctx)
{
  switch (ctx->pc)
  {
  case PC_ENTRY:
    goto label_entry;
  case PC_ADDI:
    goto label_addi;
  case PC_STORE:
    goto label_store;
  case PC_COMPARE:
    goto label_compare;
  case PC_BRANCH:
    goto label_branch;
  case PC_ARGUMENT:
    goto label_argument;
  case PC_CALL:
    goto label_call;
  default:
    return;
  }

label_entry:
  ctx->pc = PC_ENTRY;
  ctx->downcount -= 3;
  ctx->gpr[3] = mem_read32(ctx, ctx->gpr[27]);

label_addi:
  ctx->gpr[0] = ctx->gpr[3] + 1u;

label_store:
  ctx->pc = PC_STORE;
  mem_write32(ctx, ctx->gpr[27], ctx->gpr[0]);

label_compare:
  ctx->downcount -= 2;
  {
    const int32_t value = (int32_t)ctx->gpr[28];
    uint32_t bits = 0;
    if (value < 0)
      bits |= 0x8u;
    if (value > 0)
      bits |= 0x4u;
    if (value == 0)
      bits |= 0x2u;
    bits |= (ctx->xer >> 31) & 1u;
    ctx->cr = (ctx->cr & 0x0fffffffu) | (bits << 28);
  }

label_branch:
  if ((ctx->cr & 0x20000000u) != 0)
  {
    ctx->pc = PC_FINAL;
    return;
  }

label_argument:
  ctx->downcount -= 2;
  ctx->gpr[3] = ctx->gpr[24];

label_call:
  ctx->lr = PC_CALL_RETURN;
  ctx->pc = PC_CALL_TARGET;
}

NOINLINE void merged_region(CPUState* ctx)
{
  ctx->pc = PC_ENTRY;
  ctx->downcount -= 3;
  const uint32_t address = ctx->gpr[27];
  const uint32_t loaded = mem_read32(ctx, address);
  ctx->gpr[3] = loaded;

  const uint32_t incremented = loaded + 1u;
  ctx->gpr[0] = incremented;
  ctx->pc = PC_STORE;
  mem_write32(ctx, address, incremented);

  ctx->downcount -= 2;
  const int32_t compared = (int32_t)ctx->gpr[28];
  uint32_t bits = 0;
  if (compared < 0)
    bits |= 0x8u;
  if (compared > 0)
    bits |= 0x4u;
  if (compared == 0)
    bits |= 0x2u;
  bits |= (ctx->xer >> 31) & 1u;
  ctx->cr = (ctx->cr & 0x0fffffffu) | (bits << 28);

  if (compared == 0)
  {
    ctx->pc = PC_FINAL;
    return;
  }

  ctx->downcount -= 2;
  ctx->gpr[3] = ctx->gpr[24];
  ctx->lr = PC_CALL_RETURN;
  ctx->pc = PC_CALL_TARGET;
}

static uint64_t next_random(uint64_t* state)
{
  *state ^= *state << 13;
  *state ^= *state >> 7;
  *state ^= *state << 17;
  return *state;
}

static int semantic_check(void)
{
  uint64_t random = UINT64_C(0x123456789abcdef0);
  for (unsigned i = 0; i < 4096; ++i)
  {
    CPUState canonical;
    CPUState merged;
    uint8_t canonical_ram[4096];
    uint8_t merged_ram[4096];
    memset(&canonical, 0, sizeof(canonical));
    memset(canonical_ram, 0, sizeof(canonical_ram));

    canonical.pc = PC_ENTRY;
    canonical.downcount = -(int64_t)(next_random(&random) & 0xffu);
    canonical.gpr[24] = (uint32_t)next_random(&random);
    canonical.gpr[27] = RAM_ADDRESS;
    canonical.gpr[28] = (uint32_t)next_random(&random);
    canonical.xer = (uint32_t)next_random(&random);
    canonical.cr = (uint32_t)next_random(&random);
    canonical.ram = canonical_ram;
    canonical.ram_size = sizeof(canonical_ram);
    mem_write32(&canonical, RAM_ADDRESS, (uint32_t)next_random(&random));

    merged = canonical;
    memcpy(merged_ram, canonical_ram, sizeof(merged_ram));
    merged.ram = merged_ram;

    canonical_region(&canonical);
    merged_region(&merged);

    const uint8_t* canonical_bytes = (const uint8_t*)&canonical;
    const uint8_t* merged_bytes = (const uint8_t*)&merged;
    const size_t ram_offset = (size_t)((const uint8_t*)&canonical.ram - canonical_bytes);
    bool state_equal = true;
    for (size_t byte = 0; byte < sizeof(CPUState); ++byte)
    {
      if (byte >= ram_offset && byte < ram_offset + sizeof(canonical.ram))
        continue;
      if (canonical_bytes[byte] != merged_bytes[byte])
      {
        state_equal = false;
        break;
      }
    }
    if (!state_equal || memcmp(canonical_ram, merged_ram, sizeof(canonical_ram)) != 0)
    {
      fprintf(stderr,
              "semantic mismatch iteration=%u canonical pc=%08X lr=%08X down=%lld "
              "merged pc=%08X lr=%08X down=%lld\n",
              i, canonical.pc, canonical.lr, (long long)canonical.downcount, merged.pc,
              merged.lr, (long long)merged.downcount);
      return 1;
    }
  }
  printf("MERGED,semantic-equivalence-4096-cases,PASS\n");
  return 0;
}

static double now_nanoseconds(void)
{
  static mach_timebase_info_data_t timebase;
  if (timebase.denom == 0)
    mach_timebase_info(&timebase);
  return (double)mach_continuous_time() * timebase.numer / timebase.denom;
}

typedef void (*Region)(CPUState*);

static double measure(Region region, CPUState* cpu, uint64_t iterations)
{
  const double start = now_nanoseconds();
  for (uint64_t i = 0; i < iterations; ++i)
  {
    cpu->pc = PC_ENTRY;
    cpu->gpr[28] = (i & 7u) == 0 ? 1u : 0u;
    region(cpu);
  }
  return (now_nanoseconds() - start) / (double)iterations;
}

static int compare_double(const void* left, const void* right)
{
  const double a = *(const double*)left;
  const double b = *(const double*)right;
  return (a > b) - (a < b);
}

int main(int argc, char** argv)
{
  if (semantic_check() != 0)
    return 1;

  uint64_t iterations = 5000000;
  if (argc > 1)
  {
    char* end = NULL;
    iterations = strtoull(argv[1], &end, 10);
    if (!end || *end != '\0' || iterations == 0)
    {
      fprintf(stderr, "iterations must be a positive integer\n");
      return 2;
    }
  }

  CPUState canonical;
  CPUState merged;
  uint8_t canonical_ram[4096] = {0};
  uint8_t merged_ram[4096] = {0};
  memset(&canonical, 0, sizeof(canonical));
  canonical.pc = PC_ENTRY;
  canonical.gpr[24] = 0x10203040u;
  canonical.gpr[27] = RAM_ADDRESS;
  canonical.ram = canonical_ram;
  canonical.ram_size = sizeof(canonical_ram);
  merged = canonical;
  merged.ram = merged_ram;

  double canonical_samples[REPEATS];
  double merged_samples[REPEATS];
  for (unsigned repeat = 0; repeat < REPEATS; ++repeat)
  {
    if ((repeat & 1u) == 0)
    {
      canonical_samples[repeat] = measure(canonical_region, &canonical, iterations);
      merged_samples[repeat] = measure(merged_region, &merged, iterations);
    }
    else
    {
      merged_samples[repeat] = measure(merged_region, &merged, iterations);
      canonical_samples[repeat] = measure(canonical_region, &canonical, iterations);
    }
  }
  qsort(canonical_samples, REPEATS, sizeof(double), compare_double);
  qsort(merged_samples, REPEATS, sizeof(double), compare_double);
  const double canonical_median = canonical_samples[REPEATS / 2];
  const double merged_median = merged_samples[REPEATS / 2];
  printf("mode,median_ns_per_region\n");
  printf("canonical,%.6f\n", canonical_median);
  printf("merged,%.6f\n", merged_median);
  printf("saved_ns_per_region,%.6f\n", canonical_median - merged_median);
  printf("improvement_percent,%.6f\n",
         (canonical_median - merged_median) * 100.0 / canonical_median);
  printf("sink,%u,%u\n", canonical.gpr[0], merged.gpr[0]);
  return 0;
}
