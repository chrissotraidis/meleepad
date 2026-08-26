# G5 empty forced-fallback preflight

Date: 2026-08-26

## Question

After isolated interrupt-leaf coalescing removed only about 51 of roughly
67,000 CSS native dispatches/frame, is the common empty forced-fallback-range
check large enough to justify another full module build and cold game run?

## Method and result

A temporary optimized arm64 C++ benchmark modeled the exact empty `std::vector`
range scan in `StaticRecompCore::IsForcedFallbackAddress` and a caller-side
empty-vector guard. Both range-test functions were out of line, matching the
non-LTO runner translation units. Nine alternating trials performed 50 million
calls per path.

The first draft was excluded because Clang proved the local vector empty and
erased the guarded loop, reporting an impossible 0 ns. With both paths forced
to remain out of line, the medians were:

| Path | Median |
|---|---:|
| Existing empty range scan | 1.661782 ns/dispatch |
| Caller empty guard | 1.347417 ns/dispatch |
| Saved | 0.314365 ns/dispatch |

At 67,000 CSS dispatches/frame, the projected saving is only 0.021062 ms/frame.
That is an order of magnitude below the roughly 0.2 ms p95 miss and much
smaller than ordinary matched-run variation.

## Decision

**PREFLIGHT REJECTED; NO GAME BUILD.** The temporary benchmark source was
removed and no product, dependency, module, or package changed. Do not add the
empty-vector guard as a performance patch and do not continue shaving isolated
chassis branches without a measured aggregate signal.

The next diagnostic returns to the user's observed symptom: run a longer
watcher-gated normal CSS soak and search rolling windows for sustained
half-rate or sub-55-FPS behavior. This distinguishes the intermittent major
menu slowdown from the separate approximately 0.2 ms strict-tail miss.
