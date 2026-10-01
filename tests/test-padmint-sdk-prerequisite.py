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
        self.assertEqual(len(players), 1)
        sdk = players[0]
        self.assertEqual(sdk['name'], 'xcrun')
        self.assertEqual(sdk['label'], 'Xcode iOS SDK')
        self.assertEqual(sdk['version_args'], ['--sdk', 'iphoneos', '--show-sdk-path'])
        self.assertIs(sdk['player'], True)
        for instruction in ('full Xcode', 'iOS platform', "Xcode's command-line tools",
                            'Xcode Settings > Locations', 'run PadMint again'):
            self.assertIn(instruction, sdk['note'])

    def test_rust_requirement_remains_unchanged(self):
        rust = next(tool for tool in self.recipe['requirements']['tools'] if tool['name'] == 'rustup')
        self.assertEqual(rust, {
            'name': 'rustup',
            'version_args': ['--version'],
            'note': "Rust 1.88.0 with the aarch64-apple-ios target builds MeleePad's Slippi pieces",
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


if __name__ == '__main__':
    unittest.main()
