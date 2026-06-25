#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOME="${ROOT}/repos/tome"

if [[ ! -d "${TOME}/packages/tome-db" ]]; then
  echo "tome repo not found at ${TOME}" >&2
  exit 1
fi

cd "$TOME"
exec bun "$@"
