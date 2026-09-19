#!/usr/bin/env python3
"""Build a private scalar-FMA hypothesis control, reusing existing module objects.

Not a production compatibility profile. Finite scalar multiply-add results are
changed; --paired includes paired operations. The host interpreter is unchanged.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shlex
import subprocess


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('output', type=Path)
    ap.add_argument('--paired', action='store_true', help='Also control finite paired multiply-add')
    args = ap.parse_args()
    repo = Path(__file__).resolve().parents[1]
    build = repo/'ref/slippi-compatibility/native-gct-001/module-build'
    source = repo/'ref/ModernGekko/vendor/dolphin/GXRuntime/src/core/cpu_interpreter_float.c'
    out = args.output.resolve()
    if subprocess.run(['git', 'check-ignore', '-q', str(out)], cwd=repo).returncode:
        ap.error('output must be ignored')
    out.mkdir(parents=True, exist_ok=False)
    text = source.read_text()
    anchor = '''    if (fp_invalid_gated(cpu, &product))
        return;

    if (single) {'''
    assert text.count(anchor) == 1
    text = text.replace(anchor, '''    // Hypothesis control: preserve separate multiply and add rounding.
    // The volatile temporary prevents contraction even with LTO enabled.
    if (isfinite(cpu->fpr[a]) && isfinite(cpu->fpr[c]) && isfinite(cpu->fpr[b])) {
        volatile f64 separate_product = cpu->fpr[a] * cpu->fpr[c];
        product.value = subtract ? separate_product - cpu->fpr[b]
                                 : separate_product + cpu->fpr[b];
    }
''' + anchor)
    if args.paired:
        start = text.index('void ppc_ps_madd_op(')
        end = text.index('void ppc_ps_sum0(', start)
        wrapper = '''static FPRes lab_paired_madd(CPUState* cpu, f64 a, f64 c,
                                    f64 b, bool subtract, bool single) {
    FPRes result = ni_madd_msub(cpu, a, c, b, subtract, single);
    if (isfinite(a) && isfinite(c) && isfinite(b)) {
        volatile f64 separate_product = a * force_25bit_c(c);
        result.value = subtract ? separate_product - b : separate_product + b;
    }
    return result;
}

'''
        text = text[:start] + wrapper + text[start:end].replace('ni_madd_msub(', 'lab_paired_madd(') + text[end:]
    candidate = out/source.name
    candidate.write_text(text)
    commands = subprocess.check_output(['ninja', '-t', 'commands', 'gGALE01_recomp'], cwd=build, text=True).splitlines()
    compile_cmd = shlex.split(next(c for c in commands if str(source) in c and ' -c ' in c))
    compile_cmd.insert(1, '-I'+str(source.parent))
    obj = out/'scalar-unfused.o'
    original_obj = compile_cmd[compile_cmd.index('-o')+1]
    compile_cmd[compile_cmd.index('-o')+1] = str(obj)
    compile_cmd[compile_cmd.index(str(source))] = str(candidate)
    for flag in ('-MF', '-MT'):
        if flag in compile_cmd:
            i = compile_cmd.index(flag)
            compile_cmd[i+1] = str(obj)+('.d' if flag == '-MF' else '')
    link_cmd = shlex.split(commands[-1])
    start = next(i for i, part in enumerate(link_cmd) if part.endswith('/cc') or part.endswith('/clang'))
    link_cmd = link_cmd[start:]
    if '&&' in link_cmd:
        link_cmd = link_cmd[:link_cmd.index('&&')]
    module = out/'gGALE01_recomp.dylib'
    link_cmd[link_cmd.index('-o')+1] = str(module)
    link_cmd[link_cmd.index(original_obj)] = str(obj)
    for name, command in [('compile', compile_cmd), ('link', link_cmd)]:
        with (out/(name+'.log')).open('w') as log:
            subprocess.run(command, cwd=build, stdout=log, stderr=subprocess.STDOUT, check=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    (out/'manifest.json').write_text(json.dumps({
        'scope': 'Finite nonfused diagnostic; not production semantics',
        'source_sha256': sha(source), 'candidate_sha256': sha(candidate),
        'module_sha256': sha(module), 'base_module_sha256': sha(build/module.name),
        'hardware_used': False, 'shared_build_modified': False,
        'paired_control': args.paired,
    }, indent=2)+'\n')
    print(module)


if __name__ == '__main__':
    main()
