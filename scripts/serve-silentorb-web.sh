#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

exec bash "${SILENTORB}/scripts/serve-static-site.sh"
