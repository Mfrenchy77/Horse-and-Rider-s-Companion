#!/usr/bin/env python3
"""Run repeatable offline-safe checks; individual failures do not hide others."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = "^(horseandriderscompanion|authentication_repository|database_repository|form_inputs|cache)$"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-pub", action="store_true", help="Use already resolved Flutter dependencies")
    parser.add_argument("--skip-functions", action="store_true", help="Run Flutter checks only")
    args = parser.parse_args()
    flutter = os.environ.get("FLUTTER_BIN") or shutil.which("flutter")
    npm = os.environ.get("NPM_BIN") or shutil.which("npm")
    if not flutter or (not npm and not args.skip_functions):
        sys.exit("Install Flutter 3.38.1 and Node.js 20.19+ (with npm), or set FLUTTER_BIN / NPM_BIN.")
    expected = json.loads((ROOT / ".fvmrc").read_text())["flutter"]
    version = subprocess.run([flutter, "--version", "--machine"], capture_output=True, text=True, check=True)
    actual = json.loads(version.stdout)["frameworkVersion"]
    if actual != expected:
        sys.exit(f"Use Flutter {expected}; found {actual}. Select that SDK with FVM or FLUTTER_BIN before running checks.")
    failures = []

    def run(label, command, cwd=ROOT):
        print(f"\n>>> {label}", flush=True)
        result = subprocess.run(command, cwd=cwd, check=False)
        if result.returncode:
            failures.append(label)
        return result.returncode == 0

    if not args.no_pub and not run("Resolve Flutter dependencies", [flutter, "pub", "get"]):
        sys.exit(1)
    run("Analyze app, tests and local packages", [flutter, "analyze", "--no-pub", "--no-fatal-infos", "lib", "test", "packages"])
    run("Flutter tests and package coverage", [flutter, "test", "--no-pub", "--coverage", "--coverage-package", PACKAGES, "--reporter", "expanded"])
    if (ROOT / "coverage/lcov.info").exists():
        run("Summarize coverage", [sys.executable, str(ROOT / "tool/coverage_summary.py")])
    if not args.skip_functions:
        if not (ROOT / "functions/node_modules").exists():
            run("Install locked function dependencies", [npm, "ci", "--ignore-scripts", "--no-audit", "--no-fund"], ROOT / "functions")
        run("Lint Firebase functions", [npm, "run", "lint"], ROOT / "functions")
        run("Test Firebase functions", [npm, "test"], ROOT / "functions")
    if failures:
        sys.exit("\nFailed checks: " + ", ".join(failures))
    print("\nAll selected checks passed.")


if __name__ == "__main__":
    main()
