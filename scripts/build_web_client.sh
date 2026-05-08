#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
BUILD_ALIAS_ROOT="/tmp/receipt_scanner_web_build"
FLUTTER_BIN="${FLUTTER_BIN:-$HOME/development/flutter/bin/flutter}"

ln -sfn "$PROJECT_ROOT" "$BUILD_ALIAS_ROOT"

cd "$BUILD_ALIAS_ROOT/mobile_app"
"$FLUTTER_BIN" build web --release
