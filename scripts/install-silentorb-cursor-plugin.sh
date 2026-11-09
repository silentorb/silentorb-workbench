#!/usr/bin/env bash
# Install silentorb-cursor into the container Cursor local-plugins dir.
# Remote/Dev Container sessions load plugins from the remote ~/.cursor, not the
# Windows host profile. Prefer a real copy — Cursor often rejects external symlinks.
set -euo pipefail

# shellcheck source=mnt-paths.sh
source "$(dirname "$0")/mnt-paths.sh"

SRC="${SILENTORB_CURSOR}"
DEST="${HOME}/.cursor/plugins/local/silentorb-cursor"

if [[ ! -f "${SRC}/.cursor-plugin/plugin.json" ]]; then
  echo "silentorb-cursor: mount missing or empty at ${SRC}; skipping local plugin install"
  exit 0
fi

mkdir -p "$(dirname "${DEST}")"
rm -rf "${DEST}"
mkdir -p "${DEST}"
cp -a "${SRC}/." "${DEST}/"
rm -rf "${DEST}/.git"

echo "silentorb-cursor: installed local plugin → ${DEST}"
