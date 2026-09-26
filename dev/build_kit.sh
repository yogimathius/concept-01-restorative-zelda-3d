#!/usr/bin/env bash
# Rebuilds the Broken Ford environment kit from art/kit/*.py (headless Blender).
# Usage: dev/build_kit.sh [--only ground,pool]
set -euo pipefail
cd "$(dirname "$0")/.."
BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
"$BLENDER" -b --factory-startup --python art/kit/build_kit.py -- \
	--out assets/kit --blend art/kit.blend --sheet art/kit_sheet.png "$@" 2>&1 \
	| grep -E "^KIT|Error|Traceback|File \"|line [0-9]+" || true
