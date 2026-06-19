#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

bun scripts/install-repos.ts || true

if [[ ! -d repos/tome/packages/tome-db ]]; then
  echo "Workspace repos not present under repos/. Clone requires SSH access to GitHub."
  echo "Run: bun run repos:install"
  exec sleep infinity
fi

bun install --frozen-lockfile
exec bun run editor:dev
