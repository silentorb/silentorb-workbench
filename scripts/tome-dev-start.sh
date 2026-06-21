#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -d repos/tome/packages/tome-db ]]; then
  echo "tome packages not found at repos/tome/packages/tome-db" >&2
  exit 1
fi

default_content="/workspaces/silentorb-workbench/repos/marloth-story/content"
legacy_content="/workspaces/marloth-story/content"

if [[ -z "${TOME_CONTENT_PATH:-}" ]]; then
  if [[ -d "$default_content" ]]; then
    export TOME_CONTENT_PATH="$default_content"
  elif [[ -d "$legacy_content" ]]; then
    export TOME_CONTENT_PATH="$legacy_content"
  else
    echo "Content path not found. Expected one of:" >&2
    echo "  $default_content" >&2
    echo "  $legacy_content" >&2
    exit 1
  fi
fi

if [[ ! -d "$TOME_CONTENT_PATH" ]]; then
  echo "Content path not found: $TOME_CONTENT_PATH" >&2
  exit 1
fi

if [[ -z "${TOME_DB_PATH:-}" ]]; then
  export TOME_DB_PATH="${TOME_CONTENT_PATH%/content}/data/tome.sqlite"
fi

export TOME_EDITOR_DEV_HOST="${TOME_EDITOR_DEV_HOST:-0.0.0.0}"

# shellcheck source=ensure-node-modules.sh
source "$(dirname "$0")/ensure-node-modules.sh"
exec bun run editor:dev
