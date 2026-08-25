# G5 self-verifying CSS route and Fountain replay

Date: 2026-08-25

Status: **CSS ROUTE PASSES; FOUNTAIN TIMING FAILS G5; VISUAL-001B OPEN**

## Lost terminal notification

The visible four-slot CSS really is `GM_VS`. Melee sets `pending_mode = GM_VS`
when Melee is confirmed, exits `GM_MENU`, and the first `GM_VS` minor scene is
CSS route index zero. The missing terminal notification was in the controller
client, not that source model.

Dolphin sends an empty MemoryWatcher datagram every emulated frame. The route
previously slept for about eleven seconds across menu animations without
reading the socket. Hundreds of empty datagrams could therefore fill or bury
the single meaningful menu-to-VS update. `gcpipe.py` now pumps watched-memory
traffic during step delays, explicit waits, and watched tap holds. The focused
regression failed before the change because `PadWriter.tap()` owned the sleep;
all eleven controller tests pass afterward.

The route also no longer requires an initial GameState zero packet. Watcher
construction can occur after that transient value has already changed. The
source-backed nonzero-to-zero title lockout remains the deterministic boot
barrier and prevents early START.

## Cold replay

The accepted retry bound MemoryWatcher and wrote `Locations.txt` before
launching exactly one runner. Built-in MacBook Air Speakers avoided the known
Jump Desktop virtual-audio startup hang. Audio remained enabled through Cubeb;
no Simulator was booted.

The trace completed successfully:

```text
80477D68=28002D00
80477D68=18182800
80477D68=18182801
80477D68=18182802
804D4594=00000014 ... 00000000
START at 132.60 seconds
80477D68=01011800
80477D68=02020100
terminal GM_VS predicate passed at 143.83 seconds
```

`0x02020100` decodes as current mode `GM_VS=2`, pending mode `2`, previous
mode `GM_MENU=1`, and current scene index `0` (CSS). The route exited zero and
is now self-verifying.

Clean app-window CSS evidence:

- `g5-r0-self-verifying-css.jpeg`
- SHA-256: `1298b909652a977e7a408068c0c13bf070c1d1851ead2a9a4ecb3b647df7bb2f`

The macOS microphone request was neither allowed nor denied. Computer-control
app-window capture excluded the unrelated system sheet without changing that
permission.

## Temporal fighter evidence

The same live runner reached a visually verified Fountain of Dreams match with
Ice Climbers versus level-1 CPU Yoshi. Twelve original app-window JPEGs were
captured during scripted movement, attacks, jumps, overlap, and separation at
approximately 120 ms request spacing:

- directory: `g5-fountain-temporal-mesh-burst/`
- first frame SHA-256:
  `16ae52b3538857ae5f27dd72b00a4a04de2ac8fc6898d5c52e53cb669ea9ddf9`
- last frame SHA-256:
  `8a815d79765e44d729d89e062c21f33a145c00b11759a91398d2bd5b6d2dac73`

The real Yoshi, Popo, and Nana meshes remain coherent throughout this bounded
burst, including direct overlap. This is fresh negative evidence only. It does
not erase the user's reported recurrence or the retained four-player stretch,
so `VISUAL-001B` remains open and promotion-blocking.

## Clean Fountain timing

After all capture stopped, the rematch was visually verified on Fountain. A
clean audio-inclusive interval ran twenty repetitions of the existing combat
cycle with no screenshots or UI inspection inside it. The retained interval
logs were extracted from render line 50,864 and vblank line 52,233 of the live
run logs; the final records do not end in newlines, so `wc -l` is one lower
than each analyzed sample count.

| Metric | Render | Vblank |
|---|---:|---:|
| Samples | 5,463 | 5,804 |
| Mean | 16.683 ms | 16.683 ms |
| Median | 16.677 ms | 16.679 ms |
| p95 | 17.115 ms | 17.180 ms |
| p99 | 17.318 ms | 17.291 ms |
| Worst | 59.024 ms | 73.595 ms |
| Frames <=16.7 ms | 54.714% | 59.717% |

Retained interval logs:

- `g5-fountain-clean-combat-render-times.txt`, SHA-256
  `b575e97a299cc64003d1b58d27f9ccce10d435edc2910b31e65b6af69eb70337`
- `g5-fountain-clean-combat-vblank-times.txt`, SHA-256
  `f32b74bfd03d9e4e18cd18d3cc8ff10a8796f22f7f409a452df3a43a366ecda0`

The window title remained near 59.9 FPS, but the strict G5 requirement is
worst-case at or below 16.7 ms including audio. This interval fails by a wide
tail and must not be promoted as 60 FPS acceptance.

## Cleanup

The app close control terminated the exact runner, no controller or Simulator
remains, and Jump Desktop Audio is restored as the default output. Earlier
misordered/overlapping diagnostic attempts were detected, terminated, and
excluded from every retained timing or visual claim.
