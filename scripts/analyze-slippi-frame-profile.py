#!/usr/bin/env python3
"""Summarize private frame-boundary CSV and GCT captures without exposing bytes."""
import argparse
import csv
import hashlib
import json
import statistics
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path, help='Probe User directory containing timing/captures')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    timing = args.directory / 'slippi-frame-timing.csv'
    rows = [{k: int(v) for k, v in r.items()} for r in csv.DictReader(timing.open())]
    result = {'scope': 'Offline iPad game-boundary timing; audio disabled; not network rollback headroom',
              'rows': len(rows), 'timing_sha256': hashlib.sha256(timing.read_bytes()).hexdigest(),
              'analyzer_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              'filters': 'Adjacent consecutive frames in same phase; exclude negative pregame frames, phase transitions and intervals immediately after GCT capture; done phase begins after frame 300',
              'phases': {}}
    for phase, name in enumerate(('baseline', 'wrong_prediction', 'authoritative_correction', 'after_trials')):
        pairs = [(a, b) for a, b in zip(rows, rows[1:])
                 if a['phase'] == b['phase'] == phase and b['frame'] == a['frame'] + 1
                 and a['frame'] >= (301 if phase == 3 else 0)
                 and a['frame'] not in (60, 180, 300)]
        if not pairs:
            continue
        data = {'intervals': len(pairs)}
        for kind in ('wall_ns', 'thread_cpu_ns'):
            if any(a[kind] < 0 or b[kind] < a[kind] for a, b in pairs):
                raise ValueError('invalid or decreasing clock sample')
            xs = sorted((b[kind] - a[kind]) / 1e6 for a, b in pairs)
            data[kind.replace('_ns', '_ms')] = {
                'median': statistics.median(xs), 'p95': xs[int((len(xs) - 1) * .95)],
                'mean': statistics.mean(xs), 'max': max(xs)}
        data['mean_game_frames_per_second'] = 1000 / data['wall_ms']['mean']
        result['phases'][name] = data
    manifest = list(csv.DictReader((args.directory / 'slippi-gct-captures.csv').open()))
    changes = []
    for a, b in zip(manifest, manifest[1:]):
        blobs = []
        for row in (a, b):
            if Path(row['file']).name != row['file']:
                raise ValueError('capture must be a filename')
            blob = (args.directory / row['file']).read_bytes()
            if len(blob) != int(row['bytes']):
                raise ValueError('capture size mismatch')
            blobs.append(blob)
        if a['address'] != b['address'] or len(blobs[0]) != len(blobs[1]):
            raise ValueError('capture regions differ')
        offsets = [i for i in range(0, len(blobs[0]), 4) if blobs[0][i:i+4] != blobs[1][i:i+4]]
        changes.append({'from_frame': int(a['frame']), 'to_frame': int(b['frame']),
                        'changed_words': len(offsets),
                        'first_word_offset': min(offsets) if offsets else None,
                        'last_word_offset': max(offsets) if offsets else None,
                        'changed_16k_chunks': sorted({i // 16384 for i in offsets})})
    result['gct_capture_differences'] = changes
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
