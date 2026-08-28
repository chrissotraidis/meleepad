// Data-free differential/timing harness for one profile-weighted generated function.

#include "core/cpu.h"

#include <mach/mach_time.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void func_80375940_canonical(CPUState* ctx);
void func_80375940_weighted(CPUState* ctx);
void func_80375940_pgo(CPUState* ctx);

enum
{
  ENTRY_FIRST = 0x80377B6Cu,
  ENTRY_LAST = 0x80377D58u,
  OUTSIDE_RETURN_PC = 0x80001000u,
  STACK_ADDRESS = 0x80010000u,
  DESTINATION_ADDRESS = 0x80020000u,
  SOURCE_ADDRESS = 0x80030000u,
  R2_ADDRESS = 0x80400000u,
  RAM_BYTES = 5 * 1024 * 1024,
  SEMANTIC_VARIANTS = 8,
  REPEATS = 9,
};

typedef void (*GuestFunction)(CPUState*);

static uint64_t next_random(uint64_t* state)
{
  *state ^= *state << 13;
  *state ^= *state >> 7;
  *state ^= *state << 17;
  return *state;
}

static void write_f32(CPUState* cpu, uint32_t address, float value)
{
  uint32_t bits;
  memcpy(&bits, &value, sizeof(bits));
  mem_write32(cpu, address, bits);
}

static void write_f64(CPUState* cpu, uint32_t address, double value)
{
  uint64_t bits;
  memcpy(&bits, &value, sizeof(bits));
  mem_write64(cpu, address, bits);
}

static void initialize(CPUState* cpu, uint8_t* ram, uint64_t* random,
                       uint32_t entry, unsigned variant)
{
  memset(cpu, 0, sizeof(*cpu));
  memset(ram, 0, RAM_BYTES);
  cpu->ram = ram;
  cpu->ram_size = RAM_BYTES;
  cpu->pc = entry;
  cpu->lr = OUTSIDE_RETURN_PC;
  cpu->gpr[0] = OUTSIDE_RETURN_PC;
  cpu->gpr[1] = entry >= 0x80377B78u ? STACK_ADDRESS - 96u : STACK_ADDRESS;
  cpu->gpr[2] = R2_ADDRESS;
  cpu->gpr[3] = SOURCE_ADDRESS;
  cpu->gpr[4] = DESTINATION_ADDRESS;
  cpu->gpr[31] = DESTINATION_ADDRESS;
  cpu->msr = (variant & 1u) == 0 ? PPC_MSR_FP : 0;
  cpu->hid2 = PPC_HID2_LSQE | PPC_HID2_PSE;
  cpu->fpscr = (uint32_t)next_random(random) & 0x0007f8ffu;
  cpu->xer = (uint32_t)next_random(random);
  cpu->cr = (uint32_t)next_random(random);
  cpu->downcount = -(int64_t)(variant * 17u);
  cpu->fpr[31] = (double)(float)((int32_t)next_random(random) / 65536.0f);
  cpu->ps1[31] = (double)(float)((int32_t)next_random(random) / 65536.0f);

  mem_write32(cpu, STACK_ADDRESS + 4u, OUTSIDE_RETURN_PC);
  mem_write32(cpu, STACK_ADDRESS - 12u, 0x31415926u);
  write_f64(cpu, STACK_ADDRESS - 8u, cpu->fpr[31]);
  write_f32(cpu, R2_ADDRESS - 5016u, 0.0f);
  write_f32(cpu, R2_ADDRESS - 5012u, 1.0f);
  for (unsigned index = 0; index < 12; ++index)
  {
    const int32_t random_value = (int32_t)(next_random(random) & 0xffffu) - 0x8000;
    write_f32(cpu, SOURCE_ADDRESS + index * 4u,
              (float)random_value / 32768.0f + (float)index * 0.125f);
  }
}

static bool states_equal(const CPUState* left, const CPUState* right)
{
  const uint8_t* left_bytes = (const uint8_t*)left;
  const uint8_t* right_bytes = (const uint8_t*)right;
  const size_t ram_offset = (size_t)((const uint8_t*)&left->ram - left_bytes);
  for (size_t index = 0; index < sizeof(*left); ++index)
  {
    if (index >= ram_offset && index < ram_offset + sizeof(left->ram))
      continue;
    if (left_bytes[index] != right_bytes[index])
      return false;
  }
  return true;
}

