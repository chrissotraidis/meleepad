#!/usr/bin/env python3
"""Exercise missing and malformed prepared inputs without any game/account data."""
from pathlib import Path
import runpy
import tempfile
import unittest

API = runpy.run_path(str(Path(__file__).resolve().parents[1] /
                       'scripts/check-ios-slippi-build-inputs.py'))


class PreparedInputsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name) / 'repo'
        self.repo.mkdir()
        paths = [API['OVERLAY'] / name for name in API['OVERLAY_FILES']]
        paths += [API['SLIPPI_GAME_SETTINGS'],
                  Path('scripts/slippi-network-diagnostics.hpp'),
                  Path('scripts/slippi-native-diagnostics.hpp'),
                  Path('ref/ModernGekko/vendor/dolphin/SlippiAdapter/Source/Core/PowerPC/Interpreter_LoadStore.cpp'),
                  Path('MeleePad.xcodeproj/project.pbxproj')]
        for path in paths:
            self.write(path, '')
        for path, markers in API['OVERLAY_CONTRACTS'].items():
            self.write(API['OVERLAY'] / path, '\n'.join(markers))
        self.response = Path('apple/ios/Provisioned/iphoneos/libs/MeleePadSlippiCore.rsp')
        self.write(Path('ref/runtime.a'), 'fixture')
        self.write(self.response, 'ref/runtime.a\n')

    def write(self, path, text):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)
        return target

    def check(self, **kwargs):
        return API['check_inputs'](self.repo, **kwargs)

    def test_complete_inputs(self):
        self.assertTrue(self.check()['pass'])

    def test_first_provision_skips_only_response(self):
        (self.repo / self.response).unlink()
        self.assertTrue(self.check(sources_only=True)['pass'])
        self.assertFalse(self.check()['pass'])
        (self.repo / API['OVERLAY'] / API['OVERLAY_FILES'][0]).unlink()
        self.assertFalse(self.check(sources_only=True)['pass'])

    def test_empty_response_fails(self):
        self.write(self.response, '\n')
        self.assertFalse(self.check()['pass'])

    def test_missing_relative_archive_fails(self):
        self.write(self.response, 'ref/missing.a\n')
        self.assertIn('ref/missing.a', self.check()['missing'])

    def test_external_archive_is_checked(self):
        external = Path(self.temp.name) / 'outside.a'
        self.write(self.response, str(external))
        self.assertIn(str(external), self.check()['missing'])
        external.write_text('fixture')
        self.assertTrue(self.check()['pass'])

    def test_force_load_and_quoted_spaces(self):
        archive = self.write(Path('ref/space name.a'), 'fixture')
        self.write(self.response, '"-Wl,-force_load,' + str(archive) + '"\n')
        self.assertTrue(self.check()['pass'])
        archive.unlink()
        self.assertFalse(self.check()['pass'])

    def test_directory_is_not_archive(self):
        (self.repo / 'ref/wrong.a').mkdir()
        self.write(self.response, 'ref/wrong.a')
        self.assertFalse(self.check()['pass'])

    def test_unsupported_or_malformed_arguments_fail_closed(self):
        for text in ('@nested.rsp', '-lmissing', '-Wl,-force_load,', '"unclosed'):
            with self.subTest(text=text):
                self.write(self.response, text)
                self.assertFalse(self.check()['pass'])
                self.assertTrue(self.check()['response_errors'])

    def test_stale_overlay_still_fails(self):
        self.write(API['OVERLAY'] / next(iter(API['OVERLAY_CONTRACTS'])), '')
        self.assertFalse(self.check()['pass'])
        self.assertFalse(self.check(sources_only=True)['pass'])


if __name__ == '__main__':
    unittest.main()
