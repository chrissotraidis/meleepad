# G5 guest-cost attribution

Date: 2026-08-28

## Question

PERF-079 proved that a small merged region can be faster locally but selected
the region by dispatch-edge frequency. Does the retained byte-identical
line-table Fountain sample identify a single previously untested guest region
with enough inclusive CPU cost to clear the 5% retention gate?

## Result

`scripts/analyze-macos-sample-guest-cost.py` maps direct generated-function
children of `chassis_dispatch` through matching generated C source lines to
guest PC/opcode, then groups nearby sampled PCs without counting nested helper
frames twice. On the retained current-PGO sample it maps 1,127 direct samples;
184 direct samples have line zero or no usable guest line.

The leading regions are:

| Guest range | Inclusive samples | Chassis share | Status |
| --- | ---: | ---: | --- |
| `8033FABC..8033FB6C` | 133 | 8.69% | `WriteMTXPS4x3`; prior PSQ/FIFO routes closed |
| `803408D0..80340994` | 68 | 4.44% | `PSMTXConcat`; prior replacement closed |
| `803248F4..80324B44` | 52 | 3.40% | highest unclosed complete-function family |
| `80377B14..80377C30` | 48 | 3.14% | diffuse render/resource work |
| `8035AB40..8035AC44` | 30 | 1.96% | diffuse render/resource work |

The first two independently reproduce previously retained attribution, which
is a useful check on the mapper. No unclosed single region reaches 5% of the
1,531 chassis samples; even deleting the third region entirely could not pass.
The top 30 clusters cover 545 samples / 35.60%. At a representative 10% local
speedup they would project only 3.56% overall; roughly half of chassis cost
would need the same improvement to reach 5%.

## Decision

Retain the mapper and reject another one-region product experiment. The next
codegen candidate must generalize register/state retention across many guest
functions without adding a common-dispatch tax. This attribution is a
selection bound, not frame-time acceptance evidence. No generated source,
module, app, game, or Simulator changed.
