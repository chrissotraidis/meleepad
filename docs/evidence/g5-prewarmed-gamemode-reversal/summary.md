# PERF-114 through PERF-116 retained evidence summary

All private raw phase logs, samplers, Game Policy extracts, app bundles,
profiled module, and savestate remain under
`/private/tmp/meleepad-perf114-115-gamemode.1aRWbj`; no game data is committed.

Exact common combat work for every run:

- emulated frames: 48123 through 54845, 6,723 rows;
- guest cycles: 23,506,257,223;
- native dispatches: 805,358,717;
- bursts: 14,058,507;
- hook fallbacks: 13,460;
- interpreter fallbacks and EFB misses: zero.

PERF-114 Game Mode A:

- total mean/p95/p99/worst: 16.680769/17.288042/18.112750/24.336541 ms;
- 3,625 rows at or below 16.7 ms, three over 20 ms, zero over 33 ms;
- phase SHA-256 `01507b3d7272d63f32297da34a1443e797fc49d844565cbdfbe69767c3728955`;
- sampler SHA-256 `f13fbcb71bf286579fa7d4186a5ca7af17af9ba6af96e59ecf2932a0dbdc9cc1`.

PERF-115 Game Mode off reversal:

- total mean/p95/p99/worst: 16.722169/17.725125/18.938167/179.210791 ms;
- 3,831 rows at or below 16.7 ms, 38 over 20 ms, six over 33 ms;
- first marker frame 50386: 35.237666 ms total, 34.759027 ms CPU wall,
  16.635403 ms CPU thread, 0.027875 ms `nextDrawable`, runnable state;
- phase SHA-256 `59d46cd8df68f329607bf5533490391df558cdf212cfb224c744d7cde15cff13`;
- marker/ring SHA-256 `21d4e68020fc3217d0ad820060df6f46e1a71024c68d2a79a92390f44cf8b51f` /
  `435cf904760f6d5695f8bc1f0a48cb9371110969538627e772f99a7a18e7e0fa`.

PERF-116 Game Mode A2:

- total mean/p95/p99/worst: 16.673662/17.461625/18.196334/24.380917 ms;
- 3,787 rows at or below 16.7 ms, nine over 20 ms, zero over 33 ms;
- phase SHA-256 `80a7f85634743f40cfa41655b443466e27162e731039515941cc62e74da8db05`;
- sampler SHA-256 `ce3f351c9ed920e10841bd92cbe5dcc141f2ea76a371bcc7816ce3ed8e6d6652`.

Product topology and package:

- wrapper/child gameplay SHA-256 `52da9cc6c97a8282b646d19f1fe572db33f6c88bf525a7f04f5df9957fed3034`;
- topology Game Policy SHA-256 `c43c40d1874b13a671ea2a2c948d4d5ec32e3727222d49e13138d323b0e32c73`;
- signed packaged default config SHA-256 `becf39a0ff37b03a1317dc83d1d960afbc4da60f4bfae57d167e590132026f02`;
- signed package runner SHA-256 `5af0d7f69bb90ae138475fcb2aa379f615775ec3bdd02b9b049df12f47be01a8`.
