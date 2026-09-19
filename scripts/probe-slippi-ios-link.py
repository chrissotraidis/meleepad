#!/usr/bin/env python3
"""Link the passing offline Slippi probe for iPhoneOS; does not install or run it.

Uses isolated replacement objects ahead of existing core archives. No generated
game module is embedded, and this command-line entry point is not a UIKit app.
"""
import argparse
import json
from pathlib import Path
import re
import runpy
import shlex
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("boot-probe", "component-probe", "upstream", "rust",
                 "rust-ios-archive", "ios-build", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    helpers = runpy.run_path(str(repo / "scripts/probe-slippi-peer.py"))
    sha256, run_logged = (helpers[n] for n in ("sha256", "run_logged"))
    boot, component, build = (p.resolve() for p in
                              (args.boot_probe, args.component_probe, args.ios_build))
    output = args.output.resolve()
    if output.exists() or subprocess.run(
            ["git", "check-ignore", "-q", str(output)], cwd=repo).returncode:
        parser.error("use a new ignored output directory")
    previous = json.loads((boot / "results.json").read_text())
    if not previous.get("results") or not previous.get("game_restore_harness_sha256") or not all(
            row.get("startup_progress") and row.get("game_restore", {}).get("pass")
            for row in previous["results"]):
        parser.error("requires a passing actual-game restore probe")
    overlay = boot / "overlay"
    # Later adapters deliberately supersede earlier versions of the same file.
    expected = {}
    for lock_name, field in (("exi-source-lock.json", "overlay_sha256"),
                             ("boot-source-lock.json", "boot_overlay_sha256")):
        expected.update(json.loads((repo / "patches/slippi" / lock_name).read_text())[field])
    for key in ("gct_loader_invalidation", "game_frame_observer"):
        expected.update(previous[key]["overlay_sha256"])
    for key in ("cache_clear_fix", "restore_invalidation"):
        lock = previous[key]
        expected[lock["path"]] = lock["overlay_sha256"]
    for path, digest in expected.items():
        if sha256(overlay / path) != digest:
            raise RuntimeError(f"overlay changed: {path}")
    if sha256(repo / "scripts/slippi-game-restore-trial.hpp") != previous["game_restore_harness_sha256"]:
        raise RuntimeError("restore harness changed since passing probe")
    if sha256(repo / "scripts/slippi-boot-probe.cpp") != previous["harness_sha256"]:
        raise RuntimeError("boot harness changed since passing probe")
    core = repo / "ref/ModernGekko"
    upstream, rust = args.upstream.resolve(), args.rust.resolve()
    rust_archive = args.rust_ios_archive.resolve()
    database = json.loads((build / "compile_commands.json").read_text())
    base = next(e for e in database if e["file"].endswith("/HW/EXI/EXI_Device.cpp"))
    runtime_command = subprocess.check_output(["ninja", "-t", "commands",
        "CMakeFiles/moderngekko.dir/src/runtime/dolphin_runtime.cpp.o"], cwd=build, text=True).splitlines()[-1]
    runtime = {"command": runtime_command, "directory": str(build)}
    sources = sorted((overlay / "Core/Slippi").glob("*.cpp")) + [overlay / p for p in (
        "Core/HW/EXI/EXI_DeviceSlippi.cpp", "Core/Cheats/GeckoCode.cpp", "Core/State.cpp",
        "Core/HW/DVD/DVDThread.cpp", "VideoCommon/OnScreenDisplay.cpp", "Core/HW/EXI/EXI_Device.cpp",
        "Core/PowerPC/JitCommon/JitCache.cpp", "Core/HLE/HLE_Misc.cpp")]
    sources += [core / "src/runtime/dolphin_runtime.cpp", repo / "scripts/slippi-boot-probe.cpp",
                core / "vendor/dolphin/Source/Core/Core/Config/StaticRecompSettings.cpp"]
    rsp = repo / "apple/ios/Provisioned/iphoneos/libs/MeleePadCore.rsp"
    libraries = [Path(line.removeprefix("-Wl,-force_load,")) for line in rsp.read_text().splitlines() if line.strip()]
    if any(not p.is_relative_to(build) for p in libraries):
        raise RuntimeError("provisioned archives do not belong to requested build")
    dependencies = sorted(component.glob("Semver200*-ios.o")) + [
        component / "vcdiff-ios" / f"lib{n}.a" for n in ("vcdenc", "vcddec", "vcdcom")]
    hashes = {str(p.relative_to(repo)): sha256(p) for p in libraries + dependencies + [rust_archive]}
    output.mkdir(parents=True)
    objects, compiled = [], []
    for source in sources:
        entry = runtime if source.name == "dolphin_runtime.cpp" else next(
            (e for e in database if e["file"].endswith("/" + source.name)), base)
        command = shlex.split(entry["command"])
        command = [a for a in command[:command.index("-o")] if a != "-DOFF"]
        command[1:1] = ["-I" + str(p) for p in
                         (overlay, upstream / "Externals", rust / "ffi/includes", core / "include")]
        command += ["-DSLIPPI=CORE", "-DSLIPPI_ONLINE=CORE", "-DSLIPPI_PROBE_GAME_RESTORE=1",
                    "-include", str(overlay / "Core/Slippi/SlippiCompat.h")]
        obj = output / (source.stem + ".o")
        run_logged(command + ["-c", str(source), "-o", str(obj)], entry["directory"],
                   output / (source.stem + ".log"))
        objects.append(obj)
        compiled.append({"source": str(source.relative_to(repo)), "source_sha256": sha256(source),
                         "object_sha256": sha256(obj)})
    print(f"Compiled {len(objects)} iPhoneOS integration units", flush=True)
    sdk = subprocess.check_output(["xcrun", "--sdk", "iphoneos", "--show-sdk-path"], text=True).strip()
    executable = output / "SlippiProbe"
    command = ["xcrun", "clang++", "-target", "arm64-apple-ios16.0", "-isysroot", sdk,
               "-Wl,-map," + str(output / "link.map"), "-o", str(executable)]
    command += list(map(str, objects + dependencies + [rust_archive] + libraries))
    frameworks = sorted(set(re.findall(r"name = (\w+)\.framework;", (repo / "MeleePad.xcodeproj/project.pbxproj").read_text())))
    frameworks += ["AVFAudio", "CoreFoundation"]
    for name in frameworks:
        command += ["-framework", name]
    command += ["-lz", "-lbz2", "-liconv", "-lresolv", "-lcompression"]
    linked = run_logged(command, output, output / "link.log")
    if "built for newer" in linked.stderr:
        raise RuntimeError("dependency deployment target mismatch")
    metadata = run_logged(["xcrun", "vtool", "-show-build", str(executable)], output, output / "platform.log").stdout
    unchanged = all(sha256(repo / p) == h for p, h in hashes.items())
    result = {"scope": "Full offline Slippi runtime linked for iPhoneOS ARM64; command-line harness only",
              "runner_sha256": sha256(Path(__file__)),
              "boot_result_sha256": sha256(boot / "results.json"), "input_sha256": hashes,
              "compiled": compiled, "executable_sha256": sha256(executable),
              "link_log_sha256": sha256(output / "link.log"), "platform": metadata,
              "archives_unchanged": unchanged, "ios_linked": True, "ios_executed": False,
              "uikit_app_built": False, "game_module_embedded": False, "pass": unchanged}
    (output / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    if not unchanged:
        raise RuntimeError("shared input changed during probe")
    print("Full iPhoneOS Slippi runtime link passed; device execution remains untested", flush=True)


if __name__ == "__main__":
    main()
