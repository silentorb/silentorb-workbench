#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

export IMP_TS TOME
exec bun "${WORKBENCH_ROOT}/scripts/git-tag-version.ts" "$@"
