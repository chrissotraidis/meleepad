#!/usr/bin/env python3
"""Bounded Mac-only reference/native pairing. Synthetic identities, OS loopback sandbox."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import signal
import subprocess
import time


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('output', type=Path)
    ap.add_argument('--module', type=Path, help='Private diagnostic native module override')
    ap.add_argument('--native-interpreter', action='store_true',
                    help='Run the native-side probe with the full PowerPC interpreter')
    ap.add_argument('--native-item-host-hook', type=Path,
                    help='Load a private native item host-hook mod for paired capture')
    ap.add_argument('--reference-interpreter', action='store_true',
                    help='Run the reference-side guest with the full PowerPC interpreter')
    ap.add_argument('--reference-full-codes', action='store_true',
                    help='Enable the reference bundle\'s full default six-group code set')
    ap.add_argument('--reference-item-capture', action='store_true',
                    help='Capture reference-side itemData candidates at the EXI item boundary')
    args = ap.parse_args()
    repo = Path(__file__).resolve().parents[1]
    base = repo/'ref/slippi-compatibility'
    if args.native_item_host_hook and not args.native_item_host_hook.is_dir():
        ap.error('--native-item-host-hook must be an existing ModernGekko mod directory')
    out = args.output.resolve()
    if subprocess.run(['git', 'check-ignore', '-q', str(out)], cwd=repo).returncode:
        ap.error('use a fresh ignored test output directory')
    out.mkdir(parents=True, exist_ok=False)
    reference = base/'ishiiruka-build-002/Binaries/SlippiReferenceLab.app'
    bundle = out/'SlippiReferenceLab.app'; shutil.copytree(reference,bundle,symlinks=True)
    shutil.copytree(base/'ishiiruka-reference-001/Data/Sys', bundle/'Contents/Resources/Sys')
    plist = bundle/'Contents/Info.plist'
    info = plistlib.loads(plist.read_bytes()); info['CFBundleIdentifier']='com.meleepad.SlippiReferenceLab'
    info.update(CFBundleExecutable='SlippiReferenceLab', CFBundleDisplayName='Slippi Reference Lab', CFBundleName='SlippiReferenceLab')
    plist.write_bytes(plistlib.dumps(info))
    subprocess.run(['codesign','--force','--sign','-',str(bundle)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
    user = out/'reference-user'; (user/'Config').mkdir(parents=True)
    (user/'Pipes').mkdir()
    account=out/'synthetic-account'; account.mkdir(mode=0o700)
    (account/'user.json').write_text(json.dumps({'uid':'offline-local-1','playKey':'not-a-real-key-1','displayName':'Local fixture 1','connectCode':'TEST#1','latestVersion':'3.6.4'}))
    os.chmod(account/'user.json',0o600)
    replay=out/'replays'; replay.mkdir()
    (user/'Config/Dolphin.ini').write_text(f'''[Analytics]
Enabled = False
PermissionAsked = True
[Interface]
ConfirmStop = False
UsePanicHandlers = False
PauseOnFocusLost = False
[Display]
RenderToMain = True
[Core]
EnableCheats = True
CPUCore = {0 if args.reference_interpreter else 1}
CPUThread = True
DSPHLE = True
GFXBackend = OGL
SIDevice0 = 6
SIDevice1 = 0
SIDevice2 = 0
SIDevice3 = 0
SlippiSaveReplays = True
SlippiReplayDir = {replay}
SlippiReplayMonthFolders = False
BlockingPipes = True
SlippiEnableSpectator = True
SlippiSpectatorLocalPort = 51549
[Input]
BackgroundInput = True
[DSP]
Backend = Null
''')
    (user/'Config/Logger.ini').write_text('[Options]\nWriteToFile = True\nVerbosity = 4\n[Logs]\nSLIPPI = True\nSLIPPI_ONLINE = True\nBOOT = True\nCORE = True\n')
    # Match the native diagnostic subset explicitly; full defaults remain a separate gate.
    (user/'GameSettings').mkdir()
    settings_path = user/'GameSettings/GALE01r2.ini'
    if args.reference_full_codes:
        settings_path.write_text((bundle/'Contents/Resources/Sys/GameSettings/GALE01r2.ini').read_text())
    else:
        settings_path.write_text('''[Gecko_Disabled]
$Recommended: Normal Lag Reduction
$Recommended: Apply Delay to all In-Game Scenes
$Recommended: Lagless FoD
''')
    # libmelee's menu observer emits 0x3e and skips in-game scenes.
    # Keep this distinct from the three pinned gameplay code groups.
    menu_ini=base/'reference-controller-tools/lib/python3.11/site-packages/melee/GALE01r2.ini'
    menu_text=menu_ini.read_text()
    menu_code=menu_text.split('$Optional: Extract Menu Info [altf4, Fizzi]',1)[1].split('$Optional: Instant Match',1)[0]
    with (user/'GameSettings/GALE01r2.ini').open('a') as f:
        f.write('[Gecko_Enabled]\n$Optional: Extract Menu Info\n[Gecko]\n$Optional: Extract Menu Info [altf4, Fizzi]'+menu_code)
    if args.reference_item_capture:
        reference_ini=(bundle/'Contents/Resources/Sys/GameSettings/GALE01r2.ini').read_text()
        reference_lines=reference_ini.splitlines()
        gecko_start=reference_lines.index('[Gecko]')
        recording_start=next(i for i, line in enumerate(reference_lines[gecko_start:], gecko_start)
                             if line.startswith('$Required: Slippi Recording'))
        recording_end=next((i for i in range(recording_start + 1, len(reference_lines))
                            if reference_lines[i].startswith('$')), len(reference_lines))
        recording_code='\n'.join(reference_lines[recording_start:recording_end])
        if recording_code.count('907F001E 807C001C') != 1:
            raise RuntimeError('reference item pointer diagnostic requires the pinned SendGameInfo pair')
        recording_code=recording_code.replace('907F001E 807C001C', '907F001E 7F83E378')
        reference_settings_path=bundle/'Contents/Resources/Sys/GameSettings/GALE01r2.ini'
        reference_settings_path.write_text(reference_ini.replace('907F001E 807C001C', '907F001E 7F83E378'))
    policy=out/'loopback.sb'
    private = Path.home()/'Library/Application Support/com.project-slippi.dolphin'
    policy.write_text('''(version 1)
(allow default)
(deny network*)
(allow network-bind (local ip "localhost:*"))
(allow network-inbound (local ip "localhost:*"))
(allow network-outbound (remote ip "localhost:*"))
''' + f'(deny file-read* file-write* (subpath "{private}"))\n')
    sandbox=['/usr/bin/sandbox-exec','-f',str(policy)]
    check='''import socket,os
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.bind(('127.0.0.1',0));s.settimeout(1);s.sendto(b'lab',s.getsockname());assert s.recv(8)==b'lab'
try:s.connect(('192.0.2.1',443))
except PermissionError:pass
else:raise RuntimeError('external destination was allowed')
try:os.listdir(os.environ['LAB_DENIED_DIR'])
except PermissionError:pass
else:raise RuntimeError('owner directory was readable')
print('loopback allowed, external networking and owner directory denied')
'''
    with (out/'sandbox-check.log').open('w') as f:
        subprocess.run(sandbox+['/usr/bin/python3','-c',check],env={**os.environ,'LAB_DENIED_DIR':str(private)},stdout=f,stderr=subprocess.STDOUT,check=True)
    src=(repo/'scripts/slippi-local-matchmaking.cpp').read_text()
    src=src.replace('request.value("appVersion", "") != "0.0.0-meleepad-dev"','request.value("appVersion", "") != (player == 0 ? "0.0.0-meleepad-dev" : "3.6.4")')
    fixture_source=out/'fixture.cpp'; fixture_source.write_text(src)
    fixture=out/'fixture'
    subprocess.run(['clang++','-std=c++17','-I'+str(repo/'ref/ModernGekko/vendor/dolphin/Externals/enet/enet/include'),'-I'+str(base/'ishiiruka-reference-001/Externals'),str(fixture_source),str(repo/'ref/ModernGekko/build-desktop-tools-meleepad-netplay/vendor/dolphin/Externals/enet/enet/libenet.a'),'-o',str(fixture)],check=True)
    native_input=out/'native-input.txt'
    native_input.write_text('\n'.join(l for l in (repo/'scripts/fixtures/slippi-local-online-active-0.txt').read_text().splitlines() if ' Start ' not in l or l.startswith('16 '))+'\n')
    native_module = args.module.resolve() if args.module else base/'native-gct-001/module-build/gGALE01_recomp.dylib'
    native_probe = base/('local-online-hook-003' if args.native_item_host_hook else 'local-online-011')/'SlippiProbe.app'
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    (out/'configuration-manifest.json').write_text(json.dumps({
        'native_module_sha256': sha(native_module),
        'reference_binary_sha256': sha(bundle/'Contents/MacOS/SlippiReferenceLab'),
        'game_code_configuration_sha256': sha(user/'GameSettings/GALE01r2.ini'),
        'reference_game_code_configuration_sha256': sha(bundle/'Contents/Resources/Sys/GameSettings/GALE01r2.ini'),
        'controller_sha256': sha(repo/'scripts/slippi-reference-controller.py'),
        'driver_sha256': sha(Path(__file__)),
        'module_override': bool(args.module), 'reference_item_capture': args.reference_item_capture,
        'reference_item_pointer_capture': args.reference_item_capture,
        'reference_item_instruction_capture': args.reference_item_capture,
        'reference_interpreter': args.reference_interpreter,
        'reference_full_codes': args.reference_full_codes,
        'reference_gct_capture': args.reference_full_codes and args.reference_item_capture,
        'native_item_host_hook': bool(args.native_item_host_hook),
        'native_item_host_hook_sha256': (sha(args.native_item_host_hook/'slippi-send-item-hook.mgm.dylib')
                                         if args.native_item_host_hook else None),
        'native_probe_binary_sha256': sha(native_probe/'Contents/MacOS/SlippiProbe'),
        'hardware_used': False,
        'public_service_used': False,
    }, indent=2)+'\n')
    processes=[]; logs=[]
    try:
        def start(name,command,env):
            f=(out/(name+'.log')).open('w'); logs.append(f)
            p=subprocess.Popen(sandbox+command,cwd=out,env=env,stdout=f,stderr=subprocess.STDOUT,start_new_session=True);processes.append(p);return p
        env={k:v for k,v in os.environ.items() if not k.startswith(('SLIPPI_','STATICRECOMP_'))}
        fixture_ports = ['55665', '61773'] if args.native_item_host_hook else ['61773']
        fixture_process=start('fixture',[str(fixture),*fixture_ports],env)
        time.sleep(.3)
        if fixture_process.poll() is not None: raise RuntimeError('fixture failed to bind')
        control=start('controller',[str(base/'reference-controller-tools/bin/python3'),str(repo/'scripts/slippi-reference-controller.py'),str(out)],env)
        ready_deadline=time.monotonic()+8
        while not (out/'controller-ready').exists():
            if control.poll() is not None or time.monotonic()>ready_deadline: raise RuntimeError('frame controller did not initialize')
            time.sleep(.05)
        native_env={**env,'SLIPPI_PROBE_LOCAL_PLAYER':'0','SLIPPI_PROBE_GROUPS':'required','SLIPPI_PROBE_SECONDS':'60','SLIPPI_PROBE_GRAPHICS':'Metal','SLIPPI_PROBE_SCREENSHOT':'1','SLIPPI_PROBE_INPUT_SCRIPT':str(native_input)}
        if args.native_interpreter:
            native_env['SLIPPI_PROBE_ALL_INTERPRETER']='1'
        if args.native_item_host_hook:
            native_env['SLIPPI_PROBE_MOD_DIRECTORY'] = str(args.native_item_host_hook.resolve())
            native_env['SLIPPI_PROBE_HOOK_LOG'] = str((out/'native-item-host-hook.log').resolve())
            native_env['SLIPPI_PROBE_SPAWN_HOOK_LOG'] = str((out/'native-item-spawn-hook.log').resolve())
            native_env['STATICRECOMP_FALLBACK_RANGES'] = '8065cc80-8066aaa0'
        reference_env={**env,'SLIPPI_REFERENCE_ACCOUNT_DIR':str(account)}
        if args.reference_item_capture:
            reference_env['SLIPPI_REFERENCE_ITEM_CAPTURE_PATH']=str((out/'reference-item-capture.log').resolve())
            reference_env['SLIPPI_REFERENCE_ITEM_INSTRUCTION_CAPTURE_PATH']=str(
                (out/'reference-item-instruction-capture.log').resolve())
            reference_env['SLIPPI_REFERENCE_ITEM_SPAWN_CAPTURE_PATH']=str(
                (out/'reference-item-spawn-capture.log').resolve())
            if args.reference_full_codes:
                reference_env['SLIPPI_REFERENCE_GCT_CAPTURE_PATH']=str(
                    (out/'reference-post-handler-gct.bin').resolve())
        reference_command=[str(bundle/'Contents/MacOS/SlippiReferenceLab'),'-b','-e',
                           str(base.parent/'revision-102/GALE01-r2.iso'),'-u',str(user),'-c','false',
                           '--slippi-spectator-port','51549']
        native_command=[str(native_probe/'Contents/MacOS/SlippiProbe'),
                        str(base.parent/'revision-102/extracted'),str(base.parent/'revision-102/GALE01-r2.iso'),
                        str(native_module),str(out/'user-0')]
        if args.native_item_host_hook:
            reference_process=start('reference',reference_command,reference_env)
            time.sleep(1)
            native=start('native',native_command,native_env)
        else:
            native=start('native',native_command,native_env)
            reference_process=start('reference',reference_command,reference_env)
        print('Reference and native processes started; bounded to 115 seconds',flush=True)
        started=time.monotonic()
        while time.monotonic()-started<115:
            if reference_process.poll() is not None or control.poll() is not None or (out/'controller-finished').exists(): break
            elapsed=time.monotonic()-started
            if elapsed>95 and native.poll() is not None:break
            time.sleep(.05)
        (out/'run-status.json').write_text(json.dumps({'reference_exit_before_cleanup':reference_process.poll(),'native_exit_before_cleanup':native.poll(),'fixture_exit_before_cleanup':fixture_process.poll(),'controller_exit_before_cleanup':control.poll(),'elapsed_seconds':time.monotonic()-started,'hardware_used':False,'crossplay_accepted':False},indent=2)+'\n')
    finally:
        for p in processes:
            if p.poll() is None:os.killpg(p.pid,signal.SIGTERM)
        for p in processes:
            try:p.wait(timeout=5)
            except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
        for f in logs:f.close()

if __name__=='__main__':main()
