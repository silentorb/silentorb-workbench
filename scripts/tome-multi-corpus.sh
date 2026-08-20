#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Start the Tome editor/API with Marloth + Translucence (both read/write) via the
# Compose `tome` service. Stops any running tome container first, then starts fresh.
#
# Run from the WSL host (not inside a devcontainer). No shell env vars required.
if [[ -f /.dockerenv ]]; then
  echo "Run scripts/tome-multi-corpus.sh from the WSL host, not inside a devcontainer." >&2
  exit 1
fi

ROOT="$(pwd)"
DEVCONTAINER="$ROOT/.devcontainer"
COMPOSE_FILE="$DEVCONTAINER/docker-compose.yml"

resolve_default_repo() {
  local rel="$1"
  cd "$DEVCONTAINER/$rel" && pwd
}

TOME_REPO="${TOME_REPO:-$(resolve_default_repo ../../tome)}"
MARLOTH_REPO="${MARLOTH_REPO:-$(resolve_default_repo ../../marloth-story)}"
TRANSLUCENCE_REPO="${TRANSLUCENCE_REPO:-$(resolve_default_repo ../../translucence)}"
IMP_REPO="${IMP_REPO:-${HOME}/dev/imp}"

require_path() {
  local label="$1"
  local path="$2"
  if [[ ! -e "$path" ]]; then
    echo "$label not found at $path" >&2
    return 1
  fi
}

missing=0
require_path "tome repo (tome-db)" "$TOME_REPO/packages/tome-db" || missing=1
require_path "marloth-story content" "$MARLOTH_REPO/content" || missing=1
require_path "translucence content" "$TRANSLUCENCE_REPO/content" || missing=1
require_path "imp repo" "$IMP_REPO" || missing=1

if [[ "$missing" -ne 0 ]]; then
  echo >&2
  echo "Clone sibling repos on the host (see README.md):" >&2
  echo "  ../tome, ../marloth-story, ../translucence, ~/dev/imp" >&2
  exit 1
fi

DETACHED=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d)
      DETACHED=(-d)
      shift
      ;;
    -h | --help)
      echo "Usage: $0 [-d]" >&2
      echo "  Start Tome with Marloth + Translucence (read/write). -d runs detached." >&2
      exit 0
      ;;
    *)
      echo "Unknown option: $1 (try -h)" >&2
      exit 1
      ;;
  esac
done

tome_ids="$(docker ps -q --filter label=com.docker.compose.service=tome || true)"
if [[ -n "$tome_ids" ]]; then
  echo "Stopping existing tome service container(s)..."
  # shellcheck disable=SC2086
  docker stop $tome_ids
fi

echo "Starting Tome (Marloth + Translucence, read/write)..."
echo "  Editor → http://127.0.0.1:5173"
echo "  API    → http://127.0.0.1:3847"
echo

export TOME_REPO MARLOTH_REPO TRANSLUCENCE_REPO IMP_REPO
exec env \
  TOME_CORPORA='marloth=/workspaces/marloth-story/content,translucence=/workspaces/translucence/content' \
  TOME_DB_PATH='/workspaces/tome/data/tome-session.sqlite' \
  docker compose -f "$COMPOSE_FILE" up "${DETACHED[@]}" tome
