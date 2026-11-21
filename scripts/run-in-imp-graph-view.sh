#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -f "${IMP_GRAPH_VIEW}/package.json" ]]; then
  echo "imp-graph-view repo not found at ${IMP_GRAPH_VIEW} (expected package.json)" >&2
  exit 1
fi

if [[ ! -d "${IMP_TS}/packages/imp-core-types" ]]; then
  echo "imp-ts repo not found at ${IMP_TS} (imp-graph-view workspaces require sibling imp-ts packages)" >&2
  exit 1
fi

cd "$IMP_GRAPH_VIEW"
exec bun "$@"
