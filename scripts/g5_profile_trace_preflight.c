// Data-free differential/timing harness for one narrowed generated hot trace.

#include "core/cpu.h"

#include <mach/mach_time.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void func_80375940_canonical(CPUState* ctx);
void func_80377B6C_trace(CPUState* ctx);

enum
{
  ENTRY_PC = 0x80377B6Cu,
  OUTSIDE_RETURN_PC = 0x80001000u,
  STACK_ADDRESS = 0x80010000u,
  DESTINATION_ADDRESS = 0x80020000u,
  SOURCE_ADDRESS = 0x80030000u,
  R2_ADDRESS = 0x80400000u,
  RAM_BYTES = 5 * 1024 * 1024,
  SEMANTIC_CASES = 4096,
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

static void initialize(CPUState* cpu, uint8_t* ram, uint64_t* random,
                       unsigned variant)
{
  memset(cpu, 0, sizeof(*cpu));
  memset(ram, 0, RAM_BYTES);
  cpu->ram = ram;
  cpu->ram_size = RAM_BYTES;
  cpu->pc = ENTRY_PC;
  cpu->lr = OUTSIDE_RETURN_PC;
  cpu->gpr[1] = STACK_ADDRESS;
  cpu->gpr[2] = R2_ADDRESS;
  cpu->gpr[3] = SOURCE_ADDRESS;
  cpu->gpr[4] = DESTINATION_ADDRESS;
  cpu->gpr[31] = (uint32_t)next_random(random);
  cpu->msr = (variant & 7u) == 0 ? 0 : PPC_MSR_FP;
  cpu->hid2 = PPC_HID2_LSQE | PPC_HID2_PSE;
  cpu->fpscr = (uint32_t)next_random(random) & 0x0007f8ffu;
  cpu->xer = (uint32_t)next_random(random);
  cpu->cr = (uint32_t)next_random(random);
  cpu->downcount = -(int64_t)(variant & 0xffu);
  cpu->fpr[31] = (double)(float)((int32_t)next_random(random) / 65536.0f);
  cpu->ps1[31] = (double)(float)((int32_t)next_random(random) / 65536.0f);

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
  uint8_t* trace_ram = malloc(RAM_BYTES);
  if (!canonical_ram || !trace_ram)
    return 2;
  uint64_t random = UINT64_C(0x329ab76c45e801fd);
  for (unsigned variant = 0; variant < SEMANTIC_CASES; ++variant)
  {
    CPUState canonical;
    CPUState trace;
    initialize(&canonical, canonical_ram, &random, variant);
    trace = canonical;
    memcpy(trace_ram, canonical_ram, RAM_BYTES);
    trace.ram = trace_ram;
    func_80375940_canonical(&canonical);
    func_80377B6C_trace(&trace);
    if (!states_equal(&canonical, &trace) ||
        memcmp(canonical_ram, trace_ram, RAM_BYTES) != 0)
    {
      fprintf(stderr,
              "trace mismatch variant=%u pc=%08X/%08X exception=%08X/%08X "
              "downcount=%lld/%lld\n",
              variant, canonical.pc, trace.pc, canonical.exception, trace.exception,
              (long long)canonical.downcount, (long long)trace.downcount);
      return 1;
    }
  }
  free(canonical_ram);
  free(trace_ram);
  printf("TRACE,semantic-equivalence-%u-cases,PASS\n", SEMANTIC_CASES);
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
    cpu->pc = ENTRY_PC;
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
  uint8_t* trace_ram = malloc(RAM_BYTES);
  if (!canonical_ram || !trace_ram)
    return 2;
  uint64_t random = 1;
  CPUState canonical_state;
  CPUState trace_state;
  initialize(&canonical_state, canonical_ram, &random, 1);
  trace_state = canonical_state;
  memcpy(trace_ram, canonical_ram, RAM_BYTES);
  trace_state.ram = trace_ram;

  double canonical[REPEATS];
  double trace[REPEATS];
  for (unsigned repeat = 0; repeat < REPEATS; ++repeat)
  {
    if ((repeat & 1u) == 0)
    {
      canonical[repeat] = measure(func_80375940_canonical, &canonical_state, iterations);
      trace[repeat] = measure(func_80377B6C_trace, &trace_state, iterations);
    }
    else
    {
      trace[repeat] = measure(func_80377B6C_trace, &trace_state, iterations);
      canonical[repeat] = measure(func_80375940_canonical, &canonical_state, iterations);
    }
  }
  qsort(canonical, REPEATS, sizeof(double), compare_double);
  qsort(trace, REPEATS, sizeof(double), compare_double);
  const double canonical_ns = canonical[REPEATS / 2];
  const double trace_ns = trace[REPEATS / 2];
  if (canonical_ns < 0.0 || trace_ns < 0.0)
    return 1;
  printf("arm,median_ns_per_entry\ncanonical,%.6f\ntrace,%.6f\n", canonical_ns,
         trace_ns);
  printf("trace_improvement_percent,%.6f\n",
         (1.0 - trace_ns / canonical_ns) * 100.0);
  return 0;
}
