#!/usr/bin/env python3
import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "matrix_experiment",
    Path(__file__).with_name("prepare-matrix-local-state-experiment.py"),
)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class ExperimentInputTests(unittest.TestCase):
    def test_unsupported_sources_fail_before_output_creation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(ValueError, "unsupported source"):
                m.prepare(root / "generated", root / "runtime", root / "output")
            self.assertFalse((root / "output").exists())

    def test_validates_both_source_roots_and_rejects_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for kind in ("generated", "runtime"):
                (root / kind).mkdir()
                (root / kind / "fixture").write_bytes(kind.encode())
            expected = {
                f"{kind}/fixture": hashlib.sha256(kind.encode()).hexdigest()
                for kind in ("generated", "runtime")
            }
            with patch.object(m, "EXPECTED_INPUTS", expected):
                m.validate_inputs(root / "generated", root / "runtime")
                (root / "runtime/fixture").write_text("changed arithmetic")
                with self.assertRaisesRegex(ValueError, "runtime/fixture"):
                    m.validate_inputs(root / "generated", root / "runtime")

    def test_never_overwrites_existing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "output").mkdir()
            marker = root / "output/marker"
            marker.write_text("keep")
            with patch.object(m, "validate_inputs"):
                with self.assertRaisesRegex(ValueError, "already exists"):
                    m.prepare(root / "generated", root / "runtime", root / "output")
            self.assertEqual(marker.read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
