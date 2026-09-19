#!/usr/bin/env python3
"""Build the pinned Slippi Rust FFI for the iOS adapter, without game/account data.

This records one library's provenance. It does not certify the rest of an app.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

REVISION = '4ad5ab440f3d277cfea82accbadfdcdc9510f2f9'
SOURCE_URL = 'https://github.com/chrissotraidis/slippi-rust-extensions.git'
TOOLCHAIN = '1.88.0'


def output(command, cwd=None):
    return subprocess.check_output(command, cwd=cwd, text=True).strip()


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verify_source(source):
    if Path(output(['git', 'rev-parse', '--show-toplevel'], source)).resolve() != source:
        raise ValueError('Source must be its own Git checkout, not a copied directory')
    if output(['git', 'rev-parse', 'HEAD'], source) != REVISION:
        raise ValueError('Slippi Rust source does not match the pinned fork commit')
    if output(['git', 'status', '--porcelain', '--untracked-files=all'], source):
        raise ValueError('Slippi Rust source has local changes; use a clean checkout')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True, type=Path,
                        help=f'Clean checkout of {SOURCE_URL} at {REVISION}')
    parser.add_argument('--output', required=True, type=Path, help='New, private build directory')
    parser.add_argument('--platform', choices=('device', 'simulator'), default='device')
    args = parser.parse_args()
    source, build = args.source.resolve(), args.output.resolve()
    verify_source(source)
    if build.exists() or build.is_relative_to(source):
        parser.error('Use a new output directory outside the source checkout')
    target, sdk = {'device': ('aarch64-apple-ios', 'iphoneos'),
                   'simulator': ('aarch64-apple-ios-sim', 'iphonesimulator')}[args.platform]
    rustc = output(['rustup', 'which', '--toolchain', TOOLCHAIN, 'rustc'])
    cargo = output(['rustup', 'which', '--toolchain', TOOLCHAIN, 'cargo'])
    env = os.environ.copy()
    for name in ('CARGO_ENCODED_RUSTFLAGS', 'RUSTC_WRAPPER', 'RUSTC_WORKSPACE_WRAPPER'):
        env.pop(name, None)
    env.update(RUSTC=rustc,
               RUSTDOC=output(['rustup', 'which', '--toolchain', TOOLCHAIN, 'rustdoc']),
               RUSTFLAGS=f'--remap-path-prefix={source}=/slippi-rust --remap-path-prefix={Path.home()}=/build-home', CARGO_TARGET_DIR=str(build), IPHONEOS_DEPLOYMENT_TARGET='16.0',
               SDKROOT=output(['xcrun', '--sdk', sdk, '--show-sdk-path']))
    build.mkdir(parents=True)
    command = [cargo, 'build', '--locked', '--release', '--target', target]
    with (build / 'build.log').open('w') as log:
        subprocess.run(command, cwd=source, env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
    verify_source(source)
    archive = build / target / 'release/libslippi_rust_extensions.a'
    record = dict(source_url=SOURCE_URL, source_commit=REVISION,
                  cargo_lock_sha256=digest(source / 'Cargo.lock'),
                  rustc=output([rustc, '--version']), cargo=output([cargo, '--version']),
                  target=target, deployment_target='16.0', rustflags=env['RUSTFLAGS'],
                  sdk_version=output(['xcrun', '--sdk', sdk, '--show-sdk-version']),
                  xcode=output(['xcodebuild', '-version']),
                  archive_sha256=digest(archive),
                  ffi_header_sha256=digest(source / 'ffi/includes/SlippiRustExtensions.h'))
    (build / 'provenance.json').write_text(json.dumps(record, indent=2) + '\n')
    print(json.dumps(record, indent=2))


if __name__ == '__main__':
    main()
