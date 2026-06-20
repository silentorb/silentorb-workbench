#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-silentorb-workbench}"
COMPOSE_FILE="${ROOT}/.devcontainer/docker-compose.yml"
CI_COMMAND='export TOME_CONTENT_PATH=/workspaces/marloth-story/content TOME_DB_PATH=/workspaces/marloth-story/data/tome.sqlite && cd /workspaces/silentorb-workbench && bun install --frozen-lockfile && bun run --filter tome-static-site test && bun run web:build'

usage() {
  cat <<EOF
Usage: ci-build-static-site.sh [--run-only | --rebuild-image | -h | --help]

Build the static site via the marloth-story compose sidecar (CI parity with GitHub Actions).

  (default)       docker compose exec into running marloth-story service
  --run-only      same as default
  --rebuild-image rebuild marloth-story image, then run build

Requires Docker on PATH and the marloth-story compose service running.
EOF
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker not found on PATH." >&2
    echo "Rebuild the devcontainer with docker-outside-of-docker, or run on the host." >&2
    exit 1
  fi
}

compose() {
  docker compose -p "$COMPOSE_PROJECT" -f "$COMPOSE_FILE" "$@"
}

run_build() {
  if ! compose ps --status running --services 2>/dev/null | grep -qx marloth-story; then
    echo "marloth-story service is not running." >&2
    echo "Reopen the devcontainer or run: docker compose -p ${COMPOSE_PROJECT} -f ${COMPOSE_FILE} up -d marloth-story" >&2
    exit 1
  fi

  echo "Building static site in marloth-story sidecar (workbench root + tome packages)"
  compose exec -T \
    -u "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -w /workspaces/silentorb-workbench \
    marloth-story \
    bash -c "$CI_COMMAND"
}

rebuild_image() {
  echo "Rebuilding marloth-story image"
  compose build marloth-story
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  --rebuild-image)
    require_docker
    rebuild_image
    run_build
    ;;
  --run-only | "")
    require_docker
    run_build
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
esac
