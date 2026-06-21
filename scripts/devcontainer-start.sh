#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -d repos/tome/packages/tome-db ]]; then
  echo "Sibling repos not mounted. Clone tome and marloth-story as siblings of this repo, then reopen the devcontainer."
  echo "  ../../tome           → repos/tome"
  echo "  ../../marloth-story  → repos/marloth-story"
  exec sleep infinity
fi

if [[ ! -d repos/marloth-story/content ]]; then
  echo "marloth-story content not found at repos/marloth-story/content."
  echo "Mount marloth-story as a sibling repo, then reopen the devcontainer."
  exec sleep infinity
fi

# shellcheck source=ensure-node-modules.sh
source "$(dirname "$0")/ensure-node-modules.sh"
exec sleep infinity
