#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${ROOT}/.devcontainer/docker-compose.yml"

CHANGED=false
HTML=false
STRICT=false
WRITE_BASELINE=false

usage() {
  cat <<'EOF'
Usage: bash scripts/coverage-imp-rust.sh [options]

Run imp-rust tests and line coverage in one ephemeral compose container, then
print an agent-friendly report from the workbench.

Options:
  --changed         Highlight git-changed crates/*/src files
  --html            Also emit HTML under target/llvm-cov/html/
  --strict          Exit non-zero if below line_minimum in coverage-targets.toml
  --write-baseline  Update docs/coverage.md baseline section (imp-rust repo)
  -h, --help        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --changed) CHANGED=true; shift ;;
    --html) HTML=true; shift ;;
    --strict) STRICT=true; shift ;;
    --write-baseline) WRITE_BASELINE=true; shift ;;
    -h | --help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "${IMP_RUST}/Cargo.toml" ]]; then
  echo "imp-rust repo not found at ${IMP_RUST} (expected Cargo.toml)" >&2
  exit 1
fi

run_in_imp_rust() {
  local script=$1
  if command -v cargo >/dev/null 2>&1; then
    cd "$IMP_RUST"
    bash -c "$script"
    return
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "cargo not found and docker unavailable" >&2
    exit 1
  fi
  HOST_REPO="$(resolve_imp_rust_host_repo || true)"
  if [[ -z "$HOST_REPO" ]]; then
    echo "IMP_RUST_HOST_REPO is unset and could not be inferred — reopen devcontainer or set host path to imp-rust" >&2
    exit 1
  fi
  export IMP_RUST_HOST_REPO="$HOST_REPO"
  docker compose -f "$COMPOSE_FILE" --profile imp-rust run --rm -T imp-rust \
    bash -c "$script"
}

LLVM_COV_SCRIPT='set -euo pipefail
rm -f coverage.json lcov.info
cargo llvm-cov --workspace --lcov --output-path lcov.info
cargo llvm-cov report --json --summary-only --output-path coverage.json'

if [[ "$HTML" == true ]]; then
  LLVM_COV_SCRIPT+='
cargo llvm-cov report --html --output-dir target/llvm-cov/html'
fi

echo "Running imp-rust tests and coverage (batched in one container)..." >&2
run_in_imp_rust "$LLVM_COV_SCRIPT"

REPORT_ARGS=(--imp-rust "$IMP_RUST")
[[ "$CHANGED" == true ]] && REPORT_ARGS+=(--changed)
[[ "$STRICT" == true ]] && REPORT_ARGS+=(--strict)
[[ "$WRITE_BASELINE" == true ]] && REPORT_ARGS+=(--write-baseline)

exec bun "${ROOT}/scripts/coverage-imp-rust-report.ts" "${REPORT_ARGS[@]}"
