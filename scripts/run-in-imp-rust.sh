#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -f "${IMP_RUST}/Cargo.toml" ]]; then
  echo "imp-rust repo not found at ${IMP_RUST} (expected Cargo.toml)" >&2
  exit 1
fi

if command -v cargo >/dev/null 2>&1; then
  cd "$IMP_RUST"
  exec cargo "$@"
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "cargo not found and docker unavailable — install rustup, open imp-rust/.devcontainer, or use the workbench devcontainer" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${ROOT}/.devcontainer/docker-compose.yml"

HOST_REPO="$(resolve_imp_rust_host_repo || true)"
if [[ -z "$HOST_REPO" ]]; then
  echo "IMP_RUST_HOST_REPO is unset and could not be inferred — reopen devcontainer or set host path to imp-rust" >&2
  exit 1
fi
export IMP_RUST_HOST_REPO="$HOST_REPO"

exec docker compose -f "$COMPOSE_FILE" --profile imp-rust run --rm -T imp-rust cargo "$@"
