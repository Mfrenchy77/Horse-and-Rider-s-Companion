#!/usr/bin/env python3
"""Summarize LCOV without counting external files or duplicate line records."""

from collections import defaultdict
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read_lcov(text, root):
    files = {}
    current = None
    for record in text.splitlines():
        if record.startswith('SF:'):
            current = None
            path = Path(record[3:])
            if path.is_absolute():
                try:
                    path = path.relative_to(root)
                except ValueError:
                    continue
            parts = path.parts
            local = parts and parts[0] == 'lib'
            local_package = len(parts) > 2 and parts[0] == 'packages' and parts[2] == 'lib'
            if not (local or local_package) or '..' in parts:
                continue
            current = path.as_posix()
            files.setdefault(current, {})
        elif record.startswith('DA:') and current is not None:
            line, hits = record[3:].split(',')[:2]
            line = int(line)
            files[current][line] = files[current].get(line, 0) + int(hits)
        elif record == 'end_of_record':
            current = None
    return files


def summarize(files, sources):
    counts = {name: {'total': len(lines), 'covered': sum(hits > 0 for hits in lines.values())}
              for name, lines in files.items()}
    components = defaultdict(lambda: {'total': 0, 'covered': 0})
    for name, count in counts.items():
        key = name.split('/')[1] if name.startswith('packages/') else 'app'
        for field in ['total', 'covered']:
            components[key][field] += count[field]
    total = {field: sum(count[field] for count in counts.values()) for field in ['total', 'covered']}
    return {'components': dict(components), 'total': total, 'files': counts,
            'absent_files': sorted(set(sources) - files.keys())}


def main(root=ROOT):
    source = root / 'coverage/lcov.info'
    if not source.exists():
        sys.exit('No coverage/lcov.info; run python3 tool/check.py first.')
    sources = {p.relative_to(root).as_posix()
               for base in [root / 'lib', *(root / 'packages').glob('*/lib')]
               for p in base.rglob('*.dart')}
    result = summarize(read_lcov(source.read_text(), root), sources)
    status_path = root / 'coverage/run_status.json'
    status = json.loads(status_path.read_text()) if status_path.exists() else {}
    result['run_status'] = status
    if status.get('tests_passed') is False:
        banner = '**INCOMPLETE: Flutter tests failed. These are partial coverage results.**'
    elif status.get('tests_passed') is True:
        banner = 'The Flutter test run passed. Line coverage does not prove end-to-end behavior.'
    else:
        banner = 'Test-run status is unknown. Line coverage does not prove end-to-end behavior.'
    rows = ['# Test coverage', '', banner, '',
            '| Component | Covered / measured lines | Coverage |', '| --- | ---: | ---: |']
    entries = [*sorted(result['components'].items()), ('Total', result['total'])]
    for label, count in entries:
        percent = count['covered'] / count['total'] if count['total'] else 0
        rows.append(f"| {label} | {count['covered']} / {count['total']} | {percent:.1%} |")
    rows += ['', f"{len(result['absent_files'])} source files are absent from LCOV and excluded from these percentages.",
             '', 'Archived training-path and prerequisite implementation tests are included.',
             '', '## Largest measured gaps', '', '| File | Uncovered lines |', '| --- | ---: |']
    for name, count in sorted(result['files'].items(),
                              key=lambda item: item[1]['total'] - item[1]['covered'], reverse=True)[:20]:
        rows.append(f"| {name} | {count['total'] - count['covered']} |")
    rows += ['', '## Source files absent from LCOV', ''] + [f'- {name}' for name in result['absent_files']]
    (root / 'coverage/summary.md').write_text('\n'.join(rows) + '\n')
    (root / 'coverage/summary.json').write_text(json.dumps(result, indent=2) + '\n')
    print('\n'.join(rows[:len(entries) + 8]))
    print(f"\nFull report: {root / 'coverage/summary.md'}")


if __name__ == '__main__':
    main()
