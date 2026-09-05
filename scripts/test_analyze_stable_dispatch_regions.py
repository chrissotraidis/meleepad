#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "analyze-stable-dispatch-regions.py"
PHASE_HEADER = (
    "frame,host_frame_end_unix_ns,cpu_thread_ms,static_native_dispatches,"
    "draw_calls,primitives\n"
)


class StableDispatchRegionsTest(unittest.TestCase):
    def test_joins_wall_windows_and_rejects_unstable_regions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            phase_a = root / "phase-a.csv"
            phase_b = root / "phase-b.csv"
            samples_a = root / "samples-a.csv"
            samples_b = root / "samples-b.csv"
            phase_a.write_text(
                PHASE_HEADER
                + "1,100,10.0,100,700,40000\n"
                + "2,200,12.0,120,800,50000\n"
                + "3,300,1.0,10,1,1\n",
                encoding="utf-8",
            )
            phase_b.write_text(
                PHASE_HEADER
                + "10,100,20.0,200,900,60000\n"
                + "11,200,22.0,220,1000,70000\n",
                encoding="utf-8",
            )
            samples_a.write_text(
                "frame,pc\n"
                + "1,00001004\n" * 3
                + "2,00001008\n" * 3
                + "1,00002004\n" * 2
                + "2,00003004\n" * 2
                + "3,00004004\n" * 30,
                encoding="utf-8",
            )
            samples_b.write_text(
                "frame,pc\n"
                + "10,00001004\n" * 3
                + "11,00001008\n" * 3
                + "10,00002004\n" * 4
                + "11,00002008\n" * 4,
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    str(SCRIPT),
                    "--window",
                    "a",
                    str(phase_a),
                    str(samples_a),
                    "50",
                    "250",
                    "--window",
                    "b",
                    str(phase_b),
                    str(samples_b),
                    "50",
                    "250",
                    "--region-size",
                    "0x1000",
                    "--minimum-region-samples",
                    "2",
                    "--maximum-share-ratio",
                    "1.5",
                    "--target-coverage",
                    "0.4",
                ],
                check=False,
                text=True,
                capture_output=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("WINDOW,a,2,0.000000", result.stdout)
        self.assertIn("stable_regions=1", result.stdout)
        self.assertIn("selected_regions=1", result.stdout)
        self.assertIn("coverage_gate=PASS", result.stdout)
        self.assertIn("REGION,1,00001000,00002000", result.stdout)
        self.assertNotIn("REGION,2,00002000", result.stdout)
        self.assertIn("ENTRY,00001000", result.stdout)
        self.assertIn("00001004", result.stdout)

    def test_rejects_phase_csv_without_required_columns(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            phase = root / "phase.csv"
            samples = root / "samples.csv"
            phase.write_text("frame,host_frame_end_unix_ns\n1,100\n", encoding="utf-8")
            samples.write_text("frame,pc\n1,00001000\n", encoding="utf-8")
            result = subprocess.run(
                [
                    str(SCRIPT),
                    "--window",
                    "bad",
                    str(phase),
                    str(samples),
                    "50",
                    "150",
                ],
                check=False,
                text=True,
                capture_output=True,
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("phase CSV for bad must contain", result.stderr)


if __name__ == "__main__":
    unittest.main()
