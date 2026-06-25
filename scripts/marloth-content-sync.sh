#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARLOTH="${ROOT}/repos/marloth-story"

if [[ ! -d "${MARLOTH}/content" ]]; then
  echo "marloth-story content not found at ${MARLOTH}/content" >&2
  exit 1
fi

export TOME_CONTENT_PATH="${MARLOTH}/content"
export TOME_DB_PATH="${MARLOTH}/data/tome.sqlite"

exec bash "${ROOT}/repos/tome/scripts/content-sync.sh"
