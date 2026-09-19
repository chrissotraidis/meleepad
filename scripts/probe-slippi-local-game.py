#!/usr/bin/env python3
"""Run two actual Slippi game runtimes against a loopback-only matchmaking fixture.

Synthetic accounts only. The local assignment is not Slippi service acceptance.
Uses existing passing boot components; never changes the normal app or builds.
"""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import runpy
import shlex
import shutil
import socket
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('boot-probe', 'component-probe', 'build', 'game', 'iso', 'module', 'output'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--input-script', type=Path, required=True)
    parser.add_argument('--module-override', action='store_true',
                        help='Allow a private diagnostic native module override')
    parser.add_argument('--gct-interpreter-fallback', action='store_true',
                        help='Force the private Slippi GCT range through the interpreter')
    parser.add_argument('--interpreter-control', action='store_true', help='Diagnostic interpreter control; no JIT')
    parser.add_argument('--packed-float-control', action='store_true', help='Diagnostic scoped Ishiiruka scalar float semantics')
    parser.add_argument('--guest-item-capture', action='store_true', help='Capture private emulated CPU/object context at item events')
    parser.add_argument('--guest-item-asm-capture', action='store_true', help='Also instrument the private SendItem GCT block; slower diagnostic')
    parser.add_argument('--mod-directory', type=Path,
                        help='Load a private ModernGekko mod directory for a hook diagnostic')
    parser.add_argument('--player-one-input-script', type=Path)
    parser.add_argument('--input-delay-ms', type=int, default=0)
    parser.add_argument("--lan-address", help="Private IPv4 fixture host; uses scoped runtime UDP guard")
    args = parser.parse_args()
    if args.lan_address:
        address=ipaddress.IPv4Address(args.lan_address)
        if not any(address in ipaddress.IPv4Network(n) for n in ("10.0.0.0/8","172.16.0.0/12","192.168.0.0/16")):
            parser.error("LAN fixture must use RFC1918 IPv4")
    if not 0 <= args.input_delay_ms <= 200: parser.error('delay must be 0..200 ms')
    if args.guest_item_asm_capture and not args.guest_item_capture:
        parser.error('--guest-item-asm-capture requires --guest-item-capture')
    if args.module_override and not args.guest_item_asm_capture:
        parser.error('--module-override is reserved for the guest ASM diagnostic')
    if args.mod_directory and not args.mod_directory.is_dir():
        parser.error('--mod-directory must be an existing directory')
    repo = Path(__file__).resolve().parents[1]
    helper = runpy.run_path(str(repo / 'scripts/probe-slippi-peer.py'))
    sha, run = helper['sha256'], helper['run_logged']
    runner_start_sha256 = sha(Path(__file__))
    input_paths = [args.input_script, args.player_one_input_script or args.input_script]
    input_start_sha256 = [sha(p) for p in input_paths]
    boot, component, build, output = [p.resolve() for p in
                                     (args.boot_probe, args.component_probe, args.build, args.output)]
    if output.exists() or subprocess.run(['git', 'check-ignore', '-q', str(output)], cwd=repo).returncode:
        parser.error('use a new ignored output directory')
    old = json.loads((boot / 'results.json').read_text())
    if not old['results'][0].get('game_restore', {}).get('pass'):
        parser.error('requires passing full-packet game-correction boot components')
    source = repo / 'scripts/slippi-boot-probe.cpp'
    if sha(source) != old['harness_sha256']:
        parser.error('boot source differs from accepted harness')
    for name, path in [('main_dol', args.game / 'sys/main.dol'), ('iso', args.iso), ('native_module', args.module)]:
        if name == 'native_module' and args.module_override:
            continue
        if sha(path) != old['input_sha256'][name]:
            parser.error('game/module differs from passing boot evidence')
    for name, expected in old['existing_library_sha256'].items():
        if sha(build / name) != expected:
            parser.error('core archive differs from accepted boot build')
    for name, expected in old['dependency_sha256'].items():
        if sha(component / name) != expected:
            parser.error('dependency differs from accepted boot build')
    rust = repo / 'ref/slippi-compatibility/rust-build-macos-stable/release/libslippi_rust_extensions.a'
    if sha(rust) != old['input_sha256']['rust_archive']:
        parser.error('Rust archive differs')
    output.mkdir(parents=True)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind(('127.0.0.1', 0)); port = sock.getsockname()[1]
    policy = output / 'loopback.sb'
    policy.write_text('''(version 1)
(allow default)
(deny network*)
(allow network-bind (local ip "localhost:*"))
(allow network-inbound (local ip "localhost:*"))
(allow network-outbound (remote ip "localhost:*"))
''')
    sandbox = ['/usr/bin/sandbox-exec', '-f', str(policy)]
    # Verify both allowed loopback delivery and denied non-loopback connection.
    sanity = '''import socket
a=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);a.bind(('127.0.0.1',0));a.settimeout(1)
b=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);b.bind(('127.0.0.1',0))
b.sendto(b'fixture',a.getsockname());assert a.recv(32)==b'fixture'
try:b.connect(('192.0.2.1',443))
except PermissionError:pass
else:raise RuntimeError('sandbox did not deny non-loopback connection')
print('loopback allowed; non-loopback denied')
'''
    run(sandbox + ['/usr/bin/python3', '-c', sanity], output, output / 'sandbox-check.log')
    # The loopback OS test above remains a sanity control; LAN candidates use
    # a linked destination/UDP guard, not a claim of OS network denial.
    process_sandbox = [] if args.lan_address else sandbox
    overlay = output / 'overlay'; shutil.copytree(boot / 'overlay', overlay)
    mm = overlay / 'Core/Slippi/SlippiMatchmaking.cpp'
    text = mm.read_text()
    replacements = {
      'MM_HOST = SlippiCompat::Version().find("dev") == std::string::npos ? MM_HOST_PROD : MM_HOST_DEV;':
      'MM_HOST = "127.0.0.1"; // Local fixture only; OS denies external network.',
      'client_addr.host = ENET_HOST_ANY;':
      'enet_address_set_host_ip(&client_addr, "127.0.0.1");'}
    for before, after in replacements.items():
        if text.count(before) != 1: raise RuntimeError('matchmaking anchor changed')
        text = text.replace(before, after)
    if args.lan_address:
        text=text.replace('127.0.0.1',args.lan_address).replace('OS denies external network.','Linked runtime UDP guard restricts destinations.')
    mm.write_text(text)
    header = overlay / 'Core/Slippi/SlippiMatchmaking.h'
    text = header.read_text(); assert text.count('MM_PORT = 43113;') == 1
    header.write_text(text.replace('MM_PORT = 43113;', f'MM_PORT = {port};'))
    netplay = overlay / 'Core/Slippi/SlippiNetplay.cpp'
    net_text = netplay.read_text()
    net_text = '#include "Core/Slippi/SlippiNetplay.h"\n#include "slippi-local-input-delay.hpp"\n' + net_text
    anchor = '  while (m_do_loop.IsSet())'
    assert net_text.count(anchor) == 1
    net_text = net_text.replace(anchor, f'  SlippiLocalInputDelay::Queue local_delay({args.input_delay_ms});\n' + anchor)
    net_text = net_text.replace('net = enet_host_service(m_client, &net_event, 250);',
        'local_delay.Flush(Common::Timer::NowUs(), [this](sf::Packet& p) { Send(p); });\n    net = enet_host_service(m_client, &net_event, local_delay.PollTimeout(Common::Timer::NowUs()));')
    anchor = '      Send(*(m_async_queue.Front().get()));'
    assert net_text.count(anchor) == 1
    net_text = net_text.replace(anchor, '      local_delay.Submit(*(m_async_queue.Front().get()), Common::Timer::NowUs(), [this](sf::Packet& p) { Send(p); });')
    if args.lan_address:
        net_text=net_text.replace('enet_address_set_host(&local_addr_def, "127.0.0.1"); // Probe binds loopback only.', 'local_addr_def.host = ENET_HOST_ANY; // Explicit local-network diagnostic.')
    netplay.write_text(net_text)
    adapted = source.read_text()
    replacements = {
      '#include <thread>': '''#include <thread>
#include "slippi-online-frame-trace.hpp"
#include "slippi-item-guest-capture.hpp"
#include "Core/Slippi/SlippiNetplay.h"
#include "slippi-local-input-delay.hpp"
#include "Core/HLE/HLE.h"
#include "Common/Logging/LogManager.h"
struct LocalGuestLog final : Common::Log::LogListener {
  void Log(Common::Log::LogLevel, const char* message) override {
    std::fprintf(stderr, "[local-guest-report] %s\\n", message);
  }
};''',
      '  auto created = moderngekko::Runtime::Create(config);': '''  if (const char* mods = std::getenv("SLIPPI_PROBE_MOD_DIRECTORY"); mods && mods[0])
    config.mod_directories.emplace_back(std::filesystem::absolute(mods));
  const char* local_player = std::getenv("SLIPPI_PROBE_LOCAL_PLAYER");
  if (!local_player || (std::string(local_player) != "0" && std::string(local_player) != "1")) return 20;
  std::filesystem::create_directories(config.user_directory / "Slippi");
  {
    std::ofstream account(config.user_directory / "Slippi/user.json");
    account << "{\\"uid\\":\\"offline-local-" << local_player
      << "\\",\\"playKey\\":\\"not-a-real-key-" << local_player
      << "\\",\\"displayName\\":\\"Local fixture\\",\\"connectCode\\":\\"TEST#" << local_player
      << "\\",\\"latestVersion\\":\\"0.0.0-meleepad-dev\\"}";
  }
  auto created = moderngekko::Runtime::Create(config);''',
      '  std::atomic<bool> finished{false};': '''  auto online_trace = std::make_shared<SlippiOnlineFrameTrace>();
  std::shared_ptr<SlippiItemGuestCapture> guest_capture;
  if (std::getenv("SLIPPI_PROBE_GUEST_ITEM_CAPTURE"))
    guest_capture = std::make_shared<SlippiItemGuestCapture>(config.user_directory / "item-guest-context.csv");
  SlippiCompat::game_frame_observer = [online_trace, guest_capture](u8 command, const u8* packet, u32 size) {
    online_trace->Observe(command, packet, size);
    if (guest_capture)
      guest_capture->Observe(command, packet, size);
  };
  std::atomic<bool> finished{false};''',
      '  observer.join();': '''  observer.join();
  SlippiCompat::game_frame_observer = {};
  online_trace->Write(config.user_directory);
  std::fprintf(stderr, "local_input_delay=%llu,%llu,%llu,%llu\\n", SlippiLocalInputDelay::enqueued.load(), SlippiLocalInputDelay::released.load(), SlippiLocalInputDelay::overflow.load(), SlippiLocalInputDelay::max_hold_us.load());''',
      '        const auto& state = guard.GetSystem().GetPPCState();': '''        const auto& state = guard.GetSystem().GetPPCState();
        if (second == 5) {
          auto* logs = Common::Log::LogManager::GetInstance();
          if (logs) {
            logs->RegisterListener(Common::Log::LogListener::LOG_WINDOW_LISTENER, std::make_unique<LocalGuestLog>());
            logs->EnableListener(Common::Log::LogListener::LOG_WINDOW_LISTENER, true);
            logs->SetEnable(Common::Log::LogType::OSREPORT_HLE, true);
          }
          // Fixed start hook formats the report and retains original guest execution.
          HLE::Patch(guard.GetSystem(), 0x803456A8u, "AppLoaderReport");
        }
        if (second == 12) {
          auto& memory = guard.GetSystem().GetMemory();
          std::ofstream ram(config.user_directory / "local-scene-ram.bin", std::ios::binary);
          ram.write(reinterpret_cast<const char*>(memory.GetRAM()), memory.GetRamSizeReal());
          std::ofstream registers(config.user_directory / "local-scene-registers.txt");
          registers << state.pc << ' ' << state.spr[SPR_LR] << '\\n';
          for (unsigned i = 0; i < 32; ++i) registers << state.gpr[i] << '\\n';
        }'''}
    for before, after in replacements.items():
        if adapted.count(before) != 1: raise RuntimeError('main anchor changed')
        adapted = adapted.replace(before, after)
    if args.packed_float_control:
        adapted = '#include "slippi-packed-float-control.hpp"\n' + adapted
        adapted = adapted.replace('  observer.join();', '  observer.join();\n  std::fprintf(stderr, "packed_float_accesses=%llu\\n", SlippiPackedFloatControl::accesses.load());')
    main_source = output / 'slippi-local-game.cpp'; main_source.write_text(adapted)
    db = json.loads((build / 'compile_commands.json').read_text())
    entry = next(e for e in db if e['file'].endswith('/HW/EXI/EXI_Device.cpp'))
    base = shlex.split(entry['command']); base = [a for a in base[:base.index('-o')] if a != '-DOFF']
    base[1:1] = ['-I' + str(p) for p in (overlay, repo / 'scripts', repo / 'ref/ModernGekko/include',
        repo / 'ref/slippi-compatibility/upstream/Externals', repo / 'ref/slippi-compatibility/rust/ffi/includes')]
    flags = ['-DSLIPPI=CORE', '-DSLIPPI_ONLINE=CORE', '-include', str(overlay / 'Core/Slippi/SlippiCompat.h')]
    replacements = []
    for src in (mm, netplay, main_source):
        obj = output / (src.stem + '.o')
        run(base + flags + ['-c', str(src), '-o', str(obj)], entry['directory'], output / (src.stem + '.log'))
        replacements.append(obj)
    packed_source = None
    if args.packed_float_control:
        original = repo / 'ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/Interpreter/Interpreter_LoadStore.cpp'
        packed_text = original.read_text()
        for instruction in ('lfs', 'stfs'):
            start = packed_text.index('void Interpreter::' + instruction + '(')
            end = packed_text.index('\nvoid Interpreter::', start + 1)
            section = packed_text[start:end]
            anchor = 'if ((address & 0b11) != 0)'
            if section.count(anchor) != 1: raise RuntimeError('float alignment anchor changed')
            section = section.replace(anchor, 'if ((address & 0b11) != 0 && !SlippiPackedFloatControl::Allows(ppc_state.pc, address))')
            packed_text = packed_text[:start] + section + packed_text[end:]
        packed_source = output / 'Interpreter_LoadStore.cpp'
        packed_source.write_text('#include "slippi-packed-float-control.hpp"\n' + packed_text)
        obj = output / 'Interpreter_LoadStore.o'
        load_entry = next(e for e in db if e['file'].endswith('/Interpreter/Interpreter_LoadStore.cpp'))
        load_base = shlex.split(load_entry['command'])
        load_base = [a for a in load_base[:load_base.index('-o')] if a != '-DOFF']
        load_base[1:1] = ['-I' + str(overlay), '-I' + str(repo / 'scripts')]
        run(load_base + flags + ['-c', str(packed_source), '-o', str(obj)], load_entry['directory'], output / 'packed-float-compile.log')
        replacements.append(obj)
    if args.lan_address:
        guard_src=repo / 'scripts/slippi-lan-probe-network.cpp'; guard_obj=output / 'lan-network.o'
        run(base + [f'-DSLIPPI_FIXTURE_IPV4="{args.lan_address}"','-c',str(guard_src),'-o',str(guard_obj)],entry['directory'],output/'lan-network-compile.log')
        replacements.append(guard_obj)
    fixture_source = repo / 'scripts/slippi-local-matchmaking.cpp'; fixture = output / 'matchmaking-fixture'
    if args.lan_address:
        fixture_text=fixture_source.read_text().replace('enet_address_set_host_ip(&address, "127.0.0.1");',f'enet_address_set_host_ip(&address, "{args.lan_address}");')
        fixture_text=fixture_text.replace('std::array<unsigned, 2> ports{};', 'std::array<unsigned, 2> ports{};\n  std::array<std::string, 2> addresses{};')
        fixture_text=fixture_text.replace('std::string(ip) != "127.0.0.1" ||','false ||')
        fixture_text=fixture_text.replace('peers[player] = event.peer;', 'addresses[player] = ip; peers[player] = event.peer;')
        fixture_text=fixture_text.replace('"127.0.0.1:" + std::to_string(ports[p])','addresses[p] + ":" + std::to_string(ports[p])')
        fixture_text=fixture_text.replace('loopback_only\\":true','loopback_only\\":false')
        fixture_source=output/'slippi-lan-matchmaking.cpp';fixture_source.write_text(fixture_text)
    fixture_obj = output / 'fixture.o'
    run(base + ['-c', str(fixture_source), '-o', str(fixture_obj)], entry['directory'], output / 'fixture-compile.log')
    enet = build / 'vendor/dolphin/Externals/enet/enet/libenet.a'
    run(['/usr/bin/c++', str(fixture_obj), str(enet), '-o', str(fixture)], output, output / 'fixture-link.log')
    objects = sorted(p for p in boot.glob('*.o') if p.name not in ('slippi-boot-probe.o', 'SlippiMatchmaking.o', 'SlippiNetplay.o'))
    dependencies = [component / n for n in old['dependency_sha256']]
    commands = subprocess.check_output(['ninja', '-t', 'commands', 'moderngekko_netplay_session_test'], cwd=build, text=True)
    command = shlex.split(commands.splitlines()[-1]); command = command[command.index('/usr/bin/c++'):]
    command = command[:command.index('&&')]
    bundle = output / 'SlippiProbe.app'; shutil.copytree(boot / 'SlippiProbe.app', bundle, symlinks=True)
    guest_resource_sha256 = None
    if args.guest_item_asm_capture:
        settings = bundle / 'Contents/Resources/Sys/GameSettings/GALE01r2.ini'
        settings_text = settings.read_text()
        if settings_text.count('C216E74C 00000119 #Recording/SendGameInfo.asm') != 1:
            raise RuntimeError('guest item capture requires the pinned SendGameInfo block')
        if settings_text.count('839D002C 3860003B') != 1:
            raise RuntimeError('guest item capture requires the pinned item loop')
        instrumentation = '''839D002C 7C036378
3D80817F 618C0000
938C0000 906C0040
93AC0004 93EC0008
807C0010 906C0010
807C0024 906C0014
807C002C 906C0018
807C0040 906C001C
807C0044 906C0020
807C004C 906C0024
807C0050 906C0028
807C0518 906C002C
807C0C9C 906C0030
807C0D44 906C0034
807C0DA8 906C0038
887C0DD7 986C003C
887C0DDB 986C003D
887C0DEB 986C003E
887C0DEF 986C003F
818C0040 3860003B'''
        settings_text = settings_text.replace('C216E74C 00000119 #Recording/SendGameInfo.asm',
                                                'C216E74C 0000012C #Recording/SendGameInfo.asm')
        settings_text = settings_text.replace('839D002C 3860003B', instrumentation)
        settings.write_text(settings_text)
        guest_resource_sha256 = sha(settings)
    executable = bundle / 'Contents/MacOS/SlippiProbe'
    command[command.index('-o') + 1] = str(executable)
    index = next(i for i, a in enumerate(command) if a.endswith('netplay_session_test.cpp.o'))
    command[index:index+1] = list(map(str, replacements + objects + dependencies + [rust]))
    for fw in ('CoreFoundation', 'Security', 'AudioToolbox', 'CoreAudio', 'Foundation', 'AudioUnit', 'SystemConfiguration'):
        command += ['-framework', fw]
    command += ['-lresolv', '-liconv']
    run(command, build, output / 'link.log')
    if args.packed_float_control:
        test_src = repo / 'scripts/slippi-packed-float-test.cpp'
        test_obj = output / 'packed-float-test.o'
        run(base + flags + ['-c', str(test_src), '-o', str(test_obj)], entry['directory'], output / 'packed-float-test-compile.log')
        test_command = list(command)
        test_command[test_command.index(str(output / 'slippi-local-game.o'))] = str(test_obj)
        test_executable = output / 'packed-float-test'
        test_command[test_command.index('-o') + 1] = str(test_executable)
        run(test_command, build, output / 'packed-float-test-link.log')
        run(sandbox + [str(test_executable)], output, output / 'packed-float-test.log')
    print('Two-client local game candidate linked', flush=True)
    handles, logs = [], []
    try:
        log = (output / 'fixture.log').open('w'); logs.append(log)
        server = subprocess.Popen(process_sandbox + [str(fixture), str(port)], stdout=log, stderr=subprocess.STDOUT); handles.append(server)
        deadline = time.monotonic() + 3
        while 'fixture ready' not in (output / 'fixture.log').read_text():
            if server.poll() is not None or time.monotonic() > deadline: raise RuntimeError('fixture did not start')
            time.sleep(.05)
        for player in range(2):
            env = {k:v for k,v in os.environ.items() if not k.startswith(('SLIPPI_PROBE_', 'STATICRECOMP_'))}
            env.update(SLIPPI_PROBE_LOCAL_PLAYER=str(player), SLIPPI_PROBE_GROUPS='required',
                       SLIPPI_PROBE_SECONDS='60', SLIPPI_PROBE_GRAPHICS='Metal', SLIPPI_PROBE_SCREENSHOT='1',
                       SLIPPI_PROBE_INPUT_SCRIPT=str(input_paths[player].resolve()))
            if args.interpreter_control:
                env['SLIPPI_PROBE_ALL_INTERPRETER'] = '1'
            if args.guest_item_capture:
                env['SLIPPI_PROBE_GUEST_ITEM_CAPTURE'] = '1'
            if args.mod_directory:
                env['SLIPPI_PROBE_MOD_DIRECTORY'] = str(args.mod_directory.resolve())
                env['SLIPPI_PROBE_HOOK_LOG'] = str((output / f'send-item-hook-{player}.log').resolve())
            if args.gct_interpreter_fallback:
                env['STATICRECOMP_FALLBACK_RANGES'] = '8065cc80-8066aaa0'
            log = (output / f'player-{player}.log').open('w'); logs.append(log)
            handles.append(subprocess.Popen(process_sandbox + [str(executable), str(args.game.resolve()), str(args.iso.resolve()),
                str(args.module.resolve()), str(output / f'user-{player}')], cwd=output, env=env, stdout=log, stderr=subprocess.STDOUT))
        print('Local fixture and two isolated game processes running', flush=True)
        deadline = time.monotonic() + 105
        while any(p.poll() is None for p in handles) and time.monotonic() < deadline:
            time.sleep(.5)
        if any(p.poll() is None for p in handles): raise RuntimeError('bounded local game run timed out')
    finally:
        for p in handles:
            if p.poll() is None: p.kill(); p.wait()
        for log in logs: log.close()
    result = {'scope':'Two local game runtimes with synthetic matchmaking; no live service or desktop interoperability proof',
              'process_exit_codes':[p.returncode for p in handles], 'players':[],
              'base_result_sha256':sha(boot / 'results.json'), 'runner_sha256':runner_start_sha256,
              'runner_unchanged':runner_start_sha256 == sha(Path(__file__)),
              'input_script_sha256':input_start_sha256,
              'input_script_unchanged':input_start_sha256 == [sha(p) for p in input_paths],
              'reused_object_sha256':{p.name:sha(p) for p in objects},
              'fixture_sha256':sha(fixture_source), 'adapted_main_sha256':sha(main_source),
              'guest_resource_sha256':guest_resource_sha256,
              'mod_directory':str(args.mod_directory.resolve()) if args.mod_directory else None,
              'module_override':args.module_override,
              'gct_interpreter_fallback':args.gct_interpreter_fallback,
              'matchmaking_source_sha256':sha(mm), 'matchmaking_header_sha256':sha(header),
              'network_policy_sha256':sha(policy), 'non_loopback_denial_checked':not bool(args.lan_address),
              'lan_fixture':bool(args.lan_address),
              'lan_guard_sha256':sha(repo / 'scripts/slippi-lan-probe-network.cpp') if args.lan_address else None}
    result['input_delay_ms'] = args.input_delay_ms
    result['netplay_source_sha256'] = sha(netplay)
    result['delay_header_sha256'] = sha(repo / 'scripts/slippi-local-input-delay.hpp')
    result['interpreter_control'] = args.interpreter_control
    result['packed_float_control'] = args.packed_float_control
    result['guest_item_capture'] = args.guest_item_capture
    result['guest_item_asm_capture'] = args.guest_item_asm_capture
    if packed_source:
        result['packed_float_source_sha256'] = sha(packed_source)
        result['packed_float_guard_sha256'] = sha(repo / 'scripts/slippi-packed-float-control.hpp')
        result['packed_float_test_sha256'] = sha(repo / 'scripts/slippi-packed-float-test.cpp')
        result['packed_float_unit_log'] = (output / 'packed-float-test.log').read_text()
        result['packed_float_accesses'] = []
        for player in range(2):
            lines = (output / f'player-{player}.log').read_text(errors='replace').splitlines()
            result['packed_float_accesses'].append([int(x.split('=')[1]) for x in lines if x.startswith('packed_float_accesses=')])
    for player in range(2):
        log = (output / f'player-{player}.log').read_text(errors='replace')
        summaries = [json.loads(s) for s in log.splitlines() if s.startswith('{"boot_error"')]
        result['players'].append({'player':player, 'runtime':summaries[-1] if summaries else None,
           'matchmaking_ticket_accepted':'Request ticket success' in log,
           'opponent_assigned':'Opponent found.' in log,
           'input_delay_counters':[[int(x) for x in line.split('=')[1].split(',')] for line in log.splitlines() if line.startswith('local_input_delay=')]})
    result['online_engine_entered'] = all(p['opponent_assigned'] and p['runtime'] and
        p['runtime']['commands'].get('b0', 0) > 0 and p['runtime']['commands'].get('3c', 0) > 0
        and p['runtime']['memory_errors'] == 0 and p['runtime']['graphics_errors'] == 0
        for p in result['players'])
    result['cross_client_state_agreement_tested'] = False
    (output / 'results.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2), flush=True)
    return 0 if result['online_engine_entered'] and all(p.returncode == 0 for p in handles) else 1


if __name__ == '__main__':
    raise SystemExit(main())
