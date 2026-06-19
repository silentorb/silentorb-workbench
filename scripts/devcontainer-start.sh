#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -d repos/tome/packages/tome-db ]]; then
  echo "Sibling repos not mounted. Clone tome and marloth-story as siblings of this repo, then reopen the devcontainer."
  echo "  ../tome           → repos/tome"
  echo "  ../marloth-story  → repos/marloth-story"
  exec sleep infinity
fi

bun install --frozen-lockfile
exec bun run editor:dev
