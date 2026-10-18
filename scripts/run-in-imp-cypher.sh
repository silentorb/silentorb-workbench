#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -f "${IMP_CYPHER}/package.json" ]]; then
  echo "imp-cypher repo not found at ${IMP_CYPHER} (expected package.json)" >&2
  exit 1
fi

if [[ ! -d "${IMP_TS}/packages/imp-core-types" ]]; then
  echo "imp-ts repo not found at ${IMP_TS} (imp-cypher workspaces require sibling imp-ts packages)" >&2
  exit 1
fi

cd "$IMP_CYPHER"
exec bun "$@"
