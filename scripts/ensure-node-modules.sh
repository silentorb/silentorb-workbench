#!/usr/bin/env bash
# Named Docker volumes mount as root:root; bun install runs as vscode.
if [[ ! -d node_modules ]] || [[ ! -w node_modules ]]; then
  sudo mkdir -p node_modules
  sudo chown "$(id -u):$(id -g)" node_modules
fi
