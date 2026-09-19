#include "slippi-packed-float-control.hpp"
#include "Core/Core.h"
#include "Core/System.h"
#include "Core/HW/Memmap.h"
#include "Core/PowerPC/MMU.h"
#include "Core/PowerPC/PowerPC.h"
#include "Core/PowerPC/Interpreter/Interpreter.h"
#include <cstdio>
int main() {
  Config::Init();
  auto& system = Core::System::GetInstance();
  system.SetIsWii(false);
  auto& memory = system.GetMemory(); memory.Init();
  Core::DeclareAsCPUThread();
  auto& state = system.GetPPCState();
  state.msr.DR = 1;
  auto& bat = system.GetMMU().GetDBATTable();
  for (u32 off = 0; off < 0x01800000; off += PowerPC::BAT_PAGE_SIZE)
    bat[(0x80000000u + off) >> PowerPC::BAT_INDEX_SHIFT] = off | PowerPC::BAT_MAPPED_BIT | PowerPC::BAT_PHYSICAL_BIT;
  auto& interpreter = system.GetInterpreter();
  int checks=0, failures=0;
  auto check = [&](bool ok) { ++checks; if (!ok) { ++failures; std::fprintf(stderr,"check %d failed\n",checks); } };
  SlippiCompat::boot_enabled=true;
  SlippiCompat::loaded_gct_address=0x80650000;
  SlippiCompat::loaded_gct_size=0x1000;
  state.pc=0x80650004; state.gpr[3]=0x81000000;
  state.ps[1].Fill(1.25); state.Exceptions=0;
  memory.Write_U32(0xaabbccdd,0x8100000c);
  memory.Write_U32(0xeeff0011,0x81000010);
  Interpreter::stfs(interpreter, UGeckoInstruction{(52u<<26)|(1u<<21)|(3u<<16)|14u});
  check(state.Exceptions==0);
  check(memory.Read_U32(0x8100000c)==0xaabb3fa0 && memory.Read_U32(0x81000010)==0x00000011);
  Interpreter::lfs(interpreter, UGeckoInstruction{(48u<<26)|(2u<<21)|(3u<<16)|14u});
  check(state.Exceptions==0 && state.ps[2].PS0AsDouble()==1.25);
  check(SlippiPackedFloatControl::accesses==2);
  state.pc=0x80001000; state.Exceptions=0;
  Interpreter::stfs(interpreter, UGeckoInstruction{(52u<<26)|(1u<<21)|(3u<<16)|14u});
  check((state.Exceptions & EXCEPTION_ALIGNMENT)!=0);
  state.Exceptions=0;
  Interpreter::stfs(interpreter, UGeckoInstruction{(52u<<26)|(1u<<21)|(3u<<16)|20u});
  check(state.Exceptions==0 && memory.Read_U32(0x81000014)==0x3fa00000);
  state.pc=0x80650004; SlippiCompat::boot_enabled=false; state.Exceptions=0;
  Interpreter::lfs(interpreter, UGeckoInstruction{(48u<<26)|(2u<<21)|(3u<<16)|14u});
  check((state.Exceptions & EXCEPTION_ALIGNMENT)!=0);
  SlippiCompat::boot_enabled=true; state.gpr[3]=0x817ffff0; state.Exceptions=0;
  Interpreter::stfs(interpreter, UGeckoInstruction{(52u<<26)|(1u<<21)|(3u<<16)|14u});
  check((state.Exceptions & EXCEPTION_ALIGNMENT)!=0);
  check(!SlippiPackedFloatControl::Allows(0x80651000,0x8100000e));
  check(!SlippiPackedFloatControl::Allows(0x8064ffff,0x8100000e));
  check(SlippiPackedFloatControl::accesses==2);
  Core::UndeclareAsCPUThread(); memory.Shutdown(); Config::Shutdown();
  std::printf("{\"checks\":%d,\"failures\":%d,\"actual_interpreter_accesses\":true}\n",checks,failures);
  return failures?1:0;
}
