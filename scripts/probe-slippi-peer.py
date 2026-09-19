#!/usr/bin/env python3
"""Build pinned Slippi peer components and test local synthetic input exchange.

Uses existing MeleePad build libraries without rebuilding or modifying them.
Does not load a game, contact Slippi services, or install a device build.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shlex
import shutil
import socket
import subprocess


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def compile_base(build):
    db = json.loads((build / "compile_commands.json").read_text())
    entry = next(row for row in db if row["file"].endswith("/HW/EXI/EXI_Device.cpp"))
    args = shlex.split(entry["command"])
    return args[:args.index("-o")], entry["directory"]


def run_logged(args, cwd, log):
    result = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=120)
    log.write_text(result.stdout + result.stderr)
    if result.returncode:
        raise RuntimeError(f"command failed ({result.returncode}); see {log}")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--upstream", type=Path, required=True, help="Pinned Dolphin source root")
    parser.add_argument("--build", type=Path, required=True, help="Existing macOS MeleePad tools build")
    parser.add_argument("--ios-build", type=Path, required=True, help="Existing iPhoneOS compile database")
    parser.add_argument("--output", type=Path, required=True, help="New ignored/local output directory")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    if output.exists():
        parser.error("use a new output directory to preserve previous evidence")
    upstream = args.upstream.resolve() / "Source/Core"
    lock = json.loads((repo / "patches/slippi/peer-source-lock.json").read_text())
    for path, expected in lock["files"].items():
        if sha256(upstream / path) != expected:
            parser.error(f"upstream source differs from pinned revision: {path}")
    output.mkdir(parents=True)
    overlay = output / "overlay"
    for path in lock["files"]:
        destination = overlay / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(upstream / path, destination)
    patch = repo / "patches/slippi/0001-isolated-peer-probe.patch"
    run_logged(["patch", "-p1", "-i", str(patch)], overlay, output / "patch.log")
    build = args.build.resolve()
    core_library = build / "vendor/dolphin/Source/Core/Core/libcore.a"
    core_hash = sha256(core_library)
    components = ["SlippiNetplay", "SlippiPad", "SlippiGame"]
    compile_results = []
    for platform, database in (("macos", build), ("ios", args.ios_build.resolve())):
        command, cwd = compile_base(database)
        command.insert(1, "-I" + str(overlay))
        # Isolated probe only: use current log categories without editing every
        # upstream diagnostic. No logger is initialized and inputs are synthetic.
        command.extend(["-DSLIPPI_ONLINE=CORE", "-DSLIPPI=CORE"])
        for component in components + (["peer-probe"] if platform == "macos" else []):
            source = (repo / "scripts/slippi-peer-probe.cpp" if component == "peer-probe"
                      else overlay / "Core/Slippi" / (component + ".cpp"))
            obj = output / f"{component}-{platform}.o"
            run_logged(command + ["-c", str(source), "-o", str(obj)], cwd,
                       output / f"{component}-{platform}.log")
            compile_results.append({"component": component, "platform": platform, "pass": True})
    # Reuse the existing target's library/framework link list; never invoke a build.
    commands = subprocess.check_output(
        ["ninja", "-t", "commands", "moderngekko_netplay_session_test"], cwd=build, text=True)
    command = shlex.split(commands.splitlines()[-1])
    command = command[command.index("/usr/bin/c++"):]
    command = command[:command.index("&&")]
    executable = output / "peer-probe"
    command[command.index("-o") + 1] = str(executable)
    index = next(i for i, item in enumerate(command) if item.endswith("netplay_session_test.cpp.o"))
    command[index:index + 1] = [str(output / f"{name}-macos.o") for name in ["peer-probe"] + components]
    run_logged(command, build, output / "link.log")
    results = []
    for cycle in range(3):
        sockets = [socket.socket(socket.AF_INET, socket.SOCK_DGRAM) for _ in range(2)]
        try:
            for sock in sockets:
                sock.bind(("127.0.0.1", 0))
            ports = [sock.getsockname()[1] for sock in sockets]
        finally:
            for sock in sockets:
                sock.close()
        processes = [subprocess.Popen(
            [str(executable), str(player), str(ports[player]), str(ports[1-player])],
            cwd=output, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            for player in range(2)]
        try:
            for player, process in enumerate(processes):
                stdout, stderr = process.communicate(timeout=30)
                (output / f"cycle-{cycle}-peer-{player}.log").write_text(stdout + stderr)
                result = {"cycle": cycle, "player": player, "exit_code": process.returncode}
                if stdout.strip():
                    result["result"] = json.loads(stdout)
                results.append(result)
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.wait()
    evidence = {
        "scope": "Slippi synthetic peer inputs over macOS loopback; no game or service access",
        "upstream_commit": lock["upstream_commit"],
        "source_sha256": lock["files"],
        "adapter_sha256": sha256(patch),
        "harness_sha256": sha256(repo / "scripts/slippi-peer-probe.cpp"),
        "core_library_sha256": core_hash,
        "core_library_unchanged": core_hash == sha256(core_library),
        "compile_results": compile_results,
        "runs": results,
        "ios_execution": False,
        "rollback_tested": False,
        "desktop_slippi_crossplay_tested": False,
    }
    evidence["pass"] = evidence["core_library_unchanged"] and len(results) == 6 and all(
        row["exit_code"] == 0 and row.get("result", {}).get("frames_received") == 300
        and row["result"].get("mismatches") == 0 and row["result"].get("disconnect_pass")
        for row in results)
    (output / "results.json").write_text(json.dumps(evidence, indent=2) + "\n")
    print(json.dumps({"pass": evidence["pass"], "runs": results}, indent=2))
    return 0 if evidence["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
