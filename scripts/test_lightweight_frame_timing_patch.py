#!/usr/bin/env python3
"""Compile and exercise the recorder implementation retained in patch 0023."""

from __future__ import annotations

import pathlib
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[1]
PATCH = ROOT / "patches/moderngekko-dolphin/0023-lightweight-frame-timing.patch"
IDENTITY_PATCH = ROOT / "patches/moderngekko-dolphin/0024-lightweight-frame-identity.patch"
INDEX_ACTIVATION_PATCH = (
    ROOT / "patches/moderngekko-dolphin/0025-lightweight-frame-index-activation.patch"
)


def added_file(patch_text: str, path: str) -> str:
    marker = f"diff --git a/{path} b/{path}\n"
    section = patch_text.split(marker, 1)[1].split("\ndiff --git ", 1)[0]
    lines: list[str] = []
    in_hunk = False
    for line in section.splitlines():
        if line.startswith("@@"):
            in_hunk = True
        elif in_hunk and line.startswith("+") and not line.startswith("+++"):
            lines.append(line[1:])
    return "\n".join(lines) + "\n"


def main() -> None:
    patch_text = PATCH.read_text()
    identity_patch_text = IDENTITY_PATCH.read_text()
    index_activation_patch_text = INDEX_ACTIVATION_PATCH.read_text()
    required_activation_fragments = (
        'std::getenv("MELEEPAD_LIGHTWEIGHT_FRAME_LOG")',
        "inline bool IsEmulatedFrameIndexEnabled()",
        "if (Common::FramePhaseTiming::IsEmulatedFrameIndexEnabled())",
    )
    for fragment in required_activation_fragments:
        if fragment not in index_activation_patch_text:
            raise RuntimeError(f"identity activation patch is missing: {fragment}")
    header_path = "Source/Core/VideoCommon/LightweightFrameTimingRecorder.h"
    source_path = "Source/Core/VideoCommon/LightweightFrameTimingRecorder.cpp"

    with tempfile.TemporaryDirectory(prefix="meleepad-light-timing-") as temporary:
        root = pathlib.Path(temporary)
        include_dir = root / "Source/Core/VideoCommon"
        include_dir.mkdir(parents=True)
        (root / header_path).write_text(added_file(patch_text, header_path))
        (root / source_path).write_text(added_file(patch_text, source_path))
        identity_sections = []
        for path in (header_path, source_path):
            marker = f"diff --git a/{path} b/{path}\n"
            section = identity_patch_text.split(marker, 1)[1].split("\ndiff --git ", 1)[0]
            identity_sections.append(marker + section)
        filtered_patch = root / "identity.patch"
        filtered_patch.write_text("\n".join(identity_sections) + "\n")
        subprocess.run(["git", "apply", str(filtered_patch)], cwd=root, check=True)
        harness = root / "recorder_test.cpp"
        harness.write_text(
            r'''
#include "VideoCommon/LightweightFrameTimingRecorder.h"

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <optional>
#include <string>

namespace
{
unsigned int s_clock_calls = 0;

std::uint64_t FakeThreadClock()
{
  ++s_clock_calls;
  return static_cast<std::uint64_t>(s_clock_calls) * 1'000'000;
}
}

int main(int argc, char** argv)
{
  if (argc != 2)
    return 10;
  const std::filesystem::path output = argv[1];
  std::filesystem::remove(output);

  const auto t0 = std::chrono::steady_clock::time_point{std::chrono::seconds{10}};
  {
    LightweightFrameTimingRecorder disabled(std::nullopt, FakeThreadClock);
    disabled.Record(t0, 7);
    disabled.Record(t0 + std::chrono::milliseconds{20}, 8);
  }
  if (s_clock_calls != 0 || std::filesystem::exists(output))
    return 11;

  {
    LightweightFrameTimingRecorder enabled(output.string(), FakeThreadClock);
    enabled.Record(t0, 41);
    enabled.Record(t0 + std::chrono::milliseconds{20}, 42);
    if (std::filesystem::exists(output))
      return 12;
  }
  if (s_clock_calls != 2 || !std::filesystem::exists(output))
    return 13;

  std::ifstream stream(output);
  const std::string text{std::istreambuf_iterator<char>{stream}, {}};
  if (text.find("index,emulated_frame,host_frame_end_unix_ns,total_ms,thread_cpu_ms,wall_minus_thread_ms\n") != 0)
    return 14;
  if (text.find("1,42,") == std::string::npos || text.find(",20.000000,1.000000,19.000000\n") == std::string::npos)
    return 15;
  return 0;
}
'''
        )
        binary = root / "recorder_test"
        subprocess.run(
            [
                "clang++",
                "-std=c++20",
                "-Wall",
                "-Wextra",
                "-Werror",
                "-I",
                str(root / "Source/Core"),
                str(root / source_path),
                str(harness),
                "-o",
                str(binary),
            ],
            check=True,
        )
        subprocess.run([str(binary), str(root / "timing.csv")], check=True)

    print("Lightweight frame timing patch tests passed")


if __name__ == "__main__":
    main()
