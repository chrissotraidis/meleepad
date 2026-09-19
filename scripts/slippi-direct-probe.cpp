#include "Common/Timer.h"
// Private Slippi Direct acceptance runtime. No scripted inputs or fake account.
#include "slippi-direct-probe.hpp"
#include "slippi-probe-account.hpp"
#include "slippi-audio-probe.hpp"
#include "slippi-direct-trace.hpp"
#include "slippi-frame-profiler.hpp"
#include "slippi-incident-log.hpp"
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
#include "VideoCommon/PerformanceMetrics.h"
#include <enet/enet.h>
#include <chrono>
#include <cstdlib>
#include <dlfcn.h>
#include <filesystem>
#include <thread>
#include <fstream>


// ENet calls this before resetting its peer. Retain only numeric diagnostics for
// the actual connected game peer, excluding matchmaking and failed hole punches.
extern "C" void meleepad_enet_disconnect_observed(const ENetPeer* peer,
                                                 unsigned cause, unsigned now) {
  auto& d = slippi_network_diagnostics;
  if (d.connected_peer.load(std::memory_order_acquire) != peer) return;
  if (cause == 1) ++d.remote_disconnect_commands;
  if (cause == 2) ++d.reliable_timeouts;
  d.disconnect_ack_age_ms.store(static_cast<uint32_t>(now - peer->lastReceiveTime));
  d.disconnect_rtt_ms.store(peer->roundTripTime);
}

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
         << ",\"ranked_searches\":" << SlippiDirectProbe::ranked_searches.load()
         << ",\"teams_searches\":" << SlippiDirectProbe::teams_searches.load()
         << ",\"party_searches\":" << SlippiDirectProbe::party_searches.load()
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
  SlippiIncidentLog incidents(run_root / "incidents.csv");
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
  struct Errors {
    std::atomic<unsigned>* memory;
    std::atomic<unsigned>* graphics;
    SlippiIncidentLog* incidents;
  } errors{&memory_errors, &graphics_errors, &incidents};
  config.log_user_data = &errors;
  config.log_callback = [](moderngekko::RuntimeLogLevel, const char*, const char* text, void* data) {
    auto& errors = *static_cast<Errors*>(data);
    const std::string message(text);
    slippi_network_diagnostics.ObserveLog(message);
    errors.incidents->ObserveLog(message);
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
  // Preserve real-match evidence through the upstream asynchronous writer.
  // Keep player metadata private with the rest of this diagnostic session.
  Config::SetCurrent(Config::SLIPPI_REPLAY_DIR, (runtime_user / "Slippi/Replays").string());
  Config::SetCurrent(Config::SLIPPI_SAVE_REPLAYS, true);
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
    if (command==0x36) {
      ++SlippiDirectProbe::game_starts;
      SlippiDirectProbe::BeginGameTimeline();
    }
    if (command==0x39) ++SlippiDirectProbe::game_ends;
    if (command==0x3c) {
      ++SlippiDirectProbe::game_frames;
      SlippiDirectProbe::ObserveBookend(packet, size);
    }
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
      const Event legacy_events[] = {
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
      // The software iPad can already be at the native Online menu when the
      // runtime becomes visible, while its emulated frame rate makes 120 ms
      // button holds unreliable. Keep this slower path explicitly opt-in so
      // ordinary/device QA retains the historical schedule.
      const Event simulator_online_events[] = {
        {35, 0.0, 0.0, 1u, 900}, // enter the highlighted Unranked mode
        {42, 0.0, 0.0, 1u, 900}, // select the default fighter
        {49, 0.0, 0.0, 32u, 900}, // lock in and search for an opponent
      };
      const bool simulator_online =
          std::getenv("MELEEPAD_SLIPPI_MENU_PROBE_SIMULATOR") != nullptr;
      const Event* events = simulator_online ? simulator_online_events : legacy_events;
      const std::size_t event_count = simulator_online
          ? sizeof(simulator_online_events) / sizeof(*simulator_online_events)
          : sizeof(legacy_events) / sizeof(*legacy_events);
      while (!runtime_started.load(std::memory_order_acquire) &&
             !SlippiDirectProbe::stop.load(std::memory_order_acquire))
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
      if (SlippiDirectProbe::stop.load(std::memory_order_acquire))
        return;
      const auto started = std::chrono::steady_clock::now();
      for (std::size_t index = 0; index < event_count; ++index) {
        const auto& event = events[index];
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
    // Read the runtime's existing thread-safe counters, including during menus.
    // This records real presentation/vblank progress without capturing media.
    std::ofstream performance(run_root / "performance.csv");
    std::ofstream network(run_root / "network.csv");
    network << "elapsed_s,ping_samples,ping_total_us,ping_latest_us,input_stalls,time_sync_advances,stall_disconnects,invalid_packets,peer_disconnects,peer_reason,apple_service_result,queued_packets,queue_total_us,queue_max_us,loop_max_us,send_failures,enet_rtt_ms,enet_rtt_variance_ms,enet_packet_loss,native_dispatches,fallback_steps,failed_chunks,verifications,reverify_events,enet_throttle_samples,enet_throttle_min,ping_max_us,ping_over250ms,ping_over500ms,service_errors,receive_events,flush_calls,work_max_us,flush_max_us,sent_datagrams,received_datagrams,remote_disconnect_commands,reliable_timeouts,local_disconnect_requests,disconnect_ack_age_ms,disconnect_rtt_ms,input_submitted_count,input_submit_gap_window_us,input_submit_age_us,pad_received_count,pad_receive_gap_window_us,pad_receive_age_us,ack_received_count,ack_receive_gap_window_us,ack_receive_age_us,ping_window_max_us,queue_window_max_us,service_window_max_us,unreliable_sent,unreliable_discarded,local_player_port\n";
    performance << "elapsed_s,fps,vps,speed_ratio,frame_intervals,frame_avg_ms,frame_p95_upper_ms,frame_max_ms,efb_width,efb_height,game_starts,game_bookends,unranked_searches,direct_searches,denied_searches,matchmaking_state,matchmaking_initializing,matchmaking_ticket_ready,matchmaking_opponent_connecting,matchmaking_connected,matchmaking_errors,game_latest_frame,game_finalized_frame,game_progress_frames,game_rewinds,ranked_searches,teams_searches,party_searches\n";
    const auto performance_start = std::chrono::steady_clock::now();
    incidents.Record(SlippiIncidentLog::Event::TelemetryStart);
    int64_t previous_events[5] = {-2, -1, -1, -1, -1};
    auto next_sample = performance_start + std::chrono::seconds(5);
    auto next_network_sample = performance_start + std::chrono::seconds(1);
    // The bounded account-boot probe needs a finite deadline, but a normal
    // app session must remain under the user's control. The old 900-second
    // limit could terminate an active match or rematch unexpectedly.
    const auto deadline = SlippiDirectProbe::account_boot_check
        ? std::chrono::steady_clock::now() +
            std::chrono::seconds(SlippiDirectProbe::menu_probe ? 300 : 45)
        : std::chrono::steady_clock::time_point::max();
    while (!finished && !SlippiDirectProbe::stop && std::chrono::steady_clock::now()<deadline &&
           memory_errors==0 && graphics_errors==0) {
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
      const auto now = std::chrono::steady_clock::now();
      if (now >= next_network_sample && !finished) {
        slippi_network_diagnostics.WriteRow(network,
            std::chrono::duration<double>(now - performance_start).count(), Common::Timer::NowUs());
        network.flush();
        // Counters survive ENet's peer reset. Record changes even when the
        // runtime never exits and therefore never writes its final report.
        const int64_t events[] = {
            SlippiDirectProbe::last_matchmaking_state.load(),
            static_cast<int64_t>(SlippiDirectProbe::game_starts.load()),
            static_cast<int64_t>(slippi_network_diagnostics.remote_disconnect_commands.load()),
            static_cast<int64_t>(slippi_network_diagnostics.reliable_timeouts.load()),
            static_cast<int64_t>(slippi_network_diagnostics.local_disconnect_requests.load())};
        const SlippiIncidentLog::Event types[] = {
            SlippiIncidentLog::Event::MatchmakingState, SlippiIncidentLog::Event::GameStart,
            SlippiIncidentLog::Event::RemoteDisconnect, SlippiIncidentLog::Event::ReliableTimeout,
            SlippiIncidentLog::Event::LocalDisconnect};
        for (size_t i = 0; i < 5; ++i) {
          if (events[i] != previous_events[i]) incidents.Record(types[i], events[i]);
          previous_events[i] = events[i];
        }
        next_network_sample = now + std::chrono::seconds(1);
      }
      if (now >= next_sample && !finished) {
        auto& metrics = Core::System::GetInstance().GetPerfMetrics();
        const auto frames = metrics.TakeFrameIntervalSummary();
        performance << std::chrono::duration<double>(now - performance_start).count()
                    << ',' << metrics.GetFPS() << ',' << metrics.GetVPS()
                    << ',' << metrics.GetSpeed() << ',' << frames.frames
                    << ',' << frames.average_ms << ',' << frames.p95_upper_ms
                    << ',' << frames.maximum_ms << ',' << metrics.GetEFBWidth()
                    << ',' << metrics.GetEFBHeight()
                    << ',' << SlippiDirectProbe::game_starts.load()
                    << ',' << SlippiDirectProbe::game_frames.load()
                    << ',' << SlippiDirectProbe::unranked_searches.load()
                    << ',' << SlippiDirectProbe::direct_searches.load()
                    << ',' << SlippiDirectProbe::denied_searches.load()
                    << ',' << SlippiDirectProbe::last_matchmaking_state.load()
                    << ',' << SlippiDirectProbe::matchmaking_initializing.load()
                    << ',' << SlippiDirectProbe::matchmaking_ticket_ready.load()
                    << ',' << SlippiDirectProbe::matchmaking_opponent_connecting.load()
                    << ',' << SlippiDirectProbe::matchmaking_connected.load()
                    << ',' << SlippiDirectProbe::matchmaking_errors.load()
                    << ',' << SlippiDirectProbe::game_latest_frame.load()
                    << ',' << SlippiDirectProbe::game_finalized_frame.load()
                    << ',' << SlippiDirectProbe::game_progress_frames.load()
                    << ',' << SlippiDirectProbe::game_rewinds.load()
                    << ',' << SlippiDirectProbe::ranked_searches.load()
                    << ',' << SlippiDirectProbe::teams_searches.load()
                    << ',' << SlippiDirectProbe::party_searches.load() << '\n';
        performance.flush();
        WriteCheckpoint(run_root, "running", "none", false,
                        memory_errors || graphics_errors);
        next_sample = now + std::chrono::seconds(5);
      }
    }
    slippi_network_diagnostics.WriteRow(network,
        std::chrono::duration<double>(std::chrono::steady_clock::now() - performance_start).count(), Common::Timer::NowUs());
    network.flush();
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
         << ",\"ranked_searches\":" << SlippiDirectProbe::ranked_searches.load()
         << ",\"teams_searches\":" << SlippiDirectProbe::teams_searches.load()
         << ",\"party_searches\":" << SlippiDirectProbe::party_searches.load()
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
