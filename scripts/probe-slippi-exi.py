#!/usr/bin/env python3
"""Build the pinned C++ Slippi device and run offline synthetic EXI commands.

Uses existing MeleePad libraries read-only. A prebuilt pinned Rust static archive
is required. iOS objects are compiled; only the macOS executable is run. No game,
account, device installation or production service is involved.
"""
import argparse
import json
from pathlib import Path
import runpy
import shlex
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("upstream", "rust", "rust-macos-archive", "build", "ios-build", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    helpers = runpy.run_path(str(repo / "scripts/probe-slippi-peer.py"))
    sha256, run_logged = (helpers[name] for name in ("sha256", "run_logged"))
    upstream, rust, output = args.upstream.resolve(), args.rust.resolve(), args.output.resolve()
    if output.exists():
        parser.error("use a new output directory to preserve previous evidence")
    lock = json.loads((repo / "patches/slippi/exi-source-lock.json").read_text())
    roots = {"upstream": upstream / "Source/Core",
             "core": repo / "ref/ModernGekko/vendor/dolphin/Source/Core",
             "externals": upstream / "Externals"}
    for group, paths in lock["files"].items():
        for path, expected in paths.items():
            if sha256(roots[group] / path) != expected:
                parser.error(f"source differs from recorded input: {group}/{path}")
    for path, expected in lock["reference_sources"].items():
        if sha256(roots["upstream"] / path) != expected:
            parser.error(f"adapter reference source differs: {path}")
    rust_revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=rust, text=True).strip()
    if rust_revision != lock["rust_commit"]:
        parser.error("Rust checkout is not the pinned revision")
    rust_archive = args.rust_macos_archive.resolve()
    rust_hash = sha256(rust_archive)
    output.mkdir(parents=True)
    overlay = output / "overlay"
    for group in ("upstream", "core"):
        for path in lock["files"][group]:
            target = overlay / path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(roots[group] / path, target)
    patch = repo / "patches/slippi/0004-isolated-full-exi.patch"
    run_logged(["patch", "-p1", "-i", str(patch)], overlay, output / "patch.log")
    for path, expected in lock["overlay_sha256"].items():
        if sha256(overlay / path) != expected:
            raise RuntimeError(f"patched output differs: {path}")

    build = args.build.resolve()
    libraries = sorted(build.glob("vendor/dolphin/**/lib*.a"))
    library_hashes = {str(p.relative_to(build)): sha256(p) for p in libraries}
    compiled, objects = [], []
    for platform, database in (("macos", build), ("ios", args.ios_build.resolve())):
        commands = json.loads((database / "compile_commands.json").read_text())
        base = next(x for x in commands if x["file"].endswith("/HW/EXI/EXI_Device.cpp"))
        sources = sorted((overlay / "Core/Slippi").glob("*.cpp")) + [
            overlay / path for path in ("Core/HW/EXI/EXI_DeviceSlippi.cpp", "Core/Cheats/GeckoCode.cpp",
                                        "Core/State.cpp", "Core/HW/DVD/DVDThread.cpp",
                                        "VideoCommon/OnScreenDisplay.cpp")]
        if platform == "macos":
            sources.append(repo / "scripts/slippi-exi-probe.cpp")
        for source in sources:
            entry = (next(x for x in commands if x["file"].endswith("/VideoCommon/OnScreenDisplay.cpp"))
                     if source.name == "OnScreenDisplay.cpp" else base)
            command = shlex.split(entry["command"])
            command = [arg for arg in command[:command.index("-o")] if arg != "-DOFF"]
            command[1:1] = ["-I" + str(overlay), "-I" + str(roots["externals"]),
                            "-I" + str(rust / "ffi/includes")]
            command += ["-DSLIPPI=CORE", "-DSLIPPI_ONLINE=CORE", "-include",
                        str(overlay / "Core/Slippi/SlippiCompat.h")]
            obj = output / f"{source.stem}-{platform}.o"
            run_logged(command + ["-c", str(source), "-o", str(obj)], entry["directory"],
                       output / f"{source.stem}-{platform}.log")
            compiled.append({"component": source.name, "platform": platform, "pass": True})
            if platform == "macos":
                objects.append(obj)

        vcdiff = output / f"vcdiff-{platform}"
        options = ["-DCMAKE_POLICY_VERSION_MINIMUM=3.5", "-DCMAKE_BUILD_TYPE=Release",
                   "-DBUILD_TESTING=OFF", "-DCMAKE_OSX_ARCHITECTURES=arm64"]
        if platform == "ios":
            options += ["-DCMAKE_SYSTEM_NAME=iOS", "-DCMAKE_OSX_SYSROOT=iphoneos",
                        "-DCMAKE_OSX_DEPLOYMENT_TARGET=16.0", "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"]
        else:
            options += ["-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0"]
        run_logged(["cmake", "-S", str(roots["externals"] / "open-vcdiff"), "-B", str(vcdiff),
                    "-G", "Ninja"] + options, output, output / f"vcdiff-{platform}-configure.log")
        run_logged(["cmake", "--build", str(vcdiff), "-j", "4"], output,
                   output / f"vcdiff-{platform}-build.log")
        sdk = "iphoneos" if platform == "ios" else "macosx"
        sdk_path = subprocess.check_output(["xcrun", "--sdk", sdk, "--show-sdk-path"], text=True).strip()
        target = "arm64-apple-ios16.0" if platform == "ios" else "arm64-apple-macos14.0"
        for source in sorted((roots["externals"] / "semver/src").glob("*.cpp")):
            obj = output / f"{source.stem}-{platform}.o"
            command = ["xcrun", "clang++", "-std=c++14", "-O2", "-target", target,
                       "-isysroot", sdk_path, "-I" + str(roots["externals"] / "semver/include"),
                       "-c", str(source), "-o", str(obj)]
            run_logged(command, output, output / f"{source.stem}-{platform}.log")
            compiled.append({"component": source.name, "platform": platform, "pass": True})
            if platform == "macos":
                objects.append(obj)
        print(f"{platform}: component and dependency compilation passed", flush=True)

    commands = subprocess.check_output(["ninja", "-t", "commands", "moderngekko_netplay_session_test"],
                                       cwd=build, text=True)
    command = shlex.split(commands.splitlines()[-1])
    command = command[command.index("/usr/bin/c++"):]
    command = command[:command.index("&&")]
    executable = output / "exi-probe"
    command[command.index("-o") + 1] = str(executable)
    index = next(i for i, item in enumerate(command) if item.endswith("netplay_session_test.cpp.o"))
    command[index:index + 1] = list(map(str, objects)) + [
        str(output / "vcdiff-macos" / f"lib{name}.a") for name in ("vcdenc", "vcddec", "vcdcom")
    ] + [str(rust_archive)]
    for framework in ("CoreFoundation", "Security", "AudioToolbox", "CoreAudio", "Foundation",
                      "AudioUnit", "SystemConfiguration"):
        command += ["-framework", framework]
    command += ["-lresolv", "-liconv"]
    linked = run_logged(command, build, output / "link.log")
    if "built for newer" in linked.stderr:
        raise RuntimeError("dependency deployment target mismatch; see link.log")
    run = run_logged(["/usr/bin/sandbox-exec", "-p", "(version 1) (allow default) (deny network*)",
                      str(executable), str(output / "fixture")], output, output / "run.log")
    runtime = json.loads(run.stdout)
    unchanged = all(sha256(build / path) == expected for path, expected in library_hashes.items())
    evidence = {"scope": "real Slippi C++ EXI dispatch with synthetic memory and resources; network denied",
                "upstream_commit": lock["upstream_commit"], "rust_commit": rust_revision,
                "source_lock_sha256": sha256(repo / "patches/slippi/exi-source-lock.json"),
                "adapter_sha256": sha256(patch), "harness_sha256": sha256(repo / "scripts/slippi-exi-probe.cpp"),
                "runner_sha256": sha256(Path(__file__)), "rust_archive_sha256": rust_hash,
                "rust_header_sha256": sha256(rust / "ffi/includes/SlippiRustExtensions.h"),
                "linked_core_archives": library_hashes, "core_archives_unchanged": unchanged,
                "compile_results": compiled, "runtime": runtime,
                "ios_linked": False, "ios_execution": False, "game_executed": False,
                "factory_registration_tested": False, "desktop_crossplay": False}
    evidence["pass"] = unchanged and runtime["checks"] == 10 and runtime["failures"] == 0
    (output / "results.json").write_text(json.dumps(evidence, indent=2) + "\n")
    print(json.dumps({"pass": evidence["pass"], "runtime": runtime}, indent=2))
    return 0 if evidence["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
