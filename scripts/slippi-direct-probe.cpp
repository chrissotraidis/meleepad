// Private Slippi Direct acceptance runtime. No scripted inputs or fake account.
#include "slippi-direct-probe.hpp"
#include "slippi-probe-account.hpp"
#include "slippi-audio-probe.hpp"
#include "slippi-direct-trace.hpp"
#include "slippi-frame-profiler.hpp"
#include "moderngekko/runtime.hpp"
#include "moderngekko/module.h"
#include "Core/Slippi/SlippiCompat.h"
#include "Core/Cheats/GeckoCode.h"
#include "Core/Cheats/GeckoCodeConfig.h"
#include "Core/Config/CheatSettings.h"
#include "Core/Config/SessionSettings.h"
#include "Core/Config/StaticRecompSettings.h"
#include "Core/Config/GraphicsSettings.h"
#include "Core/Core.h"
#include "Core/HW/GCPad.h"
#include "Core/HW/GCPadEmu.h"
#include "Core/HW/SI/SI_Device.h"
#include "InputCommon/InputConfig.h"
#include "Common/IniFile.h"
#include "VideoCommon/VideoConfig.h"
#include <chrono>
#include <cstdlib>
#include <dlfcn.h>
#include <filesystem>
#include <thread>
#include <fstream>

namespace {
const char* BoolText(bool value) { return value ? "true" : "false"; }

const char* RuntimeErrorCodeText(moderngekko::RuntimeErrorCode code) {
  switch (code) {
    case moderngekko::RuntimeErrorCode::AlreadyActive:
      return "already_active";
    case moderngekko::RuntimeErrorCode::InvalidGame:
      return "invalid_game";
    case moderngekko::RuntimeErrorCode::ModuleRequired:
      return "module_required";
    case moderngekko::RuntimeErrorCode::ModuleRejected:
      return "module_rejected";
    case moderngekko::RuntimeErrorCode::PlatformUnavailable:
      return "platform_unavailable";
    case moderngekko::RuntimeErrorCode::InitializationFailed:
      return "initialization_failed";
    case moderngekko::RuntimeErrorCode::BootFailed:
      return "boot_failed";
    case moderngekko::RuntimeErrorCode::InvalidState:
      return "invalid_state";
  }
  return "unknown";
}

const char* ModuleStatusText(ModernGekkoModuleStatus status) {
  switch (status) {
    case MODERNGEKKO_MODULE_OK: return "ok";
    case MODERNGEKKO_MODULE_NULL_DESCRIPTOR: return "null_descriptor";
    case MODERNGEKKO_MODULE_ABI_MISMATCH: return "abi_mismatch";
    case MODERNGEKKO_MODULE_CPU_ABI_MISMATCH: return "cpu_abi_mismatch";
    case MODERNGEKKO_MODULE_CPU_STATE_SIZE_MISMATCH: return "cpu_state_size_mismatch";
    case MODERNGEKKO_MODULE_INVALID_GAME_ID: return "invalid_game_id";
    case MODERNGEKKO_MODULE_GAME_ID_MISMATCH: return "game_id_mismatch";
    case MODERNGEKKO_MODULE_MISSING_DISPATCH: return "missing_dispatch";
    case MODERNGEKKO_MODULE_INVALID_CODE_RANGES: return "invalid_code_ranges";
    case MODERNGEKKO_MODULE_INVALID_SMC_RANGES: return "invalid_smc_ranges";
    case MODERNGEKKO_MODULE_INVALID_CHUNKS: return "invalid_chunks";
    case MODERNGEKKO_MODULE_ENTRY_POINT_UNCOVERED: return "entry_point_uncovered";
    case MODERNGEKKO_MODULE_INVALID_REL_MODULES: return "invalid_rel_modules";
  }
  return "unknown";
}

bool WriteCheckpoint(const std::filesystem::path& root, const char* phase,
                     const char* reason, bool complete, bool runtime_error = false,
                     const char* runtime_error_code = nullptr) {
  std::error_code error;
  std::filesystem::create_directories(root, error);
  if (error) return false;
  const auto target = root / "direct-checkpoint.json";
  const auto temporary = root / "direct-checkpoint.json.tmp";
  std::ofstream output(temporary, std::ios::trunc);
  if (!output) return false;
  output << "{\"phase\":\"" << phase << "\",\"reason\":\"" << reason
         << "\",\"complete\":" << BoolText(complete)
         << ",\"runtime_error\":" << BoolText(runtime_error)
         << (runtime_error_code ? std::string(",\"runtime_error_code\":\"") +
                                   runtime_error_code + "\"" : "")
         << ",\"direct_searches\":" << SlippiDirectProbe::direct_searches.load()
         << ",\"unranked_searches\":" << SlippiDirectProbe::unranked_searches.load()
         << ",\"denied_searches\":" << SlippiDirectProbe::denied_searches.load()
         << ",\"matchmaking_initializing\":"
         << SlippiDirectProbe::matchmaking_initializing.load()
         << ",\"matchmaking_ticket_ready\":"
         << SlippiDirectProbe::matchmaking_ticket_ready.load()
         << ",\"matchmaking_opponent_connecting\":"
         << SlippiDirectProbe::matchmaking_opponent_connecting.load()
         << ",\"matchmaking_connected\":"
         << SlippiDirectProbe::matchmaking_connected.load()
         << ",\"matchmaking_errors\":"
         << SlippiDirectProbe::matchmaking_errors.load() << "}\n";
  output.flush();
  if (!output) {
    output.close();
    std::filesystem::remove(temporary, error);
    return false;
  }
  output.close();
  std::filesystem::rename(temporary, target, error);
  if (error) {
    std::filesystem::remove(temporary, error);
    return false;
  }
  return true;
}
}

