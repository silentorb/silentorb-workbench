#!/usr/bin/env bash
set -euo pipefail

TOME="${TOME:-/workspaces/tome}"

if [[ ! -d "${TOME}/packages/tome-db" ]] || [[ ! -d "${TOME}/packages/tome-store-flatfile" ]] || [[ ! -d "${TOME}/packages/tome-cache-sqlite" ]]; then
  echo "tome repo not found at ${TOME} (expected packages: tome-db, tome-store-flatfile, tome-cache-sqlite)" >&2
  exit 1
fi

cd "$TOME"
exec bun "$@"
