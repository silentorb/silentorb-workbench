#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export TOME_CONTENT_PATH="${TOME_CONTENT_PATH:-${ROOT}/repos/marloth-story/content}"
export TOME_DB_PATH="${TOME_DB_PATH:-${ROOT}/repos/marloth-story/data/tome.sqlite}"

if [[ ! -d "$TOME_CONTENT_PATH" ]]; then
  echo "Content path not found: $TOME_CONTENT_PATH" >&2
  echo "Mount marloth-story as a sibling repo, then reopen the devcontainer." >&2
  exit 1
fi

bun run --filter tome-static-site test
bun run web:build -- --repo "$ROOT" --out-dir "$ROOT/dist/web"
