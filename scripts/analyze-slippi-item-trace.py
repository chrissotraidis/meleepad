#!/usr/bin/env python3
"""Compare finalized Slippi item events without collapsing packets per frame.

The 0x3b event can occur more than once in a frame. This diagnostic keeps the
ordinal and item type for every event, reports raw packet offsets, and only
calls a float lane a one-ULP difference when its encoded 32-bit words differ
by exactly one. It does not assign game-object semantics to packet offset
0x18.
"""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct


ITEM_COMMAND = 0x3B
FLOAT_OFFSETS = (0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C)
ITEM_PACKET_LENGTH = 45


def load_finalized(path):
    comparator = runpy.run_path(str(Path(__file__).with_name("analyze-slippi-local-game.py")))
    return comparator["read_rollback_trace"](path)


def items_by_frame(frames):
    return {
        frame: [packet for packet in packets if packet[0] == ITEM_COMMAND]
        for frame, packets in frames.items()
    }


def encoded_float(packet, offset):
    return struct.unpack_from(">I", packet, offset)[0]


def is_one_encoded_ulp(left_word, right_word):
    return (left_word ^ right_word) & 0x80000000 == 0 and abs(left_word - right_word) == 1


def first_difference(left, right):
    for offset, (a, b) in enumerate(zip(left, right)):
        if a != b:
            return offset, a, b
    if len(left) != len(right):
        return min(len(left), len(right)), None, None
    return None


def compare(left_csv, right_csv, left_label="native", right_label="reference"):
    left_frames, left_meta = load_finalized(left_csv)
    right_frames, right_meta = load_finalized(right_csv)
    common = sorted(set(left_frames) & set(right_frames))
    if not common:
        raise ValueError("no common finalized frames")

    left_items = items_by_frame(left_frames)
    right_items = items_by_frame(right_frames)
    count_mismatches = []
    payload_mismatches = []
    byte_counts = {}
    float_lane_counts = {}
    one_ulp = []
    compared_packets = 0

    for frame in common:
        a_items = left_items.get(frame, [])
        b_items = right_items.get(frame, [])
        compared_packets += min(len(a_items), len(b_items))
        if len(a_items) != len(b_items):
            count_mismatches.append({
                "frame": frame,
                left_label: len(a_items),
                right_label: len(b_items),
                "reason": "item_packet_count",
            })
        for ordinal, (left_packet, right_packet) in enumerate(zip(a_items, b_items)):
            if left_packet == right_packet:
                continue
            first = first_difference(left_packet, right_packet)
            item_types = {
                left_label: f"0x{left_packet[5]:02x}{left_packet[6]:02x}",
                right_label: f"0x{right_packet[5]:02x}{right_packet[6]:02x}",
            }
            mismatch = {
                "frame": frame,
                "ordinal": ordinal,
                **item_types,
                "reason": "item_packet_payload",
                "first_differing_offset": f"0x{first[0]:02x}",
            }
            payload_mismatches.append(mismatch)
            for offset, (a, b) in enumerate(zip(left_packet, right_packet)):
                if a != b:
                    key = f"0x{ITEM_COMMAND:02x}:0x{offset:02x}"
                    byte_counts[key] = byte_counts.get(key, 0) + 1
            for offset in FLOAT_OFFSETS:
                a_word = encoded_float(left_packet, offset)
                b_word = encoded_float(right_packet, offset)
                if a_word == b_word:
                    continue
                key = f"0x{offset:02x}"
                float_lane_counts[key] = float_lane_counts.get(key, 0) + 1
                if is_one_encoded_ulp(a_word, b_word):
                    one_ulp.append({
                        "frame": frame,
                        "ordinal": ordinal,
                        "item_type": item_types[left_label],
                        "packet_offset": key,
                        f"{left_label}_bits": f"{a_word:08x}",
                        f"{right_label}_bits": f"{b_word:08x}",
                    })

    result = {
        "scope": "Common finalized frames; complete emitted 0x3b item packets, preserving per-frame multiplicity and order",
        "clients": {
            left_label: {"trace_sha256": hashlib.sha256(left_csv.read_bytes()).hexdigest(), **left_meta},
            right_label: {"trace_sha256": hashlib.sha256(right_csv.read_bytes()).hexdigest(), **right_meta},
        },
        "first_frame": common[0],
        "last_frame": common[-1],
        "frames": len(common),
        "item_packets": {
            left_label: sum(len(left_items.get(frame, [])) for frame in common),
            right_label: sum(len(right_items.get(frame, [])) for frame in common),
            "compared_pairs": compared_packets,
        },
        "item_packet_count_mismatches": count_mismatches,
        "item_packet_payload_mismatches": len(payload_mismatches),
        "first_item_packet_count_mismatch": count_mismatches[0] if count_mismatches else None,
        "first_item_packet_payload_mismatch": payload_mismatches[0] if payload_mismatches else None,
        "raw_byte_mismatch_counts": byte_counts,
        "float_lane_mismatch_counts": float_lane_counts,
        "one_ulp_float_differences": one_ulp[:32],
        "one_ulp_float_difference_count": len(one_ulp),
        "pass": not count_mismatches and not payload_mismatches,
    }
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--left-label", default="native")
    parser.add_argument("--right-label", default="reference")
    args = parser.parse_args()
    result = compare(
        args.run / "user-0/online-frame-packets.csv",
        args.run / "user-1/online-frame-packets.csv",
        args.left_label,
        args.right_label,
    )
    result["analyzer_sha256"] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
