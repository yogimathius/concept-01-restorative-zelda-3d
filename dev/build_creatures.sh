#!/usr/bin/env bash
# Rebuilds Bearer / Charger models from art/characters/build_creatures.py.
set -euo pipefail
cd "$(dirname "$0")/.."
BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
"$BLENDER" -b --factory-startup --python art/characters/build_creatures.py -- \
	--out assets/creatures --preview art/creatures "$@" 2>&1 \
	| grep -E "^CREATURE|Error|Traceback|File \"|line [0-9]+" || true
