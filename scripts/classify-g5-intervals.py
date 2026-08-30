#!/usr/bin/env python3
"""Classify G5 producer misses and GPU-ready fixed-rate presentation holds.

This tool deliberately does not decide whether G5 passes. It separates two
independent timelines inside an explicitly bounded combat window and refuses
to silently discard ambiguous, unjoined, or undisplayed records.
"""

import argparse
import bisect
import csv
import json
import math
import sys
from fractions import Fraction
from pathlib import Path


PRESENTATION_REQUIRED = {
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
}
PHASE_REQUIRED = {
    "frame",
    "emulated_frame",
    "host_frame_end_unix_ns",
    "total_ms",
    "cpu_wall_ms",
    "cpu_thread_ms",
    "audio_mix_ms",
}


class ClassifierError(Exception):
    pass


def finite_float(value, field, row_number):
    try:
        result = float(value)
    except (TypeError, ValueError) as error:
        raise ClassifierError(f"row {row_number}: invalid {field}: {value!r}") from error
    if not math.isfinite(result):
        raise ClassifierError(f"row {row_number}: non-finite {field}: {value!r}")
    return result


def integer(value, field, row_number):
    try:
        return int(value)
    except (TypeError, ValueError) as error:
        raise ClassifierError(f"row {row_number}: invalid {field}: {value!r}") from error


def read_csv(path, required_columns, kind):
    try:
        source = path.open(newline="")
    except OSError as error:
        raise ClassifierError(f"cannot open {kind} CSV {path}: {error}") from error
    with source:
        reader = csv.DictReader(source)
        columns = set(reader.fieldnames or [])
        missing = sorted(required_columns - columns)
        if missing:
            raise ClassifierError(
                f"{kind} CSV missing required columns: {', '.join(missing)}"
            )
        return list(reader)


def parse_presentation_rows(path):
    raw_rows = read_csv(path, PRESENTATION_REQUIRED, "presentation")
    rows = []
    previous_index = None
    for row_number, raw in enumerate(raw_rows, start=2):
        row = {
            "index": integer(raw["index"], "index", row_number),
            "emulated_frame": integer(raw["emulated_frame"], "emulated_frame", row_number),
            "present_frame": integer(raw["present_frame"], "present_frame", row_number),
            "calibration_unix_ns": integer(
                raw["calibration_unix_ns"], "calibration_unix_ns", row_number
            ),
            "command_status": integer(raw["command_status"], "command_status", row_number),
        }
        for field in (
            "calibration_ca_s",
            "registered_ca_s",
            "scheduled_ca_s",
            "gpu_start_ca_s",
            "gpu_end_ca_s",
            "completed_ca_s",
            "presented_ca_s",
        ):
            row[field] = finite_float(raw[field], field, row_number)
        if previous_index is not None and row["index"] <= previous_index:
            raise ClassifierError("presentation indices must be strictly increasing")
        previous_index = row["index"]
        rows.append(row)
    return rows


def parse_phase_rows(path):
    raw_rows = read_csv(path, PHASE_REQUIRED, "phase")
    rows = []
    previous_host_time = None
    for row_number, raw in enumerate(raw_rows, start=2):
        row = {
            "frame": integer(raw["frame"], "frame", row_number),
            "emulated_frame": integer(raw["emulated_frame"], "emulated_frame", row_number),
            "host_frame_end_unix_ns": integer(
                raw["host_frame_end_unix_ns"], "host_frame_end_unix_ns", row_number
            ),
            "total_ms": finite_float(raw["total_ms"], "total_ms", row_number),
            "cpu_wall_ms": finite_float(raw["cpu_wall_ms"], "cpu_wall_ms", row_number),
            "cpu_thread_ms": finite_float(raw["cpu_thread_ms"], "cpu_thread_ms", row_number),
            "audio_mix_ms": finite_float(raw["audio_mix_ms"], "audio_mix_ms", row_number),
        }
        if any(row[field] < 0 for field in ("total_ms", "cpu_wall_ms", "cpu_thread_ms", "audio_mix_ms")):
            raise ClassifierError(f"row {row_number}: phase durations must be non-negative")
        if previous_host_time is not None and row["host_frame_end_unix_ns"] <= previous_host_time:
            raise ClassifierError("phase host timestamps must be strictly increasing")
        previous_host_time = row["host_frame_end_unix_ns"]
        rows.append(row)
    return rows


def select_window(rows, start_index, end_index):
    if start_index > end_index:
        raise ClassifierError("start-index must be at most end-index")
    selected = [row for row in rows if start_index <= row["index"] <= end_index]
    if not selected or selected[0]["index"] != start_index or selected[-1]["index"] != end_index:
        raise ClassifierError("selected presentation window does not contain both requested bounds")
    expected = list(range(start_index, end_index + 1))
    actual = [row["index"] for row in selected]
    if actual != expected:
        raise ClassifierError("selected presentation window contains an index gap")
    if len(selected) < 2:
        raise ClassifierError("selected presentation window needs at least two rows")
    return selected


