#!/usr/bin/env python3
"""End-to-end schema tests for g5_triggered_thread_sampler.cpp."""

from __future__ import annotations

import pathlib
import csv
import subprocess
import tempfile
import textwrap
import time


ROOT = pathlib.Path(__file__).resolve().parents[1]
SAMPLER_SOURCE = ROOT / "scripts" / "g5_triggered_thread_sampler.cpp"


def compile_binary(
    compiler: str, sdk_path: str, source: pathlib.Path, output: pathlib.Path
) -> None:
    subprocess.run(
        [
            compiler,
            "-isysroot",
            sdk_path,
            "-std=c++17",
            "-O2",
            str(source),
            "-o",
            str(output),
        ],
        check=True,
        capture_output=True,
        text=True,
    )


def run_case(
    sampler: pathlib.Path,
    target: pathlib.Path,
    work: pathlib.Path,
    name: str,
    phase_text: str,
    expected_returncode: int,
    native_pc: bool = False,
    thread_selector: str = "sampler-target",
    trigger_metric: str | None = None,
    require_image_path: bool = True,
    native_stack: bool = False,
) -> subprocess.CompletedProcess[str]:
    phase_path = work / f"{name}-phase.csv"
    output_path = work / f"{name}-samples.csv"
    phase_path.write_text(phase_text, encoding="utf-8")
    process = subprocess.Popen([str(target)])
    try:
        command = [
                str(sampler),
                str(process.pid),
                thread_selector,
                str(phase_path),
                "400",
                "600",
                "16.7",
                "1000",
                "1",
                str(output_path),
            ]
        if native_pc:
            command.append("native-stack" if native_stack else "native-pc")
        if trigger_metric:
            if not native_pc:
                raise AssertionError("custom trigger metric requires native-pc mode")
            command.append(trigger_metric)
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=8,
        )
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=5)
    if result.returncode != expected_returncode:
        raise AssertionError(
            f"{name}: expected {expected_returncode}, got {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    if native_pc and expected_returncode in {0, 3}:
        with output_path.open(newline="", encoding="utf-8") as source:
            rows = list(csv.DictReader(source))
        if not rows or not any(int(row["native_pc"]) != 0 for row in rows):
            raise AssertionError(f"{name}: native-pc mode did not retain a nonzero PC")
        resolved = [
            row
            for row in rows
            if int(row["native_pc"]) != 0 and int(row["image_base"]) != 0
        ]
        if require_image_path and (
            not resolved or not any(row["image_path"] for row in resolved)
        ):
            raise AssertionError(f"{name}: native PCs did not resolve to a Mach-O image")
        if not all(int(row["pc_read_ns"]) > 0 for row in resolved):
            raise AssertionError(f"{name}: native PC read latency was not retained")
        if native_stack and not any(int(row["return_pc_0"]) != 0 for row in rows):
            raise AssertionError(f"{name}: native-stack mode did not retain a link register")
    return result


def main() -> None:
    compiler = subprocess.run(
        ["xcrun", "--find", "clang++"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    sdk_path = subprocess.run(
        ["xcrun", "--sdk", "macosx", "--show-sdk-path"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    with tempfile.TemporaryDirectory(prefix="meleepad-triggered-sampler-test-") as temporary:
        work = pathlib.Path(temporary)
        sampler = work / "sampler"
        target_source = work / "target.cpp"
        target = work / "target"
        entitlements = work / "debug-entitlements.plist"
        target_source.write_text(
            textwrap.dedent(
                """\
                #include <pthread.h>
                #include <chrono>

                int main() {
                  pthread_setname_np("sampler-target");
                  const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(10);
                  volatile unsigned long value = 0;
                  while (std::chrono::steady_clock::now() < deadline)
                    ++value;
                  return value == 0;
                }
                """
            ),
            encoding="utf-8",
        )
        compile_binary(compiler, sdk_path, SAMPLER_SOURCE, sampler)
        compile_binary(compiler, sdk_path, target_source, target)
        entitlements.write_text(
            """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>com.apple.security.get-task-allow</key><true/>
</dict></plist>
""",
            encoding="utf-8",
        )
        subprocess.run(
            [
                "codesign",
                "--force",
                "--sign",
                "-",
                "--entitlements",
                str(entitlements),
                str(target),
            ],
            check=True,
            capture_output=True,
            text=True,
        )

        cases = (
            (
                "current-below-threshold",
                "frame,emulated_frame,host_frame_end_unix_ns,total_ms,cpu_wall_ms\n"
                "1,500,1788067000000000000,10.0,9.0\n",
                3,
            ),
            (
                "current-trigger",
                "frame,emulated_frame,host_frame_end_unix_ns,total_ms,cpu_wall_ms\n"
                "1,500,1788067000000000000,20.0,19.0\n",
                0,
            ),
            (
                "legacy-trigger",
                "frame,emulated_frame,total_ms,cpu_wall_ms\n1,500,20.0,19.0\n",
                0,
            ),
            (
                "reordered-trigger",
                "total_ms,frame,cpu_wall_ms,emulated_frame\n20.0,1,19.0,500\n",
                0,
            ),
            (
                "missing-total-ms",
                "frame,emulated_frame,cpu_wall_ms\n1,500,19.0\n",
                2,
            ),
        )
        for name, phase_text, expected_returncode in cases:
            run_case(sampler, target, work, name, phase_text, expected_returncode)
        native_result = run_case(
            sampler,
            target,
            work,
            "current-native-pc-trigger",
            "frame,emulated_frame,host_frame_end_unix_ns,total_ms,cpu_wall_ms\n"
            f"1,500,{time.time_ns()},20.0,19.0\n",
            0,
            native_pc=True,
        )
        run_case(
            sampler,
            target,
            work,
            "current-native-stack-trigger",
            "frame,emulated_frame,host_frame_end_unix_ns,total_ms,cpu_wall_ms\n"
            f"1,500,{time.time_ns()},20.0,19.0\n",
            0,
            native_pc=True,
            native_stack=True,
        )
        run_case(
            sampler,
            target,
            work,
            "native-pc-missing-host-time",
            "frame,emulated_frame,total_ms,cpu_wall_ms\n1,500,20.0,19.0\n",
            2,
            native_pc=True,
        )
        run_case(
            sampler,
            target,
            work,
            "hottest-native-pc-trigger",
            "frame,emulated_frame,host_frame_end_unix_ns,total_ms,cpu_wall_ms\n"
            f"1,500,{time.time_ns()},20.0,19.0\n",
            0,
            native_pc=True,
            thread_selector="@hottest",
            require_image_path=False,
        )
        run_case(
            sampler,
            target,
            work,
            "cpu-thread-metric-trigger",
            "frame,emulated_frame,host_frame_end_unix_ns,total_ms,cpu_thread_ms\n"
            f"1,500,{time.time_ns()},10.0,20.0\n",
            0,
            native_pc=True,
            trigger_metric="cpu_thread_ms",
        )
        run_case(
            sampler,
            target,
            work,
            "native-no-trigger-retains-ring",
            "frame,emulated_frame,host_frame_end_unix_ns,total_ms,cpu_thread_ms\n"
            f"1,500,{time.time_ns()},10.0,10.0\n",
            3,
            native_pc=True,
            trigger_metric="cpu_thread_ms",
        )
        run_case(
            sampler,
            target,
            work,
            "missing-custom-metric",
            "frame,emulated_frame,host_frame_end_unix_ns,total_ms\n"
            f"1,500,{time.time_ns()},20.0\n",
            2,
            native_pc=True,
            trigger_metric="cpu_thread_ms",
        )

    native_summary = native_result.stdout.strip().splitlines()[-1]
    print(f"Native PC preflight: {native_summary}")
    print("Triggered thread sampler tests passed")


if __name__ == "__main__":
    main()
