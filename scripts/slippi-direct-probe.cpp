// Private Slippi Direct acceptance runtime. No scripted inputs or fake account.
#include "slippi-direct-probe.hpp"
#include "slippi-probe-account.hpp"
#include "slippi-audio-probe.hpp"
#include "slippi-direct-trace.hpp"
#include "slippi-frame-profiler.hpp"
#include "moderngekko/runtime.hpp"
#include "Core/Slippi/SlippiCompat.h"
#include "Core/Cheats/GeckoCode.h"
#include "Core/Cheats/GeckoCodeConfig.h"
#include "Core/Config/CheatSettings.h"
#include "Core/Config/SessionSettings.h"
#include "Core/Config/StaticRecompSettings.h"
#include "Core/Config/GraphicsSettings.h"
#include "Core/HW/GCPad.h"
#include "Core/HW/GCPadEmu.h"
#include "Core/HW/SI/SI_Device.h"
#include "InputCommon/InputConfig.h"
#include "Common/IniFile.h"
#include "VideoCommon/VideoConfig.h"
#include <chrono>
#include <thread>
#include <fstream>

int SlippiDirectMain(const char* game, const char* iso, const char* module,
                    const char* user, const std::string& account, void* surface) {
  if (std::filesystem::exists(user)) return 2;
  // Declared before the runtime: delete its plaintext copy only after all
  // runtime objects have shut down. Keychain remains the account source.
  SlippiProbeAccount::RuntimeCopy credentials;
  if (!credentials.InstallSerialized(account, user)) return 20;
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
  auto created = moderngekko::Runtime::Create(config);
  if (!created) return 3;
  auto& runtime = *created.runtime;
  if (runtime.GetGameMetadata().disc_id != "GALE01" || runtime.GetGameMetadata().revision != 2) return 4;
  Config::SetCurrent(Config::GetInfoForSIDevice(0), SerialInterface::SIDEVICE_GC_CONTROLLER);
  for (int i=1; i<4; ++i) Config::SetCurrent(Config::GetInfoForSIDevice(i), SerialInterface::SIDEVICE_NONE);
  Pad::GetConfig()->GetController(0)->SetInputOverrideFunction(
    [](std::string_view group, std::string_view control, ControlState) -> std::optional<ControlState> {
      std::lock_guard lock(SlippiDirectProbe::pad_mutex);
      const auto& p = SlippiDirectProbe::pad;
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
        for (unsigned i=0; i<6; ++i) if (control == names[i]) return (p.buttons & (1u<<i)) ? 1.0 : 0.0;
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
  Config::SetCurrent(Config::GFX_VERTEX_LOADER_TYPE, VertexLoaderType::Software);
  Config::SetCurrent(Config::MAIN_STATICRECOMP_IDLE_PC, 0u);
  Config::SetCurrent(Config::MAIN_STATICRECOMP_SECONDARY_IDLE_PC, 0x8034B164u);
  Config::SetCurrent(Config::MAIN_STATICRECOMP_CALLER_IDLE_PC, 0x800195D0u);
  Config::SetCurrent(Config::MAIN_STATICRECOMP_CALLER_IDLE_LR, 0x801A4DACu);
  Common::IniFile ini, empty;
  if (!ini.Load(File::GetSysDirectory()+"GameSettings/GALE01r2.ini")) return 5;
  auto codes = Gecko::LoadCodes(ini, empty);
  if (std::count_if(codes.begin(), codes.end(), [](const auto& c){return c.enabled;}) != 6) return 6;
  // Retain the explicitly documented required-code diagnostic subset for the
  // first comparison. This does not establish full default-code compatibility.
  for (auto& c : codes) c.enabled = c.enabled && (c.name == "Required: General Codes" ||
    c.name == "Required: Slippi Recording" || c.name == "Required: Slippi Online");
  Gecko::UpdateSyncedCodes(codes);
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
  std::thread watchdog([&] {
    // The bounded account-boot probe needs a finite deadline, but a normal
    // app session must remain under the user's control. The old 900-second
    // limit could terminate an active match or rematch unexpectedly.
    const auto deadline = SlippiDirectProbe::account_boot_check
        ? std::chrono::steady_clock::now() + std::chrono::seconds(45)
        : std::chrono::steady_clock::time_point::max();
    while (!finished && !SlippiDirectProbe::stop && std::chrono::steady_clock::now()<deadline &&
           memory_errors==0 && graphics_errors==0) std::this_thread::sleep_for(std::chrono::milliseconds(100));
    if (!finished) runtime.RequestStop();
  });
  auto result = runtime.Run();
  finished=true; watchdog.join();
  SlippiCompat::game_frame_observer={};
  const bool trace_written=trace->Write(user); timing->Write(); audio->Write(user);
  std::ofstream report(config.user_directory/"direct-runtime.json");
  report << "{\"boot_error\":" << bool(result.error) << ",\"memory_errors\":" << memory_errors.load()
         << ",\"graphics_errors\":" << graphics_errors.load() << ",\"direct_searches\":" << SlippiDirectProbe::direct_searches.load()
         << ",\"denied_searches\":" << SlippiDirectProbe::denied_searches.load()
         << ",\"account_file_loaded\":" << SlippiDirectProbe::account_loaded.load()
         << ",\"game_starts\":" << SlippiDirectProbe::game_starts.load() << ",\"game_ends\":" << SlippiDirectProbe::game_ends.load()
         << ",\"game_bookends\":" << SlippiDirectProbe::game_frames.load()
         << ",\"code_subset\":\"required\",\"jit_enabled\":false,\"crossplay_accepted\":false}\n";
  return result.error ? 7 : (memory_errors || graphics_errors ? 8 : (!trace_written ? 21 : 0));
}
