#!/usr/bin/env python3
"""Exercise macOS module staging with synthetic, non-game inputs."""
import hashlib
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "stage_macos_modules", ROOT / "scripts/stage-macos-modules.py")
STAGER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(STAGER)


class MacOSModuleTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="meleepad module staging ")
        self.addCleanup(temporary.cleanup)
        self.repo = Path(temporary.name)
        self.template = self.repo / "ref/ModernGekko-Template"
        self.output = self.repo / "build-macos/MeleePad.app/Contents/MacOS"
        self.build_info = {}
        self.dependencies = {}
        self.probe = patch.object(STAGER.subprocess, "check_output", self.inspect_binary)
        self.probe.start()
        self.addCleanup(self.probe.stop)

    def module(self, revision, pointer_kind="absolute"):
        directory = self.template / "build" / (
            "modules-macos14" if revision == 0 else "modules-macos14-r2") / "GALE01"
        directory.mkdir(parents=True)
        source = directory / "compiled module/gGALE01_recomp.dylib"
        source.parent.mkdir()
        source.write_bytes(f"synthetic module {revision}".encode())
        dol = self.template / f"extracted/Super-Smash-Bros-Melee-GALE01-r{revision}/sys/main.dol"
        dol.parent.mkdir(parents=True)
        dol.write_bytes(f"synthetic executable {revision}".encode())
        digest = hashlib.sha256(dol.read_bytes()).hexdigest()
        (source.parent / "manifest.txt").write_text(f"dol_sha256={digest}\n")
        pointer = source if pointer_kind == "absolute" else source.relative_to(
            self.template if pointer_kind == "template" else self.repo)
        (directory / "active-module.txt").write_text(str(pointer) + "\n")
        self.build_info[source] = "platform MACOS\n    minos 14.0\n      sdk 15.0\n"
        self.dependencies[source] = "/usr/lib/libSystem.B.dylib (compatibility version 1.0.0)"
        return source, digest

    def inspect_binary(self, command, **kwargs):
        source = Path(command[-1])
        if "-show-build" in command:
            result = f"{source}:\nLoad command 0\n      cmd LC_BUILD_VERSION\n    " + self.build_info[source]
        elif "-L" in command:
            result = f"{source}:\n\t{self.dependencies[source]}\n"
        else:
            raise AssertionError(f"Unexpected inspection command: {command}")
        return result if kwargs.get("text") or kwargs.get("encoding") or kwargs.get("universal_newlines") else result.encode()

    def stage(self):
        STAGER.stage_modules(self.template, self.output)

    def assert_staged(self, source, digest):
        staged = self.output / "StaticRecompModules" / digest / "gGALE01_recomp.dylib"
        self.assertEqual(staged.read_bytes(), source.read_bytes())

    def assert_rejected(self):
        with self.assertRaises((ValueError, OSError, subprocess.CalledProcessError)):
            self.stage()
        self.assertFalse(self.output.exists(), "Invalid input must not leave a partially staged app")

    def test_revision_102_only_is_staged_without_a_legacy_fallback(self):
        source, digest = self.module(2)
        self.stage()
        self.assert_staged(source, digest)
        self.assertFalse((self.output / source.name).exists())

    def test_revision_100_only_is_staged_and_used_as_fallback(self):
        source, digest = self.module(0)
        self.stage()
        self.assert_staged(source, digest)
        self.assertEqual((self.output / source.name).read_bytes(), source.read_bytes())

    def test_both_revisions_have_separate_digest_directories(self):
        first, first_digest = self.module(0)
        second, second_digest = self.module(2)
        self.stage()
        self.assert_staged(first, first_digest)
        self.assert_staged(second, second_digest)
        self.assertEqual((self.output / first.name).read_bytes(), first.read_bytes())
        self.assertEqual({path.name for path in (self.output / "StaticRecompModules").iterdir()},
                         {first_digest, second_digest})

    def test_relative_pointers_and_paths_with_spaces(self):
        first, first_digest = self.module(0, "template")
        second, second_digest = self.module(2, "repository")
        self.stage()
        self.assert_staged(first, first_digest)
        self.assert_staged(second, second_digest)

    def test_missing_module_is_rejected(self):
        self.assert_rejected()

    def test_missing_pointer_target_is_rejected(self):
        source, _ = self.module(2)
        source.unlink()
        self.assert_rejected()

    def test_empty_pointer_is_rejected(self):
        source, _ = self.module(2)
        (source.parent.parent / "active-module.txt").write_text(" \n")
        self.assert_rejected()

    def test_missing_manifest_is_rejected(self):
        source, _ = self.module(2)
        (source.parent / "manifest.txt").unlink()
        self.assert_rejected()

    def test_wrong_executable_digest_is_rejected_before_any_copy(self):
        self.module(0)
        source, _ = self.module(2)
        (source.parent / "manifest.txt").write_text("dol_sha256=" + "0" * 64 + "\n")
        self.assert_rejected()

    def test_missing_executable_is_rejected(self):
        self.module(2)
        (self.template / "extracted/Super-Smash-Bros-Melee-GALE01-r2/sys/main.dol").unlink()
        self.assert_rejected()

    def test_non_macos_binary_is_rejected(self):
        source, _ = self.module(2)
        self.build_info[source] = "platform IOS\n    minos 14.0\n      sdk 15.0\n"
        self.assert_rejected()

    def test_newer_deployment_target_is_rejected(self):
        source, _ = self.module(2)
        self.build_info[source] = "platform MACOS\n    minos 15.0\n      sdk 15.0\n"
        self.assert_rejected()

    def test_homebrew_dependency_is_rejected(self):
        source, _ = self.module(2)
        self.dependencies[source] = "/opt/homebrew/opt/zstd/lib/libzstd.1.dylib"
        self.assert_rejected()

    def test_local_dependency_is_rejected(self):
        source, _ = self.module(2)
        self.dependencies[source] = "/usr/local/lib/libzstd.1.dylib"
        self.assert_rejected()

    def test_inspection_failure_does_not_stage_any_module(self):
        self.module(0)
        self.module(2)
        with patch.object(STAGER.subprocess, "check_output",
                          side_effect=subprocess.CalledProcessError(1, "vtool")):
            self.assert_rejected()


if __name__ == "__main__":
    unittest.main()
