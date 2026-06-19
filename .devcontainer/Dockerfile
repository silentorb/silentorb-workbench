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
# git: clone sibling repos at container start (see scripts/install-repos.ts).
# python3: optional one-off temporary scripts (see AGENTS.md).
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git unzip python3
apt-get upgrade -y
rm -rf /var/lib/apt/lists/*
EOF

# Bun (pin matches root package.json "packageManager"). System-wide so CI can run as bind-mount UID.
ENV BUN_INSTALL=/usr/local/bun
ENV PATH="${BUN_INSTALL}/bin:${PATH}"
USER root
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v1.3.13"

# Root scaffolding (cloned repos live under repos/ at container start, not in the image).
USER root
WORKDIR /opt/silentorb-workbench
COPY package.json bunfig.toml workspace.repos.json ./
COPY scripts scripts
RUN chown -R vscode:vscode /opt/silentorb-workbench
USER vscode

WORKDIR /workspaces/silentorb-workbench
# Bind-mounted workspace + node_modules volume are empty at first start; clone repos, sync deps, run dev servers.
CMD ["/bin/bash", "scripts/devcontainer-start.sh"]
