// Data-free G5 preflight for a complete generated single-entry guest function.

#include "core/cpu.h"

#include <mach/mach_time.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void func_80321940(CPUState* ctx);
void func_803248DC_single(CPUState* ctx);

enum
{
  ENTRY_PC = 0x803248DCu,
  OUTSIDE_RETURN_PC = 0x80001000u,
  STACK_ADDRESS = 0x80010000u,
  R2_ADDRESS = 0x80400000u,
  RAM_BYTES = 5 * 1024 * 1024,
  REPEATS = 9,
};

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

static void initialize_case(CPUState* cpu, uint8_t* ram, uint64_t* random)
{
  memset(cpu, 0, sizeof(*cpu));
  memset(ram, 0, RAM_BYTES);
  cpu->ram = ram;
  cpu->ram_size = RAM_BYTES;
  cpu->pc = ENTRY_PC;
  cpu->lr = OUTSIDE_RETURN_PC;
  cpu->gpr[1] = STACK_ADDRESS;
  cpu->gpr[2] = R2_ADDRESS;
  cpu->msr = PPC_MSR_FP;
  cpu->hid2 = PPC_HID2_LSQE | PPC_HID2_PSE;
  cpu->fpscr = (uint32_t)next_random(random) & 0x0007f8ffu;
  cpu->xer = (uint32_t)next_random(random);
  cpu->cr = (uint32_t)next_random(random);
  cpu->fpr[1] = (double)(float)((int32_t)next_random(random) / 65536.0f);

  write_f32(cpu, R2_ADDRESS - 6232u, 1.0f);
  write_f32(cpu, R2_ADDRESS - 6228u, 0.5f);
  write_f32(cpu, R2_ADDRESS - 6224u, 0.00001f);
  write_f64(cpu, R2_ADDRESS - 6216u, 4503601774854144.0);

  const uint32_t vector = 0x803FE8E8u;
  for (unsigned index = 0; index < 4; ++index)
    write_f32(cpu, vector + index * 4u, (float)(index + 1u) * 0.125f);

  for (unsigned index = 0; index < 16; ++index)
    write_f32(cpu, 0x803B7498u + index * 4u, (float)(index + 1u) * 0.03125f);
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
  uint8_t* single_ram = malloc(RAM_BYTES);
  if (!canonical_ram || !single_ram)
    return 2;

  uint64_t random = UINT64_C(0x8ac7234d901be5f6);
  for (unsigned iteration = 0; iteration < 4096; ++iteration)
  {
    CPUState canonical;
    CPUState single;
    initialize_case(&canonical, canonical_ram, &random);
    canonical.downcount = -(int64_t)(iteration & 0xffu);
    if ((iteration & 7u) == 0)
      canonical.msr &= ~PPC_MSR_FP;
    single = canonical;
    memcpy(single_ram, canonical_ram, RAM_BYTES);
    single.ram = single_ram;

    func_80321940(&canonical);
    func_803248DC_single(&single);

    const uint32_t stack_offset = STACK_ADDRESS - GC_RAM_BASE - 64u;
    if (!states_equal(&canonical, &single) ||
        memcmp(canonical_ram + stack_offset, single_ram + stack_offset, 128) != 0)
    {
      fprintf(stderr,
              "semantic mismatch iteration=%u canonical_pc=%08X single_pc=%08X "
              "canonical_exception=%08X single_exception=%08X\n",
              iteration, canonical.pc, single.pc, canonical.exception, single.exception);
      free(canonical_ram);
      free(single_ram);
      return 1;
    }
  }
  free(canonical_ram);
  free(single_ram);
  printf("SINGLE_ENTRY,semantic-equivalence-4096-cases,PASS\n");
  return 0;
}

static double now_nanoseconds(void)
{
  static mach_timebase_info_data_t timebase;
  if (timebase.denom == 0)
    mach_timebase_info(&timebase);
  return (double)mach_continuous_time() * timebase.numer / timebase.denom;
}

typedef void (*GuestFunction)(CPUState*);

static double measure(GuestFunction function, CPUState* cpu, uint64_t iterations)
{
  const double start = now_nanoseconds();
  for (uint64_t iteration = 0; iteration < iterations; ++iteration)
  {
    cpu->pc = ENTRY_PC;
    cpu->lr = OUTSIDE_RETURN_PC;
    cpu->gpr[1] = STACK_ADDRESS;
    cpu->fpr[1] = (double)(float)((int32_t)iteration / 65536.0f);
    cpu->downcount = 0;
    cpu->exception = 0;
    function(cpu);
    if (cpu->pc != OUTSIDE_RETURN_PC)
    {
      fprintf(stderr, "incomplete timing iteration=%llu pc=%08X downcount=%lld\n",
              (unsigned long long)iteration, cpu->pc, (long long)cpu->downcount);
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

  uint64_t iterations = 1000000;
  if (argc > 1)
  {
    char* end = NULL;
    iterations = strtoull(argv[1], &end, 10);
    if (!end || *end != '\0' || iterations == 0)
      return 2;
  }

  uint8_t* ram = malloc(RAM_BYTES);
  if (!ram)
    return 2;
  CPUState cpu;
  uint64_t random = 1;
  initialize_case(&cpu, ram, &random);

  double canonical[REPEATS];
  double single[REPEATS];
  for (unsigned repeat = 0; repeat < REPEATS; ++repeat)
  {
    if ((repeat & 1u) == 0)
    {
      canonical[repeat] = measure(func_80321940, &cpu, iterations);
      single[repeat] = measure(func_803248DC_single, &cpu, iterations);
    }
    else
    {
      single[repeat] = measure(func_803248DC_single, &cpu, iterations);
      canonical[repeat] = measure(func_80321940, &cpu, iterations);
    }
  }
  qsort(canonical, REPEATS, sizeof(double), compare_double);
  qsort(single, REPEATS, sizeof(double), compare_double);
  const double canonical_median = canonical[REPEATS / 2];
  const double single_median = single[REPEATS / 2];
  if (canonical_median < 0.0 || single_median < 0.0)
    return 1;
  printf("mode,median_ns_per_call\n");
  printf("canonical,%.6f\n", canonical_median);
  printf("single_entry,%.6f\n", single_median);
  printf("saved_ns_per_call,%.6f\n", canonical_median - single_median);
  printf("improvement_percent,%.6f\n",
         (canonical_median - single_median) * 100.0 / canonical_median);
  printf("sink,%08X,%08X\n", cpu.pc, cpu.fpscr);
  free(ram);
  return 0;
}
