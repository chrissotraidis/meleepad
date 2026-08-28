#!/usr/bin/env python3
"""Create a disposable single-entry variant of one generated C chunk.

The normal chunk must accept every guest instruction as an entry. This tool
narrows both its initial and internal-return switches so the host compiler can
discard unreachable guest code and optimize one complete guest function as a
single-entry CFG. The canonical chunk remains the correctness fallback.
"""

from __future__ import annotations

import argparse
import pathlib
import re


def replace_braced_statement(text: str, start: int, replacement: str) -> str:
    brace = text.find("{", start)
    if brace < 0:
        raise ValueError("switch has no opening brace")
    depth = 0
    for index in range(brace, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                return text[:start] + replacement + text[index + 1 :]
    raise ValueError("switch has no closing brace")


def transform(
    text: str,
    entry: int,
    returns: list[int],
    output_name: str,
    cached_gprs: list[int],
    cached_fprs: list[int],
    cached_ps1: list[int],
    fp_gate_pc: int | None,
    hot: bool = False,
) -> str:
    function = re.search(r"\bvoid\s+(func_[0-9A-Fa-f]+)\s*\(CPUState\* ctx\)\s*\{", text)
    if function is None:
        raise ValueError("generated chunk function not found")
    original_name = function.group(1)
    text = text[: function.start(1)] + output_name + text[function.end(1) :]
    if hot:
        signature = f"void {output_name}(CPUState* ctx) {{"
        if text.count(signature) != 1:
            raise ValueError("renamed function signature is not unique")
        text = text.replace(signature, f"__attribute__((hot)) {signature}", 1)

    initial = text.find("switch (ctx->pc)", function.end())
    if initial < 0:
        raise ValueError("initial entry switch not found")
    initial_replacement = f"goto label_{entry:08X};"
    text = replace_braced_statement(text, initial, initial_replacement)

    return_label = text.find(f"return_dispatch_{original_name[5:]}:")
    if return_label < 0:
        raise ValueError("return-dispatch label not found")
    return_switch = text.find("switch (ctx->pc)", return_label)
    if return_switch < 0:
        raise ValueError("return-dispatch switch not found")
    cases = " ".join(
        f"case 0x{pc:08X}u: goto label_{pc:08X};" for pc in returns
    )
    return_replacement = f"switch (ctx->pc) {{ {cases} default: return; }}"
    text = replace_braced_statement(text, return_switch, return_replacement)

    cached: list[tuple[str, int, str]] = []
    cached.extend(("gpr", register, "u32") for register in cached_gprs)
    cached.extend(("fpr", register, "f64") for register in cached_fprs)
    cached.extend(("ps1", register, "f64") for register in cached_ps1)
    if cached:
        renamed = re.search(
            rf"\bvoid\s+{re.escape(output_name)}\s*\(CPUState\* ctx\)\s*\{{", text
        )
        if renamed is None:
            raise ValueError("renamed function not found")
        prefix = text[: renamed.end()]
        body = text[renamed.end() :]
        if fp_gate_pc is not None:
            gate = re.compile(
                r"^\s*if \(!ppc_fp_available\(ctx, 0x(?P<pc>[0-9A-Fa-f]{8})u\)\) return;\s*$",
                re.MULTILINE,
            )

            def keep_selected_gate(match: re.Match[str]) -> str:
                return match.group(0) if int(match.group("pc"), 16) == fp_gate_pc else ""

            body, gate_count = gate.subn(keep_selected_gate, body)
            if gate_count == 0 or f"0x{fp_gate_pc:08X}u" not in body:
                raise ValueError("selected FP gate was not found")
        for field, register, _ctype in cached:
            body = body.replace(f"ctx->{field}[{register}]", f"local_{field}_{register}")
        declarations = " ".join(
            f"{ctype} local_{field}_{register} = ctx->{field}[{register}];"
            for field, register, ctype in cached
        )
        flush = " ".join(
            f"ctx->{field}[{register}] = local_{field}_{register};"
            for field, register, _ctype in cached
        )
        body = body.replace("return;", f"do {{ {flush} return; }} while (0);")
        text = prefix + "\n    " + declarations + body
    return text


def guest_pc(value: str) -> int:
    parsed = int(value, 0)
    if parsed < 0 or parsed > 0xFFFFFFFF:
        raise argparse.ArgumentTypeError("guest PC must fit in u32")
    return parsed


def register(value: str) -> int:
    parsed = int(value, 0)
    if parsed < 0 or parsed > 31:
        raise argparse.ArgumentTypeError("register must be in 0..31")
    return parsed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    parser.add_argument("--entry", type=guest_pc, required=True)
    parser.add_argument("--return-pc", type=guest_pc, action="append", default=[])
    parser.add_argument("--name", required=True)
    parser.add_argument("--cache-gpr", type=register, action="append", default=[])
    parser.add_argument("--cache-fpr", type=register, action="append", default=[])
    parser.add_argument("--cache-ps1", type=register, action="append", default=[])
    parser.add_argument("--fp-gate-pc", type=guest_pc)
    parser.add_argument("--hot", action="store_true")
    args = parser.parse_args()

    if not args.source.is_file():
        parser.error(f"source does not exist: {args.source}")
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", args.name):
        parser.error("--name must be a C identifier")

    transformed = transform(
        args.source.read_text(encoding="utf-8"),
        args.entry,
        args.return_pc,
        args.name,
        sorted(set(args.cache_gpr)),
        sorted(set(args.cache_fpr)),
        sorted(set(args.cache_ps1)),
        args.fp_gate_pc,
        args.hot,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(transformed, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
