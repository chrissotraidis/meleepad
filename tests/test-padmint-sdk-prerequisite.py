#!/usr/bin/env python3
"""Keep the portable iPhone prerequisites separate from the full Mac app build."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SDKPrerequisiteTests(unittest.TestCase):
    def setUp(self):
        self.recipe = json.loads((ROOT / 'padmint.json').read_text())

    def test_mac_ios_route_is_the_released_one(self):
        # Macs keep the device-tested route; only Windows uses the portable module.
        ios = self.recipe['targets']['ios']
        mac = [step for step in ios['steps'] if step.get('on') == ['macos']]
        self.assertEqual([step['stage'] for step in mac],
                         ['dependencies', 'prepare', 'slippi', 'translate', 'package'])
        players = {tool['name'] for tool in self.recipe['requirements']['tools']
                   if tool.get('player') and tool.get('hosts') == ['macos-arm64']}
        self.assertTrue({'xcodebuild', 'xcrun', 'rustup'} <= players)

    def test_mac_requirements_stay_on_the_mac(self):
        for tool in self.recipe['requirements']['tools']:
            if not tool['name'].endswith('/vswhere.exe'):
                self.assertEqual(tool.get('hosts'), ['macos-arm64'], tool['name'])

    def test_host_support_requires_an_explicit_route(self):
        self.assertEqual(set(self.recipe['targets']), {'ios', 'macos'})
        self.assertEqual(self.recipe['targets']['ios']['hosts'],
                         {'macos-arm64': 'experimental', 'windows-arm64': 'experimental', 'windows-x86_64': 'experimental'})
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

    def test_x64_prerequisite_requires_the_x64_compiler(self):
        compiler, = [tool for tool in self.recipe['requirements']['tools']
                     if tool.get('player') and tool.get('hosts') == ['windows-x86_64']]
        self.assertNotIn('-requiresAny', compiler['version_args'])
        self.assertNotIn('Microsoft.VisualStudio.Component.VC.Tools.ARM64', compiler['version_args'])
        self.assertIn('Microsoft.VisualStudio.Component.VC.Tools.x86.x64', compiler['version_args'])
        self.assertEqual(compiler['targets'], ['ios'])

    def test_recipe_requires_safe_revision_aware_packaging(self):
        self.assertEqual(self.recipe['schema_version'], 2)
        ios = self.recipe['targets']['ios']
        self.assertEqual(ios['ios_module'], {'result': '{work}/module-result.json', 'on': ['windows']})
        self.assertEqual(ios['published_app'], 'MeleePad-v{version}-ios-unsigned.ipa')
        self.assertEqual(ios['tools'], ['git', 'cmake', 'ninja', 'llvm', 'libcxx'])
        windows = [step for step in ios['steps'] if step.get('on') == ['windows']]
        self.assertEqual(len(windows), 1)
        self.assertEqual(windows[0]['command'][0], '{python}')
        self.assertIn('{ios_toolchain}', windows[0]['command'])

    def test_personal_ipa_uses_generic_package_validation(self):
        self.assertEqual(self.recipe['targets']['ios']['check'], 'ipa')


    def test_every_host_name_is_one_padmint_knows(self):
        # PadMint's host names (padmint/manifest.py HOSTS). An unknown target host makes PadMint
        # reject the whole recipe; an unknown tool host silently skips that check on real PCs.
        known = {'macos-arm64', 'macos-x86_64', 'linux-x86_64', 'linux-arm64', 'windows-x86_64', 'windows-arm64'}
        for name, target in self.recipe['targets'].items():
            self.assertLessEqual(set(target['hosts']), known, name)
        for tool in self.recipe['requirements']['tools']:
            self.assertLessEqual(set(tool.get('hosts', [])), known, tool['name'])


if __name__ == '__main__':
    unittest.main()
