#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d /workspaces/tome/packages/tome-db ]]; then
  echo "Sibling repos not mounted. Clone tome and marloth-story as siblings of this repo, then reopen the devcontainer."
  echo "  ../../tome           → /workspaces/tome"
  echo "  ../../marloth-story  → /workspaces/marloth-story"
  exec sleep infinity
fi

if [[ ! -d /workspaces/marloth-story/content ]]; then
  echo "marloth-story content not found at /workspaces/marloth-story/content."
  echo "Mount marloth-story as a sibling repo, then reopen the devcontainer."
  exec sleep infinity
fi

exec sleep infinity
