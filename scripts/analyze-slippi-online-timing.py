#!/usr/bin/env python3
"""Summarize online game progression and CPU cost, including intervening rollback work."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import statistics


def analyze(rows):
    if len(rows)>=10000:raise ValueError('profiler may have reached its cap')
    selected=[r for r in rows if r['phase']==4 and r['frame']>=120]
    if len(selected)<2:raise ValueError('no measured online match window')
    # Validate every clock, including replayed frames; do not hide expensive rewinds.
    for a,b in zip(selected,selected[1:]):
        if a['thread_cpu_ns']<0 or b['thread_cpu_ns']<a['thread_cpu_ns'] or b['wall_ns']<=a['wall_ns']:
            raise ValueError('invalid profiler clock')
    highs=[];maximum=119
    for r in selected:
        if r['frame']>maximum:
            if highs and r['frame']!=maximum+1:raise ValueError('missing high-water frame')
            highs.append(r);maximum=r['frame']
    if len(highs)<2:raise ValueError('no game progression')
    pairs=list(zip(highs,highs[1:]));result={'scope':'Short online game-progression timing; CPU intervals include rollback between new highest frames; not sustained or audio acceptance',
        'first_frame':highs[0]['frame'],'last_frame':highs[-1]['frame'],
        'highwater_intervals':len(pairs),'simulation_bookends':len(selected),
        'replayed_bookends':len(selected)-len(highs)}
    for key in ('wall_ns','thread_cpu_ns'):
        values=sorted((b[key]-a[key])/1e6 for a,b in pairs)
        result[key.replace('_ns','_ms')]={'mean':statistics.mean(values),'median':statistics.median(values),'p95':values[int((len(values)-1)*.95)],'max':max(values)}
    result['elapsed_seconds']=(highs[-1]['wall_ns']-highs[0]['wall_ns'])/1e9
    result['game_progress_frames_per_second']=len(pairs)/result['elapsed_seconds']
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('timing',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    with a.timing.open() as f:rows=[{k:int(v) for k,v in r.items()} for r in csv.DictReader(f)]
    result=analyze(rows);result['timing_sha256']=hashlib.sha256(a.timing.read_bytes()).hexdigest();result['analyzer_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
if __name__=='__main__':main()
