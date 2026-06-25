#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOME="${ROOT}/repos/tome"
MARLOTH="${ROOT}/repos/marloth-story"

export TOME_CONTENT_PATH="${TOME_CONTENT_PATH:-${MARLOTH}/content}"
export TOME_DB_PATH="${TOME_DB_PATH:-${MARLOTH}/data/tome.sqlite}"

if [[ ! -d "$TOME_CONTENT_PATH" ]]; then
  echo "Content path not found: $TOME_CONTENT_PATH" >&2
  echo "Mount marloth-story as a sibling repo, then reopen the devcontainer." >&2
  exit 1
fi

if [[ ! -d "${TOME}/packages/tome-static-site" ]]; then
  echo "tome repo not found at ${TOME}" >&2
  exit 1
fi

cd "$TOME"
# shellcheck source=ensure-node-modules.sh
source "${TOME}/scripts/ensure-node-modules.sh"
bun run --filter tome-static-site test
exec bun run web:build -- \
  --repo "$TOME" \
  --content-dir "$TOME_CONTENT_PATH" \
  --out-dir "${MARLOTH}/dist/web"
