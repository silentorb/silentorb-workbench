#!/usr/bin/env bash
set -euo pipefail

TOME="${TOME:-/workspaces/tome}"

if [[ ! -d "${TOME}/packages/tome-db" ]] || [[ ! -d "${TOME}/packages/tome-flatfile" ]] || [[ ! -d "${TOME}/packages/tome-sqlite" ]]; then
  echo "tome repo not found at ${TOME} (expected packages: tome-db, tome-flatfile, tome-sqlite)" >&2
  exit 1
fi

cd "$TOME"
exec bun "$@"
