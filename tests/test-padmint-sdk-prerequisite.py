#!/usr/bin/env python3
"""Keep the player SDK prerequisite separate from existing developer requirements."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SDKPrerequisiteTests(unittest.TestCase):
    def setUp(self):
        self.recipe = json.loads((ROOT / 'padmint.json').read_text())

    def test_player_sdk_probe(self):
        players = [tool for tool in self.recipe['requirements']['tools'] if tool.get('player')]
        self.assertEqual([tool['name'] for tool in players], ['xcodebuild', 'xcrun', 'rustup'])
        xcode, sdk = players[:2]
        self.assertEqual(xcode['version_args'], ['-version'])
        self.assertIs(xcode['player'], True)
        self.assertEqual(xcode['note'], sdk['note'])
        self.assertEqual(sdk['name'], 'xcrun')
        self.assertEqual(sdk['label'], 'Xcode iOS SDK')
        self.assertEqual(sdk['version_args'], ['--sdk', 'iphoneos', '--show-sdk-path'])
        self.assertIs(sdk['player'], True)
        for instruction in ('full Xcode', 'iOS platform', "Xcode's command-line tools",
                            'Xcode Settings > Locations', 'run PadMint again'):
            self.assertIn(instruction, sdk['note'])

    def test_player_rust_probe_selects_the_backend_toolchain(self):
        rust = next(tool for tool in self.recipe['requirements']['tools'] if tool['name'] == 'rustup')
        self.assertEqual(rust, {
            'name': 'rustup',
            'label': 'Rust 1.88.0',
            'version_args': ['run', '1.88.0', 'rustc', '--version'],
            'player': True,
            'note': 'Install Rustup, then run: rustup toolchain install 1.88.0 --target aarch64-apple-ios',
        })

    def test_host_support_remains_unchanged(self):
        self.assertEqual(set(self.recipe['targets']), {'ios', 'macos'})
        self.assertEqual(self.recipe['targets']['ios']['hosts'], {'macos-arm64': 'experimental'})
        self.assertEqual(self.recipe['targets']['macos'], {'hosts': {'macos-arm64': 'planned'}})

    def test_backend_steps_remain_unchanged(self):
        self.assertEqual(self.recipe['targets']['ios']['steps'], [
            {'stage': 'dependencies', 'command': ['{repo}/scripts/bootstrap-dependencies.sh']},
            {'stage': 'prepare', 'command': ['{repo}/scripts/prepare-game.sh', '{disc}']},
            {'stage': 'slippi', 'command': ['python3', '{repo}/scripts/build-slippi-dependencies.py']},
            {'stage': 'translate', 'command': ['{repo}/scripts/ios-build-core-device.sh']},
            {'stage': 'package', 'command': ['{repo}/scripts/package-ios.sh', '{app}', '{output}']},
        ])

    def test_personal_ipa_uses_generic_package_validation(self):
        self.assertEqual(self.recipe['targets']['ios']['check'], 'ipa')


if __name__ == '__main__':
    unittest.main()
