#!/usr/bin/env bash
# Runs the headless test suite. Usage: dev/test.sh [name-filter]
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Users/mathiusjohnson/Downloads/Godot.app/Contents/MacOS/Godot}"

# refresh the global class cache so new class_name scripts resolve under -s
"$GODOT" --headless --path . --import >/dev/null 2>&1

# hard limit: a runner that dies on a script error never calls quit()
OUT=$(perl -e 'alarm 900; exec @ARGV' "$GODOT" --headless --path . -s tests/run_all.gd -- "$@" 2>&1)
STATUS=$?
echo "$OUT" | grep -v '^Godot Engine'
if echo "$OUT" | grep -qE "SCRIPT ERROR|Parse Error"; then
	echo "!! script errors in output: treating as failure"
	exit 1
fi
exit $STATUS
