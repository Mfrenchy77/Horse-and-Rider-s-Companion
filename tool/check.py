#!/usr/bin/env python3
"""Run repeatable offline-safe checks; individual failures do not hide others."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = "^(horseandriderscompanion|authentication_repository|database_repository|form_inputs|cache)$"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-pub", action="store_true", help="Use already resolved Flutter dependencies")
    parser.add_argument("--skip-functions", action="store_true", help="Run Flutter checks only")
    args = parser.parse_args()
    expected = json.loads((ROOT / ".fvmrc").read_text())["flutter"]
    flutter = os.environ.get("FLUTTER_BIN")
    settings = ROOT / ".vscode/settings.json"
    if not flutter and settings.exists():
        configured = json.loads(settings.read_text()).get("dart.flutterSdkPath")
        if configured:
            candidate = (ROOT / configured / "bin/flutter").resolve()
            if candidate.is_file():
                flutter = str(candidate)
    flutter = flutter or shutil.which("flutter")
    npm = os.environ.get("NPM_BIN") or shutil.which("npm")
    if not flutter or (not npm and not args.skip_functions):
        sys.exit(f"Install Flutter {expected} and Node.js 20.19+ (with npm), or set FLUTTER_BIN / NPM_BIN.")
    version = subprocess.run([flutter, "--version", "--machine"], capture_output=True, text=True, check=True)
    actual = json.loads(version.stdout)["frameworkVersion"]
    if actual != expected:
        sys.exit(f"Use Flutter {expected}; found {actual}. Select that SDK with FVM or FLUTTER_BIN before running checks.")
    sdk_root = Path(json.loads(version.stdout)["flutterRoot"]).resolve()
    child_env = os.environ.copy()
    child_env["PATH"] = str(sdk_root / "bin") + os.pathsep + child_env.get("PATH", "")
    child_env["FLUTTER_ROOT"] = str(sdk_root)
    child_env["DART_SDK"] = str(sdk_root / "bin/cache/dart-sdk")
    failures = []

    def run(label, command, cwd=ROOT):
        print(f"\n>>> {label}", flush=True)
        try:
            result = subprocess.run(command, cwd=cwd, env=child_env, check=False)
        except OSError as error:
            print(f"Could not run {label}: {error}", file=sys.stderr)
            failures.append(label)
            return False
        if result.returncode:
            failures.append(label)
        return result.returncode == 0

    if not args.no_pub and not run("Resolve Flutter dependencies", [flutter, "pub", "get"]):
        sys.exit(1)
    config = ROOT / ".dart_tool/package_config.json"
    if not config.exists():
        sys.exit("Dependency metadata is missing. Run the check again without --no-pub.")
    metadata = json.loads(config.read_text())
    configured_sdk = Path(unquote(urlparse(metadata.get("flutterRoot", "")).path)).resolve()
    if metadata.get("flutterVersion") != actual or configured_sdk != sdk_root:
        sys.exit("Dependency metadata belongs to a different Flutter SDK. "
                 "Stop other dependency-resolution processes and run this check without --no-pub.")
    run("Analyze app, tests and local packages", [flutter, "analyze", "--no-pub", "--no-fatal-infos", "lib", "test", "packages"])
    run("Coverage report self-tests", [sys.executable, "-m", "unittest", "discover", "-s", "test_tools"])
    coverage = ROOT / "coverage"
    coverage.mkdir(exist_ok=True)
    for generated in ["lcov.info", "summary.md", "summary.json"]:
        (coverage / generated).unlink(missing_ok=True)
    tests_passed = run("Flutter tests and package coverage", [flutter, "test", "--no-pub", "--coverage", "--coverage-package", PACKAGES, "--reporter", "expanded"])
    (coverage / "run_status.json").write_text(json.dumps({"tests_passed": tests_passed, "flutter": actual}))
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
