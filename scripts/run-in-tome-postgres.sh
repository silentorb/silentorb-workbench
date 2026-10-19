#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -f "${TOME_POSTGRES}/package.json" ]]; then
  echo "tome-postgres repo not found at ${TOME_POSTGRES} (expected package.json)" >&2
  exit 1
fi

if [[ ! -d "${TOME}/packages/tome-graph-interfaces" ]]; then
  echo "tome repo not found at ${TOME} (tome-postgres workspaces require sibling tome packages)" >&2
  exit 1
fi

if [[ ! -d "${IMP_TS}/packages/imp-core-types" ]]; then
  echo "imp-ts repo not found at ${IMP_TS} (tome-postgres workspaces require sibling imp-ts packages)" >&2
  exit 1
fi

cd "$TOME_POSTGRES"
exec bun "$@"
