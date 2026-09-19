#!/usr/bin/env python3
"""Synthetic adversarial controls for finalized Slippi timeline comparison."""
import csv
import json
from pathlib import Path
import runpy
import struct
import tempfile
import unittest

api=runpy.run_path(str(Path(__file__).with_name('analyze-slippi-local-game.py')))

def frame(number,finalized,value=0):
    prefix=struct.pack('>i',number)
    packets=[bytes([0x3a])+prefix+bytes(7)+bytes([value]),
             bytes([0x38])+prefix+bytes([0,0])+bytes(77)+bytes([value]),
             bytes([0x38])+prefix+bytes([1,0])+bytes(77)+bytes([value]),
             bytes([0x3c])+prefix+struct.pack('>i',finalized)]
    return [{'command':str(p[0]),'payload':p.hex()} for p in packets]

class Controls(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
    def tearDown(self):self.temp.cleanup()
    def write(self,name,rows,overflow=False,**status):
        d=self.root/name;d.mkdir();p=d/'online-frame-packets.csv'
        with p.open('w') as file:
            w=csv.DictWriter(file,fieldnames=['command','payload']);w.writeheader();w.writerows(rows)
        p.with_name('online-frame-trace.json').write_text(json.dumps({'packets':len(rows),'overflow':overflow,**status}))
        return p
    def test_actual_revision_replaces_prediction(self):
        rows=frame(-123,-123)+frame(-122,-123,1)+frame(-121,-123,1)+frame(-122,-122,2)+frame(-121,-121,2)
        final,meta=api['read_rollback_trace'](self.write('revision',rows))
        self.assertEqual(meta['rewind_events'],1);self.assertEqual(meta['changed_prediction_frame_events'],2)
        self.assertEqual(final[-122][1][-1],2)
    def test_finalized_frame_cannot_change(self):
        with self.assertRaises(ValueError):api['read_rollback_trace'](self.write('bad',frame(-123,-123)+frame(-123,-123,2)))
    def test_finalization_cannot_regress(self):
        with self.assertRaises(ValueError):api['read_rollback_trace'](self.write('bad',frame(-123,-123)+frame(-122,-124)))
    def test_no_skipped_frame(self):
        with self.assertRaises(ValueError):api['read_rollback_trace'](self.write('bad',frame(-123,-123)+frame(-121,-121)))
    def test_missing_player(self):
        rows=frame(-123,-123);rows.pop(1)
        with self.assertRaises(ValueError):api['read_rollback_trace'](self.write('bad',rows))
    def test_truncated_player_packet(self):
        rows=frame(-123,-123);rows[1]["payload"]=rows[1]["payload"][:-2]
        with self.assertRaises(ValueError):api["read_rollback_trace"](self.write("bad",rows))
    def test_overflow(self):
        with self.assertRaises(ValueError):api['read_rollback_trace'](self.write('bad',frame(-123,-123),True))
    def test_unfinished_group(self):
        with self.assertRaises(ValueError):api['read_rollback_trace'](self.write('bad',frame(-123,-123)[:-1]))
    def test_corruption_detected(self):
        a=sum((frame(f,f) for f in range(-123,200)),[])
        b=sum((frame(f,f,1 if f==100 else 0) for f in range(-123,200)),[])
        left=self.write('a',a);right=self.write('b',b)
        result=api['compare_rollback'](left,right)
        self.assertFalse(result['pass']);self.assertEqual(result['first_mismatching_frame'],100)
        self.assertTrue(api['compare_rollback'](left,left)['pass'])
    def test_tail_explicitly_excluded(self):
        a=sum((frame(f,f) for f in range(-123,200)),[])+frame(200,199,2)
        p=self.write('tail',a);result=api['compare_rollback'](p,p)
        self.assertTrue(result['pass']);self.assertEqual(result['last_frame'],199)
        self.assertEqual(result['clients'][0]['unfinalized_tail_frames'],1)
    def test_sequence_error_rejected_in_both_modes(self):
        p=self.write('sequence',frame(-123,-123),sequence_error=True,game_ended=True)
        for reader in ('read_trace','read_rollback_trace'):
            with self.subTest(reader=reader), self.assertRaises(ValueError):api[reader](p)
    def test_complete_match_requires_end_in_both_modes(self):
        rows=sum((frame(f,f) for f in range(-123,200)),[])
        left=self.write('left',rows,game_ended=True)
        right=self.write('right',rows,game_ended=False)
        for comparator in ('compare','compare_rollback'):
            with self.subTest(comparator=comparator):
                prefix=api[comparator](left,right)
                self.assertTrue(prefix['pass']);self.assertEqual(prefix['game_ended'],[True,False])
                self.assertFalse(api[comparator](left,right,require_complete_match=True)['pass'])
    def test_strict_complete_match_requires_beginning(self):
        p=self.write('partial',frame(100,100),game_ended=True)
        self.assertTrue(api['compare'](p,p)['pass'])
        self.assertFalse(api['compare'](p,p,require_complete_match=True)['pass'])
    def test_complete_match_rejects_excluded_frames(self):
        rows=sum((frame(f,f) for f in range(-123,200)),[])
        left=self.write('left',rows,game_ended=True)
        for name,extra in [('unfinalized',frame(200,199)),('outside',frame(200,200))]:
            right=self.write(name,rows+extra,game_ended=True)
            self.assertTrue(api['compare_rollback'](left,right)['pass'])
            self.assertFalse(api['compare_rollback'](left,right,require_complete_match=True)['pass'])
    def test_completed_emitted_match_passes(self):
        rows=sum((frame(f,f) for f in range(-123,200)),[])
        left=self.write('left',rows,game_ended=True);right=self.write('right',rows,game_ended=True)
        for comparator in ('compare','compare_rollback'):
            self.assertTrue(api[comparator](left,right,require_complete_match=True)['pass'])
        self.assertFalse(api['compare_rollback'](left,right,require_changed_rollback=True)['pass'])
    def test_changed_rollback_gate_requires_changed_prediction(self):
        final=sum((frame(f,f,2 if f==-122 else 0) for f in range(-123,200)),[])
        right=self.write('right',final,game_ended=True)
        for name,value,expected in [('changed',1,True),('unchanged',2,False)]:
            rows=frame(-123,-123)+frame(-122,-123,value)+frame(-122,-122,2)+sum((frame(f,f) for f in range(-121,200)),[])
            left=self.write(name,rows,game_ended=True)
            result=api['compare_rollback'](left,right,require_complete_match=True,require_changed_rollback=True)
            self.assertEqual(result['pass'],expected);self.assertTrue(result['rollback_timeline_observed'])
    def test_excessive_unfinalized_tail(self):
        rows=frame(-123,-123)+sum((frame(f,-123) for f in range(-122,-110)),[])
        with self.assertRaises(ValueError):api['read_rollback_trace'](self.write('bad',rows))
    def test_game_end_finalizes_bounded_tail(self):
        rows=sum((frame(f,f) for f in range(-123,200)),[])+frame(200,199)+frame(201,199)
        p=self.write('ended-tail',rows,game_ended=True)
        for comparator in ('compare','compare_rollback'):
            result=api[comparator](p,p,require_complete_match=True)
            self.assertTrue(result['pass']);self.assertEqual(result['last_frame'],201)
        _,meta=api['read_rollback_trace'](p)
        self.assertEqual(meta['bookend_last_finalized_frame'],199)
        self.assertEqual(meta['frames_finalized_at_game_end'],2)
        self.assertEqual(meta['unfinalized_tail_frames'],0)
    def test_game_end_tail_mismatch_is_not_excluded(self):
        rows=sum((frame(f,f) for f in range(-123,200)),[])
        left=self.write('left',rows+frame(200,199,1),game_ended=True)
        right=self.write('right',rows+frame(200,199,2),game_ended=True)
        for comparator in ('compare','compare_rollback'):
            self.assertFalse(api[comparator](left,right,require_complete_match=True)['pass'])
    def test_game_end_does_not_repair_incomplete_tail(self):
        rows=frame(-123,-123)+frame(-122,-123)[:-1]
        p=self.write('incomplete-ended',rows,game_ended=True)
        for reader in ('read_trace','read_rollback_trace'):
            with self.assertRaises(ValueError):api[reader](p)
    def test_game_end_does_not_repair_uncaught_rollback(self):
        rows=frame(-123,-123)+frame(-122,-123)+frame(-121,-123)+frame(-122,-123,2)
        with self.assertRaises(ValueError):
            api['read_rollback_trace'](self.write('uncaught',rows,game_ended=True))
    def test_game_end_does_not_allow_excessive_tail(self):
        rows=frame(-123,-123)+sum((frame(f,-123) for f in range(-122,-110)),[])
        p=self.write('excessive-ended',rows,game_ended=True)
        for reader in ('read_trace','read_rollback_trace'):
            with self.assertRaises(ValueError):api[reader](p)

if __name__=='__main__':
    result=unittest.TextTestRunner().run(unittest.defaultTestLoader.loadTestsFromTestCase(Controls))
    print(json.dumps({'tests':result.testsRun,'failures':len(result.failures),'errors':len(result.errors),'pass':result.wasSuccessful()}))
    raise SystemExit(0 if result.wasSuccessful() else 1)