static int semantic_check(void)
{
  uint8_t* canonical_ram = malloc(RAM_BYTES);
  uint8_t* weighted_ram = malloc(RAM_BYTES);
  uint8_t* pgo_ram = malloc(RAM_BYTES);
  if (!canonical_ram || !weighted_ram || !pgo_ram)
    return 2;

  uint64_t random = UINT64_C(0xf39217ac648be501);
  unsigned cases = 0;
  for (uint32_t entry = ENTRY_FIRST; entry <= ENTRY_LAST; entry += 4u)
  {
    for (unsigned variant = 0; variant < SEMANTIC_VARIANTS; ++variant)
    {
      CPUState canonical;
      CPUState weighted;
      CPUState pgo;
      initialize(&canonical, canonical_ram, &random, entry, variant);
      weighted = canonical;
      pgo = canonical;
      memcpy(weighted_ram, canonical_ram, RAM_BYTES);
      memcpy(pgo_ram, canonical_ram, RAM_BYTES);
      weighted.ram = weighted_ram;
      pgo.ram = pgo_ram;

      func_80375940_canonical(&canonical);
      func_80375940_weighted(&weighted);
      func_80375940_pgo(&pgo);
      if (!states_equal(&canonical, &weighted) || !states_equal(&canonical, &pgo) ||
          memcmp(canonical_ram, weighted_ram, RAM_BYTES) != 0 ||
          memcmp(canonical_ram, pgo_ram, RAM_BYTES) != 0)
      {
        fprintf(stderr,
                "semantic mismatch entry=%08X variant=%u pc=%08X/%08X/%08X "
                "exception=%08X/%08X/%08X\n",
                entry, variant, canonical.pc, weighted.pc, pgo.pc,
                canonical.exception, weighted.exception, pgo.exception);
        return 1;
      }
      cases++;
    }
  }
  free(canonical_ram);
  free(weighted_ram);
  free(pgo_ram);
  printf("WEIGHTS,semantic-equivalence-%u-cases,PASS\n", cases);
  return 0;
}

static double now_nanoseconds(void)
{
  static mach_timebase_info_data_t timebase;
  if (timebase.denom == 0)
    mach_timebase_info(&timebase);
  return (double)mach_continuous_time() * timebase.numer / timebase.denom;
}

static double measure(GuestFunction function, CPUState* cpu, uint64_t iterations)
{
  const double start = now_nanoseconds();
  for (uint64_t iteration = 0; iteration < iterations; ++iteration)
  {
    cpu->pc = ENTRY_FIRST;
    cpu->lr = OUTSIDE_RETURN_PC;
    cpu->gpr[1] = STACK_ADDRESS;
    cpu->gpr[3] = SOURCE_ADDRESS;
    cpu->gpr[4] = DESTINATION_ADDRESS;
    cpu->msr = PPC_MSR_FP;
    cpu->downcount = 0;
    cpu->exception = 0;
    function(cpu);
    if (cpu->pc != OUTSIDE_RETURN_PC || cpu->exception != 0)
    {
      fprintf(stderr, "incomplete timing iteration=%llu pc=%08X exception=%08X\n",
              (unsigned long long)iteration, cpu->pc, cpu->exception);
      return -1.0;
    }
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
  uint64_t iterations = 100000;
  if (argc > 1)
  {
    char* end = NULL;
    iterations = strtoull(argv[1], &end, 10);
    if (!end || *end != '\0' || iterations == 0)
      return 2;
  }

  uint8_t* canonical_ram = malloc(RAM_BYTES);
  uint8_t* weighted_ram = malloc(RAM_BYTES);
  uint8_t* pgo_ram = malloc(RAM_BYTES);
  if (!canonical_ram || !weighted_ram || !pgo_ram)
    return 2;
  uint64_t random = 1;
  CPUState canonical_state;
  CPUState weighted_state;
  CPUState pgo_state;
  initialize(&canonical_state, canonical_ram, &random, ENTRY_FIRST, 0);
  weighted_state = canonical_state;
  pgo_state = canonical_state;
  memcpy(weighted_ram, canonical_ram, RAM_BYTES);
  memcpy(pgo_ram, canonical_ram, RAM_BYTES);
  weighted_state.ram = weighted_ram;
  pgo_state.ram = pgo_ram;

  double canonical[REPEATS];
  double weighted[REPEATS];
  double pgo[REPEATS];
  for (unsigned repeat = 0; repeat < REPEATS; ++repeat)
  {
    GuestFunction functions[] = {
        func_80375940_canonical, func_80375940_weighted, func_80375940_pgo};
    CPUState* states[] = {&canonical_state, &weighted_state, &pgo_state};
    double* outputs[] = {&canonical[repeat], &weighted[repeat], &pgo[repeat]};
    for (unsigned index = 0; index < 3; ++index)
    {
      const unsigned rotated = (index + repeat) % 3u;
      *outputs[rotated] = measure(functions[rotated], states[rotated], iterations);
    }
  }
  qsort(canonical, REPEATS, sizeof(double), compare_double);
  qsort(weighted, REPEATS, sizeof(double), compare_double);
  qsort(pgo, REPEATS, sizeof(double), compare_double);
  const double canonical_ns = canonical[REPEATS / 2];
  const double weighted_ns = weighted[REPEATS / 2];
  const double pgo_ns = pgo[REPEATS / 2];
  printf("arm,median_ns_per_entry\ncanonical,%.6f\nweighted,%.6f\npgo,%.6f\n",
         canonical_ns, weighted_ns, pgo_ns);
  printf("weighted_improvement_percent,%.6f\n",
         (1.0 - weighted_ns / canonical_ns) * 100.0);
  printf("pgo_improvement_percent,%.6f\n",
         (1.0 - pgo_ns / canonical_ns) * 100.0);
  return 0;
}
