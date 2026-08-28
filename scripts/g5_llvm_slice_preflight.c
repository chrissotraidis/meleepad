#include "core/cpu.h"

#include <mach/mach_time.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void func_80323940(CPUState* ctx);
void func_80323940_llvm(CPUState* ctx);

enum {
  ENTRY_PC = 0x803248DCu,
  OUTSIDE_RETURN_PC = 0x80001000u,
  STACK_ADDRESS = 0x80010000u,
  R2_ADDRESS = 0x80400000u,
  RAM_BYTES = 5 * 1024 * 1024,
  REPEATS = 9,
};

typedef void (*GuestFunction)(CPUState*);

static uint64_t now_nanoseconds(void) {
  static mach_timebase_info_data_t info;
  if (info.denom == 0)
    mach_timebase_info(&info);
  return mach_absolute_time() * info.numer / info.denom;
}

static void write_f32(CPUState* cpu, uint32_t address, float value) {
  uint32_t bits;
  memcpy(&bits, &value, sizeof(bits));
  mem_write32(cpu, address, bits);
}

static void write_f64(CPUState* cpu, uint32_t address, double value) {
  uint64_t bits;
  memcpy(&bits, &value, sizeof(bits));
  mem_write64(cpu, address, bits);
}

static void initialize(CPUState* cpu, uint8_t* ram) {
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
  cpu->fpscr = 0x00020000u;
  cpu->xer = 0x12345678u;
  cpu->cr = 0x87654321u;
  cpu->fpr[1] = 1.25;
  write_f32(cpu, R2_ADDRESS - 6232u, 1.0f);
  write_f32(cpu, R2_ADDRESS - 6228u, 0.5f);
  write_f32(cpu, R2_ADDRESS - 6224u, 0.00001f);
  write_f64(cpu, R2_ADDRESS - 6216u, 4503601774854144.0);
  for (unsigned index = 0; index < 4; ++index)
    write_f32(cpu, 0x803FE8E8u + index * 4u, (float)(index + 1u) * 0.125f);
  for (unsigned index = 0; index < 16; ++index)
    write_f32(cpu, 0x803B7498u + index * 4u, (float)(index + 1u) * 0.03125f);
}

static bool states_equal(const CPUState* left, const CPUState* right) {
  const uint8_t* l = (const uint8_t*)left;
  const uint8_t* r = (const uint8_t*)right;
  const size_t ram_offset = (size_t)((const uint8_t*)&left->ram - l);
  for (size_t index = 0; index < sizeof(*left); ++index) {
    if (index >= ram_offset && index < ram_offset + sizeof(left->ram))
      continue;
    if (l[index] != r[index])
      return false;
  }
  return true;
}

static double measure(GuestFunction function, const CPUState* seed,
                      CPUState* cpu, uint8_t* ram, const uint8_t* seed_ram,
                      const size_t* changed, size_t changed_count,
                      uint64_t iterations) {
  uint64_t start = now_nanoseconds();
  for (uint64_t iteration = 0; iteration < iterations; ++iteration) {
    memcpy(cpu, seed, sizeof(*cpu));
    cpu->ram = ram;
    for (size_t i = 0; i < changed_count; ++i)
      ram[changed[i]] = seed_ram[changed[i]];
    function(cpu);
  }
  uint64_t elapsed = now_nanoseconds() - start;
  return elapsed / (double)iterations;
}

static int compare_double(const void* left, const void* right) {
  const double a = *(const double*)left;
  const double b = *(const double*)right;
  return (a > b) - (a < b);
}

int main(int argc, char** argv) {
  uint64_t iterations = argc > 1 ? strtoull(argv[1], NULL, 10) : 1000000u;
  uint8_t* seed_ram = malloc(RAM_BYTES);
  uint8_t* c_ram = malloc(RAM_BYTES);
  uint8_t* llvm_ram = malloc(RAM_BYTES);
  size_t* changed = malloc(RAM_BYTES * sizeof(*changed));
  if (!seed_ram || !c_ram || !llvm_ram || !changed)
    return 2;

  CPUState seed, c_state, llvm_state;
  initialize(&seed, seed_ram);
  memcpy(c_ram, seed_ram, RAM_BYTES);
  memcpy(llvm_ram, seed_ram, RAM_BYTES);
  c_state = seed;
  llvm_state = seed;
  c_state.ram = c_ram;
  llvm_state.ram = llvm_ram;
  func_80323940(&c_state);
  func_80323940_llvm(&llvm_state);
  if (!states_equal(&c_state, &llvm_state) ||
      memcmp(c_ram, llvm_ram, RAM_BYTES) != 0) {
    fprintf(stderr, "semantic mismatch c_pc=%08X llvm_pc=%08X\n",
            c_state.pc, llvm_state.pc);
    return 1;
  }
  size_t changed_count = 0;
  for (size_t i = 0; i < RAM_BYTES; ++i)
    if (c_ram[i] != seed_ram[i])
      changed[changed_count++] = i;
  printf("SLICE,semantic-equivalence,PASS,pc=%08X,changed_bytes=%zu\n",
         c_state.pc, changed_count);

  double c_samples[REPEATS], llvm_samples[REPEATS];
  for (unsigned repeat = 0; repeat < REPEATS; ++repeat) {
    if ((repeat & 1u) == 0) {
      c_samples[repeat] = measure(func_80323940, &seed, &c_state, c_ram,
                                  seed_ram, changed, changed_count, iterations);
      llvm_samples[repeat] = measure(func_80323940_llvm, &seed, &llvm_state,
                                     llvm_ram, seed_ram, changed, changed_count,
                                     iterations);
    } else {
      llvm_samples[repeat] = measure(func_80323940_llvm, &seed, &llvm_state,
                                     llvm_ram, seed_ram, changed, changed_count,
                                     iterations);
      c_samples[repeat] = measure(func_80323940, &seed, &c_state, c_ram,
                                  seed_ram, changed, changed_count, iterations);
    }
  }
  qsort(c_samples, REPEATS, sizeof(double), compare_double);
  qsort(llvm_samples, REPEATS, sizeof(double), compare_double);
  const double c_ns = c_samples[REPEATS / 2];
  const double llvm_ns = llvm_samples[REPEATS / 2];
  printf("backend,median_ns_per_entry\nC,%.6f\nLLVM,%.6f\n", c_ns, llvm_ns);
  printf("llvm_change_percent,%.6f\n", (llvm_ns / c_ns - 1.0) * 100.0);
  printf("sink,%08X,%08X\n", c_state.pc, llvm_state.pc);
  return 0;
}
