#!/usr/bin/env python3
import importlib.util
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def module(name, file):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / file)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


identity = module("identity", "identify-game.py")
symbols = module("symbols", "symbolize-melee.py")


class Revisions(unittest.TestCase):
    def test_catalog_preserves_legacy_and_prefers_two(self):
        catalog = json.loads(identity.CATALOG.read_text())
        self.assertEqual([0, 2], [r["revision"] for r in catalog])
        self.assertEqual([2], [r["revision"] for r in catalog if r["recommended"]])
        self.assertEqual("2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484",
                         catalog[0]["images"][0]["sha256"])
        self.assertNotEqual(catalog[0]["dol_sha256"], catalog[1]["dol_sha256"])

    def test_identity_uses_contents_not_name_and_rejects_modified_data(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            image = root / "misleading-r0.iso"
            data = b"synthetic fixture only"
            image.write_bytes(data)
            catalog = root / "catalog.json"
            catalog.write_text(json.dumps([{"revision": 2, "images": [{
                "format": "iso", "size": len(data), "sha256": hashlib.sha256(data).hexdigest()}]}]))
            original = identity.CATALOG
            try:
                identity.CATALOG = catalog
                self.assertEqual(2, identity.identify(image)["revision"])
                image.write_bytes(b"X" + data[1:])
                with self.assertRaises(ValueError):
                    identity.identify(image)
                image.write_bytes(data[:-1])
                with self.assertRaises(ValueError):
                    identity.identify(image)
            finally:
                identity.CATALOG = original

    def test_symbol_ranges_do_not_bleed_into_gaps_or_data(self):
        table = symbols.load_symbols("wait = .text:0x80000010; // type:function size:0x8\n"
                                     "data = .bss:0x80000020; // type:object size:0x8")
        self.assertEqual("wait+0x4", symbols.describe(0x80000014, table))
        for address in (0, 0x80000018, 0x80000020):
            self.assertEqual("unknown", symbols.describe(address, table))


if __name__ == "__main__":
    unittest.main()
