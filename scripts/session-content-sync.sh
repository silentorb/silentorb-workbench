#!/usr/bin/env bash
# Force-rebuild the multi-corpus editor session cache (tome-session.sqlite + FTS).
# Stop the tome Compose service first if it has the DB open (otherwise SQLite may be busy).
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

for dir in \
  "${MARLOTH}/content" \
  "${TRANSLUCENCE}/content" \
  "${SILENTORB}/content"
do
  if [[ ! -d "$dir" ]]; then
    echo "Missing corpus content at $dir" >&2
    exit 1
  fi
done

export TOME_CORPORA="marloth=${MARLOTH}/content,translucence=${TRANSLUCENCE}/content,silentorb-web=${SILENTORB}/content"
export TOME_DB_PATH="${TOME}/data/tome-session.sqlite"

echo "Rebuilding session cache → ${TOME_DB_PATH}"
echo "  (stop the tome service if this fails with database locked)"
exec bash "${TOME}/scripts/content-sync.sh"
