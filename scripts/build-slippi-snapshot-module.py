#!/usr/bin/env python3
"""Build a diagnostic native module for live-patched Melee text sections.

Requires an offline boot-probe capture and the owner's original v1.02 DOL.
Only code-generation input is changed. The game still boots its original ISO,
and the runtime must verify generated chunks against live instruction bytes.
By default this leaves heap-injected code on interpreter fallback. The optional
GCT experiment additionally compiles the captured GCT region, including its
relocated C2 hooks. Other loaded resource code remains outside this module.
Generated DOL/code/module artifacts must remain in an ignored output directory.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess


SEND_GAME_INFO_HEADER = "C216E74C 00000119 #Recording/SendGameInfo.asm"
SEND_GAME_INFO_INSTRUMENTED_HEADER = "C216E74C 0000012C #Recording/SendGameInfo.asm"
SEND_GAME_INFO_PAIR = "839D002C 3860003B"
SEND_GAME_INFO_INSTRUMENTATION = '''839D002C 7C036378
3D80817F 618C0000
938C0000 906C0040
93AC0004 93EC0008
807C0010 906C0010
807C0024 906C0014
807C002C 906C0018
807C0040 906C001C
807C0044 906C0020
807C004C 906C0024
807C0050 906C0028
807C0518 906C002C
807C0C9C 906C0030
807C0D44 906C0034
807C0DA8 906C0038
887C0DD7 986C003C
887C0DDB 986C003D
887C0DEB 986C003E
887C0DEF 986C003F
818C0040 3860003B'''


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("capture-run", "dol", "compiler", "core", "output"):
        parser.add_argument("--" + name, required=True, type=Path)
    parser.add_argument("--include-gct", action="store_true")
    parser.add_argument("--ini", type=Path, help="Pinned Slippi GALE01r2.ini; required with --include-gct")
    parser.add_argument("--gct-capture-run", type=Path,
                        help="Private run containing the live relocated GCT RAM capture; defaults to --capture-run")
    parser.add_argument("--instrument-send-game-info", action="store_true",
                        help="Compile the private SendGameInfo register/object diagnostic")
    args = parser.parse_args()
    if args.instrument_send_game_info and not args.include_gct:
        parser.error("--instrument-send-game-info requires --include-gct")
    repo = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    if output.exists():
        parser.error("use a new output directory")
    ignored = subprocess.run(["git", "check-ignore", "-q", str(output)], cwd=repo)
    if ignored.returncode:
        parser.error("output must be ignored by git; use ref/slippi-compatibility/")
    capture = args.capture_run.resolve()
    evidence = json.loads((capture / "results.json").read_text())
    result = next(row for row in evidence["results"] if row["mode"] == "required")
    if not result["startup_progress"] or result["runtime"]["memory_errors"] != 0:
        parser.error("required-group capture must have continued running without memory errors")
    original = args.dol.resolve()
    original_hash = digest(original)
    if original_hash != evidence["input_sha256"]["main_dol"]:
        parser.error("original DOL differs from the captured run")
    if original_hash != "dc21504513424350bda17a7c65e82371b45112a5dfc1e9f2749a8b7ab0eff646":
        parser.error("this experiment supports only the audited GALE01 v1.02 executable")
    memory_path = capture / "user-required/slippi-probe-ram.bin"
    memory = memory_path.read_bytes()
    if len(memory) != 0x1800000:
        parser.error("expected a 24 MiB GameCube memory capture")
    gct_capture = (args.gct_capture_run or args.capture_run).resolve()
    gct_memory_path = next((candidate for candidate in (
        gct_capture / "user-required/slippi-probe-ram.bin",
        gct_capture / "user-0/local-scene-ram.bin",
        gct_capture / "user-1/local-scene-ram.bin") if candidate.exists()), None)
    if gct_memory_path is None:
        parser.error("GCT capture run has no RAM capture")
    gct_memory = gct_memory_path.read_bytes()
    if len(gct_memory) != 0x1800000:
        parser.error("expected a 24 MiB GCT RAM capture")
    dol = bytearray(original.read_bytes())
    sections = []
    for index in range(7):
        offset = struct.unpack_from(">I", dol, index * 4)[0]
        address = struct.unpack_from(">I", dol, 0x48 + index * 4)[0]
        size = struct.unpack_from(">I", dol, 0x90 + index * 4)[0]
        if not size:
            continue
        start = address - 0x80000000
        if start < 0 or start + size > len(memory) or offset + size > len(dol):
            parser.error("text section is outside the expected file/memory bounds")
        replacement = memory[start:start + size]
        changed = sum(dol[offset + word:offset + word + 4] != replacement[word:word + 4]
                      for word in range(0, size, 4))
        dol[offset:offset + size] = replacement
        sections.append({"index": index, "address": hex(address), "size": size, "changed_words": changed})
    gct_info = None
    instrumented_ini_text = None
    if args.include_gct:
        if not args.ini or digest(args.ini) != "b30b294df5c0d92deb3129afdfbc894a48aabeb1bce0cf92cce8c4e5408a2587":
            parser.error("GCT experiment requires the pinned Slippi v3.6.4-compatible INI")
        ini_text = args.ini.read_text()
        if args.instrument_send_game_info:
            if ini_text.count(SEND_GAME_INFO_HEADER) != 1:
                parser.error("instrumentation requires the pinned SendGameInfo header")
            if ini_text.count(SEND_GAME_INFO_PAIR) != 1:
                parser.error("instrumentation requires the pinned SendGameInfo item loop")
            instrumented_ini_text = ini_text.replace(SEND_GAME_INFO_HEADER,
                                                      SEND_GAME_INFO_INSTRUMENTED_HEADER)
            instrumented_ini_text = instrumented_ini_text.replace(
                SEND_GAME_INFO_PAIR, SEND_GAME_INFO_INSTRUMENTATION)
            lines = instrumented_ini_text.splitlines()
            header_index = lines.index(SEND_GAME_INFO_INSTRUMENTED_HEADER)
            next_header = next(i for i in range(header_index + 1, len(lines))
                               if lines[i].startswith("C"))
            if next_header - header_index - 1 != 0x12C:
                parser.error("instrumented SendGameInfo line count does not match its header")
        else:
            instrumented_ini_text = ini_text
        gct_source_lines = instrumented_ini_text.splitlines()
        payload = bytearray.fromhex("00d0c0de00d0c0de")
        in_gecko, active = False, False
        for line in gct_source_lines:
            if line.startswith("["):
                in_gecko = line == "[Gecko]"
            elif in_gecko and line.startswith("$"):
                active = line[1:].split(" [", 1)[0] in (
                    "Required: General Codes", "Required: Slippi Recording", "Required: Slippi Online")
            elif in_gecko and active and (words := re.match(r"^([0-9A-Fa-f]{8})\s+([0-9A-Fa-f]{8})", line)):
                payload.extend(bytes.fromhex(words[1] + words[2]))
        payload.extend(bytes.fromhex("ff00000000000000"))
        # The code handler relocates C2 entries in the live heap GCT. Locate
        # the live region using the shared, unchanged prefix, then compile the
        # captured post-relocation bytes rather than the raw INI serialization.
        original_prefix = bytearray.fromhex("00d0c0de00d0c0de")
        for line in ini_text.splitlines():
            if line.startswith("["):
                in_gecko = line == "[Gecko]"
            elif in_gecko and line.startswith("$"):
                active = line[1:].split(" [", 1)[0] in (
                    "Required: General Codes", "Required: Slippi Recording", "Required: Slippi Online")
            elif in_gecko and active and (words := re.match(r"^([0-9A-Fa-f]{8})\s+([0-9A-Fa-f]{8})", line)):
                original_prefix.extend(bytes.fromhex(words[1] + words[2]))
                if len(original_prefix) >= 32:
                    break
        start = gct_memory.find(original_prefix[:32])
        if start < 0 or gct_memory.find(payload[:32], start + 1) >= 0:
            parser.error("captured GCT prefix is missing or ambiguous")
        original_payload = bytearray.fromhex("00d0c0de00d0c0de")
        in_gecko, active = False, False
        for line in ini_text.splitlines():
            if line.startswith("["):
                in_gecko = line == "[Gecko]"
            elif in_gecko and line.startswith("$"):
                active = line[1:].split(" [", 1)[0] in (
                    "Required: General Codes", "Required: Slippi Recording", "Required: Slippi Online")
            elif in_gecko and active and (words := re.match(r"^([0-9A-Fa-f]{8})\s+([0-9A-Fa-f]{8})", line)):
                original_payload.extend(bytes.fromhex(words[1] + words[2]))
        original_payload.extend(bytes.fromhex("ff00000000000000"))
        expected_payload_size = len(original_payload)
        if args.instrument_send_game_info:
            expected_payload_size += (0x12C - 0x119) * 8
        if len(payload) != expected_payload_size:
            parser.error("generated GCT parser dropped or added an instruction pair")
        captured = gct_memory[start:start + len(payload)]
        if (len(captured) != len(payload) or captured[:8] != payload[:8] or
                captured[-8:] != bytes.fromhex("ff00000000000000")):
            parser.error("live GCT size/header/footer differs from expected structure")
        free = next((i for i in range(7) if struct.unpack_from(">I", dol, 0x90 + i * 4)[0] == 0), None)
        if free is None:
            parser.error("no unused DOL text slot for the GCT experiment")
        while len(dol) % 32:
            dol.append(0)
        offset, address = len(dol), start + 0x80000000
        struct.pack_into(">I", dol, free * 4, offset)
        struct.pack_into(">I", dol, 0x48 + free * 4, address)
        struct.pack_into(">I", dol, 0x90 + free * 4, len(captured))
        dol.extend(captured)
        gct_info = {"text_slot": free, "address": hex(address), "bytes": len(captured),
                    "captured_sha256": hashlib.sha256(captured).hexdigest(),
                    "live_instruction_verification_required": True}
    output.mkdir(parents=True)
    instrumented_ini_path = None
    if args.instrument_send_game_info:
        instrumented_ini_path = output / "GALE01r2.instrumented.ini"
        instrumented_ini_path.write_text(instrumented_ini_text)
    fixture = output / "patched-text.dol"
    fixture.write_bytes(dol)
    compiler, core = args.compiler.resolve(), args.core.resolve()

    def run(command, name, timeout):
        result = subprocess.run(command, cwd=output, capture_output=True, text=True, timeout=timeout)
        (output / name).write_text(result.stdout + result.stderr)
        if result.returncode:
            raise RuntimeError(f"command failed ({result.returncode}); see {output / name}")
        return result

    generated = output / "codegen"
    generated_result = run([str(compiler), "--gamecube", "--cpu", "gekko", "-j4", str(fixture),
                            str(generated)], "codegen.log", 120)
    shutil.copy2(fixture, generated / "generated/main.dol")
    print("Patched text code generation completed", flush=True)
    build = output / "module-build"
    run(["cmake", "-S", str(core / "vendor/dolphin/module-template"), "-B", str(build), "-G", "Ninja",
         "-DGAME_ID=GALE01", "-DGENERATED_DIR=" + str(generated / "generated"),
         "-DGXRUNTIME_DIR=" + str(core / "vendor/dolphin/GXRuntime"),
         "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_OSX_ARCHITECTURES=arm64", "-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0",
         "-DRECOMPCORE_MODULE_OPT_LEVEL=2", "-DRECOMPCORE_MODULE_ENABLE_IPO=ON"], "configure.log", 120)
    run(["cmake", "--build", str(build), "-j4"], "build.log", 1800)
    module = build / "gGALE01_recomp.dylib"
    result = {"scope": ("native module compiled from captured patched text and GCT region" if gct_info else
                        "native module compiled from captured modifications to original text sections only"),
              "original_dol_sha256": original_hash, "captured_ram_sha256": digest(memory_path),
              "gct_capture_run": str(gct_capture), "gct_capture_ram_sha256": digest(gct_memory_path),
              "capture_evidence_sha256": digest(capture / "results.json"),
              "compiler_sha256": digest(compiler), "script_sha256": digest(Path(__file__)),
              "patched_dol_sha256": digest(fixture), "module_sha256": digest(module),
              "sections": sections, "codegen_summary": re.findall(r"\d+ decoded[^\n]*", generated_result.stdout),
              "original_dol_unchanged": digest(original) == original_hash,
              "gct_region": gct_info, "send_game_info_instrumented": args.instrument_send_game_info,
              "instrumented_ini_sha256": digest(instrumented_ini_path) if instrumented_ini_path else None,
              "other_heap_code_compiled": False,
              "executed": False, "ios_compiled": False}
    (output / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"sections": sections, "module": str(module), "executed": False}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
