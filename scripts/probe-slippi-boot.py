#!/usr/bin/env python3
"""Build an isolated no-JIT Slippi boot probe from the passing EXI overlay.

Runs bounded offline controls with owner-supplied v1.02 game data and a native
module. This is startup debugging, not gameplay, rollback or crossplay proof.
"""
import argparse
import json
import os
from pathlib import Path
import plistlib
import runpy
import shlex
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("component-probe", "upstream", "rust", "rust-macos-archive", "build",
                 "game", "iso", "module", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    modes = {"full": {}, "full-single-core": {"SLIPPI_PROBE_SINGLE_CORE": "1"},
             "full-gpu-sync-off": {"SLIPPI_PROBE_GPU_SYNC_OFF": "1"},
             "interpreter": {"SLIPPI_PROBE_ALL_INTERPRETER": "1"},
             "vanilla": {"SLIPPI_PROBE_NO_CODES": "1"},
             "vanilla-interpreter": {"SLIPPI_PROBE_NO_CODES": "1", "SLIPPI_PROBE_ALL_INTERPRETER": "1"}}
    modes.update({name: {"SLIPPI_PROBE_GROUPS": name} for name in
                  ("general", "general-recording", "required", "required-normal", "required-delay", "required-fod")})
    parser.add_argument("--modes", nargs="+", choices=list(modes), default=["full", "vanilla", "interpreter"])
    parser.add_argument("--capture", action="store_true", help="Capture local RAM and CPU-PC samples; changes timing")
    parser.add_argument("--screenshot", action="store_true", help="Save a private startup screenshot in the test user directory")
    parser.add_argument("--reverify-gct", action="store_true", help="Diagnose cached GCT verification failures after initialization; pinned capture layout only")
    parser.add_argument("--cache-clear-fix", action="store_true", help="Test automatic StaticRecomp verification reset on block-cache Clear")
    parser.add_argument("--gct-loader-invalidation", action="store_true", help="Invalidate the game-supplied GCT region after each code-handler return")
    parser.add_argument("--register-trace", action="store_true", help="Record selected native dispatch register state; diagnostic only")
    parser.add_argument("--menu-back", action="store_true", help="Send a controller B press to leave the login menu; offline navigation test")
    parser.add_argument("--offline-versus", action="store_true", help="Use ordinary controller inputs to navigate toward offline Versus mode")
    parser.add_argument("--input-script", type=Path, help="Local controller event file: second port button x y duration_ms per line")
    parser.add_argument("--seconds", type=int, choices=[20, 40, 60], default=20)
    parser.add_argument("--game-restore", action="store_true", help="Test Slippi RAM restoration at actual game bookends; offline diagnostic")
    parser.add_argument("--graphics", choices=["Null", "Metal", "Software"], default="Null")
    args = parser.parse_args()
    if args.menu_back and args.offline_versus:
        parser.error("choose one menu input sequence")
    if args.input_script and (args.menu_back or args.offline_versus):
        parser.error("choose the input script or a built-in sequence")
    if args.game_restore and (not args.gct_loader_invalidation or not args.input_script or args.seconds < 40):
        parser.error("game restoration requires the loader adapter, match-start input script, and at least 40 seconds")
    if args.screenshot and args.graphics == "Null":
        parser.error("screenshots require Metal or Software graphics")
    if (args.cache_clear_fix or args.gct_loader_invalidation) and args.reverify_gct:
        parser.error("test the automatic fix without the diagnostic timer")
    repo = Path(__file__).resolve().parents[1]
    helpers = runpy.run_path(str(repo / "scripts/probe-slippi-peer.py"))
    sha256, run_logged = (helpers[name] for name in ("sha256", "run_logged"))
    output, component = args.output.resolve(), args.component_probe.resolve()
    if output.exists() or len(set(args.modes)) != len(args.modes):
        parser.error("use a new output directory and unique test modes")
    if subprocess.run(["git", "check-ignore", "-q", str(output)], cwd=repo).returncode:
        parser.error("output must be ignored by git; use ref/slippi-compatibility/")
    lock = json.loads((repo / "patches/slippi/boot-source-lock.json").read_text())
    base_lock = json.loads((repo / "patches/slippi/exi-source-lock.json").read_text())
    previous = json.loads((component / "results.json").read_text())
    if not previous["pass"] or previous["adapter_sha256"] != lock["base_adapter_sha256"]:
        parser.error("component probe must have passed with the expected full EXI adapter")
    for path, expected in base_lock["overlay_sha256"].items():
        if sha256(component / "overlay" / path) != expected:
            parser.error(f"base overlay differs: {path}")
    core = repo / "ref/ModernGekko"
    for path, expected in lock["current_sources"].items():
        if sha256(core / path) != expected:
            parser.error(f"current integration source differs: {path}")
    upstream, rust, build = args.upstream.resolve(), args.rust.resolve(), args.build.resolve()
    for path, expected in lock["resources"].items():
        if sha256(upstream / "Data/Sys" / path) != expected:
            parser.error(f"pinned game resource differs: {path}")
    for path, expected in base_lock["files"]["externals"].items():
        if sha256(upstream / "Externals" / path) != expected:
            parser.error(f"pinned dependency differs: {path}")
    rust_archive = args.rust_macos_archive.resolve()
    if sha256(rust_archive) != previous["rust_archive_sha256"]:
        parser.error("Rust archive differs from the passing EXI component probe")
    if sha256(rust / "ffi/includes/SlippiRustExtensions.h") != previous["rust_header_sha256"]:
        parser.error("Rust FFI header differs from the passing component probe")
    inputs = {"main_dol": args.game.resolve() / "sys/main.dol", "iso": args.iso.resolve(),
              "native_module": args.module.resolve(), "rust_archive": rust_archive}
    input_hashes = {name: sha256(path) for name, path in inputs.items()}
    output.mkdir(parents=True)
    overlay = output / "overlay"
    shutil.copytree(component / "overlay", overlay)
    factory = "Core/HW/EXI/EXI_Device.cpp"
    shutil.copy2(core / "vendor/dolphin/Source/Core" / factory, overlay / factory)
    patch = repo / "patches/slippi/0005-isolated-game-boot.patch"
    run_logged(["patch", "-p1", "-i", str(patch)], overlay, output / "patch.log")
    for path, expected in lock["boot_overlay_sha256"].items():
        if sha256(overlay / path) != expected:
            raise RuntimeError(f"boot overlay differs: {path}")
    cache_lock = None
    loader_lock = None
    frame_lock = None
    restore_lock = None
    if args.gct_loader_invalidation:
        loader_lock = json.loads((repo / "patches/slippi/gct-loader-source-lock.json").read_text())
        loader_patch = repo / "patches/slippi/0007-isolated-gct-loader-invalidation.patch"
        if sha256(loader_patch) != loader_lock["patch_sha256"]:
            raise RuntimeError("GCT loader patch differs from lock")
        hle_path = "Core/HLE/HLE_Misc.cpp"
        (overlay / hle_path).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(core / "vendor/dolphin/Source/Core" / hle_path, overlay / hle_path)
        for path, expected in loader_lock["input_sha256"].items():
            if sha256(overlay / path) != expected:
                raise RuntimeError(f"GCT loader input differs: {path}")
        run_logged(["patch", "-p1", "-i", str(loader_patch)], overlay, output / "gct-loader-patch.log")
        for path, expected in loader_lock["overlay_sha256"].items():
            if sha256(overlay / path) != expected:
                raise RuntimeError(f"GCT loader overlay differs: {path}")
    if args.cache_clear_fix:
        cache_lock = json.loads((repo / "patches/slippi/cache-clear-source-lock.json").read_text())
        cache_source = core / "vendor/dolphin/Source/Core" / cache_lock["path"]
        cache_patch = repo / "patches/slippi/0006-isolated-cache-clear.patch"
        if sha256(cache_source) != cache_lock["source_sha256"] or sha256(cache_patch) != cache_lock["patch_sha256"]:
            raise RuntimeError("cache-clear source or patch differs from lock")
        cache_target = overlay / cache_lock["path"]
        cache_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(cache_source, cache_target)
        run_logged(["patch", "-p1", "-i", str(cache_patch)], overlay, output / "cache-clear-patch.log")
        if sha256(cache_target) != cache_lock["overlay_sha256"]:
            raise RuntimeError("cache-clear overlay differs from lock")
    if args.game_restore:
        frame_lock = json.loads((repo / "patches/slippi/game-frame-source-lock.json").read_text())
        frame_patch = repo / "patches/slippi/0008-isolated-game-frame-observer.patch"
        if sha256(frame_patch) != frame_lock["patch_sha256"]:
            raise RuntimeError("game frame patch differs from lock")
        for path, expected in frame_lock["input_sha256"].items():
            if sha256(overlay / path) != expected:
                raise RuntimeError(f"game frame input differs: {path}")
        run_logged(["patch", "-p1", "-i", str(frame_patch)], overlay, output / "game-frame-patch.log")
        for path, expected in frame_lock["overlay_sha256"].items():
            if sha256(overlay / path) != expected:
                raise RuntimeError(f"game frame overlay differs: {path}")
        restore_lock = json.loads((repo / "patches/slippi/restore-source-lock.json").read_text())
        restore_patch = repo / "patches/slippi/0009-isolated-restore-invalidation.patch"
        restore_source = overlay / restore_lock["path"]
        if sha256(restore_source) != restore_lock["source_sha256"] or sha256(restore_patch) != restore_lock["patch_sha256"]:
            raise RuntimeError("restoration invalidation inputs differ")
        run_logged(["patch", "-p1", "-i", str(restore_patch)], overlay, output / "restore-patch.log")
        if sha256(restore_source) != restore_lock["overlay_sha256"]:
            raise RuntimeError("restoration invalidation overlay differs")
    bundle = output / "SlippiProbe.app"
    macos = bundle / "Contents/MacOS"
    macos.mkdir(parents=True)
    system = bundle / "Contents/Resources/Sys"
    shutil.copytree(build / "Sys", system)
    for path in lock["resources"]:
        target = system / path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(upstream / "Data/Sys" / path, target)
    # Existing local-development core selects <bundle>/Sys even on macOS.
    (bundle / "Sys").symlink_to("Contents/Resources/Sys", target_is_directory=True)
    (bundle / "Contents/Info.plist").write_bytes(plistlib.dumps({
        "CFBundleExecutable": "SlippiProbe", "CFBundleIdentifier": "com.meleepad.slippi-offline-probe",
        "CFBundleName": "SlippiProbe", "CFBundlePackageType": "APPL"}))
    libraries = [build / "libmoderngekko.a"] + sorted(build.glob("vendor/dolphin/**/lib*.a"))
    library_hashes = {str(p.relative_to(build)): sha256(p) for p in libraries}
    database = json.loads((build / "compile_commands.json").read_text())
    runtime_command = subprocess.check_output(["ninja", "-t", "commands",
        "CMakeFiles/moderngekko.dir/src/runtime/dolphin_runtime.cpp.o"], cwd=build, text=True).splitlines()[-1]
    runtime_entry = {"command": runtime_command, "directory": str(build)}
    base = next(x for x in database if x["file"].endswith("/HW/EXI/EXI_Device.cpp"))
    sources = sorted((overlay / "Core/Slippi").glob("*.cpp")) + [overlay / path for path in (
        "Core/HW/EXI/EXI_DeviceSlippi.cpp", "Core/Cheats/GeckoCode.cpp", "Core/State.cpp",
        "Core/HW/DVD/DVDThread.cpp", "VideoCommon/OnScreenDisplay.cpp", factory)] + [
        core / "src/runtime/dolphin_runtime.cpp", repo / "scripts/slippi-boot-probe.cpp",
        core / "vendor/dolphin/Source/Core/Core/Config/StaticRecompSettings.cpp"]
    objects = []
    if cache_lock:
        sources.append(overlay / cache_lock["path"])
    if loader_lock:
        sources.append(overlay / "Core/HLE/HLE_Misc.cpp")
    for source in sources:
        entry = runtime_entry if source.name == "dolphin_runtime.cpp" else base
        if source.name == "OnScreenDisplay.cpp":
            entry = next(x for x in database if x["file"].endswith("/VideoCommon/OnScreenDisplay.cpp"))
        if source.name == "JitCache.cpp":
            entry = next(x for x in database if x["file"].endswith("/JitCommon/JitCache.cpp"))
        if source.name == "HLE_Misc.cpp":
            entry = next(x for x in database if x["file"].endswith("/HLE/HLE_Misc.cpp"))
        command = shlex.split(entry["command"])
        command = [arg for arg in command[:command.index("-o")] if arg != "-DOFF"]
        command[1:1] = ["-I" + str(path) for path in
                         (overlay, upstream / "Externals", rust / "ffi/includes", core / "include")]
        command += ["-DSLIPPI=CORE", "-DSLIPPI_ONLINE=CORE", "-include", str(overlay / "Core/Slippi/SlippiCompat.h")]
        if args.game_restore:
            command += ["-DSLIPPI_PROBE_GAME_RESTORE=1"]
        obj = output / (source.stem + ".o")
        run_logged(command + ["-c", str(source), "-o", str(obj)], entry["directory"], output / (source.stem + ".log"))
        objects.append(obj)
    # Dependencies were built by the passing component probe. Record their hashes.
    dependencies = sorted(component.glob("Semver200*-macos.o")) + [
        component / "vcdiff-macos" / f"lib{name}.a" for name in ("vcdenc", "vcddec", "vcdcom")]
    dependency_hashes = {str(path.relative_to(component)): sha256(path) for path in dependencies}
    commands = subprocess.check_output(["ninja", "-t", "commands", "moderngekko_netplay_session_test"], cwd=build, text=True)
    command = shlex.split(commands.splitlines()[-1])
    command = command[command.index("/usr/bin/c++"):]
    command = command[:command.index("&&")]
    executable = macos / "SlippiProbe"
    command[command.index("-o") + 1] = str(executable)
    index = next(i for i, item in enumerate(command) if item.endswith("netplay_session_test.cpp.o"))
    command[index:index + 1] = list(map(str, objects + dependencies + [rust_archive]))
    for framework in ("CoreFoundation", "Security", "AudioToolbox", "CoreAudio", "Foundation", "AudioUnit", "SystemConfiguration"):
        command += ["-framework", framework]
    command += ["-lresolv", "-liconv"]
    linked = run_logged(command, build, output / "link.log")
    if "built for newer" in linked.stderr:
        raise RuntimeError("deployment target mismatch; see link.log")
    print("Isolated boot executable linked", flush=True)
    results = []
    for mode in args.modes:
        env = {key: value for key, value in os.environ.items()
               if not key.startswith(("SLIPPI_PROBE_", "STATICRECOMP_"))}
        env.update(modes[mode])
        env["SLIPPI_PROBE_GRAPHICS"] = args.graphics
        env["SLIPPI_PROBE_SECONDS"] = str(args.seconds)
        if args.input_script:
            env["SLIPPI_PROBE_INPUT_SCRIPT"] = str(args.input_script.resolve())
        if args.capture:
            env["SLIPPI_PROBE_CAPTURE"] = "1"
        if args.screenshot:
            env["SLIPPI_PROBE_SCREENSHOT"] = "1"
        if args.reverify_gct:
            env["SLIPPI_PROBE_REVERIFY_GCT"] = "1"
        if args.menu_back:
            env["SLIPPI_PROBE_MENU_BACK"] = "1"
        if args.offline_versus:
            env["SLIPPI_PROBE_OFFLINE_VERSUS"] = "1"
        if args.register_trace:
            env["STATICRECOMP_REGISTER_TRACE"] = "1"
        command = ["/usr/bin/sandbox-exec", "-p", "(version 1) (allow default) (deny network*)",
                   str(executable), str(args.game.resolve()), str(args.iso.resolve()),
                   str(args.module.resolve()), str(output / ("user-" + mode))]
        result = subprocess.run(command, cwd=output, env=env, capture_output=True, text=True, timeout=args.seconds + 45)
        (output / (mode + ".log")).write_text(result.stdout + result.stderr)
        row = {"mode": mode, "exit": result.returncode}
        summaries = [line for line in result.stdout.splitlines() if line.startswith("{")]
        if summaries:
            row["runtime"] = json.loads(summaries[-1])
        row["startup_progress"] = result.returncode == 0
        restore_report = output / ("user-" + mode) / "slippi-game-restore.json"
        if args.game_restore and restore_report.exists():
            row["game_restore"] = json.loads(restore_report.read_text())
        if args.screenshot:
            screenshots = sorted((output / ("user-" + mode)).rglob("slippi-probe*.png"))
            row["screenshots"] = [{"path": str(p.relative_to(output)), "sha256": sha256(p)} for p in screenshots]
        results.append(row)
        print(json.dumps(row), flush=True)
    evidence = {"scope": "bounded startup debugging; network denied; CPU and vertex-loader JIT disabled",
                "graphics": args.graphics, "headless": args.graphics != "Metal",
                "capture_enabled": args.capture, "capture_changes_timing": args.capture,
                "screenshot_requested": args.screenshot,
                "gct_reverification_requested": args.reverify_gct,
                "cache_clear_fix": cache_lock,
                "gct_loader_invalidation": loader_lock,
                "menu_back_input": args.menu_back,
                "offline_versus_input": args.offline_versus,
                "input_script_sha256": sha256(args.input_script.resolve()) if args.input_script else None,
                "nominal_observer_seconds": args.seconds,
                "game_frame_observer": frame_lock,
                "restore_invalidation": restore_lock,
                "game_restore_harness_sha256": sha256(repo / "scripts/slippi-game-restore-trial.hpp") if args.game_restore else None,
                "upstream_commit": base_lock["upstream_commit"], "input_sha256": input_hashes,
                "dependency_sha256": dependency_hashes, "existing_library_sha256": library_hashes,
                "adapter_sha256": sha256(patch), "source_lock_sha256": sha256(repo / "patches/slippi/boot-source-lock.json"),
                "harness_sha256": sha256(repo / "scripts/slippi-boot-probe.cpp"), "runner_sha256": sha256(Path(__file__)),
                "compiled_units": len(objects), "results": results,
                "inputs_unchanged": all(sha256(path) == input_hashes[name] for name, path in inputs.items()),
                "libraries_unchanged": all(sha256(build / path) == value for path, value in library_hashes.items()),
                "gameplay_acceptance": False, "rollback_acceptance": False, "ios_execution": False}
    (output / "results.json").write_text(json.dumps(evidence, indent=2) + "\n")
    return 0 if all(row["startup_progress"] for row in results) and evidence["inputs_unchanged"] and evidence["libraries_unchanged"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
