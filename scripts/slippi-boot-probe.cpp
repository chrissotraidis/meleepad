// Isolated, account-free Slippi boot experiment. Requires owner-supplied game
// data and native module. Keep all generated artifacts under ignored ref/.
#include "moderngekko/runtime.hpp"
#include "Core/Slippi/SlippiCompat.h"
#include "Core/Cheats/GeckoCode.h"
#include "Core/Cheats/GeckoCodeConfig.h"
#include "Core/Config/CheatSettings.h"
#include "Core/Config/SessionSettings.h"
#include "Core/Config/GraphicsSettings.h"
#include "VideoCommon/VideoConfig.h"
#include "Core/Core.h"
#include "Core/PowerPC/PowerPC.h"
#include "Core/PowerPC/JitInterface.h"
#include "Core/PowerPC/MMU.h"
#include "Core/System.h"
#include "Core/HW/Memmap.h"
#include "Core/HW/GCPad.h"
#include "Core/HW/GCPadEmu.h"
#include "InputCommon/InputConfig.h"
#include "Core/HW/SI/SI_Device.h"
#include "Common/IniFile.h"
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <map>
#include <sstream>
#include <thread>

static std::atomic<unsigned> memory_errors{0};
static std::atomic<unsigned> graphics_errors{0};
struct InputEvent { int second, port; std::string button; double x, y; int milliseconds; };
struct ScriptPad { std::atomic<int> button{0}; std::atomic<double> x{0}, y{0}; };
#ifdef SLIPPI_PROBE_GAME_RESTORE
#include "slippi-game-restore-trial.hpp"
#endif

