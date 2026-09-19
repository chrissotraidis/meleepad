#!/usr/bin/env python3
"""Test source identity enforcement with actual temporary Git repositories."""
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest

VERIFY = runpy.run_path(str(Path(__file__).resolve().parents[1] /
                           'scripts/build-slippi-rust.py'))['verify_source']


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
