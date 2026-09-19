#!/usr/bin/env python3
"""Build and execute the pinned Slippi resource loader using synthetic disc data.

Requires the existing MeleePad core build and pinned upstream dependency source.
Output contains isolated source copies, binaries and generated test data only.
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
    parser.add_argument("--upstream", type=Path, required=True)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--ios-build", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    helpers = runpy.run_path(str(repo / "scripts/probe-slippi-peer.py"))
    sha256, run_logged, compile_base = (helpers[name] for name in ("sha256", "run_logged", "compile_base"))
    output = args.output.resolve()
    if output.exists(): parser.error("use a new output directory")
    upstream = args.upstream.resolve()
    core = repo / "ref/ModernGekko/vendor/dolphin/Source/Core"
    lock = json.loads((repo / "patches/slippi/resource-source-lock.json").read_text())
    roots = {"upstream": upstream / "Source/Core", "core": core,
             "vcdiff": upstream / "Externals/open-vcdiff"}
    for group, paths in lock["files"].items():
        for path, expected in paths.items():
            if sha256(roots[group] / path) != expected:
                parser.error(f"source differs from recorded input: {group}/{path}")
    output.mkdir(parents=True)
    overlay = output / "overlay"
    for group in ("upstream", "core"):
        for path in lock["files"][group]:
            dest = overlay / path
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(roots[group] / path, dest)
    patch = repo / "patches/slippi/0002-isolated-resource-loader.patch"
    run_logged(["patch", "-p1", "-i", str(patch)], overlay, output / "patch.log")
    build = args.build.resolve()
    library = build / "vendor/dolphin/Source/Core/Core/libcore.a"
    before_hash = sha256(library)
    compiled = []
    for platform, database in (("macos", build), ("ios", args.ios_build.resolve())):
        vcdiff_build = output / f"vcdiff-{platform}"
        options = ["-DCMAKE_POLICY_VERSION_MINIMUM=3.5", "-DCMAKE_BUILD_TYPE=Release",
                   "-DBUILD_TESTING=OFF", "-DCMAKE_OSX_ARCHITECTURES=arm64"]
        if platform == "ios":
            options += ["-DCMAKE_SYSTEM_NAME=iOS", "-DCMAKE_OSX_SYSROOT=iphoneos",
                        "-DCMAKE_OSX_DEPLOYMENT_TARGET=16.0", "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"]
        else:
            options += ["-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0"]
        run_logged(["cmake", "-S", str(roots["vcdiff"]), "-B", str(vcdiff_build), "-G", "Ninja"] + options,
                   output, output / f"vcdiff-{platform}-configure.log")
        run_logged(["cmake", "--build", str(vcdiff_build), "-j", "4"], output,
                   output / f"vcdiff-{platform}-build.log")
        command, cwd = compile_base(database)
        command[1:1] = ["-I" + str(overlay), "-I" + str(upstream / "Externals")]
        command += ["-DSLIPPI=CORE"]
        files = {"DVDThread": overlay / "Core/HW/DVD/DVDThread.cpp",
                 "SlippiGameFileLoader": overlay / "Core/Slippi/SlippiGameFileLoader.cpp"}
        if platform == "macos": files["resource-probe"] = repo / "scripts/slippi-resource-probe.cpp"
        for name, source in files.items():
            run_logged(command + ["-c", str(source), "-o", str(output / f"{name}-{platform}.o")], cwd,
                       output / f"{name}-{platform}.log")
            compiled.append({"component": name, "platform": platform, "pass": True})
    commands = subprocess.check_output(["ninja", "-t", "commands", "moderngekko_netplay_session_test"], cwd=build, text=True)
    command = shlex.split(commands.splitlines()[-1])
    command = command[command.index("/usr/bin/c++"):]
    command = command[:command.index("&&")]
    executable = output / "resource-probe"
    command[command.index("-o") + 1] = str(executable)
    index = next(i for i, item in enumerate(command) if item.endswith("netplay_session_test.cpp.o"))
    command[index:index + 1] = [str(output / f"{name}-macos.o") for name in ("resource-probe", "DVDThread", "SlippiGameFileLoader")] + [
        str(output / "vcdiff-macos" / f"lib{name}.a") for name in ("vcdenc", "vcddec", "vcdcom")]
    run_logged(command, build, output / "link.log")
    result = run_logged([str(executable), str(output / "fixture")], output, output / "run.log")
    runtime = json.loads(result.stdout)
    evidence = {"scope": "adapted Slippi resource loader using real Dolphin disc reads and synthetic data",
                "upstream_commit": lock["upstream_commit"], "source_lock": lock["files"],
                "adapter_sha256": sha256(patch),
                "harness_sha256": sha256(repo / "scripts/slippi-resource-probe.cpp"),
                "core_archive_sha256": before_hash, "core_archive_unchanged": before_hash == sha256(library),
                "compile_results": compiled, "runtime": runtime,
                "ios_execution": False, "actual_slippi_resources_loaded": False, "game_executed": False}
    evidence["pass"] = evidence["core_archive_unchanged"] and runtime["checks"] == 11 and runtime["failures"] == 0
    (output / "results.json").write_text(json.dumps(evidence, indent=2) + "\n")
    print(json.dumps({"pass": evidence["pass"], "compile_results": compiled, "runtime": runtime}, indent=2))
    return 0 if evidence["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