def join_phase_rows(presentation_rows, phase_rows, tolerance_ms):
    if tolerance_ms < 0:
        raise ClassifierError("join-tolerance-ms must be non-negative")
    phase_times = [row["host_frame_end_unix_ns"] for row in phase_rows]
    tolerance_ns = tolerance_ms * 1_000_000.0
    joined = {}
    used_phase_frames = set()
    for presentation in presentation_rows:
        target = presentation["calibration_unix_ns"]
        position = bisect.bisect_left(phase_times, target)
        candidates = []
        if position < len(phase_rows):
            candidates.append(phase_rows[position])
        if position > 0:
            candidates.append(phase_rows[position - 1])
        if not candidates:
            raise ClassifierError(
                f"cannot join presentation index {presentation['index']}: phase CSV is empty"
            )
        phase = min(candidates, key=lambda row: abs(row["host_frame_end_unix_ns"] - target))
        difference_ns = abs(phase["host_frame_end_unix_ns"] - target)
        if difference_ns > tolerance_ns:
            raise ClassifierError(
                f"cannot join presentation index {presentation['index']}: "
                f"nearest phase row is {difference_ns / 1_000_000.0:.6f} ms away"
            )
        if phase["frame"] in used_phase_frames:
            raise ClassifierError(
                f"cannot join presentation index {presentation['index']}: phase row reused"
            )
        if phase["emulated_frame"] != presentation["emulated_frame"]:
            raise ClassifierError(
                f"cannot join presentation index {presentation['index']}: emulated frame "
                f"{presentation['emulated_frame']} != {phase['emulated_frame']}"
            )
        used_phase_frames.add(phase["frame"])
        joined[presentation["index"]] = {
            **phase,
            "join_error_ms": difference_ns / 1_000_000.0,
        }
    return joined


def ambiguous_reasons(row, interval_ms, refresh_ms, refresh_tolerance_ms, deadline_s,
                      source_hz, display_hz, undisplayed_in_span):
    reasons = []
    refresh_multiple = round(interval_ms / refresh_ms)
    if refresh_multiple != 2:
        reasons.append("not_exactly_two_refreshes")
    elif abs(interval_ms - 2 * refresh_ms) > refresh_tolerance_ms:
        reasons.append("not_refresh_aligned")
    if source_hz >= display_hz:
        reasons.append("source_not_slower_than_display")
    if undisplayed_in_span:
        reasons.append("undisplayed_surface_in_span")
    if row["command_status"] != 4:
        reasons.append("command_buffer_not_completed")
    readiness_fields = (
        "registered_ca_s",
        "scheduled_ca_s",
        "gpu_end_ca_s",
        "completed_ca_s",
    )
    if any(row[field] <= 0 for field in readiness_fields):
        reasons.append("missing_readiness_timestamp")
    elif any(row[field] > deadline_s for field in readiness_fields):
        reasons.append("surface_not_ready_by_missed_deadline")
    return reasons