int SlippiDirectMain(const char* game, const char* iso, const char* module,
                    const char* user, const std::string& account, void* surface,
                    const std::function<void()>& on_runtime_ready) {
  const auto runtime_user = std::filesystem::path(user);
  const auto run_root = runtime_user.parent_path();
  WriteCheckpoint(run_root, "starting", "none", false);
  if (std::filesystem::exists(user)) {
    WriteCheckpoint(run_root, "failed", "stale_user_directory", false);
    return 2;
  }
  // Declared before the runtime: delete its plaintext copy only after all
  // runtime objects have shut down. Keychain remains the account source.
  SlippiProbeAccount::RuntimeCopy credentials;
  if (!credentials.InstallSerialized(account, user)) {
    WriteCheckpoint(run_root, "failed", "account_stage", false);
    return 20;
  }
  WriteCheckpoint(run_root, "account_staged", "none", false);
  // This records the local Keychain-to-runtime handoff. It deliberately does
  // not mean that Slippi's service accepted the play key.
  SlippiDirectProbe::account_loaded.store(true, std::memory_order_release);
  setenv("STATICRECOMP_NO_FALLBACK_JIT", "1", 1);
  moderngekko::RuntimeConfig config;
  config.game_root = game;
  config.disc_image = iso;
  config.module = moderngekko::ModuleSource::DynamicPath(module);
  config.user_directory = user;
  config.render_surface = surface;
  config.graphics.backend = "Metal";
  config.audio.backend = "CoreAudio";
  config.headless = false;
  config.input.background_input = true;
  std::atomic<unsigned> memory_errors{0}, graphics_errors{0};
  struct Errors { std::atomic<unsigned>* memory; std::atomic<unsigned>* graphics; } errors{&memory_errors,&graphics_errors};
  config.log_user_data = &errors;
  config.log_callback = [](moderngekko::RuntimeLogLevel, const char*, const char* text, void* data) {
    auto& errors = *static_cast<Errors*>(data);
    const std::string message(text);
    if (message.find("Invalid read") != std::string::npos || message.find("Invalid write") != std::string::npos ||
        message.find("ISI exception") != std::string::npos) ++*errors.memory;
    if (message.find("FIFO: Unknown Opcode") != std::string::npos || message.find("Aux FIFO not synced") != std::string::npos)
      ++*errors.graphics;
    // Never persist arbitrary upstream logs: they may contain addresses,
    // player names, server payloads or credentials. Record counters only.
  };
  // The bounded QA launch performs the same module checks as Runtime::Create
  // first, but records which class failed. This keeps a native loader failure
  // distinguishable from a descriptor-compatibility failure without storing
  // dlerror text or any account/server data.
  if (SlippiDirectProbe::account_boot_check &&
      config.module.kind == moderngekko::ModuleSource::Kind::DynamicPath) {
    WriteCheckpoint(run_root, "module_preflight", "starting", false);
    auto inspected = moderngekko::InspectGame(config.game_root);
    void* handle = dlopen(config.module.path.c_str(), RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
      const char* loader_error = dlerror();
      std::fprintf(stderr, "[MeleePad] native Slippi module loader error=%s\n",
                   loader_error ? loader_error : "unknown");
      std::ofstream loader_report(run_root / "module-loader-error.txt",
                                  std::ios::trunc);
      if (loader_report)
        loader_report << (loader_error ? loader_error : "unknown") << '\n';
      WriteCheckpoint(run_root, "failed", "module_dlopen", false, false,
                      "library_open_failed");
      return 3;
    }
    auto get_module = reinterpret_cast<ModernGekkoGetModuleFn>(
        dlsym(handle, MODERNGEKKO_GET_MODULE_SYMBOL));
    if (!get_module) {
      dlclose(handle);
      WriteCheckpoint(run_root, "failed", "module_dlopen", false, false,
                      "entry_point_missing");
      return 3;
    }
    ModernGekkoModuleRequirements requirements{
        MODERNGEKKO_CPU_ABI_VERSION, static_cast<std::uint32_t>(sizeof(CPUState)),
        inspected ? inspected.metadata->disc_id.c_str() : nullptr};
    const ModernGekkoModuleStatus status = moderngekko_validate_module(
        get_module(), &requirements);
    dlclose(handle);
    if (status != MODERNGEKKO_MODULE_OK) {
      std::string code = "module_";
      code += ModuleStatusText(status);
      WriteCheckpoint(run_root, "failed", "module_validation", false, false,
                      code.c_str());
      return 3;
    }
    WriteCheckpoint(run_root, "module_preflight", "ok", false);
  }
  auto created = moderngekko::Runtime::Create(config);
  if (!created) {
    WriteCheckpoint(run_root, "failed", "runtime_create", false, false,
                    created.error ? RuntimeErrorCodeText(created.error->code)
                                  : "unknown");
    return 3;
  }
  auto& runtime = *created.runtime;
  if (runtime.GetGameMetadata().disc_id != "GALE01" || runtime.GetGameMetadata().revision != 2) {
    WriteCheckpoint(run_root, "failed", "revision", false);
    return 4;
  }
  Config::SetCurrent(Config::GetInfoForSIDevice(0), SerialInterface::SIDEVICE_GC_CONTROLLER);
  for (int i=1; i<4; ++i) Config::SetCurrent(Config::GetInfoForSIDevice(i), SerialInterface::SIDEVICE_NONE);
  Pad::GetConfig()->GetController(0)->SetInputOverrideFunction(
    [](std::string_view group, std::string_view control, ControlState) -> std::optional<ControlState> {
      std::lock_guard lock(SlippiDirectProbe::pad_mutex);
      const auto& p = SlippiDirectProbe::pad;
      ++SlippiDirectProbe::input_override_reads;
      if (p.x != 0 || p.y != 0 || p.cx != 0 || p.cy != 0 || p.l != 0 || p.r != 0 || p.buttons != 0)
        ++SlippiDirectProbe::input_active_reads;
      if (group == GCPad::MAIN_STICK_GROUP) return control == "X" ? p.x : control == "Y" ? p.y : 0.0;
      if (group == GCPad::C_STICK_GROUP) return control == "X" ? p.cx : control == "Y" ? p.cy : 0.0;
      if (group == GCPad::TRIGGERS_GROUP) {
        if (control == "L-Analog") return p.l;
        if (control == "R-Analog") return p.r;
        if (control == "L") return p.l >= 0.95 ? 1.0 : 0.0;
        if (control == "R") return p.r >= 0.95 ? 1.0 : 0.0;
      }
      if (group == GCPad::BUTTONS_GROUP) {
        const char* names[] = {"A", "B", "X", "Y", "Z", "Start"};
        for (unsigned i=0; i<6; ++i) if (control == names[i]) {
          if (p.buttons & (1u << i))
            ++SlippiDirectProbe::input_button_reads[i];
          return (p.buttons & (1u << i)) ? 1.0 : 0.0;
        }
      }
      return 0.0;
    });
  SlippiCompat::boot_iso_path = iso;
  SlippiCompat::boot_enabled = true;
  Config::SetCurrent(Config::MAIN_SLOT_A, ExpansionInterface::EXIDeviceType::None);
  Config::SetCurrent(Config::MAIN_SLOT_B, SlippiCompat::device_type);
  Config::SetCurrent(Config::SLIPPI_ENABLE_SPECTATOR, false);
  Config::SetCurrent(Config::SLIPPI_ENABLE_JUKEBOX, false);
  Config::SetCurrent(Config::SLIPPI_SAVE_REPLAYS, false);
  Config::SetCurrent(Config::MAIN_ENABLE_CHEATS, true);
  Config::SetCurrent(Config::SESSION_CODE_SYNC_OVERRIDE, true);
  // The main-app host starts the runtime from a UIKit worker rather than the
  // normal Dolphin game-properties flow. Pin these two run settings in the
  // base layer as well, then install the synchronized set immediately. This
  // keeps the Slippi menu hooks active even if a later config reload replaces
  // the current-run layer before the first Gecko handler tick.
  Config::SetBase(Config::MAIN_ENABLE_CHEATS, true);
  Config::SetBase(Config::SESSION_CODE_SYNC_OVERRIDE, true);
  Config::SetCurrent(Config::GFX_VERTEX_LOADER_TYPE, VertexLoaderType::Software);
  Config::SetCurrent(Config::MAIN_STATICRECOMP_IDLE_PC, 0u);
  Config::SetCurrent(Config::MAIN_STATICRECOMP_SECONDARY_IDLE_PC, 0x8034B164u);
  Config::SetCurrent(Config::MAIN_STATICRECOMP_CALLER_IDLE_PC, 0x800195D0u);
  Config::SetCurrent(Config::MAIN_STATICRECOMP_CALLER_IDLE_LR, 0x801A4DACu);
  Common::IniFile ini, empty;
  if (!ini.Load(File::GetSysDirectory()+"GameSettings/GALE01r2.ini")) {
    WriteCheckpoint(run_root, "failed", "game_ini", false);
    return 5;
  }
  auto codes = Gecko::LoadCodes(ini, empty);
  if (std::count_if(codes.begin(), codes.end(), [](const auto& c){return c.enabled;}) != 6) {
    WriteCheckpoint(run_root, "failed", "code_set", false);
    return 6;
  }
  // Retain the explicitly documented required-code diagnostic subset for the
  // first comparison. This does not establish full default-code compatibility.
  for (auto& c : codes) c.enabled = c.enabled && (c.name == "Required: General Codes" ||
    c.name == "Required: Slippi Recording" || c.name == "Required: Slippi Online");
  Gecko::UpdateSyncedCodes(codes);
  Gecko::SetSyncedCodesAsActive();
  const auto active_code_groups = Gecko::CountEnabledCodes();
  auto trace = std::make_shared<SlippiDirectTrace>();
  auto timing = std::make_shared<SlippiFrameProfiler>(config.user_directory);
  auto audio = std::make_shared<SlippiAudioProbe>();
  SlippiCompat::game_frame_observer = [trace,timing,audio](u8 command,const u8* packet,u32 size) {
    if (command==0x36) ++SlippiDirectProbe::game_starts;
    if (command==0x39) ++SlippiDirectProbe::game_ends;
    if (command==0x3c) ++SlippiDirectProbe::game_frames;
    trace->Observe(command,packet,size); timing->Observe(command,packet,size,4); audio->Observe(command,packet,size);
  };
  std::atomic<bool> finished{false};
  std::atomic<bool> runtime_started{false};
  WriteCheckpoint(run_root, "running", "none", false);
  std::thread menu_input;
  if (SlippiDirectProbe::menu_probe) {
    menu_input = std::thread([&runtime_started] {
      struct Event { int second; double x; double y; unsigned buttons; int milliseconds; };
      // This is a QA-only reproduction of ordinary controller input. It is
      // disabled for normal launches and never invents an account or peer.
      // Times are relative to Runtime::Run(), not process start: iOS can spend
      // about a minute creating the Metal surface and booting the disc. The
      // first event is deliberately after the observed memory-card dialog.
      const Event events[] = {
        // Acknowledge both boot prompts before allowing any menu navigation.
        // The second press is the save-data prompt. The third lands on the
        // observed title screen after the long native intro sequence.
        {60, 0.0, 0.0, 1u, 120},
        {62, 0.0, 0.0, 1u, 120},
        {175, 0.0, 0.0, 32u, 120},
        // The title Start press reaches the normal Main Menu. A then opens
        // the Slippi-modified 1-P Mode submenu. Its third entry is rendered
        // as Stadium but its patched handler switches to Online Play.
        {185, 0.0, 0.0, 1u, 120},
        {195, 0.0, 1.0, 0u, 120}, // select the second 1-P Mode entry
        {198, 0.0, 1.0, 0u, 120}, // select the third 1-P Mode entry
        {205, 0.0, 0.0, 1u, 120}, // confirm the selected character
        {215, 0.0, 0.0, 32u, 120}, // press START to search in Unranked Mode
      };
      while (!runtime_started.load(std::memory_order_acquire) &&
             !SlippiDirectProbe::stop.load(std::memory_order_acquire))
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
      if (SlippiDirectProbe::stop.load(std::memory_order_acquire))
        return;
      const auto started = std::chrono::steady_clock::now();
      for (const auto& event : events) {
        if (SlippiDirectProbe::stop.load(std::memory_order_acquire))
          break;
        std::this_thread::sleep_until(started + std::chrono::seconds(event.second));
        {
          std::lock_guard lock(SlippiDirectProbe::pad_mutex);
          SlippiDirectProbe::pad = {event.x, event.y, 0, 0, 0, 0, event.buttons};
        }
        ++SlippiDirectProbe::menu_events_emitted;
        std::this_thread::sleep_for(std::chrono::milliseconds(event.milliseconds));
        std::lock_guard lock(SlippiDirectProbe::pad_mutex);
        SlippiDirectProbe::pad = {};
      }
    });
  }
  std::thread screenshot_monitor;
  if (SlippiDirectProbe::menu_probe) {
    screenshot_monitor = std::thread([&finished, &runtime] {
      // Retain visual checkpoints around the only scripted action. This uses
      // the same renderer screenshot path as the accepted desktop menu probe
      // and avoids reading a guessed guest address from the host thread.
      for (int second = 1; second <= 280 &&
                           !finished.load(std::memory_order_acquire) &&
                           !SlippiDirectProbe::stop.load(std::memory_order_acquire); ++second) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        if (second != 59 && second != 61 && second != 63 && second != 70 &&
            second != 76 && second != 80 && second != 90 && second != 100 && second != 110 &&
            second != 130 && second != 150 && second != 170 && second != 175 &&
            second != 180 && second != 185 && second != 190 && second != 195 &&
            second != 198 && second != 200 && second != 205 && second != 210 &&
            second != 215 && second != 220 &&
            second != 230 && second != 250 && second != 270)
          continue;
        if (Core::GetState(Core::System::GetInstance()) == Core::State::Running)
          Core::SaveScreenShot("meleepad-direct-menu-" + std::to_string(second));
      }
    });
  }
  std::thread watchdog([&] {
    // The bounded account-boot probe needs a finite deadline, but a normal
    // app session must remain under the user's control. The old 900-second
    // limit could terminate an active match or rematch unexpectedly.
    const auto deadline = SlippiDirectProbe::account_boot_check
        ? std::chrono::steady_clock::now() +
            std::chrono::seconds(SlippiDirectProbe::menu_probe ? 300 : 45)
        : std::chrono::steady_clock::time_point::max();
    while (!finished && !SlippiDirectProbe::stop && std::chrono::steady_clock::now()<deadline &&
           memory_errors==0 && graphics_errors==0) std::this_thread::sleep_for(std::chrono::milliseconds(100));
    if (!finished) {
      const char* reason = memory_errors || graphics_errors ? "runtime_error"
                             : std::chrono::steady_clock::now() >= deadline ? "deadline"
                             : "requested";
      WriteCheckpoint(run_root, "stop_requested", reason, false,
                      memory_errors || graphics_errors);
      runtime.RequestStop();
    }
  });
  runtime_started.store(true, std::memory_order_release);
  if (on_runtime_ready)
    on_runtime_ready();
  auto result = runtime.Run();
  finished=true; watchdog.join();
  if (menu_input.joinable()) menu_input.join();
  if (screenshot_monitor.joinable()) screenshot_monitor.join();
  WriteCheckpoint(run_root, "run_returned", result.error ? "runtime_error" : "none",
                  false, result.error.has_value());
  SlippiCompat::game_frame_observer={};
  const bool trace_written=trace->Write(user); timing->Write(); audio->Write(user);
  std::ofstream report(config.user_directory/"direct-runtime.json");
  report << "{\"boot_error\":" << bool(result.error) << ",\"memory_errors\":" << memory_errors.load()
         << ",\"graphics_errors\":" << graphics_errors.load() << ",\"direct_searches\":" << SlippiDirectProbe::direct_searches.load()
         << ",\"unranked_searches\":" << SlippiDirectProbe::unranked_searches.load()
         << ",\"denied_searches\":" << SlippiDirectProbe::denied_searches.load()
         << ",\"matchmaking_initializing\":" << SlippiDirectProbe::matchmaking_initializing.load()
         << ",\"matchmaking_ticket_ready\":" << SlippiDirectProbe::matchmaking_ticket_ready.load()
         << ",\"matchmaking_opponent_connecting\":" << SlippiDirectProbe::matchmaking_opponent_connecting.load()
         << ",\"matchmaking_connected\":" << SlippiDirectProbe::matchmaking_connected.load()
         << ",\"matchmaking_errors\":" << SlippiDirectProbe::matchmaking_errors.load()
         << ",\"account_file_loaded\":" << SlippiDirectProbe::account_loaded.load()
         << ",\"menu_events_emitted\":" << SlippiDirectProbe::menu_events_emitted.load()
         << ",\"input_override_reads\":" << SlippiDirectProbe::input_override_reads.load()
         << ",\"input_active_reads\":" << SlippiDirectProbe::input_active_reads.load()
         << ",\"input_a_reads\":" << SlippiDirectProbe::input_button_reads[0].load()
         << ",\"input_b_reads\":" << SlippiDirectProbe::input_button_reads[1].load()
         << ",\"input_start_reads\":" << SlippiDirectProbe::input_button_reads[5].load()
         << ",\"active_code_groups\":" << active_code_groups
         << ",\"frames\":" << runtime.GetDiagnosticsSnapshot().frame_count
         << ",\"game_starts\":" << SlippiDirectProbe::game_starts.load() << ",\"game_ends\":" << SlippiDirectProbe::game_ends.load()
         << ",\"game_bookends\":" << SlippiDirectProbe::game_frames.load()
         << ",\"code_subset\":\"required\",\"jit_enabled\":false,\"crossplay_accepted\":false}\n";
  report.flush();
  WriteCheckpoint(run_root, "diagnostics_written", result.error ? "runtime_error" : "none",
                  false, result.error.has_value());
  return result.error ? 7 : (memory_errors || graphics_errors ? 8 : (!trace_written ? 21 : 0));
}
