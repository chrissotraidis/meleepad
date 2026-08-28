// Data-free G5 preflight for the exact GALE01 PSMTXCopy guest function.

#include "core/cpu.h"
#include "StaticRecompABI.h"

#include <dlfcn.h>
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
  ENTRY_PC = 0x803408A0u,
  RETURN_PC = 0x90000000u,
  SOURCE_ADDRESS = 0x80100000u,
  DESTINATION_ADDRESS = 0x80100100u,
  RAM_BYTES = 24 * 1024 * 1024,
  MATRIX_BYTES = 48,
  SEMANTIC_CASES = 20000,
  TIMING_REPEATS = 9,
};

static uint64_t next_random(uint64_t* state)
{
  *state ^= *state << 13;
  *state ^= *state >> 7;
  *state ^= *state << 17;
  return *state;
}

static bool state_equal(const CPUState* left, const CPUState* right)
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

static bool psmtxcopy_fast(const StaticRecompModuleDesc* canonical, CPUState* cpu)
{
  // The generated function checks these conditions at each paired load/store.
  // They cannot change inside this leaf. Any nonordinary case stays on the
  // canonical generated path so exceptions and quantized GQR behavior remain
  // exact.
  if ((cpu->msr & PPC_MSR_FP) == 0 || (cpu->hid2 & PPC_HID2_LSQE) == 0 ||
      cpu->gqr[0] != 0 || g_mem_write_journal != NULL ||
      get_ram_ptr(cpu, cpu->gpr[3], MATRIX_BYTES, NULL) == NULL ||
      get_ram_ptr(cpu, cpu->gpr[4], MATRIX_BYTES, NULL) == NULL)
  {
    return canonical->dispatch(cpu, ENTRY_PC);
  }

  cpu->pc = ENTRY_PC;
  cpu->downcount -= 13;
  for (unsigned pair = 0; pair < 6; ++pair)
  {
    const uint32_t source = cpu->gpr[3] + pair * 8u;
    const uint32_t destination = cpu->gpr[4] + pair * 8u;
    const uint64_t packed = mem_read64(cpu, source);
    cpu->fpr[pair] = f64_value(convert_to_double((uint32_t)(packed >> 32)));
    cpu->ps1[pair] = f64_value(convert_to_double((uint32_t)packed));
    const uint32_t first = convert_to_single_ftz(f64_bits(cpu->fpr[pair]));
    const uint32_t second = convert_to_single_ftz(f64_bits(cpu->ps1[pair]));
    mem_write64(cpu, destination, ((uint64_t)first << 32) | second);
  }
  cpu->pc = cpu->lr & ~3u;
  return true;
}

static void initialize_case(CPUState* cpu, uint8_t* ram, uint64_t* random,
                            unsigned iteration)
{
  memset(cpu, 0, sizeof(*cpu));
  memset(ram, 0, RAM_BYTES);
  cpu->ram = ram;
  cpu->ram_size = RAM_BYTES;
  cpu->pc = ENTRY_PC;
  cpu->lr = RETURN_PC;
  cpu->msr = PPC_MSR_FP;
  cpu->hid2 = PPC_HID2_LSQE;
  cpu->downcount = -(int64_t)(iteration & 0xffu);
  cpu->gpr[3] = SOURCE_ADDRESS;
  cpu->gpr[4] = DESTINATION_ADDRESS;
  for (unsigned index = 0; index < 32; ++index)
  {
    cpu->gpr[index] ^= (uint32_t)next_random(random);
    uint64_t bits = next_random(random);
    memcpy(&cpu->fpr[index], &bits, sizeof(bits));
    bits = next_random(random);
    memcpy(&cpu->ps1[index], &bits, sizeof(bits));
  }
  cpu->gpr[3] = SOURCE_ADDRESS;
  // Exercise identical, forward-overlap, backward-overlap, and disjoint copy.
  switch (iteration & 3u)
  {
  case 0:
    cpu->gpr[4] = SOURCE_ADDRESS;
    break;
  case 1:
    cpu->gpr[4] = SOURCE_ADDRESS + 8u;
    break;
  case 2:
    cpu->gpr[3] = SOURCE_ADDRESS + 8u;
    cpu->gpr[4] = SOURCE_ADDRESS;
    break;
  default:
    cpu->gpr[4] = DESTINATION_ADDRESS;
    break;
  }
  for (unsigned byte = 0; byte < 128; ++byte)
    ram[SOURCE_ADDRESS - GC_RAM_BASE - 16u + byte] = (uint8_t)next_random(random);

  if ((iteration & 7u) == 4u)
  {
    cpu->reserve_valid = true;
    cpu->reserve_addr = cpu->gpr[4] + 16u;
  }
  else if ((iteration & 7u) == 5u)
  {
    cpu->reserve_valid = true;
    cpu->reserve_addr = 0x80200000u;
  }

  // Force canonical fallback cases through each entry gate.
  if ((iteration & 31u) == 1u)
    cpu->msr &= ~PPC_MSR_FP;
  else if ((iteration & 31u) == 2u)
    cpu->hid2 &= ~PPC_HID2_LSQE;
  else if ((iteration & 31u) == 3u)
    cpu->gqr[0] = 4u;
  else if ((iteration & 31u) == 4u)
    cpu->gpr[4] = 0x90000000u;
}

