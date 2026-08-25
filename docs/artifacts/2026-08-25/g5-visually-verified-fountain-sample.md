# G5 visually verified Fountain sample

Date: 2026-08-25

Status: **STAGE ATTRIBUTION RESTORED; G5 FAILS; VISUAL-001B OPEN**

## Route correction

The exploratory file named `css-p2-iceclimbers.json` did not do what its name
claimed. App-window inspection showed that it moved the player-one cursor to
Fox, left every other slot inactive, and could not start a match. Any blind
screening run that depended on that filename is excluded from stage evidence.

A fresh native macOS run used the retained arm64 runner, retained module,
Metal, 640x528, Cubeb, the isolated revision-0 user directory, and exactly one
FIFO controller. Every consequential transition was inspected in the native
window:

1. Character Select visibly showed player-one Pikachu and level-1 CPU Kirby,
   followed by `READY TO FIGHT`.
2. Stage Select was visible.
3. The red stage highlight and large stage label both read
   `Fountain of Dreams` before A was sent.
4. Live Fountain combat was visible before sampling began.
5. The two-minute match completed at the Kirby-wins results screen.

The retained route frames are in `g5-verified-fountain-route/`. Their ordered
SHA-256 values are:

```text
65cffb36b50db48effc70a89d03b3314e5f2ebb36ceda28b76c21cbf45755aeb
4f56ea9ec41ee2b214e01c9836ad099529dd65d5a6e2bc4012e9e6b017695f9d
4e2b0d8870e7b23669b028142f45aa505c60b05f33985bbb434d6a6d7ad913fe
46b1fb73582ffc87ae38cddc45f2e513b6ee25184907cc024e9bf6c5e9b2762e
b4829632fbdea1d2be374d2b9b215b59a86c998de0387c1eeb7180266ab59301
```

## Combat sample

The 12-second `sample(1)` interval ran only after Fountain combat was visible.
Four repetitions of the existing movement/attack/jump/special combat cycle ran
concurrently. The retained sample is
`g5-verified-fountain-combat-sample.txt`, SHA-256
`4fe6180888044c20687e87d0eb86ee059051f4cb9aacc49f8ced820aa7f051b0`.

Unlike the withdrawn opening-movie sample, this one is valid combat
attribution. Of 8,396 CPU-thread samples, 5,367 were in
`StaticRecompCore::Run`, 2,009 were in the coarse sleep inside
`PrecisionTimer::SleepUntil`, and 192 were in its final yield region. The
hottest generated chunks were `func_8033D940` (476), `func_80375940` (447),
`func_8035D940` (386), and `func_80339940` (328). The retained module was the
old Fountain-only PGO module, SHA-256
`a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`.

This changes the next experiment. The retained module's profile predates the
revision-0 `StaticRecompIdlePC` optimization, so its code layout was trained on
idle polling. A new visually verified, idle-skipping profile is a narrower and
better-supported test than another generic timer or memory fast path.

## Concurrent timing bracket

The exact concurrent sample/control interval is render records 45,413-47,119
and vblank records 46,430-48,137. It includes Cubeb audio and the active combat
cycle, but also includes `sample(1)` overhead, so it is attribution evidence
and a conservative diagnostic rather than the clean G5 acceptance interval.

| Metric | Render | Vblank |
|---|---:|---:|
| Samples | 1,707 | 1,708 |
| Mean | 16.715117 ms | 16.714946 ms |
| Median | 16.684166 ms | 16.683333 ms |
| p95 | 17.565000 ms | 17.282042 ms |
| p99 | 22.529791 ms | 22.364167 ms |
| Worst | 30.614958 ms | 28.707875 ms |
| Frames <=16.7 ms | 54.013% | 64.403% |

The exact extracted byte-stream hashes are
`f7a5fcce20578c3b49c4799f63f21202ead3dc28ab513d8641586a986b9cc6eb`
(render) and
`1d6a63af56c23a9c13bef32fc36f643b34967ac5356592f6dfef165767be1ebd`
(vblank). The full logs remain local with the isolated runtime directory.

## Visual recurrence

Four app-window frames were retained approximately 250 ms apart during the
same verified match. They show large changes in Kirby's body silhouette,
including a very flat horizontal pose in frame three. That can be either a
legitimate squash animation or the user-reported intermittent deformation;
the sequence alone does not distinguish them. It is therefore positive
reproduction coverage, not a closed diagnosis. `VISUAL-001B` remains
promotion-blocking until the same action is compared with the reference
implementation or a clearly impossible connected-mesh stretch is captured.

The frames are in `g5-verified-fountain-adjacent/`, with ordered SHA-256 values:

```text
85f83f76288a8a5a49cc336b5e23309716b50c4103b85b73d5451613a944ba4b
1ff72cb9e09ad60b81921c23d95ac6458593ad42e91c4082bb9682c5714f10b0
031a725d441dca0b491dd6fe7d1ee8ff35d6b20c8c2d70f00b1ce4210f0a8ed3
3f32ea6bec44154ed4fcf52f87094a736b23923a796e5ae4952d1d9e33706994
```

## Cleanup

The app close control terminated the exact native runner. No controller client
or Simulator remains active. The ROM, extracted game, save, module, full
runtime logs, and temporary input fragments remain outside tracked paths.
