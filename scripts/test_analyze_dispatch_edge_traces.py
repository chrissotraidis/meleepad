#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "analyze-dispatch-edge-traces.py"
SPEC = importlib.util.spec_from_file_location("analyze_dispatch_edge_traces", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class DispatchEdgeTraceTest(unittest.TestCase):
    def test_burst_index_zero_is_not_an_edge(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            trace = Path(directory) / "burst.csv"
            trace.write_text(
                "emulated_frame,burst,index,previous_pc,pc\n"
                "10,1,0,deadbeef,80000000\n"
                "10,1,1,80000000,80000004\n"
                "10,1,2,80000004,80000008\n",
                encoding="utf-8",
            )
            edges = MODULE.load_edges(trace, 10, 10)
        self.assertNotIn("DEADBEEF", edges)
        self.assertEqual(edges["80000000"]["80000004"], 1)
        self.assertEqual(edges["80000004"]["80000008"], 1)


if __name__ == "__main__":
    unittest.main()
