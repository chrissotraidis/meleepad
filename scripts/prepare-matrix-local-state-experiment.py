#!/usr/bin/env python3
"""Prepare the private, unaccepted v1.02 local-FP-state experiment.

No game code is embedded in this script. The exact locally generated game
sources and runtime are required and authenticated before writing anything.
Output includes game-derived C: keep it private, outside release artifacts.
This does not build, install, enable, or promote the candidate.
"""

from pathlib import Path
import argparse
import hashlib
import json
import re
import sys

EXPECTED_INPUTS = {
    "generated/generated.h": "7c3b9ff865121ef0ce8f81ead0e68135a36662050f25c29057d60dfe84544f3c",
    "generated/chunks/chunk_0208_text1_80341940.c": "4d03efef1e18bd00177b3fd56271119c1083b960657d1afd6ee39955e015991e",
    "generated/chunks/chunk_0222_text1_80379940.c": "ae720d8f90f04afc593540ad7aeb1bd7fbd889d2a5a65ea7659eb5968f4e7205",
    "runtime/src/core/cpu_interpreter_float.c": "0dcddb08a2feb6d5b67ece4401f94d098604301ae1ba1658f743c63ecd8d45e7",
    "runtime/src/core/cpu_interpreter_private.h": "52a9bba63741750f8550332563ae21aff5922bed3130364176ddd88664e7e63f",
    "runtime/include/core/cpu.h": "880562ddfdeba90abc70f7d6c8d34de36b48a55ad73cada3011b25e33eb21318",
    "runtime/include/core/types.h": "824490a35e968e645067711189a67156536ddd127ade063418ddcb59787f58bf",
}


def validate_inputs(gen: Path, runtime: Path) -> None:
    for name, expected in EXPECTED_INPUTS.items():
        kind, relative = name.split("/", 1)
        source = (gen if kind == "generated" else runtime) / relative
        if (
            not source.is_file()
            or hashlib.sha256(source.read_bytes()).hexdigest() != expected
        ):
            raise ValueError(
                f"unsupported source: {name}; expected the pinned v1.02 experiment inputs"
            )


