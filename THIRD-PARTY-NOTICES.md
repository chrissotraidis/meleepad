# Third-party notices

MeleePad-owned integration code is licensed under GPL-3.0-or-later; see
[LICENSE](LICENSE). This statement does not relicense third-party files or remove
any original copyright notice. Files with their own license or SPDX identifier
retain those terms. [Credits](CREDITS.md) identifies the principal upstream projects.

ModernGekko and DolRecomp carry GNU GPL version 3 license texts. RecompCore derives
from Dolphin: its COPYING file describes mostly GPLv2-or-later original Dolphin
code, other per-file licenses, and GPLv3 compatibility in aggregate. Preserve its
COPYING, LICENSES directory, and per-file SPDX notices. Dependencies within these
projects retain their own licenses; this page is not an exhaustive inventory of a
particular binary's linked components.

ENet retains Lee Salzman's MIT license and copyright notice. MeleePad's maintained
fork adjusts startup RTT smoothing; that does not change ENet's license.

The Slippi adapter in the pinned RecompCore fork includes Project Slippi Dolphin
code, open-vcdiff and semver, with original notices. Its Rust FFI is a pinned
submodule of the maintained slippi-rust-extensions fork. These are build inputs
for Preview 5, and their license texts are bundled in Notices.

The Apple integration builds on SunPad. Melee decompilation, m-ex, and Slippi
sources retain their original notices and attribution. Their presence as research
references does not imply that every reference is linked into a public build.

The NSO GameCube controller support in `apple/ios/NSOGC` is a copy of NSOGCKit from
[pookee/nso-gamecube-ios](https://github.com/pookee/nso-gamecube-ios) at `fe4a2e4`,
linked into the iPhone and iPad app under the MIT license:

```text
MIT License

Copyright (c) 2026 pookee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

The offline replay reader at `third_party/dashdance/slp.py` derives from
DashDance's `tools/mac/slp.py`, distributed under GPL-2.0-or-later. Its pinned
source commit, original hash, local changes, and GPL-2.0 text are preserved in
`third_party/dashdance/`. It is a developer tool, not linked into the app.

For each release, retain the exact app revision, dependency base commits and
patches, build instructions, original third-party license texts, and the source
corresponding to the code actually distributed. Include notices with the binary,
not only on GitHub. The [dependency guide](docs/DEPENDENCIES.md) records the current
source arrangement; it is not proof that a historical binary is reproducible.

Game images, extracted game assets, saves, signing material, accounts, and locally
generated game modules are not public repository inputs. MeleePad's software
license does not grant rights in the original game. Do not interpret the private
iPad test bundle as an artifact approved for public distribution.
