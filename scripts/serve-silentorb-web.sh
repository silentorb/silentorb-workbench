#!/usr/bin/env bash
set -euo pipefail

SILENTORB="${SILENTORB:-/workspaces/silentorb-web}"
exec bash "${SILENTORB}/scripts/serve-static-site.sh"
