#!/usr/bin/env python3
"""Prepare an unpromoted v1.02 GX load-prefix experiment from local game code.

Output is game-derived and must stay in an ignored private directory. This
script does not build, install, enable, or release the candidate.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess

CHUNK = 'chunk_0207_text1_8033D940.c'
SOURCE_SHA256 = 'fce5c973c9b46bd6749e8b11e8b48a5d898fb48e551882710e610ce777a823fe'


def transform(source):
    for start, end in [('80341408', '80341420'), ('8034143C', '80341454')]:
        a = source.index('label_' + start + ':')
        b = source.index('label_' + end + ':', a)
        part = source[a:b]
        marker = '    ctx->downcount -= 13;\n'
        body = part.split(marker, 1)[1]
        body = re.sub(r'^label_\w+:\n', '', body, flags=re.M)
        body = re.sub(r'    ctx->pc = 0x[0-9A-F]+u;\n', '', body)
        body = re.sub(r'    if \(!ppc_fp_available\(ctx, 0x[0-9A-F]+u\)\) return;\n', '', body)
        body = body.replace('        if (ctx->exception) return;\n', '')
        body = re.sub(
            r'ppc_psq_load\(ctx, (\d+)u, ea, false, 0u, false, 0x[0-9A-F]+u\);',
            lambda m: f'ctx->fpr[{m[1]}]=f64_value(convert_to_double(mem_read32(ctx,ea))); '
                      f'ctx->ps1[{m[1]}]=f64_value(convert_to_double(mem_read32(ctx,ea+4)));',
            body)
        guard = ('!ctx->exception && (ctx->msr&PPC_MSR_FP) && (ctx->hid2&PPC_HID2_LSQE) '
                 '&& ctx->gqr[0]==0 && ctx->ram && !ctx->exram && ctx->ram_size>=48 '
                 '&& ctx->gpr[3]>=0x80000000u && ctx->gpr[3]-0x80000000u<=ctx->ram_size-48')
        injection = f'    if ({guard}) {{\n{body}        goto label_{end};\n    }}\n'
        source = source[:a] + part.replace(marker, marker + injection, 1) + source[b:]
    return source.replace('"../generated.h"', '"generated.h"')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generated', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    original = (args.generated / 'chunks' / CHUNK).read_bytes()
    if hashlib.sha256(original).hexdigest() != SOURCE_SHA256:
        parser.error('unsupported generated chunk; expected the pinned v1.02 source')
    root = Path(__file__).resolve().parents[1]
    out = args.out.resolve()
    if out.exists():
        parser.error('output already exists; use a fresh private directory')
    if subprocess.run(['git', '-C', str(root), 'check-ignore', '-q', str(out / CHUNK)]).returncode:
        parser.error('output must be inside an ignored private directory')
    candidate = transform(original.decode()).encode()
    out.mkdir(parents=True)
    (out / CHUNK).write_bytes(candidate)
    (out / 'experiment.json').write_text(json.dumps({
        'status': 'private, unpromoted load-prefix experiment; no device acceptance',
        'source_sha256': SOURCE_SHA256,
        'candidate_sha256': hashlib.sha256(candidate).hexdigest(),
        'build': 'Replace only this chunk object in the exact original module link. Preserve compiler flags, all runtime objects and original chunk hashes.'
    }, indent=2) + '\n')


if __name__ == '__main__':
    main()
