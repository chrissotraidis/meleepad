#!/usr/bin/env python3
"""Keep the portable iPhone prerequisites separate from the full Mac app build."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SDKPrerequisiteTests(unittest.TestCase):
    def setUp(self):
        self.recipe = json.loads((ROOT / 'padmint.json').read_text())

    def test_player_sdk_probe(self):
        players = [tool for tool in self.recipe['requirements']['tools']
                   if tool.get('player') and 'ios' in tool.get('targets', ['ios'])
                   and 'macos-arm64' in tool.get('hosts', ['macos-arm64'])]
        sdk, = players
        self.assertEqual(sdk['name'], 'xcrun')
        self.assertEqual(sdk['version_args'], ['--sdk', 'macosx', '--show-sdk-path'])
        self.assertEqual(sdk['hosts'], ['macos-arm64'])
        self.assertIn('xcode-select --install', sdk['note'])

    def test_player_rust_probe_selects_the_backend_toolchain(self):
        rust = next(tool for tool in self.recipe['requirements']['tools'] if tool['name'] == 'rustup')
        self.assertEqual(rust, {
            'name': 'rustup',
            'label': 'Rust 1.88.0',
            'version_args': ['run', '1.88.0', 'rustc', '--version'],
            'player': True,
            'targets': ['macos'],
            'note': 'Install Rustup, then run: rustup toolchain install 1.88.0 --target aarch64-apple-ios',
        })

    def test_host_support_requires_an_explicit_route(self):
        self.assertEqual(set(self.recipe['targets']), {'ios', 'macos'})
        self.assertEqual(self.recipe['targets']['ios']['hosts'],
                         {'macos-arm64': 'experimental', 'windows-arm64': 'experimental'})
        mac = self.recipe['targets']['macos']
        self.assertEqual(mac['hosts'], {'macos-arm64': 'experimental'})
        self.assertEqual((mac['output'], mac['check']), ('zip', 'none'))
        self.assertEqual([step['stage'] for step in mac['steps']],
                         ['dependencies', 'prepare', 'slippi', 'compile', 'version', 'sign', 'package'])
        self.assertEqual(mac['steps'][-1]['command'][-2:], ['{repo}/build-macos/MeleePad.app', '{output}'])

    def test_windows_prerequisite_accepts_native_or_x64_cpp_tools(self):
        windows = [tool for tool in self.recipe['requirements']['tools']
                   if tool.get('player') and 'ios' in tool.get('targets', ['ios'])
                   and 'windows-arm64' in tool.get('hosts', ['windows-arm64'])]
        compiler, = windows
        self.assertTrue(compiler['name'].endswith('/vswhere.exe'))
        self.assertEqual(compiler['min_version'], '17')
        self.assertIn('-requiresAny', compiler['version_args'])
        self.assertIn('Microsoft.VisualStudio.Component.VC.Tools.ARM64', compiler['version_args'])
        self.assertIn('Microsoft.VisualStudio.Component.VC.Tools.x86.x64', compiler['version_args'])

    def test_recipe_requires_safe_revision_aware_packaging(self):
        self.assertEqual(self.recipe['schema_version'], 2)
        ios = self.recipe['targets']['ios']
        self.assertEqual(ios['ios_module'], {'result': '{work}/module-result.json'})
        self.assertEqual(ios['published_app'], 'MeleePad-v{version}-ios-unsigned.ipa')
        self.assertEqual(ios['tools'], ['git', 'cmake', 'ninja', 'llvm', 'libcxx'])
        self.assertEqual(len(ios['steps']), 1)
        self.assertEqual(ios['steps'][0]['command'][0], '{python}')
        self.assertIn('{ios_toolchain}', ios['steps'][0]['command'])

    def test_personal_ipa_uses_generic_package_validation(self):
        self.assertEqual(self.recipe['targets']['ios']['check'], 'ipa')


if __name__ == '__main__':
    unittest.main()
