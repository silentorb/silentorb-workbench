#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SILENTORB="${ROOT}/repos/silentorb-web"

if [[ ! -d "$SILENTORB/content" ]]; then
  echo "silentorb-web content not found: $SILENTORB/content" >&2
  exit 1
fi

bash "${SILENTORB}/scripts/build-static-site.sh"
