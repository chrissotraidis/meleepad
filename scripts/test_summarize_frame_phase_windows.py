#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "summarize-frame-phase-windows.py"


class SummarizeFramePhaseWindowsTest(unittest.TestCase):
    def test_summarizes_complete_rows_and_skips_partial_tail(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            phase = Path(directory) / "phase.csv"
            phase.write_text(
                "emulated_frame,host_frame_end_unix_ns,total_ms,cpu_thread_ms,"
                "video_build_ms,present_ms,static_cycles,static_native_dispatches,"
                "draw_calls,primitives\n"
                "10,1000000000,10,8,1,0.1,100,10,5,50\n"
                "11,1020000000,20,16,2,0.2,200,20,6,60\n"
                "12,\n",
                encoding="utf-8",
            )
            result = subprocess.run(
                [str(SCRIPT), str(phase), "--window", "test", "10", "12"],
                check=False, text=True, capture_output=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("WINDOW,test,2", result.stdout)
        self.assertIn(",15.000000,19.500000,12.000000,15.600000,", result.stdout)
        self.assertIn(",150.000,15.000,5.500,55.000", result.stdout)

    def test_rejects_missing_columns(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            phase = Path(directory) / "phase.csv"
            phase.write_text("emulated_frame,total_ms\n1,2\n", encoding="utf-8")
            result = subprocess.run(
                [str(SCRIPT), str(phase), "--window", "bad", "1", "2"],
                check=False, text=True, capture_output=True,
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing required timing columns", result.stderr)


if __name__ == "__main__":
    unittest.main()
