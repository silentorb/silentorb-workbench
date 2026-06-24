#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
COMPOSE=(docker compose -f .devcontainer/docker-compose.yml)

if [[ ! -f repos/silentorb-web/package.json ]]; then
  echo "silentorb-web not found at repos/silentorb-web/." >&2
  echo "Clone git@github.com:silentorb/silentorb-web.git as a sibling of this repo (or set SILENTORB_WEB_REPO), then reopen the devcontainer." >&2
  exit 1
fi

if ! "${COMPOSE[@]}" ps --status running --services 2>/dev/null | grep -qx silentorb-web; then
  echo "silentorb-web service is not running." >&2
  echo "Rebuild/reopen the devcontainer with COMPOSE_PROFILES=silentorb-web (set in devcontainer.json remoteEnv)." >&2
  exit 1
fi

exec "${COMPOSE[@]}" exec -T silentorb-web "$@"
