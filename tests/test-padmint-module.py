#!/usr/bin/env python3
"""Portable module preparation tests; all game bytes here are synthetic."""
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path
import struct
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('padmint_module', ROOT / 'scripts/build-padmint-module.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ModulePreparationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.work = Path(self.temporary.name) / 'private work with spaces 雪'
        self.work.mkdir()
        self.identity = {'revision': 2, 'format': 'iso', 'image_sha256': 'a' * 64,
                         'dol_sha256': 'b' * 64}

    def test_result_selects_revision_name_and_checksums_identity_companion(self):
        binary = self.work / 'module/gGALE01_recomp.dylib'
        binary.parent.mkdir()
        binary.write_bytes(b'synthetic compiled module')
        for revision, name in ((0, 'gGALE01_recomp.dylib'), (2, 'gGALE01r2_recomp.dylib')):
            with self.subTest(revision=revision):
                result = module.write_result(self.work, binary, {**self.identity, 'revision': revision})
                self.assertEqual(result, json.loads((self.work / 'module-result.json').read_text()))
                self.assertEqual((result['file'], result['into']), ('module/gGALE01_recomp.dylib', name))
                self.assertEqual(result['sha256'], module.sha256(binary))
                companion, = result['companions']
                self.assertEqual(companion['into'], name + '.dol-sha256')
                self.assertNotIn('\\', companion['file'])
                sidecar = self.work / companion['file']
                self.assertEqual(sidecar.read_bytes(), (self.identity['dol_sha256'] + '\n').encode('ascii'))
                self.assertEqual(companion['sha256'], module.sha256(sidecar))
        with self.assertRaisesRegex(ValueError, 'reviewed'):
            module.write_result(self.work, binary, {**self.identity, 'revision': 1})

    def test_cached_extraction_requires_source_dol_and_complete_files(self):
        game = self.work / 'extracted-r2'
        (game / 'sys').mkdir(parents=True)
        (game / 'files').mkdir()
        dol = game / 'sys/main.dol'
        dol.write_bytes(b'synthetic DOL')
        (game / 'sys/boot.bin').write_bytes(b'synthetic boot')
        identity = {**self.identity, 'dol_sha256': module.sha256(dol)}
        marker = game / '.meleepad-source-sha256'
        marker.write_text(identity['image_sha256'])
        for index in range(1209):
            (game / 'files' / str(index)).touch()
        module.check_extraction(game, identity)
        (game / 'files/1208').unlink()
        with self.assertRaisesRegex(ValueError, 'incomplete'):
            module.check_extraction(game, identity)
        dol.write_bytes(b'changed DOL')
        with self.assertRaisesRegex(ValueError, 'DOL'):
            module.check_extraction(game, identity)
        marker.write_text('different image')
        with self.assertRaisesRegex(ValueError, 'Preserving extraction'):
            module.extract(self.work / 'disc.iso', identity, 'never-run', self.work, {})
        self.assertEqual(dol.read_bytes(), b'changed DOL')

    def test_failed_fresh_extraction_leaves_no_reusable_cache(self):
        def incomplete_extract(*args, **kwargs):
            args[-1].mkdir()
        with mock.patch.object(module, 'run', side_effect=incomplete_extract):
            with self.assertRaisesRegex(ValueError, 'DOL'):
                module.extract(self.work / 'disc.iso', self.identity, 'synthetic-extractor', self.work, {})
        self.assertFalse((self.work / 'extracted-r2').exists())
        self.assertEqual(list(self.work.iterdir()), [])

    def test_existing_normalized_image_cannot_change_revision(self):
        normalized = self.work / 'GALE01-r2.iso'
        normalized.write_bytes(b'preserve original contents')
        identity = {**self.identity, 'format': 'ciso'}
        with mock.patch.object(module.identify, 'identify', return_value={'dol_sha256': 'c' * 64}), \
                mock.patch.object(module, 'run') as run:
            with self.assertRaisesRegex(ValueError, 'another revision'):
                module.extract(self.work / 'disc.ciso', identity, 'never-run', self.work, {})
        run.assert_not_called()
        self.assertEqual(normalized.read_bytes(), b'preserve original contents')

    def test_ciso_interruption_closes_partial_output_before_removal(self):
        source = self.work / 'synthetic.ciso'
        header = bytearray(0x8000)
        header[:4] = b'CISO'
        struct.pack_into('<I', header, 4, 2097152)
        source.write_bytes(header)
        destination = self.work / 'normalized.iso'
        opened = []
        real_open, real_unlink = Path.open, Path.unlink
        class InterruptedOutput:
            def __init__(self, stream):
                self.stream = stream
            def __enter__(self):
                return self
            def __exit__(self, *args):
                self.stream.close()
            def write(self, data):
                self.stream.write(data[:8])
                raise KeyboardInterrupt()
        def open_path(path, *args, **kwargs):
            stream = real_open(path, *args, **kwargs)
            if path == destination:
                opened.append(stream)
                return InterruptedOutput(stream)
            return stream
        def unlink_path(path, *args, **kwargs):
            if path == destination:
                self.assertTrue(all(stream.closed for stream in opened))
            return real_unlink(path, *args, **kwargs)
        with mock.patch.object(Path, 'open', open_path), mock.patch.object(Path, 'unlink', unlink_path):
            with self.assertRaises(KeyboardInterrupt):
                module.identify.normalize_ciso(source, destination)
        self.assertFalse(destination.exists())
        self.assertEqual(source.read_bytes(), header)
        destination.write_bytes(b'preserve existing image')
        with self.assertRaises(FileExistsError):
            module.identify.normalize_ciso(source, destination)
        self.assertEqual(destination.read_bytes(), b'preserve existing image')

    def test_ciso_reuses_the_equivalent_verified_iso_extraction(self):
        image = self.work / 'GALE01-r2.iso'
        image.write_bytes(b'synthetic canonical ISO')
        game = self.work / 'extracted-r2'
        (game / 'sys').mkdir(parents=True)
        (game / 'files').mkdir()
        dol = game / 'sys/main.dol'
        dol.write_bytes(b'synthetic DOL')
        (game / 'sys/boot.bin').write_bytes(b'synthetic boot')
        for index in range(1209):
            (game / 'files' / str(index)).touch()
        normalized = {**self.identity, 'image_sha256': module.sha256(image),
                      'dol_sha256': module.sha256(dol)}
        (game / '.meleepad-source-sha256').write_text(normalized['image_sha256'])
        container = {**normalized, 'format': 'ciso', 'image_sha256': 'c' * 64}
        with mock.patch.object(module.identify, 'identify', return_value=normalized), \
                mock.patch.object(module, 'run') as run:
            self.assertEqual(module.extract(self.work / 'disc.ciso', container, 'never-run', self.work, {}), dol)
        run.assert_not_called()

    def test_generation_uses_wrapper_flags_and_separates_revision_chunks(self):
        dolphin = self.work / 'dependency'
        dolphin.mkdir()
        dol = self.work / 'main.dol'
        dol.write_bytes(b'synthetic revision zero')
        invocations = []
        environments = []
        def generated(*args, **kwargs):
            invocations.append(args)
            environments.append(kwargs['env'])
            target = args[-1] / 'generated'
            target.mkdir(parents=True, exist_ok=True)
        with mock.patch.object(module, 'run', side_effect=generated):
            first = module.generate(dol, dolphin, 'dolrecomp', self.work, 3,
                                    {'DOLRECOMP_C_CHUNK_INSTRUCTIONS': '128', 'PATH': 'kept'})
            self.assertEqual((first / 'main.dol').read_bytes(), dol.read_bytes())
            self.assertTrue((first / 'generated_smc.txt').is_file())
            dol.write_bytes(b'synthetic revision two')
            second = module.generate(dol, dolphin, 'dolrecomp', self.work, 3,
                                     {'dolrecomp_c_chunk_instructions': '4096', 'PATH': 'kept'})
        self.assertNotEqual(first, second)
        self.assertEqual((first / 'main.dol').read_bytes(), b'synthetic revision zero')
        self.assertEqual(invocations[0][1:6], ('-j3', '--backend=c', '--cpu', 'gekko', '--gamecube'))
        self.assertEqual(environments, [{'PATH': 'kept'}, {'PATH': 'kept'}])
        patches = dolphin / 'Data/Sys/GameSettings/GALE01.ini'
        patches.parent.mkdir(parents=True)
        patches.write_text('[OnFrame]\n')
        with mock.patch.object(module, 'run') as run:
            with self.assertRaisesRegex(ValueError, 'default DOL patches'):
                module.generate(dol, dolphin, 'never-run', self.work, 3, {})
        run.assert_not_called()

    def test_external_sources_are_verified_read_only_and_must_match_pins(self):
        source = self.work / 'prepared source'
        (source / 'config').mkdir(parents=True)
        lock = source / 'config/dependencies.lock.json'
        lock.write_bytes((ROOT / 'config/dependencies.lock.json').read_bytes())
        with mock.patch.object(module.dependencies, 'verify') as verify, mock.patch.object(module, 'run') as run:
            result = module.prepare_sources(source)
        verify.assert_called_once_with(source.resolve())
        run.assert_not_called()
        self.assertEqual(result, source.resolve() / 'ref/ModernGekko/vendor/dolphin')
        lock.write_text('{}')
        with mock.patch.object(module.dependencies, 'verify') as verify, mock.patch.object(module, 'run') as run:
            with self.assertRaisesRegex(ValueError, 'pins differ'):
                module.prepare_sources(source)
        verify.assert_not_called()
        run.assert_not_called()

    def test_local_modified_dependency_is_preserved_before_update(self):
        source = self.work / 'local checkout'
        (source / 'config').mkdir(parents=True)
        (source / 'config/dependencies.lock.json').write_text('{}')
        runtime = source / 'ref/ModernGekko'
        runtime.mkdir(parents=True)
        (runtime / '.git').write_text('synthetic gitdir')
        with mock.patch.object(module, 'ROOT', source.resolve()), \
                mock.patch.object(module.subprocess, 'check_output', return_value=b' M source.cpp'), \
                mock.patch.object(module, 'run') as run:
            with self.assertRaisesRegex(ValueError, 'Preserving modified dependency'):
                module.prepare_sources(source)
        run.assert_not_called()

    def test_windows_host_environment_uses_available_native_compiler_and_merges_path(self):
        programs = self.work / 'Program Files (x86)'
        installer = programs / 'Microsoft Visual Studio/Installer/vswhere.exe'
        installer.parent.mkdir(parents=True)
        installer.touch()
        installation = programs / 'Visual Studio Build Tools'
        compiler = installation / 'VC/Tools/MSVC/14.44/bin/Hostarm64/arm64/cl.exe'
        compiler.parent.mkdir(parents=True)
        compiler.touch()
        env = {'ProgramFiles(x86)': str(programs), 'PATH': 'original', 'SDKROOT': 'unwanted-sdk'}
        result = SimpleNamespace(stdout='Path=prepared path\nINCLUDE=compiler headers\n')
        with mock.patch.object(module, 'os', SimpleNamespace(name='nt', environ=env)), \
                mock.patch.object(module.platform, 'machine', return_value='ARM64'), \
                mock.patch.object(module.subprocess, 'check_output', return_value=str(installation)) as discover, \
                mock.patch.object(module.subprocess, 'run', return_value=result) as run, \
                mock.patch.object(module.shutil, 'which', return_value=str(compiler)):
            prepared = module.host_environment()
        self.assertIn('" arm64 >nul', run.call_args.args[0])
        self.assertIn(' /u ', run.call_args.args[0])
        self.assertEqual(run.call_args.kwargs['encoding'], 'utf-16le')
        self.assertIn('-utf8', discover.call_args.args[0])
        self.assertEqual(discover.call_args.kwargs['encoding'], 'utf-8')
        self.assertEqual(prepared['PATH'], 'prepared path')
        self.assertNotIn('Path', prepared)
        self.assertNotIn('SDKROOT', prepared)
        self.assertEqual(prepared['INCLUDE'], 'compiler headers')

    def test_x64_host_ignores_newer_arm_only_visual_studio_installation(self):
        programs = self.work / 'Program Files (x86)'
        installer = programs / 'Microsoft Visual Studio/Installer/vswhere.exe'
        installer.parent.mkdir(parents=True)
        installer.touch()
        x64, arm = programs / 'older x64', programs / 'newer ARM only'
        compiler = x64 / 'VC/Tools/MSVC/14.44/bin/Hostx64/x64/cl.exe'
        arm_compiler = arm / 'VC/Tools/MSVC/14.45/bin/Hostarm64/arm64/cl.exe'
        for path in (compiler, arm_compiler):
            path.parent.mkdir(parents=True)
            path.touch()
        def installations(command, **kwargs):
            # vswhere -latest must filter out a newer install that cannot
            # produce the executable architecture this host needs.
            return str(arm if '-requiresAny' in command else x64)
        env = {'ProgramFiles(x86)': str(programs), 'PATH': 'original'}
        with mock.patch.object(module, 'os', SimpleNamespace(name='nt', environ=env)), \
                mock.patch.object(module.platform, 'machine', return_value='AMD64'), \
                mock.patch.object(module.subprocess, 'check_output', side_effect=installations), \
                mock.patch.object(module.subprocess, 'run', return_value=SimpleNamespace(stdout='Path=x64 path\n')) as run, \
                mock.patch.object(module.shutil, 'which', return_value=str(compiler)):
            prepared = module.host_environment()
        self.assertIn(str(x64), run.call_args.args[0])
        self.assertIn('" x64 >nul', run.call_args.args[0])
        self.assertEqual(prepared['PATH'], 'x64 path')

    def test_completed_module_status_survives_legacy_windows_output_encoding(self):
        # Exercise the real final status line after a synthetic result is written.
        fixture = r"""
import importlib.util, pathlib, sys
from unittest.mock import patch
from types import SimpleNamespace
spec = importlib.util.spec_from_file_location('builder', sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
work = pathlib.Path(sys.argv[2]); work.mkdir()
with patch.object(m, 'os', SimpleNamespace(name='nt')), patch.object(sys, 'argv', ['build', '--rom', str(work/'rom'), '--work', str(work), '--toolchain', sys.argv[1]]), patch.object(m.identify, 'identify', return_value={}), patch.object(m, 'host_environment', return_value={}), patch.object(m, 'prepare_sources', return_value=work), patch.object(m, 'host_tool'), patch.object(m, 'extract'), patch.object(m, 'generate', return_value=work), patch.object(m, 'run'), patch.object(m, 'write_result', side_effect=lambda *args:(work/'result').write_bytes(b'completed')):
    m.main()
"""
        work = self.work / 'completed 雪'
        result = subprocess.run([sys.executable, '-X', 'utf8=0', '-c', fixture,
                                 str(ROOT / 'scripts/build-padmint-module.py'), str(work)],
                                env={**os.environ, 'PYTHONIOENCODING': 'cp1252'}, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr.decode('utf-8', 'replace'))
        self.assertEqual((work / 'result').read_bytes(), b'completed')
        self.assertIn(str(work.resolve()), result.stdout.decode('utf-8'))

    def test_normalization_child_uses_utf8(self):
        identity = {**self.identity, 'format': 'ciso'}
        class StopAfterLaunch(Exception):
            pass
        with mock.patch.object(module, 'run', side_effect=StopAfterLaunch) as run:
            with self.assertRaises(StopAfterLaunch):
                module.extract(self.work / 'input.ciso', identity, 'unused', self.work, {})
        self.assertEqual(run.call_args.args[:3], (sys.executable, '-X', 'utf8'))


if __name__ == '__main__':
    unittest.main()
