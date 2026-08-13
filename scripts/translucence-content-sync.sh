#!/usr/bin/env bash
set -euo pipefail

TRANSLUCENCE="${TRANSLUCENCE:-/workspaces/translucence}"
TOME="${TOME:-/workspaces/tome}"

if [[ ! -d "${TRANSLUCENCE}/content" ]]; then
  echo "translucence content not found at ${TRANSLUCENCE}/content" >&2
  exit 1
fi

export TOME_CONTENT_PATH="${TRANSLUCENCE}/content"
export TOME_DB_PATH="${TRANSLUCENCE}/data/tome.sqlite"

exec bash "${TOME}/scripts/content-sync.sh"
