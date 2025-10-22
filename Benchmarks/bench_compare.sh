#!/usr/bin/env bash
# Run the Swift benchmark compare command and pipe its markdown output into the Python parser.
# Usage: run this from the repository root.

set -euo pipefail

# If you want to pass additional args to the swift command, set SWIFT_ARGS environment variable.
SWIFT_ARGS=${SWIFT_ARGS:-"baseline compare swiftcbor --format markdown --no-progress"}
PY_SCRIPT="$(dirname "$0")/bench_compare.py"

swift -version
# Run the swift command and pipe
swift package benchmark $SWIFT_ARGS | python3 "$PY_SCRIPT"
