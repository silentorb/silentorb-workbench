#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -d "${TOME}/packages/tome-db" ]] || [[ ! -d "${TOME}/packages/tome-flatfile" ]] || [[ ! -d "${TOME}/packages/tome-sqlite" ]]; then
  echo "tome repo not found at ${TOME} (expected packages: tome-db, tome-flatfile, tome-sqlite)" >&2
  exit 1
fi

cd "$TOME"
# shellcheck source=/dev/null
source "${TOME}/scripts/ensure-node-modules.sh"
exec bun "$@"
