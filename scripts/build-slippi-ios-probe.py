#!/usr/bin/env python3
"""Package an unsigned, private UIKit Slippi probe from passing local components.

Embeds owner-supplied game data. Output must remain ignored; never distribute it.
Does not sign, install, launch or access any device/app container.
"""
import argparse
import ipaddress
import json
from pathlib import Path
import plistlib
import re
import runpy
import shlex
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("ios-link", "ios-build", "boot-probe", "module-build", "game", "iso", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--input-script", type=Path, help="Optional device-specific controller timing fixture")
    parser.add_argument("--profile", action="store_true", help="Record game-boundary wall/CPU timing and private GCT samples")
    parser.add_argument("--idle-control", action="store_true", help="Diagnostic: apply normal v1.02 caller/secondary idle settings; requires correction/profile test")
    parser.add_argument("--local-online", type=Path, help="Passing LAN local-game probe whose isolated sources supply online client")
    parser.add_argument("--fixture-address", help="Private IPv4 host used by the accepted LAN probe")
    parser.add_argument("--audio", action="store_true", help="Enable iOS CoreAudio and measure mixer output in the local online probe")
    parser.add_argument("--seconds", type=int, default=60, help="Bounded observer duration, 60..120 seconds for online probes")
    args = parser.parse_args()
    if bool(args.local_online) != bool(args.fixture_address): parser.error("online probe requires fixture address")
    if args.audio and not (args.local_online and args.profile): parser.error("audio probe requires local online profiling")
    if not 60 <= args.seconds <= 120 or (args.seconds != 60 and not args.local_online): parser.error("extended duration requires local online and 60..120 seconds")
    if args.fixture_address:
        address=ipaddress.IPv4Address(args.fixture_address)
        if not any(address in ipaddress.IPv4Network(n) for n in ("10.0.0.0/8","172.16.0.0/12","192.168.0.0/16")):
            parser.error("fixture must be RFC1918 IPv4")
    if args.idle_control and not args.profile:
        parser.error("idle control requires --profile")
    repo = Path(__file__).resolve().parents[1]
    helpers = runpy.run_path(str(repo / "scripts/probe-slippi-peer.py"))
    sha256, run_logged = (helpers[n] for n in ("sha256", "run_logged"))
    link, build, boot, module_run, output = (p.resolve() for p in
        (args.ios_link, args.ios_build, args.boot_probe, args.module_build, args.output))
    if output.exists() or subprocess.run(["git", "check-ignore", "-q", str(output)], cwd=repo).returncode:
        parser.error("use a new ignored output directory")
    evidence = json.loads((link / "results.json").read_text())
    previous = json.loads((boot / "results.json").read_text())
    module_result = json.loads((module_run / "results.json").read_text())
    module = module_run / "build/gGALE01_recomp.dylib"
    if not evidence["pass"] or evidence["boot_result_sha256"] != sha256(boot / "results.json"):
        parser.error("requires matching passing boot and iOS link results")
    if not module_result["generated_inputs_unchanged"] or sha256(module) != module_result["module_sha256"]:
        parser.error("module differs from iOS build evidence")
    inputs = dict(evidence["input_sha256"])
    for path, expected in inputs.items():
        if sha256(repo / path) != expected:
            raise RuntimeError(f"link input changed: {path}")
    for row in evidence["compiled"]:
        if sha256(link / (Path(row["source"]).stem + ".o")) != row["object_sha256"]:
            raise RuntimeError("linked object changed")
    iso, game = args.iso.resolve(), args.game.resolve()
    if sha256(iso) != previous["input_sha256"]["iso"] or sha256(game / "sys/main.dol") != previous["input_sha256"]["main_dol"]:
        parser.error("game data differs from passing macOS test")
    source = repo / "scripts/slippi-boot-probe.cpp"
    if sha256(source) != previous["harness_sha256"]:
        parser.error("boot harness differs from passing test")
    if sha256(repo / "scripts/slippi-game-restore-trial.hpp") != previous["game_restore_harness_sha256"]:
        parser.error("restore harness differs from passing test")
    output.mkdir(parents=True)
    # Adapt the accepted harness for UIKit, then apply explicit diagnostic
    # controls below. Keep the accepted sources and core archives unchanged.
    online = args.local_online.resolve() if args.local_online else None
    online_evidence = None
    if online:
        online_evidence=json.loads((online/"results.json").read_text())
        if not online_evidence.get("lan_fixture") or not online_evidence["online_engine_entered"] or online_evidence["process_exit_codes"] != [0,0,0]:
            parser.error("requires passing LAN online engine run")
        for key,path in (("adapted_main_sha256",online/"slippi-local-game.cpp"),
                         ("matchmaking_source_sha256",online/"overlay/Core/Slippi/SlippiMatchmaking.cpp"),
                         ("netplay_source_sha256",online/"overlay/Core/Slippi/SlippiNetplay.cpp"),
                         ("packed_float_source_sha256",online/"Interpreter_LoadStore.cpp")):
            if sha256(path)!=online_evidence[key]:parser.error("accepted online source changed")
        if args.fixture_address not in (online/"overlay/Core/Slippi/SlippiMatchmaking.cpp").read_text():parser.error("fixture address differs")
    adapted = (online/"slippi-local-game.cpp" if online else source).read_text()
    for old, new in (("int main(int argc, char** argv)",
                      "int SlippiProbeMain(int argc, char** argv, void* render_surface)"),
                     ("moderngekko::RuntimeConfig config;",
                      "moderngekko::RuntimeConfig config;\n  config.render_surface = render_surface;")):
        if adapted.count(old) != 1:
            raise RuntimeError("probe source anchor changed")
        adapted = adapted.replace(old, new)
    if args.profile and online:
        adapted='#include "slippi-frame-profiler.hpp"\n'+adapted
        adapted=adapted.replace('  auto online_trace =', '  auto frame_profiler=std::make_shared<SlippiFrameProfiler>(config.user_directory);\n  auto online_trace =')
        adapted=adapted.replace('[online_trace](u8 command','[online_trace, frame_profiler](u8 command')
        adapted=adapted.replace('    online_trace->Observe(command, packet, size);','    frame_profiler->Observe(command, packet, size, 4);\n    online_trace->Observe(command, packet, size);')
        adapted=adapted.replace('  online_trace->Write(config.user_directory);','  online_trace->Write(config.user_directory);\n  frame_profiler->Write();')
    if args.profile and not online:
        for old, new in (
            ('#include "slippi-game-restore-trial.hpp"', '#include "slippi-game-restore-trial.hpp"\n#include "slippi-frame-profiler.hpp"'),
            ('  SlippiCompat::game_frame_observer = [game_restore]',
             '  const auto frame_profiler = std::make_shared<SlippiFrameProfiler>(config.user_directory);\n  SlippiCompat::game_frame_observer = [game_restore, frame_profiler]'),
            ('    game_restore->Observe(command, payload, size);',
             '    frame_profiler->Observe(command, payload, size, static_cast<int>(game_restore->phase));\n    game_restore->Observe(command, payload, size);'),
            ('  SlippiCompat::game_frame_observer = {};',
             '  SlippiCompat::game_frame_observer = {};\n  frame_profiler->Write();')):
            if adapted.count(old) != 1:
                raise RuntimeError("profiling anchor changed")
            adapted = adapted.replace(old, new)
    if args.idle_control:
        for old, new in (
            ('#include "Core/Config/GraphicsSettings.h"',
             '#include "Core/Config/GraphicsSettings.h"\n#include "Core/Config/StaticRecompSettings.h"'),
            ('  SlippiCompat::boot_iso_path = config.disc_image.string();',
             '  Config::SetCurrent(Config::MAIN_STATICRECOMP_IDLE_PC, 0u);\n'
             '  Config::SetCurrent(Config::MAIN_STATICRECOMP_SECONDARY_IDLE_PC, 0x8034B164u);\n'
             '  Config::SetCurrent(Config::MAIN_STATICRECOMP_CALLER_IDLE_PC, 0x800195D0u);\n'
             '  Config::SetCurrent(Config::MAIN_STATICRECOMP_CALLER_IDLE_LR, 0x801A4DACu);\n'
             '  std::fprintf(stderr, "[slippi-probe] diagnostic v1.02 idle control enabled\\n");\n'
             '  SlippiCompat::boot_iso_path = config.disc_image.string();')):
            if adapted.count(old) != 1:
                raise RuntimeError("idle control anchor changed")
            adapted = adapted.replace(old, new)
    if online:
        anchor = '(button == 3 && control == "Start")'
        if adapted.count(anchor) != 1: raise RuntimeError("online Start control anchor changed")
        adapted = adapted.replace(anchor, '(button == 3 && control == "Start" && SlippiCompat::command_counts[0x36].load() == 0)')
        if adapted.count('duration > 60') != 1: raise RuntimeError("duration bound anchor changed")
        adapted = adapted.replace('duration > 60', 'duration > 120')
        anchor='  return result.error ? 7 : (memory_errors.load()'
        if adapted.count(anchor)!=1:raise RuntimeError("online acceptance return anchor changed")
        adapted=adapted.replace(anchor,'  if (!result.error && (SlippiCompat::command_counts[0xb0].load() == 0 || SlippiCompat::command_counts[0x3c].load() < 300 || online_trace->overflow)) return 15;\n'+anchor)
    if args.audio:
        for old, new in (
            ('  config.audio.backend = "No audio output";', '  config.audio.backend = "CoreAudio";'),
            ('  auto online_trace =', '  auto audio_probe = std::make_shared<SlippiAudioProbe>();\n  auto online_trace ='),
            ('[online_trace, frame_profiler]', '[online_trace, frame_profiler, audio_probe]'),
            ('    online_trace->Observe(command, packet, size);', '    online_trace->Observe(command, packet, size);\n    audio_probe->Observe(command, packet, size);'),
            ('  frame_profiler->Write();', '  frame_profiler->Write();\n  audio_probe->Write(config.user_directory);'),
            ('  return result.error ? 7 : (memory_errors.load()', '  if (!result.error && !audio_probe->HasOutput()) return 16;\n  return result.error ? 7 : (memory_errors.load()')):
            if adapted.count(old) != 1: raise RuntimeError("audio probe anchor changed")
            adapted = adapted.replace(old, new)
        adapted = '#include "slippi-audio-probe.hpp"\n' + adapted
    adapted_path = output / "slippi-boot-probe-ios.cpp"
    adapted_path.write_text(adapted)
    database = json.loads((build / "compile_commands.json").read_text())
    entry = next(e for e in database if e["file"].endswith("/HW/EXI/EXI_Device.cpp"))
    command = shlex.split(entry["command"])
    command = [a for a in command[:command.index("-o")] if a != "-DOFF"]
    overlay = (online or boot) / "overlay"
    command[1:1] = ["-I" + str(p) for p in (overlay, overlay / "Core/Slippi", repo / "scripts", repo / "ref/ModernGekko/include",
        repo / "ref/slippi-compatibility/upstream/Externals", repo / "ref/slippi-compatibility/rust/ffi/includes")]
    command += ["-DSLIPPI=CORE", "-DSLIPPI_ONLINE=CORE", "-DSLIPPI_PROBE_GAME_RESTORE=1",
                "-include", str(overlay / "Core/Slippi/SlippiCompat.h")]
    if online: command.remove("-DSLIPPI_PROBE_GAME_RESTORE=1")
    objects = [link / (Path(row["source"]).stem + ".o") for row in evidence["compiled"]
               if Path(row["source"]).name != "slippi-boot-probe.cpp"]
    if online:
        objects=[p for p in objects if p.name not in ("SlippiMatchmaking.o","SlippiNetplay.o")]
        for src in (overlay/"Core/Slippi/SlippiMatchmaking.cpp",overlay/"Core/Slippi/SlippiNetplay.cpp",online/"Interpreter_LoadStore.cpp"):
            if src.name=="SlippiMatchmaking.cpp":
                mm_text=src.read_text()
                anchor=f'enet_address_set_host_ip(&client_addr, "{args.fixture_address}");'
                if mm_text.count(anchor)!=1:raise RuntimeError("LAN bind anchor changed")
                mm_text=mm_text.replace(anchor,'client_addr.host = ENET_HOST_ANY; // Device owns a different LAN address.')
                src=output/"SlippiMatchmaking.cpp";src.write_text(mm_text)
            obj=output/(src.stem+".o")
            run_logged(command+["-c",str(src),"-o",str(obj)],entry["directory"],output/(src.stem+"-compile.log"));objects.append(obj)
    probe_obj = output / "slippi-boot-probe-ios.o"
    run_logged(command + ["-c", str(adapted_path), "-o", str(probe_obj)], entry["directory"], output / "probe-compile.log")
    objects.append(probe_obj)
    sdk = subprocess.check_output(["xcrun", "--sdk", "iphoneos", "--show-sdk-path"], text=True).strip()
    platform = ["xcrun", "clang++", "-target", "arm64-apple-ios16.0", "-isysroot", sdk]
    host_sources = [repo / "scripts/slippi-ios-probe-host.mm", repo / "scripts/slippi-ios-probe-network.cpp"]
    if online:
        host_text=host_sources[0].read_text().replace('offline','local online').replace('Offline','Local online')
        host_text=host_text.replace('-runLocal onlineProbe','-runLocalOnlineProbe').replace('Slippi local online probe — no online play','Slippi local peer diagnostic')
        host_text=host_text.replace('      setenv("SLIPPI_PROBE_GRAPHICS"', '      setenv("SLIPPI_PROBE_LOCAL_PLAYER", "1", 1);\n      setenv("SLIPPI_PROBE_GRAPHICS"')
        host_text=host_text.replace('@"online_tested": @NO','@"local_online_attempted": @YES, @"internet_tested": @NO')
        host_text=host_text.replace('Local online test passed. Online play remains untested.','Local test finished. Check peer and state diagnostics.')
        host_text=host_text.replace('setenv("SLIPPI_PROBE_SECONDS", "60", 1);', f'setenv("SLIPPI_PROBE_SECONDS", "{args.seconds}", 1);')
        if args.audio:
            host_text = '#import <AVFAudio/AVFAudio.h>\n' + host_text
            anchor = '      NSInteger initialThermal ='
            if host_text.count(anchor) != 1: raise RuntimeError("audio session anchor changed")
            host_text = host_text.replace(anchor, '''      NSError* audioError = nil;
      AVAudioSession* audioSession = AVAudioSession.sharedInstance;
      BOOL audioActive = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&audioError] &&
                         [audioSession setActive:YES error:&audioError];
      std::fprintf(stderr, "[slippi-audio] session_active=%d error_code=%ld\\n", audioActive, (long)audioError.code);
''' + anchor)
            host_text = host_text.replace('int result = SlippiProbeMain(5, arguments, (__bridge void*)layer);',
                                         'int result = audioActive ? SlippiProbeMain(5, arguments, (__bridge void*)layer) : 17;')
            host_text = host_text.replace('@"audio_tested": @NO', '@"audio_requested": @YES, @"audio_session_active": @(audioActive)')
        host_path=output/"slippi-ios-online-host.mm";host_path.write_text(host_text)
        host_sources=[host_path,repo/"scripts/slippi-lan-probe-network.cpp"]
    for src in host_sources:
        obj = output / (src.stem + ".o")
        flags = ["-fobjc-arc"] if src.suffix == ".mm" else []
        if online and src.suffix==".cpp":flags += [f'-DSLIPPI_FIXTURE_IPV4="{args.fixture_address}"']
        run_logged(platform + ["-O2", "-std=c++20"] + flags + ["-c", str(src), "-o", str(obj)],
                   output, output / (src.stem + ".log"))
        objects.append(obj)
    bundle = output / "SlippiProbe.app"
    bundle.mkdir()
    executable = bundle / "SlippiProbe"
    # Dependencies precede core archives, as in the accepted full-runtime link.
    dependencies = [repo / p for p in inputs if not (repo / p).is_relative_to(build)]
    archives = [repo / p for p in inputs if (repo / p).is_relative_to(build)]
    command = platform + ["-Wl,-map," + str(output / "link.map"), "-o", str(executable)]
    command += list(map(str, objects + dependencies + archives))
    frameworks = sorted(set(re.findall(r"name = (\w+)\.framework;", (repo / "MeleePad.xcodeproj/project.pbxproj").read_text())))
    for name in frameworks + ["AVFAudio", "CoreFoundation"]:
        command += ["-framework", name]
    command += ["-lz", "-lbz2", "-liconv", "-lresolv", "-lcompression"]
    linked = run_logged(command, output, output / "link.log")
    if "built for newer" in linked.stderr:
        raise RuntimeError("deployment target mismatch")
    (bundle / "Frameworks").mkdir()
    shutil.copy2(module, bundle / "Frameworks/gGALE01_recomp.dylib")
    shutil.copytree(game / "sys", bundle / "ProbeGame/sys")
    # InspectGame validates/hashes the extracted files tree even when runtime
    # DVD reads use the ISO. Preserve the same asset identity as the host test.
    cloned_assets = subprocess.run(["cp", "-cR", str(game / "files"),
                                   str(bundle / "ProbeGame/files")], capture_output=True)
    if cloned_assets.returncode:
        shutil.copytree(game / "files", bundle / "ProbeGame/files")
    # APFS clone avoids a second physical copy when supported; ordinary local
    # copying remains safe on filesystems without cloning.
    cloned = subprocess.run(["cp", "-c", str(iso), str(bundle / "Probe.iso")], capture_output=True)
    if cloned.returncode:
        shutil.copy2(iso, bundle / "Probe.iso")
    shutil.copytree(boot / "SlippiProbe.app/Contents/Resources/Sys", bundle / "Sys")
    input_script = (args.input_script or repo / "scripts/fixtures/slippi-match-start-input.txt").resolve()
    shutil.copy2(input_script, bundle / "match-start-input.txt")
    info = {"CFBundleExecutable": "SlippiProbe", "CFBundleIdentifier": "com.meleepad.SlippiProbe",
            "CFBundleName": "SlippiProbe", "CFBundleDisplayName": "Slippi Offline Probe",
            "CFBundlePackageType": "APPL", "CFBundleVersion": "1", "CFBundleShortVersionString": "0.1",
            "MinimumOSVersion": "16.0", "CFBundleSupportedPlatforms": ["iPhoneOS"],
            "UIDeviceFamily": [1, 2], "UIRequiredDeviceCapabilities": ["arm64", "metal"],
            "UIRequiresFullScreen": True, "UIFileSharingEnabled": True, "UILaunchScreen": {},
            "UISupportedInterfaceOrientations": ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"]}
    if online:
        info["CFBundleDisplayName"]="Slippi Local Probe"
        info["NSLocalNetworkUsageDescription"]="Connect to the local diagnostic peer to measure Slippi compatibility."
    (bundle / "Info.plist").write_bytes(plistlib.dumps(info))
    identity_audit = runpy.run_path(str(repo / "scripts/audit-slippi-bundle-identity.py"))["audit"](bundle)
    (output / "bundle-identity-audit.json").write_text(json.dumps(identity_audit, indent=2) + "\n")
    if not identity_audit["pass"]:
        raise RuntimeError("bundle failed account identity audit; inspect classifications in audit result")
    result = {"scope": "Unsigned private UIKit offline Slippi diagnostic app; contains owner-supplied game data",
              "ios_link_result_sha256": sha256(link / "results.json"), "module_build_result_sha256": sha256(module_run / "results.json"),
              "runner_sha256": sha256(Path(__file__)), "adapted_probe_sha256": sha256(adapted_path),
              "host_sources": {src.name: sha256(src) for src in host_sources},
              "executable_sha256": sha256(executable), "module_sha256": sha256(bundle / "Frameworks/gGALE01_recomp.dylib"),
              "iso_matches": sha256(bundle / "Probe.iso") == previous["input_sha256"]["iso"],
              "extracted_assets_included": True,
              "input_script_sha256": sha256(input_script),
              "profiling_enabled": args.profile,
              "audio_requested": args.audio,
              "observer_duration_seconds": args.seconds,
              "online_start_suppressed_after_game_start": bool(online),
              "audio_probe_sha256": sha256(repo / "scripts/slippi-audio-probe.hpp") if args.audio else None,
              "diagnostic_idle_control": args.idle_control,
              "bundle_identity_audit_pass": identity_audit["pass"],
              "profiler_sha256": sha256(repo / "scripts/slippi-frame-profiler.hpp") if args.profile else None,
              "signed": False, "installed": False, "ios_executed": False, "redistributable": False}
    if online:
        result["scope"]="Unsigned private iPad local Slippi peer probe; synthetic account only; no Internet acceptance"
        result["local_online_base_sha256"]=sha256(online/"results.json")
        result["local_online_sources"]={p.name:sha256(p) for p in (online/"Interpreter_LoadStore.cpp",output/"SlippiMatchmaking.cpp",overlay/"Core/Slippi/SlippiNetplay.cpp")}
        result["network_scope"]="Static runtime UDP to loopback and one private fixture host; not OS sandbox"
    (output / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    if not result["iso_matches"]:
        raise RuntimeError("bundled ISO mismatch")
    print("Private UIKit probe packaged; unsigned and not executed", flush=True)


if __name__ == "__main__":
    main()
