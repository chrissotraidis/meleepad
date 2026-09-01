#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "analyze-dispatch-delta.py"


class DispatchDeltaTest(unittest.TestCase):
    def run_tool(
        self, candidate_contents: str, control_contents: str, *arguments: str
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            candidate = Path(directory) / "candidate.csv"
            control = Path(directory) / "control.csv"
            candidate.write_text(candidate_contents, encoding="utf-8")
            control.write_text(control_contents, encoding="utf-8")
            return subprocess.run(
                [str(SCRIPT), str(candidate), str(control), *arguments],
                check=False,
                text=True,
                capture_output=True,
            )

    def test_ranks_normalized_region_and_pc_deltas(self) -> None:
        result = self.run_tool(
            "frame,pc\n10,00000004\n10,00000008\n11,00000004\n11,00000014\n",
            "frame,pc\n20,00000004\n21,00000014\n",
            "--candidate-first-frame",
            "10",
            "--candidate-last-frame",
            "11",
            "--control-first-frame",
            "20",
            "--control-last-frame",
            "21",
            "--region-size",
            "0x10",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("delta_per_frame=1.000000", result.stdout)
        self.assertIn(
            "REGION,1,00000000,00000010,1.500000,0.500000,1.000000,1.000000",
            result.stdout,
        )
        self.assertIn("PC,1,00000004,1.000000,0.500000,0.500000", result.stdout)

    def test_rejects_missing_columns(self) -> None:
        result = self.run_tool(
            "emulated_frame,address\n1,80000000\n",
            "frame,pc\n1,80000000\n",
            "--candidate-first-frame",
            "1",
            "--candidate-last-frame",
            "1",
            "--control-first-frame",
            "1",
            "--control-last-frame",
            "1",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must contain frame and pc columns", result.stderr)


if __name__ == "__main__":
    unittest.main()
