#!/usr/bin/env python3
"""Extract complete desktop SLP events for comparison with native probe traces.

Only finalized, closed files in the pinned desktop writer format are accepted.
Metadata, game-start identity fields, and input events are not exported.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path

HEADER = b'{U\x03raw[$U#l'
EVENT_LENGTHS = {0x38: 85, 0x3a: 13, 0x3b: 45, 0x3c: 9}
MAX_BYTES = 64 * 1024 * 1024


def extract(data):
    if len(data) > MAX_BYTES or data[:11] != HEADER or len(data) < 17:
        raise ValueError('unsupported or oversized replay')
    size = int.from_bytes(data[11:15], 'big')
    if not size or size > len(data) - 15:
        raise ValueError('unclosed or truncated replay')
    raw = data[15:15 + size]
    if len(raw) < 2 or raw[0] != 0x35:
        raise ValueError('missing command table')
    length = raw[1]
    if length < 1 or (length - 1) % 3 or length + 1 > len(raw):
        raise ValueError('invalid command table')
    sizes = {}
    for offset in range(2, length + 1, 3):
        command = raw[offset]
        if command in sizes:
            raise ValueError('duplicate command size')
        sizes[command] = int.from_bytes(raw[offset + 1:offset + 3], 'big') + 1
    for command, expected in EVENT_LENGTHS.items():
        if sizes.get(command) != expected:
            raise ValueError('game-code event version differs from pinned trace')
    offset = length + 1
    rows, started, ended = [], False, False
    while offset < len(raw):
        command = raw[offset]
        size = sizes.get(command)
        if not size or size > len(raw) - offset or ended:
            raise ValueError('invalid event boundary')
        packet = raw[offset:offset + size]
        if command == 0x36:
            if started:
                raise ValueError('multiple games in one replay')
            started = True
        elif command == 0x39:
            if not started:
                raise ValueError('end before start')
            ended = True
        elif command in EVENT_LENGTHS:
            if not started:
                raise ValueError('frame before game start')
            rows.append((command, packet.hex()))
        offset += size
    if not started or not ended or not rows:
        raise ValueError('incomplete game')
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('replay', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.replay.stat().st_size > MAX_BYTES:
        parser.error('replay exceeds capture limit')
    data = args.replay.read_bytes()
    rows = extract(data)
    args.output.mkdir(parents=True, exist_ok=False)
    with (args.output / 'online-frame-packets.csv').open('w') as out:
        writer = csv.writer(out)
        writer.writerow(['command', 'payload'])
        writer.writerows(rows)
    (args.output / 'online-frame-trace.json').write_text(json.dumps({
        'packets': len(rows), 'overflow': False, 'sequence_error': False,
        'game_ended': True, 'source': 'desktop SLP raw events',
        'source_sha256': hashlib.sha256(data).hexdigest(),
        'crossplay_accepted': False,
    }, indent=2) + '\n')


if __name__ == '__main__':
    main()
