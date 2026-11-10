#!/usr/bin/env python3
"""Summarize LCOV with explicit denominators and untested source-file counts."""

from collections import defaultdict
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
source = ROOT / "coverage/lcov.info"
if not source.exists():
    sys.exit("No coverage/lcov.info; run python3 tool/check.py first.")
files = defaultdict(lambda: [0, 0])
name = ""
for line in source.read_text().splitlines():
    if line.startswith("SF:"):
        path = Path(line[3:])
        if path.is_absolute():
            try:
                path = path.relative_to(ROOT)
            except ValueError:
                continue
        name = path.as_posix()
    elif line.startswith("DA:"):
        _, hits = line[3:].split(",")[:2]
        files[name][0] += 1
        files[name][1] += int(int(hits) > 0)
groups = defaultdict(lambda: [0, 0])
for path, (total, hit) in files.items():
    key = path.split("/")[1] if path.startswith("packages/") else "app"
    groups[key][0] += total
    groups[key][1] += hit
rows = ["# Test coverage", "", "Measured executable lines in the LCOV report; this is not proof of end-to-end behavior.", "", "| Component | Covered / measured lines | Coverage |", "| --- | ---: | ---: |"]
for key, (total, hit) in sorted(groups.items()):
    rows.append(f"| {key} | {hit} / {total} | {hit / total:.1%} |")
total = sum(v[0] for v in groups.values())
hit = sum(v[1] for v in groups.values())
rows.append(f"| **Total** | **{hit} / {total}** | **{hit / total:.1%}** |")
all_sources = {p.relative_to(ROOT).as_posix() for base in [ROOT / "lib", ROOT / "packages"]
               for p in base.rglob("*.dart") if ".dart_tool" not in p.parts}
missing = sorted(all_sources - files.keys())
rows += ["", f"{len(missing)} Dart source files are absent from LCOV and therefore excluded from that percentage.", "", "## Largest measured gaps", "", "| File | Uncovered lines |", "| --- | ---: |"]
for path, (count, covered) in sorted(files.items(), key=lambda item: item[1][0] - item[1][1], reverse=True)[:20]:
    rows.append(f"| {path} | {count - covered} |")
rows += ["", "## Source files absent from LCOV", ""] + [f"- {path}" for path in missing]
report = ROOT / "coverage/summary.md"
report.write_text("\n".join(rows) + "\n")
print("\n".join(rows[:len(groups) + 9]))
print(f"\nFull coverage report: {report}")
