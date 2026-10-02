#!/usr/bin/env python3
"""Test source identity and ROM-free Rust provenance, including Python 3.9."""
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

BUILDER = runpy.run_path(str(Path(__file__).resolve().parents[1] /
                            'scripts/build-slippi-rust.py'))
VERIFY = BUILDER['verify_source']
DIGEST = BUILDER['digest']
MAIN = BUILDER['main']


class DigestTests(unittest.TestCase):
    def test_empty_small_and_multichunk_hashes_preserve_input(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'fixture.txt'
            for data in (b'', b'provenance fixture\n', b'x' * (1024 * 1024 + 17)):
                with self.subTest(length=len(data)):
                    path.write_bytes(data)
                    self.assertEqual(DIGEST(path), hashlib.sha256(data).hexdigest())
                    self.assertEqual(path.read_bytes(), data)

    def test_missing_file_still_fails(self):
        with tempfile.TemporaryDirectory() as temporary:
            with self.assertRaises(FileNotFoundError):
                DIGEST(Path(temporary) / 'absent.txt')

    def test_provenance_hashes_all_three_inputs_on_both_targets(self):
        # Toolchain and compilation are stubs; only arbitrary fixture bytes exist.
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            source = root / 'source'
            (source / 'ffi/includes').mkdir(parents=True)
            lock = b'synthetic lock fixture\n'
            header = b'synthetic header fixture\n'
            library = b'synthetic archive fixture\n'
            (source / 'Cargo.lock').write_bytes(lock)
            (source / 'ffi/includes/SlippiRustExtensions.h').write_bytes(header)
            for platform, target, sdk in (
                    ('device', 'aarch64-apple-ios', 'iphoneos'),
                    ('simulator', 'aarch64-apple-ios-sim', 'iphonesimulator')):
                with self.subTest(platform=platform):
                    build = root / platform
                    def output(command, cwd=None):
                        if command[:2] == ['rustup', 'which']:
                            self.assertEqual(command[2:4], ['--toolchain', BUILDER['TOOLCHAIN']])
                            return '/fixture/bin/' + command[-1]
                        if command[:2] == ['xcrun', '--sdk']:
                            self.assertEqual(command[2], sdk)
                            return '/fixture/sdk' if command[-1] == '--show-sdk-path' else 'fixture-sdk-version'
                        return 'fixture-tool-version'
                    def compile_fixture(command, cwd, env, stdout, stderr, check):
                        self.assertEqual(command, ['/fixture/bin/cargo', 'build', '--locked',
                                                   '--release', '--target', target])
                        self.assertEqual(cwd, source)
                        self.assertEqual(env['CARGO_TARGET_DIR'], str(build))
                        self.assertEqual(env['IPHONEOS_DEPLOYMENT_TARGET'], '16.0')
                        self.assertEqual(env['SDKROOT'], '/fixture/sdk')
                        for name in ('CARGO_ENCODED_RUSTFLAGS', 'RUSTC_WRAPPER', 'RUSTC_WORKSPACE_WRAPPER'):
                            self.assertNotIn(name, env)
                        self.assertIs(check, True)
                        archive = build / target / 'release/libslippi_rust_extensions.a'
                        archive.parent.mkdir(parents=True)
                        archive.write_bytes(library)
                    verify = mock.Mock()
                    args = ['builder', '--source', str(source), '--output', str(build),
                            '--platform', platform]
                    with mock.patch.dict(MAIN.__globals__, {'verify_source': verify, 'output': output}), \
                            mock.patch.object(sys, 'argv', args), \
                            mock.patch('subprocess.run', side_effect=compile_fixture), \
                            mock.patch('builtins.print'), \
                            mock.patch.dict('os.environ', {name: 'fixture' for name in (
                                'CARGO_ENCODED_RUSTFLAGS', 'RUSTC_WRAPPER', 'RUSTC_WORKSPACE_WRAPPER')}):
                        MAIN()
                    self.assertEqual(verify.call_args_list, [mock.call(source), mock.call(source)])
                    record = json.loads((build / 'provenance.json').read_text())
                    self.assertEqual(record['source_commit'], BUILDER['REVISION'])
                    self.assertEqual(record['source_url'], BUILDER['SOURCE_URL'])
                    self.assertEqual(record['target'], target)
                    self.assertEqual(record['deployment_target'], '16.0')
                    self.assertEqual(record['cargo_lock_sha256'], hashlib.sha256(lock).hexdigest())
                    self.assertEqual(record['archive_sha256'], hashlib.sha256(library).hexdigest())
                    self.assertEqual(record['ffi_header_sha256'], hashlib.sha256(header).hexdigest())


class SourceIdentityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name).resolve()
        self.git('init', '-q')
        self.git('config', 'user.name', 'Source fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.repo / 'source.rs').write_text('fixture\n')
        self.git('add', 'source.rs')
        self.git('-c', 'commit.gpgsign=false', 'commit', '-qm', 'Fixture')
        previous = VERIFY.__globals__['REVISION']
        VERIFY.__globals__['REVISION'] = self.git('rev-parse', 'HEAD')
        self.addCleanup(VERIFY.__globals__.__setitem__, 'REVISION', previous)

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.repo, text=True).strip()

    def test_clean_exact_checkout(self):
        VERIFY(self.repo)

    def test_wrong_revision(self):
        self.git('-c', 'commit.gpgsign=false', 'commit', '--allow-empty', '-qm', 'Different')
        with self.assertRaisesRegex(ValueError, 'pinned'):
            VERIFY(self.repo)

    def test_modified_source(self):
        (self.repo / 'source.rs').write_text('different\n')
        with self.assertRaisesRegex(ValueError, 'local changes'):
            VERIFY(self.repo)

    def test_untracked_source(self):
        (self.repo / 'unexpected.rs').write_text('untracked\n')
        with self.assertRaisesRegex(ValueError, 'local changes'):
            VERIFY(self.repo)

    def test_parent_repository_is_not_source_identity(self):
        copied = self.repo / 'copied-source'
        copied.mkdir()
        with self.assertRaisesRegex(ValueError, 'own Git checkout'):
            VERIFY(copied)


if __name__ == '__main__':
    unittest.main()
