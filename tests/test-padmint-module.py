#!/usr/bin/env python3
"""Portable module preparation tests; all game bytes here are synthetic."""
import importlib.util
import json
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
        self.work = Path(self.temporary.name) / 'private work with spaces'
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
                mock.patch.object(module.subprocess, 'check_output', return_value=str(installation)), \
                mock.patch.object(module.subprocess, 'run', return_value=result) as run, \
                mock.patch.object(module.shutil, 'which', return_value=str(compiler)):
            prepared = module.host_environment()
        self.assertIn('" arm64 >nul', run.call_args.args[0])
        self.assertEqual(prepared['PATH'], 'prepared path')
        self.assertNotIn('Path', prepared)
        self.assertNotIn('SDKROOT', prepared)
        self.assertEqual(prepared['INCLUDE'], 'compiler headers')


if __name__ == '__main__':
    unittest.main()