static int semantic_check(const StaticRecompModuleDesc* canonical)
{
  uint8_t* canonical_ram = malloc(RAM_BYTES);
  uint8_t* candidate_ram = malloc(RAM_BYTES);
  if (!canonical_ram || !candidate_ram)
    return 2;

  uint64_t random = UINT64_C(0x853c49e6748fea9b);
  for (unsigned iteration = 0; iteration < SEMANTIC_CASES; ++iteration)
  {
    CPUState canonical_cpu;
    CPUState candidate_cpu;
    initialize_case(&canonical_cpu, canonical_ram, &random, iteration);
    candidate_cpu = canonical_cpu;
    memcpy(candidate_ram, canonical_ram, RAM_BYTES);
    candidate_cpu.ram = candidate_ram;

    if (!canonical->dispatch(&canonical_cpu, ENTRY_PC) ||
        !psmtxcopy_fast(canonical, &candidate_cpu))
    {
      fprintf(stderr, "dispatch failure iteration=%u\n", iteration);
      free(canonical_ram);
      free(candidate_ram);
      return 1;
    }

    if (!state_equal(&canonical_cpu, &candidate_cpu) ||
        memcmp(canonical_ram, candidate_ram, RAM_BYTES) != 0)
    {
      fprintf(stderr,
              "semantic mismatch iteration=%u canonical_pc=%08X candidate_pc=%08X "
              "canonical_exception=%08X candidate_exception=%08X\n",
              iteration, canonical_cpu.pc, candidate_cpu.pc,
              canonical_cpu.exception, candidate_cpu.exception);
      free(canonical_ram);
      free(candidate_ram);
      return 1;
    }
  }
  free(canonical_ram);
  free(candidate_ram);
  printf("PSMTXCOPY,semantic-equivalence-%u-cases,PASS\n", SEMANTIC_CASES);
  return 0;
}

static double now_nanoseconds(void)
{
  static mach_timebase_info_data_t timebase;
  if (timebase.denom == 0)
    mach_timebase_info(&timebase);
  return (double)mach_continuous_time() * timebase.numer / timebase.denom;
}

static double measure(const StaticRecompModuleDesc* canonical, CPUState* cpu,
                      bool candidate, uint64_t iterations)
{
  const double start = now_nanoseconds();
  for (uint64_t iteration = 0; iteration < iterations; ++iteration)
  {
    cpu->pc = ENTRY_PC;
    cpu->lr = RETURN_PC;
    cpu->gpr[3] = SOURCE_ADDRESS;
    cpu->gpr[4] = DESTINATION_ADDRESS;
    cpu->downcount = 0;
    cpu->exception = 0;
    if (candidate)
      psmtxcopy_fast(canonical, cpu);
    else
      canonical->dispatch(cpu, ENTRY_PC);
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
  if (argc < 2 || argc > 3)
  {
    fprintf(stderr, "usage: %s canonical-module [iterations]\n", argv[0]);
    return 2;
  }
  uint64_t iterations = 1000000;
  if (argc == 3)
  {
    char* end = NULL;
    iterations = strtoull(argv[2], &end, 10);
    if (!end || *end != '\0' || iterations == 0)
      return 2;
  }

  void* handle = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
  if (!handle)
  {
    fprintf(stderr, "dlopen: %s\n", dlerror());
    return 2;
  }
  StaticRecompGetModuleFn get_module =
      (StaticRecompGetModuleFn)dlsym(handle, STATICRECOMP_GET_MODULE_SYMBOL);
  if (!get_module)
    return 2;
  const StaticRecompModuleDesc* canonical = get_module();
  if (semantic_check(canonical) != 0)
    return 1;

  uint8_t* ram = calloc(1, RAM_BYTES);
  if (!ram)
    return 2;
  CPUState cpu;
  uint64_t random = 1;
  initialize_case(&cpu, ram, &random, 0);
  cpu.gpr[4] = DESTINATION_ADDRESS;

  double canonical_times[TIMING_REPEATS];
  double candidate_times[TIMING_REPEATS];
  for (unsigned repeat = 0; repeat < TIMING_REPEATS; ++repeat)
  {
    if ((repeat & 1u) == 0)
    {
      canonical_times[repeat] = measure(canonical, &cpu, false, iterations);
      candidate_times[repeat] = measure(canonical, &cpu, true, iterations);
    }
    else
    {
      candidate_times[repeat] = measure(canonical, &cpu, true, iterations);
      canonical_times[repeat] = measure(canonical, &cpu, false, iterations);
    }
  }
  qsort(canonical_times, TIMING_REPEATS, sizeof(double), compare_double);
  qsort(candidate_times, TIMING_REPEATS, sizeof(double), compare_double);
  const double canonical_median = canonical_times[TIMING_REPEATS / 2];
  const double candidate_median = candidate_times[TIMING_REPEATS / 2];
  printf("mode,median_ns_per_call\n");
  printf("canonical,%.6f\n", canonical_median);
  printf("chunk_local_candidate,%.6f\n", candidate_median);
  printf("saved_ns_per_call,%.6f\n", canonical_median - candidate_median);
  printf("improvement_percent,%.6f\n",
         (canonical_median - candidate_median) * 100.0 / canonical_median);
  printf("sink,%08X,%016llX\n", cpu.pc,
         (unsigned long long)f64_bits(cpu.fpr[5]));
  free(ram);
  dlclose(handle);
  return 0;
}
