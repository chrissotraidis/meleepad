#!/usr/bin/env python3

import csv
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CLASSIFIER = ROOT / "scripts" / "classify-g5-intervals.py"
PRESENTATION_FIELDS = [
    "index",
    "emulated_frame",
    "present_frame",
    "calibration_unix_ns",
    "calibration_ca_s",
    "registered_ca_s",
    "scheduled_ca_s",
    "gpu_start_ca_s",
    "gpu_end_ca_s",
    "completed_ca_s",
    "presented_ca_s",
    "command_status",
]
PHASE_FIELDS = [
    "frame",
    "emulated_frame",
    "host_frame_end_unix_ns",
    "total_ms",
    "cpu_wall_ms",
    "cpu_thread_ms",
    "audio_mix_ms",
]
BASE_UNIX_NS = 1_788_000_000_000_000_000


def presentation_row(index, presented_s, registered_s=None, gpu_end_s=None, completed_s=None):
    calibration_s = presented_s if presented_s else 100.0 + index / 60.0
    registered_s = registered_s if registered_s is not None else calibration_s - 0.010
    gpu_end_s = gpu_end_s if gpu_end_s is not None else calibration_s - 0.005
    completed_s = completed_s if completed_s is not None else gpu_end_s + 0.0002
    return {
        "index": index,
        "emulated_frame": 1000 + index,
        "present_frame": 2000 + index,
        "calibration_unix_ns": BASE_UNIX_NS + round(calibration_s * 1_000_000_000),
        "calibration_ca_s": f"{calibration_s:.9f}",
        "registered_ca_s": f"{registered_s:.9f}",
        "scheduled_ca_s": f"{registered_s + 0.0002:.9f}",
        "gpu_start_ca_s": f"{gpu_end_s - 0.001:.9f}",
        "gpu_end_ca_s": f"{gpu_end_s:.9f}",
        "completed_ca_s": f"{completed_s:.9f}",
        "presented_ca_s": f"{presented_s:.9f}",
        "command_status": 4,
    }


def phase_row(index, presentation, total_ms, cpu_thread_ms=8.0):
    return {
        "frame": index,
        "emulated_frame": presentation["emulated_frame"],
        "host_frame_end_unix_ns": int(presentation["calibration_unix_ns"]) + 20_000,
        "total_ms": f"{total_ms:.6f}",
        "cpu_wall_ms": f"{max(total_ms - 0.2, cpu_thread_ms):.6f}",
        "cpu_thread_ms": f"{cpu_thread_ms:.6f}",
        "audio_mix_ms": "0.700000",
    }


