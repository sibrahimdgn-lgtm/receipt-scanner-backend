#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/mobile_app/build/web"

if [ ! -f "$BUILD_DIR/flutter_bootstrap.js" ] || [ ! -f "$BUILD_DIR/main.dart.js" ]; then
  echo "Flutter web build eksik veya bozuk. Once ./scripts/build_web_client.sh calistirin." >&2
  exit 1
fi

cd "$BUILD_DIR"
python3 -m http.server "${WEB_PORT:-8080}"
