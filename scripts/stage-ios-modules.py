#!/usr/bin/env python3
"""Stage private locally built modules in an unsigned local app before signing.

Never use the resulting playable app as input to the public IPA packager.
"""
import argparse
import json
from pathlib import Path
import shutil
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SLIPPI_GAME_SETTINGS = ROOT / "ref/slippi-compatibility/upstream/Data/Sys/GameSettings/GALE01r2.ini"
SLIPPI_BOOTLOADER = ROOT / "ref/slippi-compatibility/ios-direct-005/SlippiProbe.app/Sys/bootloader.gct"
SLIPPI_GAME_FILES = ROOT / "ref/slippi-compatibility/ios-direct-005/SlippiProbe.app/Sys/GameFiles/GALE01"
REQUIRED_SLIPPI_CODES = (
    "$Required: General Codes",
    "$Required: Slippi Recording",
    "$Required: Slippi Online",
)


def require_native_slippi_coverage(module):
    data = Path(module).read_bytes()
    def unpack(fmt, offset):
        if offset < 0 or offset + struct.calcsize(fmt) > len(data):
            raise ValueError('native Slippi module has truncated Mach-O data')
        return struct.unpack_from(fmt, data, offset)
    magic, cpu, _, filetype, ncmds, sizeofcmds, _, _ = unpack('<8I', 0)
    if magic != 0xFEEDFACF or cpu != 0x0100000C or filetype != 6:
        raise ValueError('native Slippi module must be a thin ARM64 Mach-O dylib')
    end = 32 + sizeofcmds
    if end > len(data) or ncmds > sizeofcmds // 8:
        raise ValueError('native Slippi module has invalid load commands')
    segments = []
    offset = 32
    for _ in range(ncmds):
        cmd, size = unpack('<II', offset)
        if size < 8 or offset + size > end:
            raise ValueError('native Slippi module has invalid load command size')
        if cmd == 0x19:  # LC_SEGMENT_64
            if size < 72:
                raise ValueError('native Slippi module has truncated segment')
            vmaddr, _, fileoff, filesize = unpack('<4Q', offset + 24)
            if fileoff + filesize > len(data):
                raise ValueError('native Slippi module has invalid segment extent')
            segments.append((vmaddr, fileoff, filesize))
        offset += size
    if offset != end:
        raise ValueError('native Slippi module has inconsistent load commands')
    def file_offset(address, size):
        matches = [fileoff + address - vmaddr for vmaddr, fileoff, filesize in segments
                   if vmaddr <= address and address + size <= vmaddr + filesize]
        if len(matches) != 1:
            raise ValueError('native Slippi descriptor is not uniquely file-backed')
        return matches[0]
    # Local generated symbols are retained in private modules. Fail closed if
    # stripped; do not infer capability from the filename or DOL identity.
    symbols = {}
    for line in subprocess.check_output(['nm', '-a', str(module)], text=True).splitlines():
        fields = line.split()
        if len(fields) == 3 and fields[2] in ('_s_desc', '_s_code_ranges'):
            if fields[2] in symbols:
                raise ValueError('native Slippi module has ambiguous descriptor symbols')
            symbols[fields[2]] = int(fields[0], 16)
    if set(symbols) != {'_s_desc', '_s_code_ranges'}:
        raise ValueError('native Slippi module lacks inspectable generated descriptor symbols')
    desc = file_offset(symbols['_s_desc'], 112)
    abi, = unpack('<I', desc)
    game_id = data[desc + 12:desc + 20].rstrip(b'\0')
    count, = unpack('<I', desc + 48)
    if abi != 3 or game_id != b'GALE01' or not 1 <= count <= 1024:
        raise ValueError('native Slippi module has unsupported descriptor identity or range count')
    start = file_offset(symbols['_s_code_ranges'], count * 8)
    ranges = [unpack('<II', start + index * 8) for index in range(count)]
    cursor = 0x8065CC80
    for low, high in sorted(ranges):
        if low >= high:
            raise ValueError('native Slippi module has an invalid native code range')
        if low <= cursor < high:
            cursor = high
    if cursor < 0x8066AA10:
        raise ValueError('native Slippi module lacks required injected GCT native coverage; vanilla Melee modules are not valid Slippi modules')
    return ranges



