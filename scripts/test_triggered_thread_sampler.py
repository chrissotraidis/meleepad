#!/usr/bin/env python3
"""End-to-end schema tests for g5_triggered_thread_sampler.cpp."""

from __future__ import annotations

import pathlib
import subprocess
import tempfile
import textwrap


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
) -> None:
    phase_path = work / f"{name}-phase.csv"
    output_path = work / f"{name}-samples.csv"
    phase_path.write_text(phase_text, encoding="utf-8")
    process = subprocess.Popen([str(target)])
    try:
        result = subprocess.run(
            [
                str(sampler),
                str(process.pid),
                "sampler-target",
                str(phase_path),
                "400",
                "600",
                "16.7",
                "1000",
                "1",
                str(output_path),
            ],
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
    with tempfile.TemporaryDirectory(prefix="ssbmpad-triggered-sampler-test-") as temporary:
        work = pathlib.Path(temporary)
        sampler = work / "sampler"
        target_source = work / "target.cpp"
        target = work / "target"
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

    print("Triggered thread sampler tests passed")


if __name__ == "__main__":
    main()
