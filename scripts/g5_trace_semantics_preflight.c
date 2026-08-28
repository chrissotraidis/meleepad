// Data-free focused regression for a boundary-guarded generated trace.
// Build with: clang -O2 -std=c11 -Wall -Wextra -Werror ...

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define TRACE_BUDGET INT64_C(256)

enum
{
  PC_A = 0x80004000u,
  PC_B = 0x80005000u,
  PC_C = 0x80006000u,
  PC_FINAL = 0x80007000u,
  PC_DIVERGED = 0x81234560u,
};

typedef struct CPUState
{
  uint32_t pc;
  uint32_t exception;
  int64_t downcount;
  uint32_t value;
  uint32_t calls;
  uint32_t mode;
} CPUState;

typedef void (*TraceBlock)(CPUState* cpu);

typedef struct TraceStep
{
  uint32_t address;
  uint32_t expected_pc;
  TraceBlock block;
} TraceStep;

static void block_a(CPUState* cpu)
{
  cpu->calls++;
  cpu->value += 1;
  cpu->downcount -= 2;
  cpu->pc = PC_B;
}

static void block_b(CPUState* cpu)
{
  cpu->calls++;
  cpu->value += 2;
  cpu->downcount -= 3;
  if (cpu->mode == 1)
    cpu->pc = PC_DIVERGED;
  else
    cpu->pc = PC_C;
  if (cpu->mode == 2)
    cpu->exception = 0x700u;
}

static void block_c(CPUState* cpu)
{
  cpu->calls++;
  cpu->value += 4;
  cpu->downcount -= 5;
  cpu->pc = PC_FINAL;
}

// Returns false only when the caller must use canonical dispatch without any
// trace step having run. Once the first block executes, every early exit is a
// handled dispatch and preserves the exact CPU state produced by that block.
static bool try_trace(CPUState* cpu, bool entry_eligible, const TraceStep* steps,
                      uint32_t step_count)
{
  if (!entry_eligible || step_count == 0 || cpu->pc != steps[0].address)
    return false;

  for (uint32_t i = 0; i < step_count; ++i)
  {
    if (cpu->pc != steps[i].address)
      return true;
    steps[i].block(cpu);
    if (cpu->exception != 0 || cpu->downcount <= -TRACE_BUDGET ||
        cpu->pc != steps[i].expected_pc)
      return true;
  }
  return true;
}

static int check(bool condition, const char* name)
{
  if (condition)
  {
    printf("TRACE,%s,PASS\n", name);
    return 0;
  }
  printf("TRACE,%s,FAIL\n", name);
  return 1;
}

int main(void)
{
  static const TraceStep steps[] = {
      {PC_A, PC_B, block_a},
      {PC_B, PC_C, block_b},
      {PC_C, PC_FINAL, block_c},
  };
  int failures = 0;
  CPUState cpu;

  memset(&cpu, 0, sizeof(cpu));
  cpu.pc = PC_A;
  failures += check(!try_trace(&cpu, false, steps, 3) && cpu.pc == PC_A && cpu.calls == 0 &&
                        cpu.downcount == 0,
                    "invalidated-or-forced-entry-refuses-trace");

  memset(&cpu, 0, sizeof(cpu));
  cpu.pc = PC_DIVERGED;
  failures += check(!try_trace(&cpu, true, steps, 3) && cpu.pc == PC_DIVERGED && cpu.calls == 0,
                    "wrong-entry-uses-canonical-dispatch");

  memset(&cpu, 0, sizeof(cpu));
  cpu.pc = PC_A;
  failures += check(try_trace(&cpu, true, steps, 3) && cpu.pc == PC_FINAL && cpu.calls == 3 &&
                        cpu.value == 7 && cpu.downcount == -10 && cpu.exception == 0,
                    "complete-trace-preserves-state-and-cycle-charge");

  memset(&cpu, 0, sizeof(cpu));
  cpu.pc = PC_A;
  cpu.mode = 1;
  failures += check(try_trace(&cpu, true, steps, 3) && cpu.pc == PC_DIVERGED && cpu.calls == 2 &&
                        cpu.value == 3 && cpu.downcount == -5,
                    "unexpected-successor-exits-after-produced-state");

  memset(&cpu, 0, sizeof(cpu));
  cpu.pc = PC_A;
  cpu.mode = 2;
  failures += check(try_trace(&cpu, true, steps, 3) && cpu.pc == PC_C && cpu.calls == 2 &&
                        cpu.value == 3 && cpu.downcount == -5 && cpu.exception == 0x700u,
                    "exception-exits-before-next-block");

  memset(&cpu, 0, sizeof(cpu));
  cpu.pc = PC_A;
  cpu.downcount = -254;
  failures += check(try_trace(&cpu, true, steps, 3) && cpu.pc == PC_B && cpu.calls == 1 &&
                        cpu.value == 1 && cpu.downcount == -256,
                    "exact-cycle-budget-exits-before-next-block");

  return failures != 0;
}
