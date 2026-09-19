#!/usr/bin/env python3
"""Frame-driven controller for the synthetic Mac lab, never a public opponent."""
import json
import os
from pathlib import Path
import sys
import time
import enet
import melee

# Keep libmelee's otherwise wildcard ENet client binding inside the OS sandbox.
original_host = enet.Host
def loopback_host(address, *args, **kwargs):
    return original_host(address or enet.Address(b'127.0.0.1', 0), *args, **kwargs)
enet.Host = loopback_host

def main():
    out=Path(sys.argv[1]).resolve()
    console=melee.Console(is_remote=True, dolphin_home_path=str(out/'reference-user'),
        tmp_home_directory=False, copy_home_directory=False, slippi_port=51549,
        polling_mode=False, skip_rollback_frames=False, setup_gecko_codes=False)
    controller=melee.Controller(console,1)
    helper=melee.MenuHelper()
    fixed_script = []
    fixed_script_path = os.environ.get('MELEEPAD_REFERENCE_GAMEPLAY_SCRIPT')
    if fixed_script_path:
        elapsed_by_second = {}
        for line_number, line in enumerate(Path(fixed_script_path).read_text().splitlines(), 1):
            if not line.strip():
                continue
            fields = line.split()
            if len(fields) != 6:
                raise RuntimeError(f'invalid shared input line {line_number}')
            second, source_port, button = int(fields[0]), int(fields[1]), fields[2]
            x, y, duration_ms = float(fields[3]), float(fields[4]), int(fields[5])
            if source_port != 0:
                raise RuntimeError(f'shared input must target native port 0: line {line_number}')
            if second < 25:
                continue
            start_ms = (second - 25) * 1000 + elapsed_by_second.get(second, 0)
            elapsed_by_second[second] = elapsed_by_second.get(second, 0) + duration_ms
            fixed_script.append((start_ms, start_ms + duration_ms, button, x, y))
        if not fixed_script:
            raise RuntimeError('shared gameplay input script is empty')
        print(f'shared gameplay schedule loaded: {fixed_script_path}',flush=True)
    (out/'controller-ready').write_text('ready\n')
    started=time.monotonic(); gameplay_started=None; frames=0; game_frames=0; states=set(); last=None
    try:
        if not console.connect(): raise RuntimeError('local reference frame stream unavailable')
        print('stream connected',flush=True)
        controller.connect(); controller.release_all(); controller.flush(); print('pipe connected',flush=True)
        while time.monotonic()-started<110:
            state=console.step()
            if state is None:
                time.sleep(.001); continue
            if frames<5: print('frame',state.frame,state.menu_state.name,flush=True)
            frames+=1; states.add(state.menu_state.name); last=int(state.frame)
            controller.release_all()
            if state.menu_state == melee.Menu.IN_GAME:
                if gameplay_started is None:
                    gameplay_started = time.monotonic()
                game_frames+=1
                if fixed_script:
                    elapsed_ms = int((time.monotonic() - gameplay_started) * 1000)
                    shared_event = next((event for event in fixed_script
                                         if event[0] <= elapsed_ms < event[1]), None)
                    if shared_event:
                        _, _, button, x, y = shared_event
                        # The native fixture uses centered coordinates in
                        # [-1, 1]; libmelee's pipe API uses [0, 1].
                        controller.tilt_analog(melee.Button.BUTTON_MAIN,
                                               (x + 1.0) / 2.0,
                                               (y + 1.0) / 2.0)
                        if button != 'None':
                            controller.press_button(getattr(melee.Button, {
                                'A': 'BUTTON_A', 'B': 'BUTTON_B', 'Start': 'BUTTON_START'
                            }[button]))
                else:
                    # Alternate motion and a normal attack in the default lab mode.
                    if state.frame>120:
                        controller.tilt_analog(melee.Button.BUTTON_MAIN,.65 if (state.frame//90)%2 else .35,.5)
                        if state.frame % 45 < 5: controller.press_button(melee.Button.BUTTON_A)
            elif state.menu_state == melee.Menu.MAIN_MENU:
                if state.frame % 2:
                    if state.submenu == melee.SubMenu.ONLINE_PLAY_SUBMENU:
                        if state.menu_selection == 1: controller.press_button(melee.Button.BUTTON_A)
                        else: controller.tilt_analog(melee.Button.BUTTON_MAIN,.5,0)
                    else: controller.press_button(melee.Button.BUTTON_A)
            elif state.menu_state == melee.Menu.PRESS_START:
                if state.frame % 2: controller.press_button(melee.Button.BUTTON_START)
            elif state.menu_state == melee.Menu.SLIPPI_ONLINE_CSS:
                helper.choose_character(melee.Character.DOC,state,controller,costume=0,start=True)
            elif state.menu_state == melee.Menu.POSTGAME_SCORES:
                helper.skip_postgame(controller)
            if frames%60==0:
                (out/'controller-status.json').write_text(json.dumps({'observed_frames':frames,'game_frames':game_frames,'last_frame':last,'menus':sorted(states),'hardware_used':False,'crossplay_accepted':False})+'\n')
    finally:
        (out/'controller-finished').write_text('finished\n')
        (out/'controller-status.json').write_text(json.dumps({'observed_frames':frames,'game_frames':game_frames,'last_frame':last,'menus':sorted(states),'hardware_used':False,'crossplay_accepted':False})+'\n')
        controller.disconnect()

if __name__ == '__main__': main()
