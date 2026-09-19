#!/usr/bin/env python3
"""Build a separate private iPad native Slippi target; never signs, installs or runs it.

Uses pinned accepted archives/game data, recompiles the full Slippi adapter with
a truthful fork version, and omits synthetic users, scripts and LAN fixtures.
Output contains owner-supplied game content and must never be distributed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import runpy
import shlex
import shutil
import subprocess


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError('Pinned source anchor changed: ' + old[:70])
    return text.replace(old, new)


def patch_network_diagnostics(text):
    text = '#include "slippi-network-diagnostics.hpp"\n' + text
    text = replace_once(text, '#ifdef __linux__\n    // highest priority', '''#ifdef __APPLE__
    // Match official Slippi 3.6.4's Apple latency-sensitive socket classification.
    int service_type = NET_SERVICE_TYPE_RV;
    slippi_network_diagnostics.apple_service_result.store(
        setsockopt(m_server[i]->host->socket, SOL_SOCKET, SO_NET_SERVICE_TYPE,
                   &service_type, sizeof(service_type)), std::memory_order_relaxed);
#endif
#ifdef __linux__
    // highest priority''')
    text = replace_once(text, '    ping_us[p_idx] = Common::Timer::NowUs() - send_time;',
        '    ping_us[p_idx] = Common::Timer::NowUs() - send_time;\n'
        '    slippi_network_diagnostics.ObservePing(ping_us[p_idx]);')
    text = replace_once(text,
        '        if (is_connected_client && all_peers_disconnected_for_key)\n        {',
        '        if (is_connected_client && all_peers_disconnected_for_key)\n        {\n'
        '          ++slippi_network_diagnostics.peer_disconnects;\n'
        '          slippi_network_diagnostics.peer_reason.store(net_event.data, std::memory_order_relaxed);')
    return text


def patch_queue_diagnostics(text):
    text = replace_once(text, '    net = enet_host_service(m_client, &net_event, 250);',
        '    net = enet_host_service(m_client, &net_event, 250);\n'
        '    for (const auto* peer : m_server)\n'
        '      slippi_network_diagnostics.ObserveThrottle(peer->packetThrottle);')
    text = replace_once(text, '    m_async_queue.Push(std::move(packet));',
        '    m_async_queue.Push(QueuedPacket{std::move(packet), Common::Timer::NowUs()});')
    text = replace_once(text, '  while (m_do_loop.IsSet())\n  {',
        '  u64 previous_loop_us = Common::Timer::NowUs();\n'
        '  while (m_do_loop.IsSet())\n  {\n'
        '    const u64 loop_now_us = Common::Timer::NowUs();\n'
        '    SlippiNetworkDiagnostics::RecordMaximum(slippi_network_diagnostics.loop_max_us,\n'
        '        loop_now_us - previous_loop_us);\n'
        '    previous_loop_us = loop_now_us;')
    text = replace_once(text, '      Send(*(m_async_queue.Front().get()));',
        '      auto& queued = m_async_queue.Front();\n'
        '      slippi_network_diagnostics.ObserveQueue(Common::Timer::NowUs() - queued.enqueued_us);\n'
        '      Send(*queued.packet);')
    text = replace_once(text, '    enet_peer_send(m_server[i], channel_id, epac);',
        '    if (enet_peer_send(m_server[i], channel_id, epac) != 0)\n'
        '      ++slippi_network_diagnostics.send_failures;\n'
        '    slippi_network_diagnostics.enet_rtt_ms.store(m_server[i]->roundTripTime, std::memory_order_relaxed);\n'
        '    slippi_network_diagnostics.enet_rtt_variance_ms.store(m_server[i]->roundTripTimeVariance, std::memory_order_relaxed);\n'
        '    slippi_network_diagnostics.enet_packet_loss.store(m_server[i]->packetLoss, std::memory_order_relaxed);')
    return text



def patch_network_flush(text):
    # enet_host_service may return a queued receive before sending anything.
    # Flush on the owning thread after both async inputs and receive-side ACKs.
    anchor = '  }\n\n#ifdef _WIN32\n  if (m_qos_handle != 0)'
    return replace_once(text, anchor,
        '    // Dispatching queued receives can bypass ENet outgoing service.\n'
        '    // Send this batch of inputs and ACKs before the next receive event.\n'
        '    enet_host_flush(m_client);\n' + anchor)



def patch_network_timing(text):
    text = replace_once(text, '    net = enet_host_service(m_client, &net_event, 250);',
        '    const auto sent_before = m_client->totalSentPackets;\n'
        '    const auto received_before = m_client->totalReceivedPackets;\n'
        '    net = enet_host_service(m_client, &net_event, 250);\n'
        '    const u64 work_start_us = Common::Timer::NowUs();\n'
        '    if (net < 0) ++slippi_network_diagnostics.service_errors;\n'
        '    if (net > 0 && net_event.type == ENET_EVENT_TYPE_RECEIVE)\n'
        '      ++slippi_network_diagnostics.receive_events;')
    return replace_once(text, '    enet_host_flush(m_client);',
        '    const u64 flush_start_us = Common::Timer::NowUs();\n'
        '    enet_host_flush(m_client);\n'
        '    const u64 work_end_us = Common::Timer::NowUs();\n'
        '    ++slippi_network_diagnostics.flush_calls;\n'
        '    SlippiNetworkDiagnostics::RecordMaximum(slippi_network_diagnostics.flush_max_us,\n'
        '        work_end_us - flush_start_us);\n'
        '    SlippiNetworkDiagnostics::RecordMaximum(slippi_network_diagnostics.work_max_us,\n'
        '        work_end_us - work_start_us);\n'
        '    slippi_network_diagnostics.sent_datagrams.fetch_add(\n'
        '        static_cast<u32>(m_client->totalSentPackets - sent_before), std::memory_order_relaxed);\n'
        '    slippi_network_diagnostics.received_datagrams.fetch_add(\n'
        '        static_cast<u32>(m_client->totalReceivedPackets - received_before), std::memory_order_relaxed);')



def patch_disconnect_diagnostics(text):
    text = replace_once(text, '  u64 previous_loop_us = Common::Timer::NowUs();',
        '  slippi_network_diagnostics.connected_peer.store(\n'
        '      m_server.empty() ? nullptr : m_server.front(), std::memory_order_release);\n'
        '  u64 previous_loop_us = Common::Timer::NowUs();')
    text = replace_once(text, '  }\n\n#ifdef _WIN32\n  if (m_qos_handle != 0)',
        '  }\n  slippi_network_diagnostics.connected_peer.store(nullptr, std::memory_order_release);\n'
        '\n#ifdef _WIN32\n  if (m_qos_handle != 0)')
    return replace_once(text, 'void SlippiNetplayClient::ForceDisconnectPlayer(u8 player_idx)\n{',
        'void SlippiNetplayClient::ForceDisconnectPlayer(u8 player_idx)\n{\n'
        '  ++slippi_network_diagnostics.local_disconnect_requests;')


def patch_queue_header(text):
    return replace_once(text, '  Common::SPSCQueue<std::unique_ptr<sf::Packet>> m_async_queue;',
        '  struct QueuedPacket { std::unique_ptr<sf::Packet> packet; u64 enqueued_us; };\n'
        '  Common::SPSCQueue<QueuedPacket> m_async_queue;')


def patch_native_diagnostics(text):
    text = replace_once(text, '    case CMD_FRAME_BOOKEND:\n',
        '    case CMD_FRAME_BOOKEND:\n      SampleSlippiNativeCounters();\n')
    return '#include "slippi-native-diagnostics.hpp"\n' + replace_once(text,
        'void CEXISlippi::handleOnlineInputs(u8* payload)\n{',
        'void CEXISlippi::handleOnlineInputs(u8* payload)\n{\n  SampleSlippiNativeCounters();')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('base-app', 'ios-link', 'boot-probe', 'ios-build', 'packed-float-source', 'output'):
        parser.add_argument('--'+name, type=Path, required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    base, link, boot, build, out = [p.resolve() for p in
        (args.base_app,args.ios_link,args.boot_probe,args.ios_build,args.output)]
    if out.exists() or subprocess.run(['git','check-ignore','-q',str(out)],cwd=repo).returncode:
        parser.error('Use a new ignored output directory')
    evidence=json.loads((link/'results.json').read_text())
    base_result=json.loads((base/'results.json').read_text())
    boot_result=json.loads((boot/'results.json').read_text())
    if not evidence['pass'] or evidence['boot_result_sha256'] != sha(boot/'results.json'):
        parser.error('Requires matching accepted iOS link and boot evidence')
    if base_result['ios_link_result_sha256'] != sha(link/'results.json') or not base_result['bundle_identity_audit_pass']:
        parser.error('Base app differs from accepted link/identity evidence')
    inputs=evidence['input_sha256']
    for path, digest in inputs.items():
        if sha(repo/path)!=digest: raise RuntimeError('Shared input changed: '+path)
    for row in evidence['compiled']:
        if sha(repo/row['source'])!=row['source_sha256']:
            raise RuntimeError('Accepted source changed: '+row['source'])
    source_bundle=base/'SlippiProbe.app'
    if sha(source_bundle/'Probe.iso') != boot_result['input_sha256']['iso']:
        parser.error('Base ISO changed')
    if sha(source_bundle/'Frameworks/gGALE01_recomp.dylib') != base_result['module_sha256']:
        parser.error('Use unsigned base: native module changed')
    if sha(source_bundle/'ProbeGame/sys/main.dol') != boot_result['input_sha256']['main_dol']:
        parser.error('Base extracted game changed')
    # This source is an explicit diagnostic scalar-float adapter already used
    # in physical tests. Compile it anew, never borrow an object with stale flags.
    accepted_online=json.loads((base/'results.json').read_text())['local_online_sources']
    packed_source=args.packed_float_source.resolve()
    if sha(packed_source)!=accepted_online['Interpreter_LoadStore.cpp']:
        parser.error('Packed float source differs from base app')
    out.mkdir(parents=True)
    overlay=out/'overlay'; shutil.copytree(boot/'overlay',overlay)
    compat=overlay/'Core/Slippi/SlippiCompat.h'
    compat.write_text(replace_once(compat.read_text(),'value="0.0.0-meleepad-dev"',
        'value="3.6.4+meleepad.probe"'))
    net=overlay/'Core/Slippi/SlippiNetplay.cpp'
    net.write_text(patch_queue_diagnostics(patch_network_diagnostics(replace_once(net.read_text(),
        'enet_address_set_host(&local_addr_def, "127.0.0.1"); // Probe binds loopback only.',
        'local_addr_def.host = ENET_HOST_ANY; // Restore upstream Internet peer binding.'))))
    net.write_text(patch_disconnect_diagnostics(patch_network_timing(patch_network_flush(net.read_text()))))
    net_header = net.with_suffix('.h')
    net_header.write_text(patch_queue_header(net_header.read_text()))
    exi=overlay/'Core/HW/EXI/EXI_DeviceSlippi.cpp'
    text=patch_native_diagnostics('#include "slippi-direct-probe.hpp"\n'+exi.read_text())
    text=replace_once(text,'  // Log the direct code to file.', '''  if (!SlippiDirectProbe::AllowsSearch(static_cast<int>(search.mode), shift_jis_code)) {
    ++SlippiDirectProbe::denied_searches;
    forced_error = SlippiDirectProbe::SearchDeniedMessage(static_cast<int>(search.mode));
    return;
  }
  SlippiDirectProbe::ObserveSearch(static_cast<int>(search.mode));

  // Log the direct code to file.''')
    text=replace_once(text,'  m_read_queue.push_back(mm_state);  // Matchmaking State',
        '  SlippiDirectProbe::ObserveMatchmakingState(static_cast<int>(mm_state));\n\n'
        '  m_read_queue.push_back(mm_state);  // Matchmaking State')
    exi.write_text(text)
    text=replace_once(text,'  auto is_logged_in = user->IsLoggedIn();',
        '  auto is_logged_in = user->IsLoggedIn();\n  SlippiDirectProbe::account_loaded = is_logged_in;')
    text=replace_once(text,'         byte == CMD_RECEIVE_ITEM) && SlippiCompat::game_frame_observer &&',
        '         byte == CMD_RECEIVE_ITEM || byte == CMD_RECEIVE_GAME_INFO ||\n'
        '         byte == CMD_RECEIVE_GAME_END) && SlippiCompat::game_frame_observer &&')
    exi.write_text(text)
    # The boot overlay still contains upstream production/dev host selection,
    # upstream port and server rejection handling. Refuse a fixture derivative.
    mm=(overlay/'Core/Slippi/SlippiMatchmaking.cpp').read_text()
    mh=(overlay/'Core/Slippi/SlippiMatchmaking.h').read_text()
    if 'MM_HOST = SlippiCompat::Version().find("dev") == std::string::npos ? MM_HOST_PROD : MM_HOST_DEV;' not in mm or 'MM_PORT = 43113;' not in mh:
        raise RuntimeError('Matchmaking does not use pinned upstream host/port selection')
    run=runpy.run_path(str(repo/'scripts/probe-slippi-peer.py'))['run_logged']
    db=json.loads((build/'compile_commands.json').read_text())
    default=next(e for e in db if e['file'].endswith('/HW/EXI/EXI_Device.cpp'))
    runtime_cmd=subprocess.check_output(['ninja','-t','commands','CMakeFiles/moderngekko.dir/src/runtime/dolphin_runtime.cpp.o'],cwd=build,text=True).splitlines()[-1]
    objects=[]; compiled=[]
    sources=[]
    for row in evidence['compiled']:
        source=repo/row['source']
        if source.name=='slippi-boot-probe.cpp': continue
        if source.is_relative_to(boot/'overlay'): source=overlay/source.relative_to(boot/'overlay')
        sources.append(source)
    sources += [packed_source, repo/'scripts/slippi-direct-probe.cpp']
    for source in sources:
        entry=({'command':runtime_cmd,'directory':str(build)} if source.name=='dolphin_runtime.cpp' else
            next((e for e in db if e['file'].endswith('/'+source.name)),default))
        cmd=shlex.split(entry['command']); cmd=[a for a in cmd[:cmd.index('-o')] if a!='-DOFF']
        cmd[1:1]=['-I'+str(p) for p in (overlay,repo/'scripts',repo/'ref/ModernGekko/include',
            repo/'ref/slippi-compatibility/upstream/Externals',repo/'ref/slippi-compatibility/rust/ffi/includes')]
        cmd+=['-DSLIPPI=CORE','-DSLIPPI_ONLINE=CORE','-include',str(compat)]
        obj=out/(source.stem+'.o')
        run(cmd+['-c',str(source),'-o',str(obj)],entry['directory'],out/(source.stem+'-compile.log'))
        objects.append(obj)
        compiled.append({'source':str(source.relative_to(repo)),'source_sha256':sha(source),'object_sha256':sha(obj)})
        print('Compiled '+source.name,flush=True)
    sdk=subprocess.check_output(['xcrun','--sdk','iphoneos','--show-sdk-path'],text=True).strip()
    platform=['xcrun','clang++','-target','arm64-apple-ios16.0','-isysroot',sdk]
    host=repo/'scripts/slippi-ios-direct-host.mm'; obj=out/'slippi-ios-direct-host.o'
    run(platform+['-O2','-std=c++20','-fobjc-arc','-I'+str(repo/'scripts'),
        '-I'+str(repo/'ref/slippi-compatibility/upstream/Externals'),'-c',str(host),'-o',str(obj)],out,out/'host-compile.log')
    objects.append(obj)
    bundle=out/'SlippiProbe.app'
    subprocess.run(['cp','-cR',str(source_bundle),str(bundle)],check=True)
    for filename in ('match-start-input.txt','_CodeSignature','embedded.mobileprovision'):
        path=bundle/filename
        if path.is_dir(): shutil.rmtree(path)
        elif path.exists(): path.unlink()
    # Delete the cloned executable before relinking so no previous signature or
    # executable bytes survive in the new target.
    (bundle/'SlippiProbe').unlink()
    deps=[repo/p for p in inputs if not (repo/p).is_relative_to(build)]
    archives=[repo/p for p in inputs if (repo/p).is_relative_to(build)]
    cmd=platform+['-Wl,-map,'+str(out/'link.map'),'-o',str(bundle/'SlippiProbe')]+list(map(str,objects+deps+archives))
    frameworks=sorted(set(re.findall(r'name = (\w+)\.framework;', (repo/'MeleePad.xcodeproj/project.pbxproj').read_text())))
    for name in sorted(set(frameworks+['AVFAudio','CoreFoundation','UniformTypeIdentifiers','GameController','Security'])):
        cmd+=['-framework',name]
    cmd+=['-lz','-lbz2','-liconv','-lresolv','-lcompression']
    run(cmd,out,out/'link.log')
    info=plistlib.loads((bundle/'Info.plist').read_bytes())
    info['CFBundleDisplayName']='Slippi Direct Probe'
    info['NSLocalNetworkUsageDescription']='Connect directly to your arranged Slippi opponent for a private compatibility test.'
    info['UIFileSharingEnabled']=False
    (bundle/'Info.plist').write_bytes(plistlib.dumps(info))
    audit=runpy.run_path(str(repo/'scripts/audit-slippi-bundle-identity.py'))['audit'](bundle)
    (out/'bundle-identity-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
    if not audit['pass']: raise RuntimeError('Bundle identity audit failed')
    unchanged=all(sha(repo/p)==h for p,h in inputs.items())
    result={'scope':'Private unsigned iPad native Slippi candidate; not executed or service-authenticated',
        'compiled':compiled,'host_sha256':sha(host),'runner_sha256':sha(Path(__file__)),
        'account_helper_sha256':sha(repo/'scripts/slippi-probe-account.hpp'),
        'direct_header_sha256':sha(repo/'scripts/slippi-direct-probe.hpp'),
        'direct_trace_sha256':sha(repo/'scripts/slippi-direct-trace.hpp'),
        'executable_sha256':sha(bundle/'SlippiProbe'),'version':'3.6.4+meleepad.probe',
        'base_result_sha256':sha(base/'results.json'),'ios_link_result_sha256':sha(link/'results.json'),
        'synthetic_accounts':False,'scripted_input':False,'fixture_transport':False,
        'permitted_search_mode':'Ranked/Unranked/Direct/Teams/Party','code_subset':'required','account_storage':'explicit import into device-only Keychain',
        'upstream_service_checks_preserved':True,'bundle_identity_audit_pass':audit['pass'],
        'archives_unchanged':unchanged,'signed':False,'installed':False,'executed':False,
        'service_authentication_tested':False,'crossplay_tested':False,'redistributable':False}
    (out/'results.json').write_text(json.dumps(result,indent=2)+'\n')
    if not unchanged: raise RuntimeError('Shared archive changed during build')
    print('Native Slippi candidate linked; no runtime or network acceptance claimed',flush=True)


if __name__=='__main__': main()
