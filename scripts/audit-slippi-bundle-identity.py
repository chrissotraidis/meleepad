#!/usr/bin/env python3
"""Reject known Slippi account/history files and nonempty credential metadata.

This is a packaging guard, not a proof that arbitrary binaries contain no secrets.
It never prints discovered credential values or file contents.
"""
import argparse
import json
import plistlib
import tempfile
from pathlib import Path

PRIVATE_FILES = {'user.json', 'direct-codes.json', 'teams-codes.json'}
SECRET_KEYS = {'playkey', 'accesstoken', 'refreshtoken', 'idtoken', 'clientsecret'}


def contains_credentials(value):
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = str(key).lower().replace('_', '').replace('-', '')
            if normalized in SECRET_KEYS and child not in (None, '', False, [], {}):
                return True
            if contains_credentials(child):
                return True
    elif isinstance(value, list):
        return any(contains_credentials(child) for child in value)
    return False


def audit(bundle):
    if not bundle.is_dir() or bundle.is_symlink():
        raise ValueError('requires a real bundle directory')
    findings, metadata = [], 0
    for path in sorted(bundle.rglob('*')):
        # Refuse aliases that could escape the audited artifact.
        reason = None
        if path.is_symlink():
            reason = 'symlink requires explicit artifact review'
        elif path.name.lower() in PRIVATE_FILES:
            reason = 'private account or opponent-history file'
        elif path.is_file() and path.suffix.lower() in ('.json', '.plist'):
            metadata += 1
            if path.stat().st_size > 8 * 1024 * 1024:
                reason = 'metadata exceeds audit bound'
            else:
                try:
                    value = (plistlib.loads(path.read_bytes()) if path.suffix.lower() == '.plist'
                             else json.loads(path.read_bytes()))
                    if contains_credentials(value):
                        reason = 'nonempty credential metadata'
                except (ValueError, TypeError, OSError, plistlib.InvalidFileException):
                    reason = 'metadata could not be audited'
        if reason:
            # Return only a classification, not filenames potentially containing
            # account identifiers or any credential values.
            findings.append(reason)
    return {'pass': not findings, 'metadata_files_checked': metadata,
            'findings': findings,
            'scope': 'Known account/history filenames and JSON/plist credential fields; not arbitrary binary secret detection'}


def self_test():
    with tempfile.TemporaryDirectory(prefix='slippi-identity-guard-') as directory:
        root = Path(directory)
        assert audit(root)['pass']
        cases = [('user.json', '{}'), ('direct-codes.json', '[]'),
                 ('config.json', '{"auth":{"playKey":"synthetic"}}'),
                 ('config.json', '{"refresh_token":"synthetic"}'),
                 ('config.json', '{invalid')]
        for name, content in cases:
            path = root / name
            path.write_text(content)
            assert not audit(root)['pass']
            path.unlink()
        path = root / 'config.plist'
        path.write_bytes(plistlib.dumps({'auth': {'access_token': 'synthetic'}}))
        assert not audit(root)['pass']
        path.unlink()
        path = root / 'alias'
        path.symlink_to(root / 'absent')
        assert not audit(root)['pass']
        path.unlink()
        (root / 'config.json').write_text('{"appVersion":"0.0.0-meleepad-dev","playKey":""}')
        assert audit(root)['pass']
    return {'pass': True, 'rejected_fixtures': 7, 'accepted_fixtures': 2}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path, nargs='?')
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        result = self_test()
    elif args.bundle:
        result = audit(args.bundle)
    else:
        parser.error('provide a bundle or --self-test')
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result['pass'] else 1)


if __name__ == '__main__':
    main()
