#!/usr/bin/env python3
"""Build one private offline Melee module without rebuilding the published app.

Uses the committed DolRecomp/RecompCore sources, never a bootstrap patch stack.
The selected module and its DOL identity are described for PadMint to package.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name.replace('-', '_'), ROOT / 'scripts' / (name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


identify = load('identify-game')
dependencies = load('dependency-lock')


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def run(*args, env=None):
    subprocess.run([str(arg) for arg in args], check=True, env=env)


def prepare_sources(source_root):
    source_root = source_root.resolve()
    if json.loads((source_root / 'config/dependencies.lock.json').read_text()) != \
            json.loads((ROOT / 'config/dependencies.lock.json').read_text()):
        raise ValueError('Source checkout dependency pins differ; existing sources were preserved')
    if source_root == ROOT:
        runtime = ROOT / 'ref/ModernGekko'
        dolphin = runtime / 'vendor/dolphin'
        for parent, names in ((ROOT, ['ref/ModernGekko']), (runtime, ['vendor/dolphin']),
                              (dolphin, ['DolRecomp', 'Externals/enet/enet'])):
            for name in names:
                path = parent / name
                if path.is_symlink():
                    raise ValueError(f'Preserving source symlink: {path}')
                if (path / '.git').exists():
                    dirty = subprocess.check_output(['git', '-C', str(path), 'status', '--porcelain',
                                                     '--untracked-files=all', '--ignore-submodules=none'])
                    if dirty:
                        raise ValueError(f'Preserving modified dependency checkout: {path}')
            run('git', '-C', parent, '-c', 'core.longpaths=true', '-c', 'core.autocrlf=false',
                'submodule', 'update', '--init', '--no-recommend-shallow', '--', *names)
    # An explicit source root is read-only: verify the complete maintained-fork
    # contract, including its gitlinks and all tracked/nonignored source bytes.
    dependencies.verify(source_root)
    return source_root / 'ref/ModernGekko/vendor/dolphin'


def host_environment():
    env = dict(os.environ)
    for key in ('SDKROOT', 'CPATH', 'LIBRARY_PATH'):
        env.pop(key, None)
    if os.name != 'nt':
        return env
    installer = Path(env.get('ProgramFiles(x86)', r'C:\Program Files (x86)')) / 'Microsoft Visual Studio/Installer/vswhere.exe'
    help_text = 'Install Visual Studio 2022 Build Tools with Desktop development with C++ and a Windows SDK.'
    if not installer.is_file():
        raise ValueError(help_text)
    native_arm = platform.machine().lower() in ('arm64', 'aarch64')
    components = ['Microsoft.VisualStudio.Component.VC.Tools.x86.x64']
    if native_arm:
        components.append('Microsoft.VisualStudio.Component.VC.Tools.ARM64')
    installation = subprocess.check_output([str(installer), '-latest', '-products', '*',
                                            *(['-requiresAny'] if native_arm else []), '-requires', *components,
                                            '-property', 'installationPath'], text=True).strip()
    if not installation:
        raise ValueError(help_text)
    versions = list((Path(installation) / 'VC/Tools/MSVC').glob('*'))
    arch = 'arm64' if native_arm and any((v / 'bin/Hostarm64/arm64/cl.exe').is_file() for v in versions) else 'x64'
    if not any((v / f'bin/Host{arch}/{arch}/cl.exe').is_file() for v in versions):
        raise ValueError(help_text)
    script = Path(installation) / 'VC/Auxiliary/Build/vcvarsall.bat'
    command = subprocess.list2cmdline([env.get('COMSPEC', 'cmd.exe')]) + f' /d /s /c ""{script}" {arch} >nul && set"'
    result = subprocess.run(command, capture_output=True, text=True, check=True, env=env)
    for line in result.stdout.splitlines():
        key, separator, value = line.partition('=')
        if separator and key:
            existing = next((name for name in env if name.casefold() == key.casefold()), key)
            env[existing] = value
    if not shutil.which('cl', path=env.get('Path', env.get('PATH'))):
        raise ValueError(help_text)
    return env


def host_tool(dolphin, work, jobs, env):
    build = work / 'dolrecomp-host'
    compilers = ['-DCMAKE_C_COMPILER=cl'] if os.name == 'nt' else []
    run('cmake', '--fresh', '-S', dolphin / 'DolRecomp', '-B', build, '-G', 'Ninja',
        '-DCMAKE_BUILD_TYPE=Release', '-DDOLRECOMP_ENABLE_LLVM=OFF', *compilers, env=env)
    run('cmake', '--build', build, '--target', 'dolrecomp', '--parallel', jobs, env=env)
    return build / ('dolrecomp.exe' if os.name == 'nt' else 'dolrecomp')


def check_extraction(game, identity):
    marker = game / '.meleepad-source-sha256'
    if not marker.is_file() or marker.read_text().strip() != identity['image_sha256']:
        raise ValueError(f'Preserving extraction with a different or missing source identity: {game}')
    if not (game / 'sys/boot.bin').is_file() or sha256(game / 'sys/main.dol') != identity['dol_sha256']:
        raise ValueError('Extracted DOL does not match the selected game revision')
    if sum(p.is_file() for p in (game / 'files').rglob('*')) != 1209:
        raise ValueError('The selected game extraction is incomplete (expected 1209 files)')


def extract(disc, identity, tool, work, env):
    image = disc
    if identity['format'] == 'ciso':
        image = work / f'GALE01-r{identity["revision"]}.iso'
        if not image.exists():
            run(sys.executable, ROOT / 'scripts/identify-game.py', disc, '--normalize', image)
        normalized = identify.identify(image)
        if normalized['dol_sha256'] != identity['dol_sha256']:
            raise ValueError('Existing normalized image belongs to another revision; preserved')
        # As in prepare-game.sh, identify the bytes actually extracted. A CISO
        # and its equivalent reviewed ISO can then reuse the same safe cache.
        identity = {**identity, 'image_sha256': normalized['image_sha256']}
    game = work / f'extracted-r{identity["revision"]}'
    if game.exists():
        check_extraction(game, identity)
        return game / 'sys/main.dol'
    with tempfile.TemporaryDirectory(prefix='extract-', dir=work) as temporary:
        staging = Path(temporary) / 'game'
        run(tool, 'extract', image, staging, env=env)
        (staging / '.meleepad-source-sha256').write_text(identity['image_sha256'] + '\n')
        check_extraction(staging, identity)
        staging.rename(game)
    return game / 'sys/main.dol'


def generate(dol, dolphin, tool, work, jobs, env):
    # moderngekko-port only applies OnFrame defaults from GALE01.ini. At the
    # reviewed pin that file is absent; stop if a future fork changes this.
    if (dolphin / 'Data/Sys/GameSettings/GALE01.ini').exists():
        raise ValueError('Review GALE01 default DOL patches before changing the generator route')
    # DolRecomp does not remove obsolete chunks. Keep its reviewed default
    # settings, and separate outputs when the disc, fork pins or options change.
    env = {key: value for key, value in env.items() if not key.upper().startswith('DOLRECOMP_')}
    options = ['--backend=c', '--cpu', 'gekko', '--gamecube']
    key = (ROOT / 'config/dependencies.lock.json').read_bytes() + '\0'.join(options).encode('ascii')
    pin = hashlib.sha256(key).hexdigest()[:12]
    output = work / f'generated-{sha256(dol)[:12]}-{pin}'
    run(tool, f'-j{jobs}', *options, dol, output, env=env)
    generated = output / 'generated'
    shutil.copyfile(dol, generated / 'main.dol')
    if not (generated / 'generated_smc.txt').exists():
        (generated / 'generated_smc.txt').write_text('')
    return generated


def write_result(work, module, identity):
    if identity['revision'] not in (0, 2):
        raise ValueError('Only the reviewed v1.00 and v1.02 module destinations are supported')
    name = 'gGALE01r2_recomp.dylib' if identity['revision'] == 2 else 'gGALE01_recomp.dylib'
    sidecar = module.with_name(module.name + '.dol-sha256')
    sidecar.write_bytes((identity['dol_sha256'] + '\n').encode('ascii'))
    result = {'file': module.relative_to(work).as_posix(), 'into': name, 'sha256': sha256(module),
              'companions': [{'file': sidecar.relative_to(work).as_posix(), 'into': name + '.dol-sha256',
                              'sha256': sha256(sidecar)}]}
    (work / 'module-result.json').write_text(json.dumps(result, indent=2) + '\n')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rom', required=True, type=Path)
    parser.add_argument('--work', required=True, type=Path)
    parser.add_argument('--toolchain', type=Path)
    parser.add_argument('--source-root', type=Path, default=ROOT, help='Read-only prepared checkout with the same pinned dependencies')
    parser.add_argument('--generate-only', action='store_true')
    parser.add_argument('--jobs', type=int, choices=range(1, 17), default=4)
    args = parser.parse_args()
    if not args.generate_only and (not args.toolchain or not args.toolchain.is_file()):
        parser.error('--toolchain must name PadMint\'s existing iOS module toolchain')
    identity = identify.identify(args.rom)
    env = host_environment()
    dolphin = prepare_sources(args.source_root)
    work = args.work.resolve()
    work.mkdir(parents=True, exist_ok=True)
    tool = host_tool(dolphin, work, args.jobs, env)
    dol = extract(args.rom.resolve(), identity, tool, work, env)
    generated = generate(dol, dolphin, tool, work, args.jobs, env)
    if args.generate_only:
        return
    build = work / 'module'
    run('cmake', '--fresh', '-S', dolphin / 'module-template', '-B', build, '-G', 'Ninja',
        f'-DCMAKE_TOOLCHAIN_FILE={args.toolchain.resolve()}', '-DCMAKE_BUILD_TYPE=Release', '-DGAME_ID=GALE01',
        f'-DGENERATED_DIR={generated}', f'-DGXRUNTIME_DIR={dolphin / "GXRuntime"}',
        f'-DCHASSIS_ABI_DIR={dolphin / "Source/Core/Core/PowerPC/StaticRecomp"}',
        f'-DPython3_EXECUTABLE={sys.executable}', '-DRECOMPCORE_MODULE_TUNE_CPU=apple-a15', env=env)
    run('cmake', '--build', build, '--parallel', args.jobs, env=env)
    write_result(work, build / 'gGALE01_recomp.dylib', identity)
    print('Private module and DOL identity ready for PadMint:', work / 'module-result.json')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
