#!/usr/bin/env python3
"""Bundle credits, pinned source references and original dependency notices."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def stage(destination):
    destination.mkdir(parents=True, exist_ok=True)
    records = []
    def copy(source, relative):
        data = source.read_bytes()
        data.decode('utf-8')  # Notices must be text, never an opaque artifact.
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        records.append({'path': str(relative), 'sha256': hashlib.sha256(data).hexdigest()})
    for name in ('LICENSE', 'CREDITS.md', 'THIRD-PARTY-NOTICES.md'):
        copy(ROOT / name, Path(name))
    copy(ROOT / 'config/dependencies.lock.json', Path('dependencies.lock.json'))
    runtime = ROOT / 'ref/ModernGekko'
    names = subprocess.check_output(['git', '-C', str(runtime), 'ls-files',
                                     '--recurse-submodules', '-z']).decode().split('\0')
    count = 0
    for name in names:
        if not name:
            continue
        path = Path(name)
        if re.fullmatch(r'(license|copying|copyright|notice)([.-].*)?', path.name.lower()) and path.suffix.lower() not in ('.zip', '.png', '.jpg', '.gif') or 'LICENSES' in path.parts:
            source = runtime / path
            if source.is_file() and not source.is_symlink():
                copy(source, Path('upstream') / path)
                count += 1
    if not count or not (destination / 'upstream/LICENSE').is_file():
        raise ValueError('Pinned dependency license texts are missing; bootstrap first')
    rust = runtime / 'vendor/dolphin/SlippiAdapter/rust'
    metadata = json.loads(subprocess.check_output(
        ['rustup', 'run', '1.88.0', 'cargo', 'metadata', '--locked', '--format-version', '1',
         '--filter-platform', 'aarch64-apple-ios'], cwd=rust, text=True))
    packages = []
    for package in metadata['packages']:
        base = Path(package['manifest_path']).parent
        label = package['name'] + '-' + package['version']
        packages.append({'name': package['name'], 'version': package['version'],
                         'license': package.get('license'), 'source': package.get('source')})
        for notice in sorted(base.rglob('*')):
            if notice.is_file() and re.fullmatch(r'(license|copying|copyright|notice)([.-].*)?', notice.name.lower()):
                try:
                    notice.read_text()
                except (UnicodeError, OSError):
                    continue
                copy(notice, Path('rust') / label / notice.relative_to(base))
    (destination / 'rust-packages.json').write_text(json.dumps(packages, indent=2) + '\n')
    credits = (ROOT / 'CREDITS.md').read_text()
    credits = re.sub(r'\[([^]]+)\]\(([^)]+)\)', r'\1 (\2)', credits)
    credits = re.sub(r'^#+\s*', '', credits, flags=re.MULTILINE)
    lines = []
    for line in credits.splitlines():
        if line.startswith('|'):
            columns = [part.strip() for part in line.strip('|').split('|')]
            if columns == ['Project', 'Contribution'] or all(set(part) <= {'-', ':', ' '} for part in columns):
                continue
            lines.append('\n'.join(columns) + '\n')
        else:
            lines.append(line)
    credits = '\n'.join(lines)
    credits = re.sub(r'\((docs/[^)]+|THIRD-PARTY-NOTICES.md)\)',
                     r'(https://github.com/chrissotraidis/meleepad/blob/main/\1)', credits)
    (destination / 'Credits.txt').write_text(credits)
    (destination / 'manifest.json').write_text(json.dumps({'schemaVersion': 1, 'files': records}, indent=2) + '\n')
    print(f'Bundled credits, source pins and {count} upstream license/notice texts')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    stage(args.destination)