def require_slippi_module_identity(module, platform, catalog):
    module = Path(module)
    revision = next((row for row in catalog if row["revision"] == 2), None)
    identity = Path(str(module) + ".dol-sha256")
    if revision is None or not module.is_file():
        raise ValueError("native Slippi v1.02 module is missing")
    if not identity.is_file() or identity.read_text().strip() != revision["dol_sha256"]:
        raise ValueError("native Slippi v1.02 module identity is missing or mismatched")
    builds = subprocess.check_output(["vtool", "-show-build", str(module)], text=True)
    expected = {"simulator": "IOSSIMULATOR", "device": "IOS"}[platform]
    if not any(line.strip() == f"platform {expected}" for line in builds.splitlines()):
        raise ValueError("native Slippi module belongs to a different Apple platform")
    require_native_slippi_coverage(module)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("--platform", choices=["device", "simulator"], required=True)
    parser.add_argument(
        "--slippi-module",
        type=Path,
        help="optional private native Slippi v1.02 module to stage",
    )
    args = parser.parse_args()
    if not (args.app / "Info.plist").is_file():
        parser.error("Expected a locally built iOS .app directory")
    catalog = json.loads((ROOT / "apple/shared/MeleePadRevisions.json").read_text())
    staged = []
    for revision in catalog:
        number = revision["revision"]
        suffix = "-r2" if number == 2 else ""
        directory = Path(f"/tmp/meleepad-module-ios-{args.platform}{suffix}")
        module = directory / "gGALE01_recomp.dylib"
        identity = directory / "gGALE01_recomp.dylib.dol-sha256"
        if not module.is_file():
            continue
        if not identity.is_file() or identity.read_text().strip() != revision["dol_sha256"]:
            parser.error(f"v{revision['version']} module identity is missing or mismatched")
        platform = subprocess.check_output(["vtool", "-show-build", str(module)], text=True)
        expected = "IOSSIMULATOR" if args.platform == "simulator" else "IOS"
        if not any(line.strip() == f"platform {expected}" for line in platform.splitlines()):
            parser.error("Module belongs to a different Apple platform")
        name = "gGALE01r2_recomp.dylib" if number == 2 else "gGALE01_recomp.dylib"
        staged.append((module, identity, name))
    if args.slippi_module:
        module = args.slippi_module.resolve()
        identity = Path(str(module) + ".dol-sha256")
        try:
            require_slippi_module_identity(module, args.platform, catalog)
        except (ValueError, OSError, subprocess.CalledProcessError) as error:
            parser.error(str(error))
        staged.append((module, identity, "gGALE01r2_slippi_recomp.dylib"))
        if not SLIPPI_GAME_SETTINGS.is_file():
            parser.error("pinned Slippi GALE01r2.ini is missing")
        settings_text = SLIPPI_GAME_SETTINGS.read_text()
        if any(code not in settings_text for code in REQUIRED_SLIPPI_CODES):
            parser.error("pinned Slippi GALE01r2.ini is missing a required code group")
        if not SLIPPI_BOOTLOADER.is_file():
            parser.error("pinned Slippi bootloader.gct is missing")
        if not (SLIPPI_GAME_FILES / "MxScn.dat").is_file():
            parser.error("pinned Slippi GALE01 resource pack is missing MxScn.dat")
    if not staged:
        parser.error("No matching locally built modules are available")
    # Validate every source before modifying the destination.
    for module, identity, name in staged:
        shutil.copy2(module, args.app / name)
        shutil.copy2(identity, args.app / (name + ".dol-sha256"))
        # Existing private test bundles may also carry a second module copy.
        # Keep it identical so a configuration path cannot select stale code.
        private_copy = args.app / "PrivateQA" / name
        if name == "gGALE01r2_slippi_recomp.dylib" and private_copy.exists():
            shutil.copy2(module, private_copy)
        print(f"Staged {name}; sign the module and app before device installation")
    if args.slippi_module:
        settings_destination = args.app / "Sys/GameSettings/GALE01r2.ini"
        if not settings_destination.parent.is_dir():
            parser.error("built app is missing its Sys/GameSettings resource directory")
        shutil.copy2(SLIPPI_GAME_SETTINGS, settings_destination)
        print("Staged pinned Slippi GALE01r2.ini; sign the app before device installation")
        bootloader_destination = args.app / "Sys/bootloader.gct"
        if not bootloader_destination.parent.is_dir():
            parser.error("built app is missing its Sys resource directory")
        shutil.copy2(SLIPPI_BOOTLOADER, bootloader_destination)
        print("Staged pinned Slippi bootloader.gct; sign the app before device installation")
        game_files_destination = args.app / "Sys/GameFiles/GALE01"
        game_files_destination.mkdir(parents=True, exist_ok=True)
        shutil.copytree(SLIPPI_GAME_FILES, game_files_destination, dirs_exist_ok=True)
        print("Staged pinned Slippi GALE01 resource pack; sign the app before device installation")


if __name__ == "__main__":
    main()
