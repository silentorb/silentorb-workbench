#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Start the Tome editor/API with Marloth + Translucence (both read/write) via the
# Compose `tome` service. Stops any running tome container first, then starts fresh.
#
# Run from the WSL host (not inside a devcontainer). No shell env vars required.
if [[ -f /.dockerenv ]]; then
  echo "Run scripts/tome.sh from the WSL host, not inside a devcontainer." >&2
  exit 1
fi

ROOT="$(pwd)"
DEVCONTAINER="$ROOT/.devcontainer"
COMPOSE_FILE="$DEVCONTAINER/docker-compose.yml"
MNT_CONTAINER="/workspaces/silentorb-workbench/.mnt"

resolve_default_repo() {
  local name="$1"
  local rel="$2"
  if [[ -e "$ROOT/.mnt/$name" ]]; then
    echo "$ROOT/.mnt/$name"
    return 0
  fi
  cd "$DEVCONTAINER/$rel" && pwd
}

TOME_REPO="${TOME_REPO:-$(resolve_default_repo tome ../../tome)}"
MARLOTH_REPO="${MARLOTH_REPO:-$(resolve_default_repo marloth-story ../../marloth-story)}"
TRANSLUCENCE_REPO="${TRANSLUCENCE_REPO:-$(resolve_default_repo translucence ../../translucence)}"
IMP_REPO="${IMP_REPO:-$(resolve_default_repo imp-ts ../../imp-ts)}"

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
require_path "imp-ts repo" "$IMP_REPO" || missing=1

if [[ "$missing" -ne 0 ]]; then
  echo >&2
  echo "Clone sibling repos on the host (see README.md):" >&2
  echo "  ../tome, ../marloth-story, ../translucence, ../imp-ts" >&2
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
  TOME_CORPORA="marloth=${MNT_CONTAINER}/marloth-story/content,translucence=${MNT_CONTAINER}/translucence/content" \
  TOME_DB_PATH="${MNT_CONTAINER}/tome/data/tome-session.sqlite" \
  docker compose -f "$COMPOSE_FILE" up "${DETACHED[@]}" tome
