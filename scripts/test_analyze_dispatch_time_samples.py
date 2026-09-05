#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "analyze-dispatch-time-samples.py"


class DispatchTimeSamplesTest(unittest.TestCase):
    def test_subtracts_clock_cost_and_ranks_stable_regions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            phase = root / "phase.csv"
            samples = root / "samples.csv"
            phase.write_text(
                "emulated_frame,cpu_thread_ms\n"
                "10,2.0\n11,4.0\n20,6.0\n21,8.0\n",
                encoding="utf-8",
            )
            samples.write_text(
                "emulated_frame,pc,host_ns,clock_ns\n"
                "10,00001004,110,10\n11,00001008,210,10\n"
                "10,00002004,1010,10\n11,00002008,1010,10\n"
                "20,00001004,310,10\n21,00001008,410,10\n"
                "20,00002004,1010,10\n21,00002008,1010,10\n",
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    str(SCRIPT), "--phase", str(phase), "--samples", str(samples),
                    "--window", "a", "10", "12", "--window", "b", "20", "22",
                    "--sample-interval", "10", "--region-size", "0x1000",
                    "--minimum-region-samples", "1",
                ],
                check=False, text=True, capture_output=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("WINDOW,a,2,4,10.000,3.000000", result.stdout)
        self.assertIn("REGION,1,00002000,00003000", result.stdout)
        self.assertIn("ENTRY,1,00002004", result.stdout)

    def test_rejects_missing_clock_column(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            phase = root / "phase.csv"
            samples = root / "samples.csv"
            phase.write_text("emulated_frame,cpu_thread_ms\n1,1\n", encoding="utf-8")
            samples.write_text("emulated_frame,pc,host_ns\n1,1000,1\n", encoding="utf-8")
            result = subprocess.run(
                [str(SCRIPT), "--phase", str(phase), "--samples", str(samples),
                 "--window", "bad", "1", "2", "--sample-interval", "2"],
                check=False, text=True, capture_output=True,
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("sample CSV must contain", result.stderr)


if __name__ == "__main__":
    unittest.main()
