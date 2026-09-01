#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "analyze-region-coverage.py"


class RegionCoverageTest(unittest.TestCase):
    def run_tool(self, contents: str, *arguments: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            sample = Path(directory) / "samples.csv"
            sample.write_text(contents, encoding="utf-8")
            return subprocess.run(
                [str(SCRIPT), str(sample), *arguments],
                check=False,
                text=True,
                capture_output=True,
            )

    def test_ranks_regions_and_computes_gate(self) -> None:
        result = self.run_tool(
            "frame,pc\n10,00000004\n10,00000008\n10,00000014\n11,00000018\n",
            "--first-frame",
            "10",
            "--last-frame",
            "10",
            "--region-size",
            "0x10",
            "--local-gain",
            "0.5",
            "--target-whole-gain",
            "0.3",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("required_coverage=0.600000,required_regions=1", result.stdout)
        self.assertIn("1,00000000,00000010,2,0.666667,0.666667,0.333333", result.stdout)
        self.assertNotIn("00000018", result.stdout)

    def test_rejects_missing_columns(self) -> None:
        result = self.run_tool(
            "emulated_frame,address\n1,80000000\n",
            "--first-frame",
            "1",
            "--last-frame",
            "1",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must contain frame and pc columns", result.stderr)


if __name__ == "__main__":
    unittest.main()
