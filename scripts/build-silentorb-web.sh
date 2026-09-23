#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

if [[ ! -d "$SILENTORB/content" ]]; then
  echo "silentorb-web content not found: $SILENTORB/content" >&2
  exit 1
fi

export TOME_ROOT="${TOME_ROOT:-$TOME}"
bash "${SILENTORB}/scripts/build-static-site.sh"
