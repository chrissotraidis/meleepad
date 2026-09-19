// Real Slippi C++ EXI command dispatch using synthetic memory/resources.
// Run under sandbox-exec with network denied. Does not execute game code.
#include "Core/Slippi/SlippiCompat.h"
#include "Core/HW/EXI/EXI_DeviceSlippi.h"
#include "Core/Cheats/GeckoCode.h"
#include "Core/Config/CheatSettings.h"
#include "Core/Core.h"
#include "Core/HW/Memmap.h"
#include "Core/PowerPC/PowerPC.h"
#include "Core/PowerPC/MMU.h"
#include "Core/System.h"
#include <filesystem>
#include <fstream>
#include <cstdio>

int main(int argc, char** argv)
{
  namespace fs = std::filesystem;
  if (argc != 2 || fs::exists(argv[1])) return 2;
  const auto root = fs::absolute(argv[1]);
  fs::create_directories(root / "user/Slippi");
  fs::create_directories(root / "resources/GameFiles/GALE01");
  const std::string contents = "synthetic Slippi EXI resource";
  std::ofstream(root / "resources/GameFiles/GALE01/probe.dat", std::ios::binary) << contents;
  Config::Init();
  File::SetUserPath(D_USER_IDX, (root / "user").string() + "/");
  Config::SetCurrent(Config::SLIPPI_ENABLE_SPECTATOR, false);
  Config::SetCurrent(Config::SLIPPI_ENABLE_JUKEBOX, false);
  Config::SetCurrent(Config::SLIPPI_SAVE_REPLAYS, false);
  Config::SetCurrent(Config::SLIPPI_ONLINE_DELAY, 3);
  Config::SetCurrent(Config::MAIN_ENABLE_CHEATS, true);
  auto& system = Core::System::GetInstance();
  system.SetIsWii(false);
  auto& memory = system.GetMemory();
  memory.Init();
  Core::DeclareAsCPUThread();
  system.GetPowerPC().GetPPCState().msr.DR = 1;
  auto& bat = system.GetMMU().GetDBATTable();
  for (u32 off = 0; off < 0x01800000; off += PowerPC::BAT_PAGE_SIZE)
    bat[(0x80000000u + off) >> PowerPC::BAT_INDEX_SHIFT] = off | PowerPC::BAT_MAPPED_BIT | PowerPC::BAT_PHYSICAL_BIT;
  memory.Write_U32(0x80bd5c40, 0x804d76b8);
  memory.Write_U32(0x811ad5a0, 0x804d76bc);
  int checks = 0, failures = 0;
  auto check = [&](bool value) { ++checks; if (!value) { ++failures; std::fprintf(stderr, "failed check %d\n", checks); } };
  {
    ExpansionInterface::CEXISlippi device(system, (root / "missing-test-image.iso").string(), (root / "resources").string());
    check(device.IsPresent());
    auto exchange = [&](u8 command, const std::vector<u8>& payload, size_t output_size) {
      std::vector<u8> request{command};
      request.insert(request.end(), payload.begin(), payload.end());
      memory.CopyToEmu(0x81000000, request.data(), request.size());
      device.DMAWrite(0x81000000, request.size());
      device.DMARead(0x81010000, output_size);
      std::vector<u8> output(output_size);
      memory.CopyFromEmu(output.data(), 0x81010000, output.size());
      return output;
    };
    const auto delay = exchange(0xd5, {}, 8);
    check(delay[0] == 1); // response marker
    check(delay[1] == 3); // configured input delay
    auto status = exchange(0xb9, {}, 42);
    check(status[0] == 0); // anonymous, not a successful service login
    check(std::all_of(status.begin() + 1, status.end(), [](u8 value) { return value == 0; }));
    std::vector<u8> filename(64, 0);
    std::copy_n("probe.dat", 9, filename.begin());
    auto length = exchange(0xd1, filename, 8);
    check(Common::swap32(length.data()) == contents.size());
    auto resource = exchange(0xd2, filename, contents.size());
    check(std::string(resource.begin(), resource.end()) == contents);
    Gecko::GeckoCode code;
    code.enabled = true;
    code.codes.push_back({0x04000000, 0x12345678, "synthetic test code"});
    Gecko::SetAndReturnActiveCodes(std::vector<Gecko::GeckoCode>{code});
    auto gct_length = exchange(0xd3, {}, 8);
    check(Common::swap32(gct_length.data()) == 24);
    auto gct = exchange(0xd4, {0x81, 0x02, 0, 0}, 24);
    const std::vector<u8> expected{0,0xd0,0xc0,0xde,0,0xd0,0xc0,0xde,4,0,0,0,0x12,0x34,0x56,0x78,0xff,0,0,0,0,0,0,0};
    check(gct == expected); // serialized only; no cheat or game instruction executed
    std::vector<u8> inputs(25, 0);
    inputs[3] = 1;
    inputs[12] = 3;
    check(exchange(0xb0, inputs, 8)[0] == 3); // no peer attached, must report disconnect
  }
  std::fprintf(stderr, "EXI scope finished: checks=%d failures=%d\n", checks, failures);
  Gecko::Shutdown();
  Core::UndeclareAsCPUThread();
  memory.Shutdown();
  Config::Shutdown();
  std::fprintf(stderr, "Core configuration shutdown finished\n");
  std::printf("{\"checks\":%d,\"failures\":%d,\"actual_cpp_exi_executed\":true,\"game_executed\":false}\n", checks, failures);
  return failures ? 3 : 0;
}
