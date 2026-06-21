#!/usr/bin/env bash
# Named Docker volumes mount as root:root; bun install runs as vscode.
if [[ ! -d node_modules ]] || [[ ! -w node_modules ]]; then
  sudo mkdir -p node_modules
  sudo chown "$(id -u):$(id -g)" node_modules
fi

# workbench and tome both start on devcontainer open and share node_modules.
# Parallel `bun install` calls race on .bin symlinks (EEXIST) and can exit 1.
# Lock file lives on the shared workspace mount (not /tmp) so both containers serialize.
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install_lock="$(cd "$_script_dir/.." && pwd)/.bun-install.lock"
(
  exec 200>"$install_lock"
  flock 200
  bun install --frozen-lockfile
)