def prepare(gen: Path, runtime: Path, out: Path) -> None:
    validate_inputs(gen, runtime)
    if out.exists():
        raise ValueError("output already exists; use a fresh private directory")
    out.mkdir(parents=True)
    core = runtime / "src/core"
    floating = (core / "cpu_interpreter_float.c").read_text().split("void ppc_frsp(")[0]
    names = set(
        re.findall(
            r"^(?:static )?(?:GXRUNTIME_ALWAYS_INLINE )?(?:f64|f32|u32|u64|unsigned|bool|void|FPRes)\s+(\w+)\(",
            floating,
            re.M,
        )
    )
    header = (
        (core / "cpu_interpreter_private.h")
        .read_text()
        .replace("GXRUNTIME_CPU_INTERPRETER_PRIVATE_H", "MELEEPAD_LOCAL_FP_PRIVATE_H")
    )
    for name in sorted(names, key=len, reverse=True):
        floating = re.sub(r"\b" + name + r"\b", "local_" + name, floating)
        header = re.sub(r"\b" + name + r"\b", "local_" + name, header)
    floating = floating.replace("CPUState", "LocalFP").replace(
        '#include "cpu_interpreter_private.h"', '#include "local-fp-private.h"'
    )
    header = header.replace("CPUState", "LocalFP")
    # All local operations keep their existing arithmetic and FPSCR semantics.
    pat = r"^(?:static )?(?:GXRUNTIME_ALWAYS_INLINE )?((?:f64|f32|u32|u64|unsigned|bool|void|FPRes)\s+local_\w+\()"
    floating = re.sub(
        pat, r"static __attribute__((always_inline)) inline \1", floating, flags=re.M
    )
    header = re.sub(
        pat, r"static __attribute__((always_inline)) inline \1", header, flags=re.M
    )
    (out / "local-fp-private.h").write_text(header)
    (out / "local-fp.c").write_text(floating)
    spec = [
        ("80341940", "80342204", "803422D0", "concat"),
        ("80379940", "80379A20", "80379C24", "inverse"),
        ("80379940", "8037A54C", "8037A610", "scaled"),
    ]
    code = [
        '#include "generated.h"\n#include <string.h>\ntypedef struct {f64 fpr[32],ps1[32];u32 fpscr,cr;} LocalFP;\n#include "local-fp.c"\nstatic bool valid_ram(CPUState*c,u32 a,u32 n){return c->ram && c->ram_size>=n && a>=0x80000000u && a-0x80000000u<=c->ram_size-n;}\n'
    ]
    code.append(
        "\nstatic bool bounded_matrix(CPUState*c,u32 a){\n for(unsigned i=0;i<12;i++) if((read_be32(c->ram+(a-0x80000000u)+4*i)&0x7fffffffu)>0x49742400u)return false;\n return true;\n}\nstatic bool separate(u32 a,u32 an,u32 b,u32 bn){return (u64)a+an<=b || (u64)b+bn<=a;}\nstatic bool matrix_alias_ok(u32 a,u32 b){return a==b || separate(a,48,b,48);}\n"
    )
    code.append(
        "\nstatic bool bounded_linear_matrix(CPUState*c,u32 a){\n for(unsigned row=0;row<3;row++)for(unsigned col=0;col<3;col++)if((read_be32(c->ram+(a-0x80000000u)+row*16+col*4)&0x7fffffffu)>0x49742400u)return false;\n return true;\n}\n"
    )
    for chunk, start, end, name in spec:
        source = next((gen / "chunks").glob("*_" + chunk + ".c")).read_text()
        body = source[
            source.index("label_" + start + ":\n") : source.index(
                "label_" + end + ":\n"
            )
        ]
        refs = set(re.findall(r"goto label_([0-9A-F]+)", body))
        labels = set(re.findall(r"^label_([0-9A-F]+):", body, re.M))
        assert refs <= labels
        # Preserve exact PSQ bit conversions; no ordinary float cast substitution.
        body = re.sub(
            r"ppc_psq_load\(ctx, (\d+)u, ea, false, 0u, false, 0x[0-9A-F]+u\);",
            lambda m: "fp.fpr["
            + m[1]
            + "]=f64_value(convert_to_double(read_be32(ram+(ea-0x80000000u)))); fp.ps1["
            + m[1]
            + "]=f64_value(convert_to_double(read_be32(ram+(ea-0x80000000u)+4)));",
            body,
        )
        body = re.sub(
            r"ppc_psq_store\(ctx, (\d+)u, ea, false, 0u, false, 0x[0-9A-F]+u\);",
            lambda m: "write_be64(ram+(ea-0x80000000u), ((u64)convert_to_single_ftz(f64_bits(fp.fpr["
            + m[1]
            + "]))<<32)|convert_to_single_ftz(f64_bits(fp.ps1["
            + m[1]
            + "])));",
            body,
        )
        assert "ppc_psq_" not in body
        body = re.sub(
            r"    if \(!ppc_fp_available\(ctx, 0x[0-9A-F]+u\)\) return;\n", "", body
        )
        body = body.replace("        if (ctx->exception) return;\n", "")
        for bits in (32, 64):
            body = body.replace(
                f"mem_read{bits}(ctx, ea)", f"read_be{bits}(ram+(ea-0x80000000u))"
            )
            body = re.sub(
                rf"mem_write{bits}\(ctx, ea, (.*)\);",
                rf"write_be{bits}(ram+(ea-0x80000000u), \1);",
                body,
            )
        assert "mem_read" not in body and "mem_write" not in body
        for helper in ["ppc_fmuls", "ppc_fdivs", "ppc_fmadd_op"]:
            body = body.replace(helper + "(ctx,", "local_" + helper + "(&fp,")
        assert not re.search(r"\bppc_\w+\(ctx", body)
        # Include every referenced architectural FP register and helper operand/destination.
        regs = set(
            int(n) for n in re.findall(r"(?:ctx->|fp\.)(?:fpr|ps1)\[(\d+)\]", body)
        )
        for call in re.findall(r"local_ppc_\w+\(&fp, ([^;]+)\);", body):
            regs.update(int(n) for n in re.findall(r"(?<![\w])\d+(?![\w])", call))
        assert all(0 <= r < 32 for r in regs)
        body = (
            body.replace("ctx->fpr", "fp.fpr")
            .replace("ctx->ps1", "fp.ps1")
            .replace("ctx->fpscr", "fp.fpscr")
        )
        guard = "ctx->exception || !(ctx->msr&PPC_MSR_FP) || ctx->reserve_valid || g_mem_write_journal || ctx->exram || !valid_ram(ctx,ctx->gpr[3],48) || !valid_ram(ctx,ctx->gpr[4],48)"
        if name in ("concat", "scaled"):
            guard += " || !valid_ram(ctx,ctx->gpr[5],48)"
        if name == "concat":
            guard += " || !(ctx->hid2&PPC_HID2_LSQE) || ctx->gqr[0]!=0 || !valid_ram(ctx,0x804D5C00u,8) || !valid_ram(ctx,ctx->gpr[1]-64,64)"
        if name == "inverse":
            guard += " || !valid_ram(ctx,ctx->gpr[1]-96,104) || !valid_ram(ctx,ctx->gpr[2]-5000,16)"
        # Inverse-transpose arithmetic reads only the input 3x3 block. Its
        # destination and translation slots are not arithmetic inputs; the
        # original singular/copy continuation remains unchanged.
        if name == "inverse":
            guard += " || !bounded_linear_matrix(ctx,ctx->gpr[3])"
        else:
            guard += " || !bounded_matrix(ctx,ctx->gpr[3]) || !bounded_matrix(ctx,ctx->gpr[4])"
        if name in ("concat", "scaled"):
            guard += " || !matrix_alias_ok(ctx->gpr[3],ctx->gpr[5]) || !matrix_alias_ok(ctx->gpr[4],ctx->gpr[5])"
        if name == "concat":
            guard += " || !separate(ctx->gpr[1]-64,64,ctx->gpr[3],48) || !separate(ctx->gpr[1]-64,64,ctx->gpr[4],48) || !separate(ctx->gpr[1]-64,64,ctx->gpr[5],48) || !separate(ctx->gpr[1]-64,64,0x804D5C00u,8) || read_be32(ctx->ram+0x4D5C00)!=0 || read_be32(ctx->ram+0x4D5C04)!=0x3f800000u"
        if name == "inverse":
            guard += " || !matrix_alias_ok(ctx->gpr[3],ctx->gpr[4]) || !separate(ctx->gpr[1]-96,104,ctx->gpr[3],48) || !separate(ctx->gpr[1]-96,104,ctx->gpr[4],48) || !separate(ctx->gpr[2]-5000,16,ctx->gpr[1]-96,104) || !separate(ctx->gpr[2]-5000,16,ctx->gpr[4],48) || read_be32(ctx->ram+(ctx->gpr[2]-5000-0x80000000u))!=0x2edbe6ffu || read_be32(ctx->ram+(ctx->gpr[2]-4996-0x80000000u))!=0x3f800000u || read_be32(ctx->ram+(ctx->gpr[2]-4992-0x80000000u))!=0"
        if name == "scaled":
            guard += " || !(ctx->fpr[1]>=-1.0 && ctx->fpr[1]<=1.0)"
        # Region returns 0 on a failed guard (no state changed), 1 on original dispatch-return,
        # and 2 on an original direct return (external tail call). Caller preserves its own dispatcher.
        body = body.replace(
            "goto return_dispatch_" + chunk + ";", "goto commit_dispatch;"
        ).replace("return;", "goto commit_direct;")
        setup = "LocalFP fp; fp.fpscr=ctx->fpscr; fp.cr=ctx->cr;\n" + "".join(
            f"fp.fpr[{r}]=ctx->fpr[{r}];fp.ps1[{r}]=ctx->ps1[{r}];\n"
            for r in sorted(regs)
        )
        commit = "ctx->fpscr=fp.fpscr;\n" + "".join(
            f"ctx->fpr[{r}]=fp.fpr[{r}];ctx->ps1[{r}]=fp.ps1[{r}];\n"
            for r in sorted(regs)
        )
        code.append(
            "int meleepad_lift_"
            + start
            + "(CPUState* __restrict ctx){\nif(ctx->pc!=0x"
            + start
            + "u || "
            + guard
            + ")return 0;\nu8* __restrict ram=ctx->ram;\n"
            + setup
            + body
            + "\ncommit_dispatch:\n"
            + commit
            + "return 1;\ncommit_direct:\n"
            + commit
            + "return 2;\n}\n"
        )
    (out / "lift.c").write_text("\n".join(code))

    spec = {"80341940": ["80342204"], "80379940": ["80379A20", "8037A54C"]}
    for chunk, entries in spec.items():
        src = next((gen / "chunks").glob("*_" + chunk + ".c"))
        s = src.read_text().replace(
            '#include "../generated.h"', '#include "generated.h"'
        )
        decl = "\n".join(
            "extern int meleepad_lift_" + pc + "(CPUState*);" for pc in entries
        )
        s = s.replace(
            "void func_" + chunk + "(CPUState* ctx) {",
            decl + "\nvoid func_" + chunk + "(CPUState* ctx) {",
            1,
        )
        for pc in entries:
            needle = "label_" + pc + ":\n"
            assert needle in s
            s = s.replace(
                needle,
                needle
                + "    { int lifted=meleepad_lift_"
                + pc
                + "(ctx); if(lifted==1) goto return_dispatch_"
                + chunk
                + "; if(lifted==2) return; }\n",
                1,
            )
        (out / src.name).write_text(s)
    outputs = {
        p.name: hashlib.sha256(p.read_bytes()).hexdigest()
        for p in sorted(out.iterdir())
        if p.is_file()
    }
    (out / "experiment.json").write_text(
        json.dumps(
            {
                "status": "private candidate; physical acceptance pending",
                "revision": "GALE01 v1.02",
                "input_sha256": EXPECTED_INPUTS,
                "output_sha256": outputs,
                "build": "Replace only the two matching chunk objects and add lift.c to the original module link. Preserve original floating-point compiler flags and all other objects.",
            },
            indent=2,
        )
        + "\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--generated",
        type=Path,
        required=True,
        help="matching generated directory containing generated.h and chunks/",
    )
    parser.add_argument(
        "--runtime", type=Path, required=True, help="matching GXRuntime directory"
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="fresh private output directory; contains game-derived C",
    )
    args = parser.parse_args()
    prepare(args.generated, args.runtime, args.output)
    print("Prepared private experiment sources; no build or installation performed.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        sys.exit(str(error))