int main(int argc, char** argv)
{
  if (argc != 5 || std::filesystem::exists(argv[4])) return 2;
  const int duration = std::getenv("SLIPPI_PROBE_SECONDS") ? std::atoi(std::getenv("SLIPPI_PROBE_SECONDS")) : 20;
  if (duration < 20 || duration > 60) return 12;
  std::vector<InputEvent> input_events;
  if (const char* path = std::getenv("SLIPPI_PROBE_INPUT_SCRIPT")) {
    std::ifstream script(path);
    if (!script) return 13;
    std::string line;
    int total_input_ms = 0;
    while (std::getline(script, line)) {
      if (line.empty()) continue;
      InputEvent event;
      std::istringstream row(line);
      std::string extra;
      if (!(row >> event.second >> event.port >> event.button >> event.x >> event.y >> event.milliseconds) || (row >> extra)) return 13;
      if (input_events.size() >= 128 || event.second < 1 || event.second >= duration ||
          event.port < 0 || event.port > 3 || event.milliseconds < 1 || event.milliseconds > 1000 ||
          !std::isfinite(event.x) || !std::isfinite(event.y) || std::abs(event.x) > 1 || std::abs(event.y) > 1 ||
          (event.button != "None" && event.button != "A" && event.button != "B" && event.button != "Start")) return 13;
      total_input_ms += event.milliseconds;
      if (total_input_ms > 20000) return 13;
      input_events.push_back(event);
    }
    if (!script.eof() || input_events.empty()) return 13;
  }
  // Same module + interpreter contract as iOS. No JIT or verification override.
  setenv("STATICRECOMP_NO_FALLBACK_JIT", "1", 1);
  moderngekko::RuntimeConfig config;
  config.game_root = std::filesystem::absolute(argv[1]);
  config.disc_image = std::filesystem::absolute(argv[2]);
  config.module = moderngekko::ModuleSource::DynamicPath(std::filesystem::absolute(argv[3]));
  config.user_directory = std::filesystem::absolute(argv[4]);
  config.headless = true;
  config.graphics.backend = "Null";
  if (const char* graphics = std::getenv("SLIPPI_PROBE_GRAPHICS")) {
    if (std::string(graphics) != "Null" && std::string(graphics) != "Metal" && std::string(graphics) != "Software") return 11;
    config.graphics.backend = graphics;
    config.headless = std::string(graphics) != "Metal";
  }
  config.audio.backend = "No audio output";
  config.input.background_input = true;
  config.log_callback = [](moderngekko::RuntimeLogLevel, const char* category, const char* text, void*) {
    const std::string message(text);
    const bool invalid_memory = message.find("Invalid read") != std::string::npos ||
                                message.find("Invalid write") != std::string::npos ||
                                message.find("ISI exception") != std::string::npos;
    if (invalid_memory && memory_errors.fetch_add(1) >= 8) return;
    const bool invalid_graphics = message.find("FIFO: Unknown Opcode") != std::string::npos ||
                                  message.find("Aux FIFO not synced") != std::string::npos;
    if (invalid_graphics && graphics_errors.fetch_add(1) >= 8) return;
    std::fprintf(stderr, "[runtime:%s] %s\n", category, text);
  };
  auto created = moderngekko::Runtime::Create(config);
  if (!created) {
    std::fprintf(stderr, "create failed: %s\n", created.error->message.c_str());
    return 3;
  }
  auto& runtime = *created.runtime;
  const auto script_pads = std::make_shared<std::array<ScriptPad, 4>>();
#ifdef SLIPPI_PROBE_GAME_RESTORE
  const auto game_restore = std::make_shared<SlippiGameRestoreTrial>();
  game_restore->set_input = [script_pads](double x, bool p1_b, bool p2_b) {
    (*script_pads)[0].x = x;
    (*script_pads)[0].button = p1_b ? 2 : 0;
    (*script_pads)[1].button = p2_b ? 2 : 0;
  };
  SlippiCompat::game_frame_observer = [game_restore](u8 command, const u8* payload, u32 size) {
    game_restore->Observe(command, payload, size);
  };
#endif
  for (int port = 0; port < 4; ++port) {
    if (!std::any_of(input_events.begin(), input_events.end(), [port](const auto& event) { return event.port == port; })) continue;
    Config::SetCurrent(Config::GetInfoForSIDevice(port), SerialInterface::SIDEVICE_GC_CONTROLLER);
    Pad::GetConfig()->GetController(port)->SetInputOverrideFunction(
      [script_pads, port](std::string_view group, std::string_view control, ControlState) -> std::optional<ControlState> {
        const auto& pad = (*script_pads)[port];
        if (group == GCPad::MAIN_STICK_GROUP && control == "X") return pad.x.load();
        if (group == GCPad::MAIN_STICK_GROUP && control == "Y") return pad.y.load();
        const int button = pad.button.load();
        return group == GCPad::BUTTONS_GROUP && ((button == 1 && control == "A") ||
            (button == 2 && control == "B") || (button == 3 && control == "Start")) ? 1.0 : 0.0;
      });
  }
  const bool menu_back = std::getenv("SLIPPI_PROBE_MENU_BACK") != nullptr;
  const bool offline_versus = std::getenv("SLIPPI_PROBE_OFFLINE_VERSUS") != nullptr;
  // 0: neutral, 1: B, 2: main stick down, 3: A. These are ordinary
  // controller events; no scene variables or account state are overwritten.
  const auto menu_control = std::make_shared<std::atomic<int>>(0);
  if (menu_back || offline_versus) {
    Pad::GetConfig()->GetController(0)->SetInputOverrideFunction(
      [menu_control](std::string_view group, std::string_view control, ControlState)
          -> std::optional<ControlState> {
        const int event = menu_control->load();
        if (group == GCPad::MAIN_STICK_GROUP && control == "Y") return event == 2 ? -1.0 : 0.0;
        return group == GCPad::BUTTONS_GROUP &&
                   ((control == GCPad::B_BUTTON && event == 1) || (control == GCPad::A_BUTTON && event == 3))
                   ? 1.0 : 0.0;
      });
  }
  if (runtime.GetGameMetadata().disc_id != "GALE01" || runtime.GetGameMetadata().revision != 2)
    return 4;
  SlippiCompat::boot_iso_path = config.disc_image.string();
  const bool vanilla_control = std::getenv("SLIPPI_PROBE_NO_CODES") != nullptr;
  SlippiCompat::boot_enabled = !vanilla_control;
  Config::SetCurrent(Config::MAIN_SLOT_A, ExpansionInterface::EXIDeviceType::None);
  Config::SetCurrent(Config::MAIN_SLOT_B, vanilla_control ? ExpansionInterface::EXIDeviceType::None : SlippiCompat::device_type);
  Config::SetCurrent(Config::SLIPPI_ENABLE_SPECTATOR, false);
  Config::SetCurrent(Config::SLIPPI_ENABLE_JUKEBOX, false);
  Config::SetCurrent(Config::SLIPPI_SAVE_REPLAYS, false);
  Config::SetCurrent(Config::MAIN_ENABLE_CHEATS, !vanilla_control);
  Config::SetCurrent(Config::SESSION_CODE_SYNC_OVERRIDE, true);
  Config::SetCurrent(Config::GFX_VERTEX_LOADER_TYPE, VertexLoaderType::Software);
  const bool interpreter_control = std::getenv("SLIPPI_PROBE_ALL_INTERPRETER") != nullptr;
  if (interpreter_control) Config::SetCurrent(Config::MAIN_CPU_CORE, PowerPC::CPUCore::Interpreter);
  if (std::getenv("SLIPPI_PROBE_SINGLE_CORE")) Config::SetCurrent(Config::MAIN_CPU_THREAD, false);
  if (std::getenv("SLIPPI_PROBE_GPU_SYNC_OFF"))
    Config::SetCurrent(Config::MAIN_GPU_DETERMINISM_MODE, std::string("none"));
  Common::IniFile ini, empty;
  std::fprintf(stderr, "[slippi-probe] system directory=%s\n", File::GetSysDirectory().c_str());
  if (!ini.Load(File::GetSysDirectory() + "GameSettings/GALE01r2.ini")) return 5;
  auto codes = Gecko::LoadCodes(ini, empty);
  const auto enabled = std::count_if(codes.begin(), codes.end(), [](const auto& code) { return code.enabled; });
  if (enabled != 6) return 6;
  // Diagnostic subsets locate a failing integration; they never establish full
  // Slippi support. The default always retains all six pinned enabled groups.
  const char* group_filter = std::getenv("SLIPPI_PROBE_GROUPS");
  if (group_filter) {
    const std::string filter(group_filter);
    if (filter != "general" && filter != "general-recording" && filter != "required" &&
        filter != "required-normal" && filter != "required-delay" && filter != "required-fod") return 10;
    for (auto& code : codes) {
      const bool selected = code.name == "Required: General Codes" ||
          (filter != "general" && code.name == "Required: Slippi Recording") ||
          (filter.starts_with("required") && code.name == "Required: Slippi Online") ||
          (filter == "required-normal" && code.name == "Recommended: Normal Lag Reduction") ||
          (filter == "required-delay" && code.name == "Recommended: Apply Delay to all In-Game Scenes") ||
          (filter == "required-fod" && code.name == "Recommended: Lagless FoD");
      code.enabled = code.enabled && selected;
    }
    std::fprintf(stderr, "[slippi-probe] diagnostic group subset=%s\n", group_filter);
  }
  Gecko::UpdateSyncedCodes(vanilla_control ? std::vector<Gecko::GeckoCode>{} : codes);
  std::fprintf(stderr, "[slippi-probe] enabled code groups=%zu, mode=%s, no fallback JIT\n",
               vanilla_control ? 0 : static_cast<size_t>(std::count_if(codes.begin(), codes.end(), [](const auto& code) { return code.enabled; })),
               interpreter_control ? "interpreter control" : "native module");

  std::atomic<bool> finished{false};
  std::atomic<bool> late_frame_progress{false};
  const bool capture = std::getenv("SLIPPI_PROBE_CAPTURE") != nullptr;
  const bool screenshot = std::getenv("SLIPPI_PROBE_SCREENSHOT") != nullptr;
  std::map<u32, u64> pc_samples;
  std::thread observer([&] {
    std::uint64_t late_start_frame = 0;
    for (int second = 1; second <= duration && !finished.load(); ++second) {
      if (capture) {
        for (int sample = 0; sample < 100 && !finished.load(); ++sample) {
          std::this_thread::sleep_for(std::chrono::milliseconds(10));
          if (Core::GetState(Core::System::GetInstance()) == Core::State::Running) {
            Core::CPUThreadGuard guard(Core::System::GetInstance());
            ++pc_samples[guard.GetSystem().GetPPCState().pc];
          }
        }
      } else {
        std::this_thread::sleep_for(std::chrono::seconds(1));
      }
      const auto frames = runtime.GetDiagnosticsSnapshot().frame_count;
      for (const auto& event : input_events) {
        if (event.second != second) continue;
        auto& pad = (*script_pads)[event.port];
        pad.x = event.x; pad.y = event.y;
        pad.button = event.button == "A" ? 1 : event.button == "B" ? 2 : event.button == "Start" ? 3 : 0;
        std::this_thread::sleep_for(std::chrono::milliseconds(event.milliseconds));
        pad.button = 0; pad.x = 0; pad.y = 0;
        std::fprintf(stderr, "[slippi-probe] script second=%d port=%d button=%s duration_ms=%d\n",
                     second, event.port, event.button.c_str(), event.milliseconds);
      }
      int menu_event = menu_back && second == 3 ? 1 : 0;
      if (offline_versus) {
        if (second == 5 || second == 6) menu_event = 1;
        if (second == 7) menu_event = 2;
        if (second == 8 || second == 9) menu_event = 3;
      }
      if (menu_event) {
        menu_control->store(menu_event);
        std::this_thread::sleep_for(std::chrono::milliseconds(80));
        menu_control->store(0);
        std::fprintf(stderr, "[slippi-probe] injected 80 ms menu control=%d\n", menu_event);
      }
      if (second == duration - 5) late_start_frame = frames;
      if (second == duration) late_frame_progress = frames > late_start_frame;
      if (Core::GetState(Core::System::GetInstance()) == Core::State::Running) {
        if (screenshot && second == 10) Core::SaveScreenShot("slippi-probe");
        if (screenshot && second == duration - 2) Core::SaveScreenShot("slippi-probe-late");
        Core::CPUThreadGuard guard(Core::System::GetInstance());
        if (second == 5 && std::getenv("SLIPPI_PROBE_REVERIFY_GCT")) {
          // Diagnostic for the pinned captured GCT layout only. Invalidate the
          // cached verdict; normal VerifyChunk must still check every byte.
          guard.GetSystem().GetJitInterface().InvalidateICache(0x8065cc80, 56720, true);
          std::fprintf(stderr, "[slippi-probe] requested normal GCT chunk reverification\n");
        }
        const auto& state = guard.GetSystem().GetPPCState();
        if (capture && second == duration) {
          auto& memory = guard.GetSystem().GetMemory();
          std::ofstream ram(config.user_directory / "slippi-probe-ram.bin", std::ios::binary);
          ram.write(reinterpret_cast<const char*>(memory.GetRAM()), memory.GetRamSizeReal());
          std::fprintf(stderr, "[slippi-probe] captured RAM bytes=%u write_ok=%d\n",
                       memory.GetRamSizeReal(), static_cast<bool>(ram));
        }
        if (second == 1)
          std::fprintf(stderr, "[slippi-probe] cpu_thread=%d gpu_mode=%s graphics=%s vertex_loader=%d\n",
                       Config::Get(Config::MAIN_CPU_THREAD), Config::Get(Config::MAIN_GPU_DETERMINISM_MODE).c_str(),
                       Config::Get(Config::MAIN_GFX_BACKEND).c_str(),
                       static_cast<int>(Config::Get(Config::GFX_VERTEX_LOADER_TYPE)));
        std::fprintf(stderr, "[slippi-probe] second=%d frames=%llu pc=%08x scene=%08x devices=%llu gct_loads=%llu\n",
                     second, static_cast<unsigned long long>(frames), state.pc,
                     PowerPC::MMU::HostRead<u32>(guard, 0x80479d30),
                     static_cast<unsigned long long>(SlippiCompat::device_creations.load()),
                     static_cast<unsigned long long>(SlippiCompat::command_counts[0xd4].load()));
      } else {
        std::fprintf(stderr, "[slippi-probe] second=%d frames=%llu core not running\n", second,
                     static_cast<unsigned long long>(frames));
      }
      if (memory_errors.load() != 0 || graphics_errors.load() != 0) break;
    }
    if (!finished.load()) runtime.RequestStop();
  });
  const auto result = runtime.Run();
  finished = true;
  observer.join();
#ifdef SLIPPI_PROBE_GAME_RESTORE
  SlippiCompat::game_frame_observer = {};
  std::ofstream restore_report(config.user_directory / "slippi-game-restore.json");
  restore_report << "{\"captured\":" << game_restore->captured << ",\"restored\":" << game_restore->restored
      << ",\"completed\":" << game_restore->completed << ",\"baseline_frames\":" << game_restore->baseline.size()
      << ",\"compared\":" << game_restore->compared << ",\"mismatches\":" << game_restore->mismatches
      << ",\"first_replay_frame\":" << game_restore->first_replay_frame
      << ",\"has_motion\":" << game_restore->HasMotion() << ",\"timeline_errors\":" << game_restore->timeline_errors
      << ",\"baseline_rng_packets\":" << game_restore->AuxPackets(0x3a)
      << ",\"baseline_item_packets\":" << game_restore->AuxPackets(0x3b)
      << ",\"pass\":" << game_restore->Passed() << ",\"delays\":[";
  bool first_trial = true;
  for (const auto& trial : game_restore->trials) {
    restore_report << (first_trial ? "" : ",") << "{\"delay\":" << trial.delay
        << ",\"prediction_differences\":" << trial.prediction_differences
        << ",\"compared\":" << trial.compared << ",\"mismatches\":" << trial.mismatches
        << ",\"aux_compared\":" << trial.aux_compared << ",\"aux_mismatches\":" << trial.aux_mismatches
        << ",\"first_replay_frame\":" << trial.first_replay_frame << ",\"completed\":" << trial.completed << "}";
    first_trial = false;
  }
  restore_report << "]}\n";
#endif
  if (capture) {
    std::ofstream samples(config.user_directory / "slippi-probe-pc-samples.csv");
    samples << "pc,samples\n";
    for (const auto& [pc, count] : pc_samples) samples << pc << ',' << count << '\n';
  }
  std::printf("{\"boot_error\":%s,\"memory_errors\":%u,\"graphics_errors\":%u,\"interpreter_control\":%s,\"vanilla_control\":%s,\"frames\":%llu,\"slippi_devices\":%llu,\"commands\":{",
              result.error ? "true" : "false",
              memory_errors.load(), graphics_errors.load(), interpreter_control ? "true" : "false",
              vanilla_control ? "true" : "false",
              static_cast<unsigned long long>(runtime.GetDiagnosticsSnapshot().frame_count),
              static_cast<unsigned long long>(SlippiCompat::device_creations.load()));
  bool first = true;
  for (unsigned command = 0; command < 256; ++command) {
    const auto count = SlippiCompat::command_counts[command].load();
    if (!count) continue;
    std::printf("%s\"%02x\":%llu", first ? "" : ",", command, static_cast<unsigned long long>(count));
    first = false;
  }
  std::printf("},\"late_frame_progress\":%s,\"jit_enabled\":false,\"gameplay_acceptance\":false}\n",
               late_frame_progress.load() ? "true" : "false");
  if (result.error) std::fprintf(stderr, "boot error: %s\n", result.error->message.c_str());
#ifdef SLIPPI_PROBE_GAME_RESTORE
  if (!result.error && !game_restore->Passed()) return 14;
#endif
  return result.error ? 7 : (memory_errors.load() != 0 || graphics_errors.load() != 0 ? 8 :
                            (!late_frame_progress.load() ? 9 : 0));
}
