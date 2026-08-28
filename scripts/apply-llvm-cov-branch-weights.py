#!/usr/bin/env python3
"""Apply exact llvm-cov branch counts to a bounded generated-C line range.

The input JSON must come from ``llvm-cov export`` for the unchanged source.
This tool deliberately supports only ordinary C ``if``/``else if`` conditions
and simple short-circuit chains. It rejects unfamiliar shapes instead of
guessing how coverage branches map back to source expressions.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
from collections import defaultdict


Branch = tuple[int, int]


def condition_span(line: str) -> tuple[int, int]:
    marker = line.find("if (")
    if marker < 0:
        raise ValueError(f"coverage branch is not on an if condition: {line.strip()}")
    start = marker + len("if (")
    depth = 1
    for index in range(start, len(line)):
        char = line[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return start, index
    raise ValueError(f"unterminated if condition: {line.strip()}")


def split_short_circuit(expression: str) -> tuple[str, list[str]] | None:
    depth = 0
    operator: str | None = None
    parts: list[str] = []
    start = 0
    index = 0
    while index + 1 < len(expression):
        char = expression[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth < 0:
                raise ValueError(f"unbalanced condition: {expression}")
        elif depth == 0 and expression[index : index + 2] in ("&&", "||"):
            found = expression[index : index + 2]
            if operator is not None and found != operator:
                raise ValueError(f"mixed top-level short-circuit condition: {expression}")
            operator = found
            parts.append(expression[start:index].strip())
            start = index + 2
            index += 1
        index += 1
    if depth != 0:
        raise ValueError(f"unbalanced condition: {expression}")
    if operator is None:
        return None
    parts.append(expression[start:].strip())
    if any(not part for part in parts):
        raise ValueError(f"empty short-circuit operand: {expression}")
    return operator, parts


def probability(branch: Branch) -> str:
    true_count, false_count = branch
    total = true_count + false_count
    if total == 0:
        raise ValueError("unexecuted branch has no probability")
    return f"{true_count / total:.17g}"


def expect(expression: str, branch: Branch) -> str:
    return (
        "__builtin_expect_with_probability(!!("
        + expression
        + "), 1, "
        + probability(branch)
        + ")"
    )


def weighted_condition(expression: str, branches: list[Branch]) -> str:
    if len(branches) == 1:
        return expect(expression, branches[0])
    split = split_short_circuit(expression)
    if split is None:
        raise ValueError(
            f"{len(branches)} coverage branches need a short-circuit condition: {expression}"
        )
    operator, parts = split
    if len(parts) != len(branches):
        raise ValueError(
            f"{len(branches)} coverage branches do not match {len(parts)} operands: {expression}"
        )
    return f" {operator} ".join(expect(part, branch) for part, branch in zip(parts, branches))


def load_branches(
    coverage: dict, source: pathlib.Path, start_line: int, end_line: int
) -> dict[int, list[Branch]]:
    matches = []
    resolved = source.resolve()
    for data in coverage.get("data", []):
        for entry in data.get("files", []):
            if pathlib.Path(entry.get("filename", "")).resolve() == resolved:
                matches.append(entry)
    if len(matches) != 1:
        raise ValueError(f"expected one coverage file for {resolved}, found {len(matches)}")

    result: dict[int, list[Branch]] = defaultdict(list)
    for record in matches[0].get("branches", []):
        if len(record) < 6:
            raise ValueError(f"malformed coverage branch record: {record}")
        line = int(record[0])
        if start_line <= line <= end_line:
            result[line].append((int(record[4]), int(record[5])))
    if not result:
        raise ValueError(f"no coverage branches in lines {start_line}..{end_line}")
    return dict(result)


def transform(
    source_text: str, branches: dict[int, list[Branch]]
) -> tuple[str, int, int]:
    lines = source_text.splitlines(keepends=True)
    weighted = 0
    skipped = 0
    for line_number, records in sorted(branches.items()):
        if line_number < 1 or line_number > len(lines):
            raise ValueError(f"coverage line {line_number} is outside the source")
        if any(true + false == 0 for true, false in records):
            if not all(true + false == 0 for true, false in records):
                raise ValueError(f"line {line_number} mixes executed and unexecuted branches")
            skipped += len(records)
            continue
        original = lines[line_number - 1]
        newline = "\n" if original.endswith("\n") else ""
        body = original[:-1] if newline else original
        start, end = condition_span(body)
        replacement = weighted_condition(body[start:end], records)
        lines[line_number - 1] = body[:start] + replacement + body[end:] + newline
        weighted += len(records)
    return "".join(lines), weighted, skipped


def mark_hot_function(source_text: str, function: str) -> str:
    if not re.fullmatch(r"func_[0-9A-Fa-f]+", function):
        raise ValueError(f"invalid generated function name: {function}")
    signature = f"void {function}(CPUState* ctx) {{"
    replacement = f"__attribute__((hot)) void {function}(CPUState* ctx) {{"
    count = source_text.count(signature)
    if count != 1:
        raise ValueError(f"expected one definition of {function}, found {count}")
    return source_text.replace(signature, replacement, 1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("coverage_json", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    parser.add_argument("--start-line", type=int, required=True)
    parser.add_argument("--end-line", type=int, required=True)
    parser.add_argument("--hot-function")
    args = parser.parse_args()
    if args.start_line < 1 or args.end_line < args.start_line:
        parser.error("invalid source line range")

    source_text = args.source.read_text(encoding="utf-8")
    coverage = json.loads(args.coverage_json.read_text(encoding="utf-8"))
    branches = load_branches(coverage, args.source, args.start_line, args.end_line)
    result, weighted, skipped = transform(source_text, branches)
    if args.hot_function:
        result = mark_hot_function(result, args.hot_function)
    args.output.write_text(result, encoding="utf-8")
    print(f"weighted_branches,{weighted}")
    print(f"skipped_unexecuted_branches,{skipped}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
