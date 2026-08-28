#!/usr/bin/env python3
"""Transform generated chunk entry switches for bounded layout preflights.

This is a private generated-source preflight tool. It does not understand or
contain game code; it preserves every emitted case and rejects unexpected C
shapes instead of guessing.
"""

from __future__ import annotations

import argparse
import pathlib
import re


FUNCTION = re.compile(r"^void (?P<name>func_[0-9A-Fa-f]+)\(CPUState\* ctx\) \{$")
CASE = re.compile(
    r"^    case 0x(?P<address>[0-9A-Fa-f]{8})u: goto "
    r"(?P<label>label_[0-9A-Fa-f]{8});$"
)


def validate_cases(function: str, cases: list[tuple[int, str]]) -> tuple[int, int]:
    if not cases:
        raise ValueError(f"{function}: empty entry switch")
    first = min(address for address, _label in cases)
    last = max(address for address, _label in cases)
    if any((address - first) & 3 for address, _label in cases):
        raise ValueError(f"{function}: unaligned entry address")
    if len({address for address, _label in cases}) != len(cases):
        raise ValueError(f"{function}: duplicate entry address")
    return first, last


def computed_table(function: str, cases: list[tuple[int, str]]) -> list[str]:
    first, last = validate_cases(function, cases)

    entries = {address: label for address, label in cases}
    result = [
        "    const u32 entry_pc = ctx->pc;\n",
        f"    if (entry_pc < 0x{first:08X}u || entry_pc > 0x{last:08X}u ||\n",
        f"        ((entry_pc - 0x{first:08X}u) & 3u) != 0)\n",
        "        return;\n",
        f"    static void* const {function}_entry_targets[] = {{\n",
    ]
    for address in range(first, last + 4, 4):
        label = entries.get(address)
        result.append(f"        {'&&' + label if label else 'NULL'},\n")
    result.extend(
        [
            "    };\n",
            f"    void* entry_target = {function}_entry_targets[\n",
            f"        (entry_pc - 0x{first:08X}u) >> 2];\n",
            "    if (entry_target == NULL)\n",
            "        return;\n",
            "    goto *entry_target;\n",
        ]
    )
    return result


def biased_switch(
    function: str, cases: list[tuple[int, str]], hot_entry: int
) -> list[str]:
    validate_cases(function, cases)
    labels = {address: label for address, label in cases}
    hot_label = labels.get(hot_entry)
    if hot_label is None:
        raise ValueError(f"{function}: hot entry 0x{hot_entry:08X} is not a case")
    result = [
        f"    if (__builtin_expect(ctx->pc == 0x{hot_entry:08X}u, 1))\n",
        f"        goto {hot_label};\n",
        "    switch (ctx->pc) {\n",
    ]
    for address, label in cases:
        if address != hot_entry:
            result.append(f"    case 0x{address:08X}u: goto {label};\n")
    result.extend(["    default: return;\n", "    }\n"])
    return result


def transform(text: str, mode: str, hot_entry: int | None) -> tuple[str, int]:
    lines = text.splitlines(keepends=True)
    output: list[str] = []
    index = 0
    transformed = 0
    pending_function: str | None = None

    while index < len(lines):
        stripped = lines[index].rstrip("\n")
        function_match = FUNCTION.match(stripped)
        if function_match:
            pending_function = function_match.group("name")
            output.append(lines[index])
            index += 1
            continue

        if pending_function and stripped == "    switch (ctx->pc) {":
            cases: list[tuple[int, str]] = []
            index += 1
            while index < len(lines):
                switch_line = lines[index].rstrip("\n")
                case_match = CASE.match(switch_line)
                if case_match:
                    cases.append(
                        (int(case_match.group("address"), 16), case_match.group("label"))
                    )
                    index += 1
                    continue
                if switch_line == "    default: return;":
                    index += 1
                    if index >= len(lines) or lines[index].rstrip("\n") != "    }":
                        raise ValueError(f"{pending_function}: malformed switch end")
                    index += 1
                    break
                raise ValueError(
                    f"{pending_function}: unexpected entry switch line: {switch_line}"
                )
            if mode == "computed":
                output.extend(computed_table(pending_function, cases))
            else:
                if hot_entry is None:
                    raise ValueError("biased mode requires --hot-entry")
                output.extend(biased_switch(pending_function, cases, hot_entry))
            transformed += 1
            pending_function = None
            continue

        output.append(lines[index])
        index += 1

    if pending_function:
        raise ValueError(f"{pending_function}: entry switch not found")
    if transformed == 0:
        raise ValueError("no generated function entry switches found")
    return "".join(output), transformed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    parser.add_argument("--mode", choices=("computed", "biased"), default="computed")
    parser.add_argument("--hot-entry", type=lambda value: int(value, 0))
    args = parser.parse_args()
    source = args.source.read_text(encoding="utf-8")
    result, count = transform(source, args.mode, args.hot_entry)
    args.output.write_text(result, encoding="utf-8")
    print(f"transformed_entry_switches,{count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
