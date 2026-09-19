#!/usr/bin/env python3
"""Test pinned Slippi UserManager isolation offline using existing Rust libraries."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rust-build', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    if output.exists() or subprocess.run(['git', 'check-ignore', '-q', str(output)], cwd=repo).returncode:
        parser.error('use a new ignored output directory')
    deps = args.rust_build.resolve() / 'release/deps'
    libraries = {}
    for name in ('slippi_user', 'slippi_gg_api'):
        candidates = list(deps.glob(f'lib{name}-*.rlib'))
        if len(candidates) != 1:
            parser.error(f'expected exactly one built {name} library')
        libraries[name] = candidates[0]
    source = repo / 'scripts/slippi-identity-probe.rs'
    hashes = {name: sha(path) for name, path in libraries.items()}
    output.mkdir(parents=True)
    compiler = subprocess.check_output(['rustup', 'which', '--toolchain', 'stable', 'rustc'], text=True).strip()
    command = [compiler, '--edition=2024', '-C', 'panic=abort', '-L', f'dependency={deps}',
               str(source), '-o', str(output / 'identity-probe')]
    for name, path in libraries.items():
        command += ['--extern', f'{name}={path}']
    with (output / 'build.log').open('w') as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
    policy = output / 'deny-network.sb'
    policy.write_text('(version 1) (allow default) (deny network*)\n')
    # Independent OS-level denial covers DNS and HTTP from the real file loader.
    result = subprocess.run(['sandbox-exec', '-f', str(policy), str(output / 'identity-probe'),
                             str(output / 'users')], capture_output=True, text=True, timeout=40)
    (output / 'run.log').write_text(result.stdout + result.stderr)
    result.check_returncode()
    evidence = json.loads(result.stdout)
    evidence.update(scope='Local account state isolation, not 1000 live players or service acceptance',
                    source_sha256=sha(source), runner_sha256=sha(Path(__file__)),
                    library_sha256=hashes, network_policy_sha256=sha(policy),
                    os_network_denied=True, executable_sha256=sha(output / 'identity-probe'))
    assert hashes == {name: sha(path) for name, path in libraries.items()}
    (output / 'results.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print(json.dumps(evidence, indent=2))


if __name__ == '__main__':
    main()
