#pragma once
// Diagnostic snapshots on the game thread; no audio samples or account data.
#include "AudioCommon/Mixer.h"
#include "AudioCommon/SoundStream.h"
#include "Core/System.h"
#include <filesystem>
#include <fstream>

struct SlippiAudioProbe {
  struct Sample { int frame; u64 callbacks, output_frames, underruns; };
  Sample first{}, last{};
  bool observed = false;
  void Observe(u8 command, const u8* packet, u32 size) {
    if (command != 0x3c || size < 5) return;
    const int frame = static_cast<s32>((u32(packet[1]) << 24) |
        (u32(packet[2]) << 16) | (u32(packet[3]) << 8) | u32(packet[4]));
    if (frame < 120 || (observed && frame <= last.frame)) return;
    auto* stream = Core::System::GetInstance().GetSoundStream();
    if (!stream || !stream->GetMixer()) return;
    auto* mixer = stream->GetMixer();
    last = {frame, mixer->GetOutputCallbackCount(), mixer->GetOutputFrameCount(),
            mixer->GetDMAUnderrunCount()};
    if (!observed) first = last;
    observed = true;
  }
  bool HasOutput() const {
    return observed && last.frame > first.frame && last.callbacks > first.callbacks &&
           last.output_frames > first.output_frames;
  }
  void Write(const std::filesystem::path& directory) const {
    std::ofstream file(directory / "slippi-audio-counters.json");
    file << "{\"scope\":\"Mixer output during observed game window; not audible quality acceptance\","
         << "\"observed\":" << (observed ? "true" : "false")
         << ",\"first_frame\":" << first.frame << ",\"last_frame\":" << last.frame
         << ",\"output_callbacks\":" << last.callbacks - first.callbacks
         << ",\"output_frames\":" << last.output_frames - first.output_frames
         << ",\"dma_underrun_delta\":" << last.underruns - first.underruns
         << ",\"dma_underruns_before_window\":" << first.underruns
         << ",\"output_observed\":" << (HasOutput() ? "true" : "false") << "}\n";
  }
};
