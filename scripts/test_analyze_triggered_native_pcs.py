#!/usr/bin/env python3
"""CLI regression for analyze-triggered-native-pcs.py."""

from __future__ import annotations

import pathlib
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[1]
ANALYZER = ROOT / "scripts" / "analyze-triggered-native-pcs.py"


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="ssbmpad-native-pc-analysis-test-") as temporary:
        work = pathlib.Path(temporary)
        phase = work / "phase.csv"
        samples = work / "samples.csv"
        phase.write_text(
            "frame,emulated_frame,host_frame_end_unix_ns,total_ms,cpu_thread_ms,video_build_ms,present_ms\n"
            "1,500,1000000000,10.0,5.0,1.0,1.0\n"
            "2,501,1020000000,20.0,18.0,1.0,1.0\n"
            "3,502,1040000000,20.0,19.0,1.0\n",
            encoding="utf-8",
        )
        samples.write_text(
            "wall_ns,unix_ns,cpu_ns,state,sleep_seconds,native_pc,pc_read_ns,image_base,image_offset,image_path,return_pc_0,return_image_base_0,return_image_offset_0,return_image_path_0\n"
            "1,990000000,1,1,0,4097,10,4096,1,/tmp/body,0,0,0,\n"
            "2,995000000,2,3,0,4098,10,4096,2,/tmp/body,0,0,0,\n"
            "3,1000000000,3,1,0,8193,10,8192,1,/tmp/tail,12304,12288,16,/tmp/caller\n"
            "4,1010000000,4,1,0,8193,10,8192,1,/tmp/tail,12304,12288,16,/tmp/caller\n",
            encoding="utf-8",
        )
        result = subprocess.run(
            [
                "python3",
                str(ANALYZER),
                str(phase),
                str(samples),
                "--min-emulated-frame",
                "500",
                "--max-emulated-frame",
                "502",
                "--show-stacks",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    expected = (
        "joined_frames=2,body_frames=1,overrun_frames=1,body_samples=2,overrun_samples=2,"
        "excluded_incomplete_rows=1"
    )
    if expected not in result.stdout:
        raise AssertionError(result.stdout)
    if "FRAME,2,501,20.000000,18.000000,2,2,0" not in result.stdout:
        raise AssertionError(result.stdout)
    if "SYMBOL,0,2,0.000000,2.000000,2.000000,inf,/tmp/tail+0x1" not in result.stdout:
        raise AssertionError(result.stdout)
    if "STACK,2,/tmp/tail+0x1 <- /tmp/caller+0x10" not in result.stdout:
        raise AssertionError(result.stdout)
    print("Triggered native PC analysis tests passed")


if __name__ == "__main__":
    main()