class ClassifyG5IntervalsTest(unittest.TestCase):
    def run_classifier(
        self,
        presentations,
        totals,
        extra_args=None,
        phase_fields=PHASE_FIELDS,
        cpu_threads=None,
    ):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            presentation_path = directory / "present.csv"
            phase_path = directory / "phase.csv"
            with presentation_path.open("w", newline="") as output:
                writer = csv.DictWriter(output, fieldnames=PRESENTATION_FIELDS)
                writer.writeheader()
                writer.writerows(presentations)
            with phase_path.open("w", newline="") as output:
                writer = csv.DictWriter(output, fieldnames=phase_fields)
                writer.writeheader()
                for index, (presentation, total_ms) in enumerate(zip(presentations, totals)):
                    cpu_thread_ms = cpu_threads[index] if cpu_threads else 8.0
                    row = phase_row(index, presentation, total_ms, cpu_thread_ms)
                    writer.writerow({field: row.get(field, "") for field in phase_fields})
            command = [
                sys.executable,
                str(CLASSIFIER),
                "--presentation",
                str(presentation_path),
                "--phase",
                str(phase_path),
                "--start-index",
                "0",
                "--end-index",
                str(len(presentations) - 1),
                "--json",
            ]
            if extra_args:
                command.extend(extra_args)
            completed = subprocess.run(command, text=True, capture_output=True, check=False)
            payload = json.loads(completed.stdout) if completed.stdout else None
            return completed, payload

    def base_presentations(self):
        return [
            presentation_row(0, 100.000000000),
            presentation_row(1, 100.016666667),
            presentation_row(
                2,
                100.050000000,
                registered_s=100.025000000,
                gpu_end_s=100.030000000,
                completed_s=100.030200000,
            ),
        ]

    def test_gpu_ready_double_interval_is_fixed_rate_conversion(self):
        completed, payload = self.run_classifier(self.base_presentations(), [0.0, 16.68, 16.68])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(payload["summary"]["fixed_rate_conversion_holds"], 1)
        self.assertEqual(payload["summary"]["ambiguous_presentation_misses"], 0)
        self.assertEqual(payload["summary"]["producer_budget_misses"], 0)
        self.assertTrue(payload["classification_complete"])

    def test_producer_miss_is_independent_of_nominal_presentation(self):
        presentations = self.base_presentations()[:2]
        completed, payload = self.run_classifier(presentations, [0.0, 22.0])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(payload["summary"]["fixed_rate_conversion_holds"], 0)
        self.assertEqual(payload["summary"]["producer_budget_misses"], 1)
        self.assertEqual(payload["summary"]["producer_thread_cpu_over_budget"], 0)
        self.assertEqual(payload["producer_misses"][0]["presentation_index"], 1)

    def test_thread_cpu_over_budget_is_reported_without_hiding_producer_miss(self):
        presentations = self.base_presentations()[:2]
        completed, payload = self.run_classifier(
            presentations, [0.0, 22.0], cpu_threads=[0.0, 18.0]
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(payload["summary"]["producer_budget_misses"], 1)
        self.assertEqual(payload["summary"]["producer_thread_cpu_over_budget"], 1)
        self.assertTrue(payload["producer_misses"][0]["thread_cpu_over_budget"])

    def test_first_phase_row_is_not_an_interval_inside_the_window(self):
        presentations = self.base_presentations()[:2]
        completed, payload = self.run_classifier(presentations, [22.0, 16.68])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(payload["summary"]["producer_budget_misses"], 0)

    def test_conversion_and_producer_miss_can_coexist(self):
        completed, payload = self.run_classifier(self.base_presentations(), [0.0, 16.68, 22.0])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(payload["summary"]["fixed_rate_conversion_holds"], 1)
        self.assertEqual(payload["summary"]["producer_budget_misses"], 1)
        self.assertEqual(payload["presentation_events"][0]["class"], "fixed_rate_conversion")

    def test_gpu_late_double_interval_is_ambiguous(self):
        presentations = self.base_presentations()
        presentations[2] = presentation_row(
            2,
            100.050000000,
            registered_s=100.040000000,
            gpu_end_s=100.045000000,
            completed_s=100.045200000,
        )
        completed, payload = self.run_classifier(presentations, [0.0, 16.68, 16.68])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(payload["summary"]["fixed_rate_conversion_holds"], 0)
        self.assertEqual(payload["summary"]["ambiguous_presentation_misses"], 1)
        self.assertEqual(payload["presentation_events"][0]["class"], "ambiguous_presentation_miss")
        self.assertFalse(payload["classification_complete"])

    def test_zero_presented_surface_is_not_silently_discarded(self):
        presentations = self.base_presentations()
        presentations[2] = presentation_row(2, 0.0)
        completed, payload = self.run_classifier(presentations, [0.0, 16.68, 16.68])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(payload["summary"]["undisplayed_surfaces"], 1)
        self.assertFalse(payload["classification_complete"])

    def test_missing_required_phase_column_is_a_hard_error(self):
        completed, payload = self.run_classifier(
            self.base_presentations(), [0.0, 16.68, 16.68], phase_fields=["frame", "total_ms"]
        )
        self.assertEqual(completed.returncode, 2)
        self.assertIsNone(payload)
        self.assertIn("missing required columns", completed.stderr)

    def test_unjoined_phase_row_is_a_hard_error(self):
        completed, payload = self.run_classifier(
            self.base_presentations(),
            [0.0, 16.68, 16.68],
            extra_args=["--join-tolerance-ms", "0.001"],
        )
        self.assertEqual(completed.returncode, 2)
        self.assertIsNone(payload)
        self.assertIn("cannot join", completed.stderr)


if __name__ == "__main__":
    unittest.main()
