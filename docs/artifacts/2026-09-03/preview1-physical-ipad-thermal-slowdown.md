# Preview 1 physical-iPad thermal slowdown

Date: 2026-09-03  
Milestone: MeleePad v0.1.0 Preview 1  
Disposition: accepted technical debt; not fixed and not closed

## Scope

This record summarizes the retained MeleePad runtime log from a hands-on run on
an iPad Pro (12.9-inch, 6th generation) using the Preview 1 candidate at 2x
internal resolution. The user reported visible stuttering after leaving Melee
paused for several minutes and continuing into a heavy Classic-mode encounter
involving a giant Captain Falcon.

The raw device logs are not committed. This document retains only bounded,
non-identifying measurements needed to describe the release debt.

## Timeline

All times below are local device time.

| Time | Retained evidence |
|---|---|
| 16:43:05–16:46:05 | A stable graphics-state signature and unchanged resource counters match the reported in-game pause. FPS/VPS remained approximately 59.9 while aggregate CPU rose from 151% to about 186%. |
| 16:45:02–16:45:06 | The app briefly resigned active and resumed. There was no multi-minute background interval; controller and speaker audio were retained. |
| 16:46:15 | Thermal state changed from nominal to serious. FPS/VPS fell to 51.0/51.0 and DMA underruns increased from 5 to 9. |
| 16:46:25 | FPS/VPS fell to 47.7/47.8, speed ratio to 0.827, and underruns reached 49. |
| 16:46:35 | Minimum report: 46.2 FPS/VPS and 0.776 speed ratio, with 183.3% aggregate CPU and 85 underruns. |
| 16:46:45 | FPS/VPS remained 47.0/47.0 and underruns reached 104. |
| 16:46:55 | FPS/VPS recovered partway to 56.7/57.0; underruns reached 138. |
| 16:47:05 | The ten-second report returned to 59.9 FPS/VPS. Later isolated dips reached 54.4 and 56.9 FPS/VPS while thermal state remained serious. |
| 17:00:45 | Thermal state returned to nominal. |

## Findings

- The slowdown was real and sustained enough for the existing ten-second
  telemetry to capture. It affected both rendered FPS and emulated VPS.
- Audio starvation accompanied the visual slowdown: DMA underruns rose from 5
  to 138 during the main 50-second interval and later reached 169.
- The CPU and video threads were the dominant consumers. Aggregate application
  CPU stayed approximately 182–186% through the worst interval.
- Resident memory stayed near 503–507 MiB during the main event. There was no
  memory warning, crash, audio interruption, or Low Power Mode transition.
- The evidence is consistent with a heavy gameplay/rendering workload running
  out of CPU/video headroom after sustained load and thermal pressure. Because
  performance recovered during lighter work while thermal state was still
  serious, thermal state alone is not a complete explanation.
- iPadOS retained separate CPU-resource diagnostics from earlier MeleePad
  sessions after the app exceeded its sustained CPU-use threshold. They support
  the broader resource-pressure finding but are not the exact slowdown window.

## Telemetry limits

The current log does not identify Melee's internal pause state, stage, match,
characters, or exact transition. Its ten-second reports also lack frame-time
percentiles, hitch counts, GPU command-buffer timing, pipeline-cache misses, and
texture-upload timing. Shorter stutters may therefore be missed even though
this sustained event was captured.

## Preview 1 decision

Ship Preview 1 with this limitation disclosed. Do not claim universal locked
60 FPS. Keep diagnostic export available and ask performance reporters for the
same-run export, device and OS, render scale, scene, controller, and exact
reproduction steps. Reopen optimization only around a repeatable retained
window rather than beginning another broad performance rewrite.
