#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MIXER_H="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/AudioCommon/Mixer.h"
MIXER_CPP="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/AudioCommon/Mixer.cpp"
COREAUDIO_CPP="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/AudioCommon/CoreAudioSoundStream.cpp"
CORE_HOST="$ROOT/apple/ios/MeleePadCoreHost.mm"

for source in "$MIXER_H" "$MIXER_CPP" "$COREAUDIO_CPP" "$CORE_HOST"; do
  [[ -f "$source" ]] || { echo "missing source: $source" >&2; exit 1; }
done

grep -Fq 'GetOutputCallbackCount() const' "$MIXER_H"
grep -Fq 'GetOutputFrameCount() const' "$MIXER_H"
grep -Fq 'GetDMAUnderrunCount() const' "$MIXER_H"
grep -Fq 'GetDMAQueuedGranules() const' "$MIXER_H"
grep -Fq 'GetDMAQueueTargetGranules() const' "$MIXER_H"
grep -Fq 'm_dma_underrun_count.fetch_add(1, std::memory_order_relaxed)' "$MIXER_CPP"
grep -Fq 'sound->GetMixer()->RecordOutputCallback(frames)' "$COREAUDIO_CPP"
grep -Fq '@"audio callbacks=%llu frames=%llu dmaUnderruns=%llu dmaQueued=%llu dmaTarget=%llu\n"' "$CORE_HOST"

echo "iOS audio diagnostics source regression passed"
