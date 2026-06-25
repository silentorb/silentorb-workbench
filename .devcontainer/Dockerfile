FROM mcr.microsoft.com/devcontainers/base:debian AS base

# By default /workspaces is owned by `root`.
# When the Dev Container extension mounts the source directory, it changes the mounted file owner to `vscode`.
# A directory is created under /workspaces which is owned by `vscode` and acts as a scratch pad to store
# miscellaneous ephemeral files.
RUN <<EOF
mkdir -p /workspaces/dev /workspaces/build
chown vscode:vscode /workspaces/dev /workspaces/build
EOF

# curl/unzip: Bun install script and notion-importer zip exports; ca-certificates: HTTPS.
# python3: optional one-off temporary scripts (see AGENTS.md).
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl unzip python3
apt-get upgrade -y
rm -rf /var/lib/apt/lists/*
EOF

# Bun (pin matches packageManager in repos/tome). System-wide for scripts that delegate to tome.
ENV BUN_INSTALL=/usr/local/bun
ENV PATH="${BUN_INSTALL}/bin:${PATH}"
USER root
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v1.3.13"

USER vscode
WORKDIR /workspaces/silentorb-workbench
CMD ["/bin/bash", "scripts/devcontainer-start.sh"]
