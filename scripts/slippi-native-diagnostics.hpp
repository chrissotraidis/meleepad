#pragma once
#include "Core/PowerPC/StaticRecomp/StaticRecompCore.h"
#include "slippi-network-diagnostics.hpp"

// Called only at the CPU-thread EXI input or frame boundary. Do not read core fields
// from the watchdog; it consumes these atomic snapshots instead.
inline void SampleSlippiNativeCounters() {
  if (auto* core = g_static_recomp_core) {
    slippi_network_diagnostics.native_dispatches = core->GetDiagnosticNativeDispatches();
    slippi_network_diagnostics.fallback_steps = core->GetDiagnosticFallbackSteps();
    slippi_network_diagnostics.failed_chunks = core->GetDiagnosticFailedChunks();
    slippi_network_diagnostics.verifications = core->GetDiagnosticVerifications();
    slippi_network_diagnostics.reverify_events = core->GetDiagnosticReverifyEvents();
  }
}
