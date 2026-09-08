#!/usr/bin/env python3
"""Identify only reviewed local images. Never trust the filename or header alone."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

CATALOG = Path(__file__).resolve().parents[1] / "apple/shared/MeleePadRevisions.json"


def identify(path):
    size = path.stat().st_size
    entries = json.loads(CATALOG.read_text())
    candidates = [(r, i) for r in entries for i in r["images"] if i["size"] == size]
    if not candidates:
        raise ValueError("Unsupported image size. Use a verified USA v1.00 or v1.02 ISO/GCM or supported CISO.")
    digest = hashlib.sha256()
    md5 = hashlib.md5()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
            md5.update(block)
    sha = digest.hexdigest()
    for revision, image in candidates:
        if image.get("sha256") == sha or image.get("md5") == md5.hexdigest():
            return {**revision, "image_sha256": sha, "format": image["format"]}
    raise ValueError("Image hash is not in the reviewed catalog; no game data was changed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", type=Path)
    parser.add_argument("--field", choices=["revision", "version", "image_sha256", "format", "dol_sha256"])
    parser.add_argument("--normalize", type=Path, help="Write a private raw ISO from a reviewed CISO; never overwrite")
    args = parser.parse_args()
    try:
        result = identify(args.image)
        if args.normalize:
            if result["format"] != "ciso":
                raise ValueError("Normalization requires a reviewed CISO")
            # Only reviewed complete containers reach this parser. Keep the
            # original intact and remove partial output after any failure.
            with args.image.open("rb") as stream:
                header = stream.read(0x8000)
                block_size = struct.unpack_from("<I", header, 4)[0]
                if header[:4] != b"CISO" or block_size != 2097152:
                    raise ValueError("Unsupported CISO layout")
                with args.normalize.open("xb") as output:
                    try:
                        size = 1459978240
                        for index in range((size + block_size - 1) // block_size):
                            block = stream.read(block_size) if header[8 + index] == 1 else bytes(block_size)
                            if len(block) != block_size:
                                raise ValueError("Truncated CISO")
                            output.write(block[:min(block_size, size - index * block_size)])
                    except BaseException:
                        args.normalize.unlink(missing_ok=True)
                        raise
            result = identify(args.normalize)
    except (OSError, ValueError) as error:
        parser.exit(1, f"{error}\n")
    print(result[args.field] if args.field else json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
