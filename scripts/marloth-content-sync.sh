#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -d "${MARLOTH}/content" ]]; then
  echo "marloth-story content not found at ${MARLOTH}/content" >&2
  exit 1
fi

export TOME_CONTENT_PATH="${MARLOTH}/content"
export TOME_DB_PATH="${MARLOTH}/data/tome.sqlite"

exec bash "${TOME}/scripts/content-sync.sh"
