#!/usr/bin/env python3
"""Compare complete finalized packets from a bounded single local online match.

Strict mode rejects repeated timelines; --rollback validates revisions before finalization.
Does not treat bookend finalization timing as game state or claim full RAM sync.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import struct


# Exact event lengths (including command) for the pinned game-code version.
EVENT_LENGTHS = {0x38:85, 0x3a:13, 0x3b:45, 0x3c:9}

def trace_status(path):
    status = json.loads(path.with_name('online-frame-trace.json').read_text())
    if status.get('sequence_error', False):
        raise ValueError('trace reports a sequence error')
    return status

def read_trace(path):
    status = trace_status(path)
    rows = list(csv.DictReader(path.open()))
    if status['overflow'] or status['packets'] != len(rows):
        raise ValueError('incomplete trace')
    frames, pending, bookends = {}, [], []
    last_finalized = -124
    for row in rows:
        command = int(row['command']); packet = bytes.fromhex(row['payload'])
        if len(packet) != EVENT_LENGTHS.get(command) or packet[0] != command:
            raise ValueError('invalid packet')
        frame = struct.unpack_from('>i', packet, 1)[0]
        if command != 0x3c:
            pending.append((frame, packet)); continue
        if len(packet) != 9: raise ValueError('unexpected bookend size')
        finalized = struct.unpack_from('>i', packet, 5)[0]
        if frame in frames or (bookends and frame != bookends[-1][0] + 1):
            raise ValueError('repeated or noncontiguous timeline requires rollback-aware analysis')
        if finalized < last_finalized or finalized > frame:
            raise ValueError('invalid finalization timeline')
        if not pending or any(f != frame for f, _ in pending):
            raise ValueError('incomplete frame grouping')
        packets = [p for _, p in pending]
        players = [p[5:7] for p in packets if p[0] == 0x38 and len(p) >= 8]
        if players != [bytes([0,0]), bytes([1,0])] or sum(p[0] == 0x3a for p in packets) != 1:
            raise ValueError('requires two complete player packets and one RNG packet per frame')
        frames[frame] = packets; pending = []
        bookends.append((frame, finalized)); last_finalized = finalized
    if pending or not frames:
        raise ValueError('trailing unfinalized or incomplete frame')
    trailing = max(frames) - last_finalized
    if trailing > 8 or (trailing and not status.get('game_ended', False)):
        raise ValueError('trailing unfinalized or incomplete frame')
    return frames, bookends


def compare(left, right, *, require_complete_match=False):
    a, ab = read_trace(left); b, bb = read_trace(right)
    if a.keys() != b.keys(): raise ValueError('different complete frame ranges')
    mismatches = sum(a[f] != b[f] for f in a)
    ended = [bool(trace_status(p).get('game_ended', False)) for p in (left, right)]
    failures = ['game end not observed on both clients'] if require_complete_match and not all(ended) else []
    if require_complete_match and min(a) != -123:
        failures.append('missing match beginning')
    return {'scope':'Two local clients, single contiguous finalized timeline; complete emitted player/RNG/item packets, not full RAM or desktop crossplay',
            'frames':len(a),'first_frame':min(a),'last_frame':max(a),
            'compared_packets':sum(len(p) for p in a.values()),'mismatching_frames':mismatches,
            'bookend_finalization_timing_differences':sum(x != y for x,y in zip(ab,bb)),
            'commands':{hex(c):sum(p[0] == c for ps in a.values() for p in ps) for c in (0x38,0x3a,0x3b)},
            'trace_sha256':[hashlib.sha256(p.read_bytes()).hexdigest() for p in (left,right)],
            'rollback_timeline_observed':False,'game_ended':ended,
            'require_complete_match':require_complete_match,'acceptance_failures':failures,
            'pass':mismatches==0 and not failures}


def read_rollback_trace(path):
    status = trace_status(path)
    with path.open() as file:
        rows = list(csv.DictReader(file))
    if status['overflow'] or status['packets'] != len(rows): raise ValueError('incomplete trace')
    frames, pending, finalized_frames = {}, [], {}
    previous = maximum = finalized = -124
    repeated = changed = rewinds = max_rewind = 0
    for row in rows:
        command = int(row['command']); packet = bytes.fromhex(row['payload'])
        if len(packet) != EVENT_LENGTHS.get(command) or packet[0] != command:
            raise ValueError('invalid packet')
        frame = struct.unpack_from('>i',packet,1)[0]
        if command != 0x3c:
            pending.append((frame,packet)); continue
        if len(packet) != 9: raise ValueError('unexpected bookend size')
        new_finalized = struct.unpack_from('>i',packet,5)[0]
        if frame <= finalized: raise ValueError('replayed an already finalized frame')
        if frame > previous + 1: raise ValueError('skipped simulation frame')
        if frame <= previous:
            rewinds += 1; max_rewind=max(max_rewind,previous-frame+1)
        if not pending or any(f != frame for f,_ in pending): raise ValueError('incomplete frame grouping')
        packets = [p for _,p in pending]; pending=[]
        players = [p[5:7] for p in packets if p[0] == 0x38 and len(p) >= 8]
        if players != [bytes([0,0]),bytes([1,0])] or sum(p[0]==0x3a for p in packets)!=1:
            raise ValueError('incomplete two-player frame')
        if frame in frames:
            repeated += 1; changed += frames[frame] != packets
        frames[frame]=packets; previous=frame; maximum=max(maximum,frame)
        if new_finalized < finalized or new_finalized > frame: raise ValueError('invalid finalization timeline')
        for f in range(finalized+1,new_finalized+1):
            if f not in frames: raise ValueError('finalized missing frame')
            finalized_frames[f]=frames[f]
        finalized=new_finalized
    if pending or not finalized_frames: raise ValueError('incomplete capture')
    trailing=maximum-finalized
    if trailing > 8: raise ValueError('too many unfinalized trailing frames')
    bookend_finalized = finalized
    end_finalized = 0
    # Slippi's parser finalizes its remaining frames on GAME_END:
    # project-slippi/slippi-js ff815345e641836a331191320c0f6eae21542a5f,
    # src/common/utils/slpParser.ts, _handleGameEnd. Preserve the bookend
    # boundary as evidence; never promote a stopped or incomplete capture.
    if status.get('game_ended', False):
        if previous != maximum:
            raise ValueError('game ended before rollback caught up')
        for f in range(finalized + 1, maximum + 1):
            if f not in frames:
                raise ValueError('game end has missing tail frame')
            finalized_frames[f] = frames[f]
            end_finalized += 1
        finalized = maximum
        trailing = 0
    return finalized_frames, {'observed_last_frame':maximum,'last_finalized_frame':finalized,
        'bookend_last_finalized_frame':bookend_finalized,'frames_finalized_at_game_end':end_finalized,
        'unfinalized_tail_frames':trailing,'game_ended':bool(status.get('game_ended', False)),
        'repeated_frame_events':repeated,
        'changed_prediction_frame_events':changed,'rewind_events':rewinds,'max_rewind_frames':max_rewind}


def compare_rollback(left,right, *, require_complete_match=False, require_changed_rollback=False):
    a,am=read_rollback_trace(left);b,bm=read_rollback_trace(right)
    if min(a)!=-123 or min(b)!=-123: raise ValueError('missing match beginning')
    end=min(max(a),max(b)); common=range(-123,end+1)
    if len(common)<300 or abs(max(a)-max(b))>16: raise ValueError('insufficient or unequal capture windows')
    if any(f not in a or f not in b for f in common): raise ValueError('missing finalized frame')
    differences=[f for f in common if a[f]!=b[f]]
    ended=[am['game_ended'],bm['game_ended']]
    outside=[max(a)-end,max(b)-end]
    rewound=any(m['rewind_events'] for m in (am,bm))
    changed=any(m['changed_prediction_frame_events'] for m in (am,bm))
    failures=[]
    if require_complete_match:
        if not all(ended): failures.append('game end not observed on both clients')
        if any(m['unfinalized_tail_frames'] for m in (am,bm)) or any(outside):
            failures.append('complete match has unfinalized or uncompared frames')
    if require_changed_rollback and not (rewound and changed):
        failures.append('no changed rollback prediction observed')
    return {'scope':'Common finalized prefix of two local online clients, complete emitted packets; not full RAM or desktop crossplay',
        'frames':len(common),'first_frame':-123,'last_frame':end,
        'compared_packets':sum(len(a[f]) for f in common),'mismatching_frames':len(differences),
        'first_mismatching_frame':differences[0] if differences else None,
        'commands':{hex(c):sum(p[0]==c for f in common for p in a[f]) for c in (0x38,0x3a,0x3b)},
        'clients':[am,bm],'finalized_frames_outside_common_prefix':outside,
        'trace_sha256':[hashlib.sha256(p.read_bytes()).hexdigest() for p in (left,right)],
        'rollback_timeline_observed':rewound,'changed_predictions_observed':changed,
        'game_ended':ended,'require_complete_match':require_complete_match,
        'require_changed_rollback':require_changed_rollback,'acceptance_failures':failures,
        'pass':not differences and not failures}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run',type=Path); parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--rollback',action='store_true',help='Compare finalized prefixes and verify rollback timelines')
    parser.add_argument('--require-complete-match', action='store_true', help='Require both game ends and no excluded frames; emitted packets only, not full RAM')
    parser.add_argument('--require-changed-rollback', action='store_true', help='Require an observed rewind with changed predictions (--rollback only)')
    args=parser.parse_args()
    if args.require_changed_rollback and not args.rollback:
        parser.error('--require-changed-rollback requires --rollback')
    comparator=compare_rollback if args.rollback else compare
    gates={'require_complete_match':args.require_complete_match}
    if args.rollback: gates['require_changed_rollback']=args.require_changed_rollback
    result=comparator(args.run/'user-0/online-frame-packets.csv',args.run/'user-1/online-frame-packets.csv',**gates)
    result['analyzer_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    args.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
    return 0 if result['pass'] else 1

if __name__=='__main__': raise SystemExit(main())
