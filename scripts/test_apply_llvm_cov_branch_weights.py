#!/usr/bin/env python3

import importlib.util
import pathlib
import unittest


SCRIPT = pathlib.Path(__file__).with_name("apply-llvm-cov-branch-weights.py")
SPEC = importlib.util.spec_from_file_location("branch_weights", SCRIPT)
assert SPEC and SPEC.loader
BRANCH_WEIGHTS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BRANCH_WEIGHTS)


class BranchWeightTests(unittest.TestCase):
    def test_single_and_short_circuit_conditions(self):
        source = (
            "void f(void) {\n"
            "  if (!ready) return;\n"
            "  if (left && right) {\n"
            "  } else if (x > y) {\n"
            "  }\n"
            "}\n"
        )
        result, weighted, skipped = BRANCH_WEIGHTS.transform(
            source,
            {
                2: [(1, 99)],
                3: [(90, 10), (80, 10)],
                4: [(0, 0)],
            },
        )
        self.assertEqual(weighted, 3)
        self.assertEqual(skipped, 1)
        self.assertIn("!!(!ready), 1, 0.01", result)
        self.assertIn("!!(left), 1, 0.90000000000000002", result)
        self.assertIn("!!(right), 1, 0.88888888888888884", result)
        self.assertIn("} else if (x > y) {", result)

    def test_rejects_multiple_branches_without_short_circuit_shape(self):
        with self.assertRaisesRegex(ValueError, "need a short-circuit condition"):
            BRANCH_WEIGHTS.transform("if (ready) return;\n", {1: [(1, 0), (1, 0)]})

    def test_rejects_mixed_executed_state_on_one_line(self):
        with self.assertRaisesRegex(ValueError, "mixes executed and unexecuted"):
            BRANCH_WEIGHTS.transform("if (left && right) return;\n", {1: [(1, 0), (0, 0)]})

    def test_marks_exactly_one_generated_function_hot(self):
        source = "void func_80375940(CPUState* ctx) {\n}\n"
        result = BRANCH_WEIGHTS.mark_hot_function(source, "func_80375940")
        self.assertEqual(
            result,
            "__attribute__((hot)) void func_80375940(CPUState* ctx) {\n}\n",
        )
        with self.assertRaisesRegex(ValueError, "expected one definition"):
            BRANCH_WEIGHTS.mark_hot_function(source, "func_80000000")


if __name__ == "__main__":
    unittest.main()
