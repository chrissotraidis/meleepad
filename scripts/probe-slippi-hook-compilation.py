#!/usr/bin/env python3
"""Compile four pinned Slippi hooks as isolated iOS objects; never run a game.

Supply the official v3.6.4 GALE01r2.ini, a DolRecomp executable, and its matching
CPU include directory. Keep --output outside tracked source: it contains
extracted patch payloads and generated binaries. This is a compiler probe,
not a Slippi loader, linker, rollback test, or interoperability implementation.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess


INI_SHA256 = "b30b294df5c0d92deb3129afdfbc894a48aabeb1bce0cf92cce8c4e5408a2587"
HOOKS = (
    "ForceEngineOnRollback",
    "LoopEngineForRollback",
    "StartEngineLoop",
    "TriggerSendInput",
)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ini", type=Path, required=True)
    parser.add_argument("--dolrecomp", type=Path, required=True)
    parser.add_argument("--cpu-include", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if sha256(args.ini) != INI_SHA256:
        parser.error("INI does not match the audited Slippi v3.6.4 file")
    if not (args.cpu_include / "cpu/cpu.h").is_file():
        parser.error("--cpu-include must contain the matching cpu/cpu.h")
    if args.output.exists():
        parser.error("use a new output directory to preserve earlier evidence")
    args.output.mkdir(parents=True)
    sdk = subprocess.check_output(
        ["xcrun", "--sdk", "iphoneos", "--show-sdk-path"], text=True
    ).strip()
    compiler = args.dolrecomp.resolve()
    results = {
        "scope": "isolated hook code generation and iOS ARM64 object compilation only",
        "slippi_release": "v3.6.4",
        "slippi_commit": "e7711b104b339a99385f2bb12b472d46140a7bc7",
        "ini_sha256": INI_SHA256,
        "dolrecomp_sha256": sha256(compiler),
        "cpu_header_sha256": sha256(args.cpu_include / "cpu/cpu.h"),
        "clang_version": subprocess.check_output(
            ["xcrun", "--sdk", "iphoneos", "clang", "--version"], text=True
        ).splitlines()[0],
        "synthetic_load_address": "0x81700000",
        "fixture_change": "final C2 return-branch placeholder replaced with blr",
        "linked": False,
        "executed": False,
        "hooks": [],
    }
    lines = args.ini.read_text().splitlines()
    for hook in HOOKS:
        pattern = re.compile(
            r"^(C2[0-9A-Fa-f]{6})\s+([0-9A-Fa-f]{8})\s+#Online/Core/"
            + re.escape(hook) + r"\.asm$"
        )
        matches = [(i, pattern.match(line)) for i, line in enumerate(lines)]
        matches = [(i, match) for i, match in matches if match]
        if len(matches) != 1:
            raise ValueError(f"expected exactly one C2 hook: {hook}")
        index, match = matches[0]
        count = int(match[2], 16)
        payload = bytearray()
        for line in lines[index + 1:index + count + 1]:
            words = re.match(r"^([0-9A-Fa-f]{8})\s+([0-9A-Fa-f]{8})", line)
            if not words:
                raise ValueError(f"invalid C2 payload in {hook}")
            payload.extend(bytes.fromhex(words[1] + words[2]))
        if len(payload) != count * 8 or payload[-4:] != b"\0\0\0\0":
            raise ValueError(f"unexpected C2 length or terminator in {hook}")
        payload[-4:] = bytes.fromhex("4e800020")
        folder = args.output / hook
        folder.mkdir()
        header = bytearray(256)
        for offset, value in ((0, 256), (0x48, 0x81700000),
                              (0x90, len(payload)), (0xE0, 0x81700000)):
            struct.pack_into(">I", header, offset, value)
        fixture = folder / "hook.dol"
        fixture.write_bytes(header + payload)
        codegen = subprocess.run(
            [str(compiler), "--gamecube", "--cpu", "gekko", str(fixture.resolve()),
             str((folder / "out").resolve())], capture_output=True, text=True
        )
        log = codegen.stdout + codegen.stderr
        (folder / "codegen.log").write_text(log)
        row = {
            "hook": hook,
            "injection_address": f"0x{0x80000000 | (int(match[1], 16) & 0x1ffffff):08X}",
            "fixture_bytes": len(payload),
            "decode_summary": re.findall(r"\d+ decoded[^\n]*", log),
            "codegen_returncode": codegen.returncode,
            "objects": [],
        }
        generated = folder / "out/generated"
        units = sorted(generated.glob("*.c")) + sorted((generated / "chunks").glob("*.c"))
        for unit in units:
            obj = folder / (unit.stem + ".o")
            compiled = subprocess.run(
                ["xcrun", "--sdk", "iphoneos", "clang", "-target", "arm64-apple-ios16.0",
                 "-isysroot", sdk, "-std=c11", "-O2", "-ffp-contract=off", "-fno-fast-math",
                 "-I", str(args.cpu_include.resolve()), "-c", str(unit), "-o", str(obj)],
                capture_output=True, text=True
            )
            (folder / (unit.stem + "-clang.log")).write_text(compiled.stdout + compiled.stderr)
            row["objects"].append({"unit": unit.name, "returncode": compiled.returncode})
        results["hooks"].append(row)
        print(hook, "codegen", codegen.returncode,
              "object results", [obj["returncode"] for obj in row["objects"]])
    results["compile_pass"] = all(
        hook["codegen_returncode"] == 0 and len(hook["objects"]) == 2
        and all(obj["returncode"] == 0 for obj in hook["objects"])
        for hook in results["hooks"]
    )
    (args.output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
    return 0 if results["compile_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
