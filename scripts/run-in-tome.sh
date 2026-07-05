#!/usr/bin/env bash
set -euo pipefail

TOME="${TOME:-/workspaces/tome}"

if [[ ! -d "${TOME}/packages/tome-db" ]]; then
  echo "tome repo not found at ${TOME}" >&2
  exit 1
fi

cd "$TOME"
exec bun "$@"
