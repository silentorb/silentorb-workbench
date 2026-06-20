#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -d repos/tome/packages/tome-db ]]; then
  echo "tome packages not found at repos/tome/packages/tome-db" >&2
  exit 1
fi

if [[ ! -d "${TOME_CONTENT_PATH:-/workspaces/marloth-story/content}" ]]; then
  echo "Content path not found: ${TOME_CONTENT_PATH:-/workspaces/marloth-story/content}" >&2
  exit 1
fi

export TOME_CONTENT_PATH="${TOME_CONTENT_PATH:-/workspaces/marloth-story/content}"
export TOME_DB_PATH="${TOME_DB_PATH:-/workspaces/marloth-story/data/tome.sqlite}"
export TOME_EDITOR_DEV_HOST="${TOME_EDITOR_DEV_HOST:-0.0.0.0}"

bun install --frozen-lockfile
exec bun run editor:dev
