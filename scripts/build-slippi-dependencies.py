#!/usr/bin/env python3
"""Build Slippi's non-game libraries from the committed dependency graph."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
ADAPTER = ROOT / 'ref/ModernGekko/vendor/dolphin/SlippiAdapter'

def run(args):
    subprocess.run([str(a) for a in args], check=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=('device', 'simulator'), default='device')
    args = parser.parse_args()
    run(['python3', ROOT / 'scripts/dependency-lock.py'])
    out = ROOT / f'build-slippi-{args.platform}'
    out.mkdir(exist_ok=True)
    sdk = 'iphoneos' if args.platform == 'device' else 'iphonesimulator'
    target = 'arm64-apple-ios16.0' + ('-simulator' if args.platform == 'simulator' else '')
    flags = f'-ffile-prefix-map={ROOT}=.'
    run(['cmake', '-S', ADAPTER / 'Externals/open-vcdiff', '-B', out / 'vcdiff', '-G', 'Ninja',
         '-DCMAKE_POLICY_VERSION_MINIMUM=3.5', '-DCMAKE_BUILD_TYPE=Release', '-DBUILD_TESTING=OFF',
         '-DCMAKE_SYSTEM_NAME=iOS', f'-DCMAKE_OSX_SYSROOT={sdk}', '-DCMAKE_OSX_ARCHITECTURES=arm64',
         '-DCMAKE_OSX_DEPLOYMENT_TARGET=16.0', '-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY',
         f'-DCMAKE_C_FLAGS={flags}', f'-DCMAKE_CXX_FLAGS={flags}'])
    run(['cmake', '--build', out / 'vcdiff', '-j', '4'])
    sdkroot = subprocess.check_output(['xcrun', '--sdk', sdk, '--show-sdk-path'], text=True).strip()
    for source in sorted((ADAPTER / 'Externals/semver/src').glob('*.cpp')):
        run(['xcrun', 'clang++', '-std=c++14', '-O2', '-target', target, '-isysroot', sdkroot,
             flags, '-I' + str(ADAPTER / 'Externals/semver/include'), '-c', source,
             '-o', out / (source.stem + '.o')])
    # Rust builder requires a new output directory so stale libraries are never
    # reused. A rerun (for example after a failed build) moves the earlier one
    # aside, outside this folder so its libraries are not recorded below, instead
    # of stopping; nothing is deleted.
    rust_out = out / 'rust'
    if rust_out.exists():
        earlier = ROOT / 'build-slippi-earlier' / f'{args.platform}-rust-{time.strftime("%Y%m%d-%H%M%S")}'
        earlier.parent.mkdir(exist_ok=True)
        rust_out.rename(earlier)
        print(f'Moved the earlier Slippi Rust build aside: {earlier}', flush=True)
    run(['python3', ROOT / 'scripts/build-slippi-rust.py', '--source', ADAPTER / 'rust',
         '--output', rust_out, '--platform', args.platform])
    records = {str(p.relative_to(out)): hashlib.sha256(p.read_bytes()).hexdigest()
               for p in sorted(out.rglob('*')) if p.is_file() and p.suffix in ('.a', '.o')}
    (out / 'libraries.sha256.json').write_text(json.dumps(records, indent=2) + '\n')

if __name__ == '__main__':
    main()
