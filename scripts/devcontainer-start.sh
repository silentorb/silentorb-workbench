#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -d "${TOME}/packages/tome-db" ]] || [[ ! -d "${TOME}/packages/tome-flatfile" ]] || [[ ! -d "${TOME}/packages/tome-sqlite" ]]; then
  echo "Sibling repos not mounted. Clone tome and marloth-story as siblings of this repo, then reopen the devcontainer."
  echo "  ../../tome           → ${TOME}"
  echo "  ../../marloth-story  → ${MARLOTH}"
  exec sleep infinity
fi

if [[ ! -d "${MARLOTH}/content" ]]; then
  echo "marloth-story content not found at ${MARLOTH}/content."
  echo "Mount marloth-story as a sibling repo, then reopen the devcontainer."
  exec sleep infinity
fi

exec sleep infinity
