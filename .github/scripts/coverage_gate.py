#!/usr/bin/env python3
"""Per-class Apex coverage gate (KES-DEV-4 §1: >= 85% per class at promotion to main).

Reads the coverage report written by
    sf project deploy validate ... --coverage-formatters json --results-dir <dir>
(<dir>/coverage/coverage.json, Istanbul format; coverage-summary.json is used when present)
and prints a per-class table.

Exit status: non-zero when any class is under the threshold and the target branch is main or uat;
on develop (and anything else) a shortfall is reported as a warning annotation and the job passes,
so work in progress can merge to develop.

Usage: coverage_gate.py <results-dir> [threshold]      (TARGET_BRANCH from the environment)
"""
import json
import os
import sys
from pathlib import Path

ENFORCED_BRANCHES = {"main", "uat"}


def class_name(path: str) -> str:
    name = Path(path).name
    for suffix in (".cls", ".trigger"):
        if name.endswith(suffix):
            return name[: -len(suffix)]
    return name


def from_summary(summary: dict) -> dict:
    out = {}
    for path, data in summary.items():
        if path == "total":
            continue
        lines = data.get("lines", {})
        out[class_name(path)] = (lines.get("covered", 0), lines.get("total", 0))
    return out


def from_istanbul(report: dict) -> dict:
    out = {}
    for path, data in report.items():
        hits = data.get("s", {})
        total = len(hits)
        covered = sum(1 for v in hits.values() if v)
        out[class_name(data.get("path", path))] = (covered, total)
    return out


def load(results_dir: Path) -> dict:
    cov = results_dir / "coverage"
    summary = cov / "coverage-summary.json"
    if summary.is_file():
        return from_summary(json.loads(summary.read_text()))
    istanbul = cov / "coverage.json"
    if istanbul.is_file():
        return from_istanbul(json.loads(istanbul.read_text()))
    raise FileNotFoundError(f"no coverage report under {cov}")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    results_dir = Path(argv[1])
    threshold = float(argv[2]) if len(argv) > 2 else 85.0
    branch = os.environ.get("TARGET_BRANCH") or os.environ.get("GITHUB_BASE_REF") or os.environ.get("GITHUB_REF_NAME", "")
    enforced = branch in ENFORCED_BRANCHES

    try:
        classes = load(results_dir)
    except FileNotFoundError as e:
        print(f"::error title=coverage gate::{e}")
        return 1

    below = []
    print(f"{'Class':48} {'Covered':>8} {'Lines':>6} {'Pct':>7}")
    for name in sorted(classes):
        covered, total = classes[name]
        pct = 100.0 if total == 0 else 100.0 * covered / total
        flag = "" if pct >= threshold else "  < " + f"{threshold:g}%"
        print(f"{name:48} {covered:>8} {total:>6} {pct:>6.1f}%{flag}")
        if pct < threshold:
            below.append((name, pct))

    if not below:
        print(f"coverage gate: all {len(classes)} classes at or above {threshold:g}%")
        return 0
    level = "error" if enforced else "warning"
    for name, pct in below:
        print(f"::{level} title=coverage gate::{name} at {pct:.1f}% (KES-DEV-4 requires {threshold:g}% per class)")
    if enforced:
        print(f"coverage gate: {len(below)} class(es) below {threshold:g}% on {branch}; failing")
        return 1
    print(f"coverage gate: {len(below)} class(es) below {threshold:g}% (advisory on {branch or 'this branch'})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