def classify(args):
    if args.budget_ms <= 0 or args.refresh_tolerance_ms < 0:
        raise ClassifierError("budget and refresh tolerance must be valid positive values")
    try:
        source_hz = float(Fraction(args.source_hz))
        display_hz = float(Fraction(args.display_hz))
    except (ValueError, ZeroDivisionError) as error:
        raise ClassifierError(f"invalid source/display frequency: {error}") from error
    if source_hz <= 0 or display_hz <= 0:
        raise ClassifierError("source and display frequencies must be positive")

    presentation_rows = parse_presentation_rows(args.presentation)
    phase_rows = parse_phase_rows(args.phase)
    selected = select_window(presentation_rows, args.start_index, args.end_index)
    joined = join_phase_rows(selected, phase_rows, args.join_tolerance_ms)

    producer_misses = []
    # total_ms is the interval ending at this row. The first selected row begins
    # before the explicit window and therefore cannot be counted as an in-window interval.
    for presentation in selected[1:]:
        phase = joined[presentation["index"]]
        if phase["total_ms"] > args.budget_ms:
            producer_misses.append(
                {
                    "presentation_index": presentation["index"],
                    "phase_frame": phase["frame"],
                    "emulated_frame": phase["emulated_frame"],
                    "total_ms": phase["total_ms"],
                    "over_budget_ms": phase["total_ms"] - args.budget_ms,
                    "cpu_wall_ms": phase["cpu_wall_ms"],
                    "cpu_thread_ms": phase["cpu_thread_ms"],
                    "wall_minus_thread_ms": phase["cpu_wall_ms"] - phase["cpu_thread_ms"],
                    "audio_mix_ms": phase["audio_mix_ms"],
                    "thread_cpu_over_budget": phase["cpu_thread_ms"] > args.budget_ms,
                }
            )

    refresh_ms = 1000.0 / display_hz
    presentation_events = []
    undisplayed = []
    previous_displayed = None
    undisplayed_since_previous = 0
    actual_interval_count = 0
    actual_over_budget_count = 0
    for row in selected:
        if row["presented_ca_s"] <= 0:
            undisplayed.append(
                {
                    "presentation_index": row["index"],
                    "emulated_frame": row["emulated_frame"],
                    "command_status": row["command_status"],
                }
            )
            undisplayed_since_previous += 1
            continue
        if previous_displayed is not None:
            actual_interval_count += 1
            interval_ms = (row["presented_ca_s"] - previous_displayed["presented_ca_s"]) * 1000.0
            if interval_ms <= 0:
                raise ClassifierError("presented timestamps must be strictly increasing")
            if interval_ms > args.budget_ms:
                actual_over_budget_count += 1
                deadline_s = previous_displayed["presented_ca_s"] + refresh_ms / 1000.0
                reasons = ambiguous_reasons(
                    row,
                    interval_ms,
                    refresh_ms,
                    args.refresh_tolerance_ms,
                    deadline_s,
                    source_hz,
                    display_hz,
                    undisplayed_since_previous,
                )
                readiness_fields = (
                    "registered_ca_s",
                    "scheduled_ca_s",
                    "gpu_end_ca_s",
                    "completed_ca_s",
                )
                ready_margin_ms = min(
                    (deadline_s - row[field]) * 1000.0 for field in readiness_fields
                )
                event_class = (
                    "fixed_rate_conversion" if not reasons else "ambiguous_presentation_miss"
                )
                presentation_events.append(
                    {
                        "class": event_class,
                        "previous_presentation_index": previous_displayed["index"],
                        "presentation_index": row["index"],
                        "emulated_frame": row["emulated_frame"],
                        "interval_ms": interval_ms,
                        "refresh_multiple": round(interval_ms / refresh_ms),
                        "missed_deadline_ca_s": deadline_s,
                        "minimum_ready_margin_ms": ready_margin_ms,
                        "producer_total_ms": joined[row["index"]]["total_ms"],
                        "reasons": reasons,
                    }
                )
        previous_displayed = row
        undisplayed_since_previous = 0

    fixed_count = sum(
        event["class"] == "fixed_rate_conversion" for event in presentation_events
    )
    ambiguous_count = sum(
        event["class"] == "ambiguous_presentation_miss" for event in presentation_events
    )
    classification_complete = ambiguous_count == 0 and not undisplayed
    summary = {
        "selected_presentation_rows": len(selected),
        "joined_phase_rows": len(joined),
        "actual_presentation_intervals": actual_interval_count,
        "actual_intervals_over_budget": actual_over_budget_count,
        "fixed_rate_conversion_holds": fixed_count,
        "ambiguous_presentation_misses": ambiguous_count,
        "undisplayed_surfaces": len(undisplayed),
        "producer_budget_misses": len(producer_misses),
        "producer_thread_cpu_over_budget": sum(
            miss["thread_cpu_over_budget"] for miss in producer_misses
        ),
        "producer_thread_cpu_within_budget": sum(
            not miss["thread_cpu_over_budget"] for miss in producer_misses
        ),
    }
    return {
        "schema_version": 1,
        "window": {"start_index": args.start_index, "end_index": args.end_index},
        "thresholds": {
            "budget_ms": args.budget_ms,
            "source_hz": source_hz,
            "display_hz": display_hz,
            "refresh_tolerance_ms": args.refresh_tolerance_ms,
            "join_tolerance_ms": args.join_tolerance_ms,
        },
        "summary": summary,
        "classification_complete": classification_complete,
        "producer_budget_pass": not producer_misses,
        "strict_all_observed_intervals_pass": (
            not producer_misses and actual_over_budget_count == 0 and not undisplayed
        ),
        "g5_pass_claimed": False,
        "presentation_events": presentation_events,
        "producer_misses": producer_misses,
        "undisplayed_surfaces": undisplayed,
    }


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--presentation", type=Path, required=True)
    parser.add_argument("--phase", type=Path, required=True)
    parser.add_argument("--start-index", type=int, required=True)
    parser.add_argument("--end-index", type=int, required=True)
    parser.add_argument("--budget-ms", type=float, default=16.7)
    parser.add_argument("--source-hz", default="60000/1001")
    parser.add_argument("--display-hz", default="60")
    parser.add_argument("--refresh-tolerance-ms", type=float, default=0.25)
    parser.add_argument("--join-tolerance-ms", type=float, default=1.0)
    parser.add_argument("--json", action="store_true")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    try:
        result = classify(args)
    except ClassifierError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    if args.json:
        json.dump(result, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        summary = result["summary"]
        print(
            "rows={selected_presentation_rows} intervals={actual_presentation_intervals} "
            "fixed={fixed_rate_conversion_holds} ambiguous={ambiguous_presentation_misses} "
            "undisplayed={undisplayed_surfaces} producer_misses={producer_budget_misses} "
            "producer_thread_over={producer_thread_cpu_over_budget} "
            "producer_thread_within={producer_thread_cpu_within_budget}".format(
                **summary
            )
        )
        print(f"classification_complete={str(result['classification_complete']).lower()}")
        print("g5_pass_claimed=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
