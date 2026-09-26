#!/usr/bin/env bash
# Rebuilds the Warden and Weaver models from art/characters/build_heroes.py.
set -euo pipefail
cd "$(dirname "$0")/.."
BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
"$BLENDER" -b --factory-startup --python art/characters/build_heroes.py -- \
	--out assets/characters --preview art/heroes "$@" 2>&1 \
	| grep -E "^HERO|Error|Traceback|File \"|line [0-9]+" || true
