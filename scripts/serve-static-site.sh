#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${TOME_WEB_PORT:-${MARLOTH_WEB_PORT:-8787}}"
OUT="${TOME_WEB_OUT_DIR:-${MARLOTH_WEB_OUT_DIR:-${ROOT}/repos/marloth-story/dist/web}}"

if [[ ! -f "$OUT/index.html" ]]; then
  echo "Missing $OUT/index.html — run: bash scripts/build-static-site.sh" >&2
  exit 1
fi

echo "Static site → http://127.0.0.1:${PORT}/"
exec python3 -m http.server "$PORT" --directory "$OUT"
