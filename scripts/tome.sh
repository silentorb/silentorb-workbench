#!/usr/bin/env bash
set -euo pipefail

# Start the Tome editor/API with Marloth + Translucence + Silent Orb (all read/write)
# via the Compose `tome` service. Uses the same Compose project as the Dev Containers
# IDE stack so host launcher and Cursor share one tome container.
#
# Run from the WSL host (not inside a devcontainer). Works from any cwd when
# invoked with a path to this script. No shell env vars required.
if [[ -f /.dockerenv ]]; then
  echo "Run scripts/tome.sh from the WSL host, not inside a devcontainer." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVCONTAINER="$ROOT/.devcontainer"
COMPOSE_FILE="$DEVCONTAINER/docker-compose.yml"
MNT_CONTAINER="/workspaces/silentorb-workbench/.mnt"
DEFAULT_COMPOSE_PROJECT="silentorb-workbench_devcontainer"

# Prefer the project already used by a running workbench/tome container (IDE).
resolve_compose_project() {
  local id project
  id="$(docker ps -q --filter label=com.docker.compose.service=workbench | head -n1)"
  if [[ -z "$id" ]]; then
    id="$(docker ps -q --filter label=com.docker.compose.service=tome | head -n1)"
  fi
  if [[ -n "$id" ]]; then
    project="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$id" 2>/dev/null || true)"
    if [[ -n "$project" ]]; then
      echo "$project"
      return 0
    fi
  fi
  echo "$DEFAULT_COMPOSE_PROJECT"
}

# Host-side: sibling repos live next to workbench (../tome). .mnt/ is the in-container
# mount target and may exist as empty stubs on the host when no container is running.
resolve_default_repo() {
  local name="$1"
  local marker="$2"
  local rel="$3"
  local sibling=""
  sibling="$(cd "$DEVCONTAINER/$rel" 2>/dev/null && pwd || true)"

  local candidate
  for candidate in "$sibling" "$ROOT/.mnt/$name"; do
    [[ -n "$candidate" && -e "$candidate/$marker" ]] || continue
    echo "$candidate"
    return 0
  done

  echo "${sibling:-$ROOT/.mnt/$name}"
}

TOME_REPO="${TOME_REPO:-$(resolve_default_repo tome packages/tome-db ../../tome)}"
MARLOTH_REPO="${MARLOTH_REPO:-$(resolve_default_repo marloth-story content ../../marloth-story)}"
TRANSLUCENCE_REPO="${TRANSLUCENCE_REPO:-$(resolve_default_repo translucence content ../../translucence)}"
SILENTORB_WEB_REPO="${SILENTORB_WEB_REPO:-$(resolve_default_repo silentorb-web content ../../silentorb-web)}"
IMP_REPO="${IMP_REPO:-$(resolve_default_repo imp-ts . ../../imp-ts)}"

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
require_path "silentorb-web content" "$SILENTORB_WEB_REPO/content" || missing=1
require_path "imp-ts repo" "$IMP_REPO" || missing=1

if [[ "$missing" -ne 0 ]]; then
  echo >&2
  echo "Clone sibling repos on the host next to silentorb-workbench (see README.md):" >&2
  echo "  ../tome, ../marloth-story, ../translucence, ../silentorb-web, ../imp-ts" >&2
  echo >&2
  echo "Resolved paths:" >&2
  echo "  TOME_REPO=$TOME_REPO" >&2
  echo "  MARLOTH_REPO=$MARLOTH_REPO" >&2
  echo "  TRANSLUCENCE_REPO=$TRANSLUCENCE_REPO" >&2
  echo "  SILENTORB_WEB_REPO=$SILENTORB_WEB_REPO" >&2
  echo "  IMP_REPO=$IMP_REPO" >&2
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
      echo "  Start Tome with Marloth + Translucence + Silent Orb (read/write). -d runs detached." >&2
      echo "  Uses the same Compose project as the Dev Containers IDE stack." >&2
      echo "  Works from any cwd when given a path to this script." >&2
      exit 0
      ;;
    *)
      echo "Unknown option: $1 (try -h)" >&2
      exit 1
      ;;
  esac
done

COMPOSE_PROJECT="$(resolve_compose_project)"

echo "Starting Tome (Marloth + Translucence + Silent Orb, read/write)..."
echo "  Compose project → $COMPOSE_PROJECT"
echo "  Editor → http://127.0.0.1:5173"
echo "  API    → http://127.0.0.1:3847"
echo

export TOME_REPO MARLOTH_REPO TRANSLUCENCE_REPO SILENTORB_WEB_REPO IMP_REPO
exec env \
  TOME_CORPORA="marloth=${MNT_CONTAINER}/marloth-story/content,translucence=${MNT_CONTAINER}/translucence/content,silentorb-web=${MNT_CONTAINER}/silentorb-web/content" \
  TOME_DB_PATH="${MNT_CONTAINER}/tome/data/tome-session.sqlite" \
  docker compose -p "$COMPOSE_PROJECT" -f "$COMPOSE_FILE" up "${DETACHED[@]}" tome
