#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -f "${TOME_NEO4J}/package.json" ]]; then
  echo "tome-neo4j repo not found at ${TOME_NEO4J} (expected package.json)" >&2
  exit 1
fi

if [[ ! -d "${TOME}/packages/tome-graph-interfaces" ]]; then
  echo "tome repo not found at ${TOME} (tome-neo4j workspaces require sibling tome packages)" >&2
  exit 1
fi

cd "$TOME_NEO4J"
exec bun "$@"
