#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# OpenCode runs inside the existing `workbench` container (same environment Cursor uses).
# This wrapper ensures the host-network Ollama bridge is running, then execs OpenCode
# inside the running workbench container.
#
# Run from the WSL host: bringing the bridge up resolves its bind-mount source path
# against the host filesystem. (Alternatively, once the bridge is up you can just run
# `opencode` directly in the Cursor integrated terminal.)
if [[ -f /.dockerenv ]]; then
  echo "Run scripts/opencode.sh from the WSL host, not inside a devcontainer." >&2
  echo "If the ollama-bridge is already running, just run 'opencode' in the Cursor terminal." >&2
  exit 1
fi

COMPOSE_FILE=.devcontainer/docker-compose.yml

# Start the Ollama bridge (host network, listens on :11435). Idempotent.
COMPOSE_PROFILES=ollama docker compose -f "$COMPOSE_FILE" up -d ollama-bridge

# Find the running workbench container by its compose service label (project-agnostic:
# works whether the IDE and this CLI share a compose project name or not).
workbench_id="$(docker ps --filter label=com.docker.compose.service=workbench --format '{{.ID}}' | head -n1)"
if [[ -z "$workbench_id" ]]; then
  echo "workbench container is not running. Open the devcontainer first." >&2
  exit 1
fi

exec docker exec -it "$workbench_id" opencode "$@"
