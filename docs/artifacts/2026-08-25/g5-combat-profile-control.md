# G5 combat-only profile control

Date: 2026-08-25

Status: **PROFILE CONTROL PATH VERIFIED; COMBAT CORPUS NOT YET COLLECTED**

## Why this exists

The first profile collected after enabling the revision-0 idle-PC skip still
contained 15,906,830 entries into `loop_80349494`. The host skipped the loop,
but LLVM counted function entry before the dispatcher returned the idle PC.
That reduced-idle corpus produced a PGO-use candidate which regressed the clean
Fountain render distribution and was rejected. A new corpus therefore has to
exclude boot and menu execution at the counter level, not merely skip the idle
loop in the host.

## Instrumented-only module hooks

The module template now exports these functions only when Clang defines
`__LLVM_INSTR_PROFILE_GENERATE`:

```c
void staticrecomp_profile_reset(void);
int staticrecomp_profile_dump(void);
```

They wrap LLVM's supported `__llvm_profile_reset_counters()` and
`__llvm_profile_dump()` interfaces. Uninstrumented and PGO-use modules do not
export either symbol; the existing module descriptor and ABI are unchanged.

The host resolves both symbols optionally from its retained dynamic-library
handle. `STATICRECOMP_PROFILE_TRIGGER=address,mask,value` arms a one-shot
predicate. The emulated CPU thread resets counters on the false-to-true edge
and dumps them on the true-to-false edge. No signal handler, debugger call,
raw profile filename, or concurrent counter mutation is used. With no hooks or
no explicit trigger, the path is dormant.

## Focused real-module regression

`scripts/test-profile-hooks.sh` loads the real GALE01 instrumented dylib, calls
`staticrecomp_get_module()` seven times, resets, calls it three more times, and
dumps. The merged profile must contain exactly:

- `staticrecomp_get_module`: 3
- `staticrecomp_profile_reset`: 0
- `staticrecomp_profile_dump`: 1

The test passed. It also verified that the retained PGO-use module does not
export reset or dump. This proves the seven pre-reset calls are excluded rather
than merely outweighed.

## Live CPU-thread transition proof

The freshly built instrumented module was loaded by the native arm64 runner
with Cubeb and Metal. A persistent MemoryWatcher route enforced the real cold
title barrier and identified the route states. The successful proof armed:

```text
STATICRECOMP_PROFILE_TRIGGER=80477D68,ff0000ff,01000000
```

The runner emitted, in order:

```text
[staticrecomp] profile trigger armed: address=80477d68 mask=ff0000ff value=01000000
[staticrecomp] profile capture started
[staticrecomp] profile capture dumped: result=0
```

The start occurred only when the watcher verified the main-menu route state.
The dump occurred when the same route entered VS CSS and the predicate became
false. The raw profile is retained outside Git at
`/private/tmp/ssbmpad-pgo-idle-combat.ILpAsI/profiles/run-50941.profraw`,
SHA-256
`6c8cf1291d888ef165500780d9e3ec7d362423e5878d8e905d45ecf82f1a8110`.
Its merged profile contains one dump call. The process then reported that the
profile was already written instead of overwriting it at shutdown.

An earlier CSS-trigger diagnostic proved the start edge but the stale CSS
input route did not reach Stage Select, so it is excluded from the dump proof.
It remains useful negative route evidence only.

## Reproduction and hygiene

- canonical dependency patch:
  `patches/moderngekko-dolphin/0005-instrumentation-profile-hooks.patch`
- focused regression: `scripts/test-profile-hooks.sh`
- bootstrap clean-apply/reverse-apply: passed
- native runner rebuild: passed
- dependency bootstrap and scope guard: passed
- runner after proof: stopped
- booted Simulator after proof: none
- ROM, extracted game, raw profile, and dylibs in tracked paths: none

The next run can now arm the trigger on a verified match-state predicate,
collect Fountain combat only, dump on results/scene exit, build a PGO-use
candidate, and screen it against the retained clean Fountain baseline.
