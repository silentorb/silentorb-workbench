FROM mcr.microsoft.com/devcontainers/base:debian AS base

# By default /workspaces is owned by `root`.
# When the Dev Container extension mounts the source directory, it changes the mounted file owner to `vscode`.
# A directory is created under /workspaces which is owned by `vscode` and acts as a scratch pad to store
# miscellaneous ephemeral files.
RUN <<EOF
mkdir -p /workspaces/dev /workspaces/build
chown vscode:vscode /workspaces/dev /workspaces/build
EOF

# curl/unzip: Bun + OpenCode install scripts and legacy zip export archives; ca-certificates: HTTPS.
# git: repo operations by the OpenCode agent. python3: optional one-off temporary scripts (see AGENTS.md).
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl unzip python3 git
apt-get upgrade -y
rm -rf /var/lib/apt/lists/*
EOF

# Bun (pin matches packageManager in repos/tome). System-wide for scripts that delegate to tome.
ENV BUN_INSTALL=/usr/local/bun
ENV PATH="${BUN_INSTALL}/bin:${PATH}"
USER root
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v1.3.13"

USER vscode

# OpenCode CLI (agent that talks to host Ollama via the ollama-bridge service).
# USER does not set $HOME during build, and `docker exec` doesn't guarantee it at
# runtime; pin it so the installer targets $HOME/.opencode/bin and config resolves.
ENV HOME=/home/vscode
ENV PATH="/home/vscode/.opencode/bin:${PATH}"
RUN curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path

# Pre-create OpenCode's XDG dirs as vscode. The compose bind mounts for
# .config/opencode and .local/share/opencode would otherwise make Docker create the
# parent dirs (~/.local, ~/.config) as root, blocking OpenCode from writing ~/.local/state.
RUN mkdir -p /home/vscode/.config/opencode \
             /home/vscode/.local/share/opencode \
             /home/vscode/.local/state \
             /home/vscode/.cache

WORKDIR /workspaces/silentorb-workbench
CMD ["/bin/bash", "scripts/devcontainer-start.sh"]
