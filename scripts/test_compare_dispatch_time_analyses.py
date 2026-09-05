#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "compare-dispatch-time-analyses.py"


class CompareDispatchTimeAnalysesTest(unittest.TestCase):
    def test_rejects_unstable_regions_and_sums_conservative_coverage(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first = root / "first.csv"
            second = root / "second.csv"
            header = (
                "REGION,rank,start,end,min_time_share,max_time_share,"
                "early_samples,early_corrected_ns,early_share,"
                "late_samples,late_corrected_ns,late_share\n"
            )
            first.write_text(
                header
                + "REGION,1,00001000,00002000,0.30,0.32,10,100,0.30,10,100,0.32\n"
                + "REGION,2,00002000,00003000,0.22,0.24,10,100,0.22,10,100,0.24\n"
                + "REGION,3,00003000,00004000,0.10,0.30,10,100,0.10,10,100,0.30\n",
                encoding="utf-8",
            )
            second.write_text(
                header
                + "REGION,1,00001000,00002000,0.28,0.31,10,100,0.28,10,100,0.31\n"
                + "REGION,2,00002000,00003000,0.20,0.23,10,100,0.20,10,100,0.23\n"
                + "REGION,3,00003000,00004000,0.08,0.29,10,100,0.20,10,100,0.29\n",
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    str(SCRIPT), "--analysis", "a", str(first),
                    "--analysis", "b", str(second), "--region-size", "0x1000",
                    "--maximum-share-ratio", "1.25", "--target-coverage", "0.45",
                ],
                check=False, text=True, capture_output=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("stable_regions=2", result.stdout)
        self.assertIn("selected_regions=2", result.stdout)
        self.assertIn("selected_minimum_coverage=0.480000", result.stdout)
        self.assertIn("coverage_gate=PASS", result.stdout)
        self.assertIn("REGION,1,00001000,00002000", result.stdout)
        self.assertNotIn("00003000,00004000", result.stdout)

    def test_rejects_analysis_without_regions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "empty.csv"
            path.write_text("WINDOW,label\n", encoding="utf-8")
            result = subprocess.run(
                [str(SCRIPT), "--analysis", "empty", str(path)],
                check=False, text=True, capture_output=True,
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("contains no region rows", result.stderr)


if __name__ == "__main__":
    unittest.main()
