# Ollama host bridge

Reverse proxy so bridge-network devcontainer services (e.g. OpenCode in `workbench`) can reach **Ollama on the host** when it listens on `127.0.0.1:11434` only.

## Prerequisites

1. **Ollama in the same environment as Docker.** This workbench uses Docker Engine inside WSL (docker-ce), not Docker Desktop. Here, “host” means the **WSL Linux distro** where the Docker daemon runs — not Windows. Ollama must be reachable from that distro:

   ```bash
   curl -s http://127.0.0.1:11434/api/tags
   ```

   If Ollama runs only on Windows (not in WSL), the bridge cannot reach it via `127.0.0.1`. Install/run Ollama in the same WSL distro as Docker, or use a different integration path.

2. **`network_mode: host` on `ollama-bridge`.** On Linux (including docker-ce in WSL), host networking works without extra configuration. Docker Desktop users must also enable **Settings → Resources → Network → Enable host networking** (Desktop 4.34+).

3. **`host.docker.internal` from containers.** The `workbench` service sets `extra_hosts: host.docker.internal:host-gateway` in [`docker-compose.yml`](../docker-compose.yml). Linux Engine does not provide `host.docker.internal` by default; this mapping is required for bridge clients to reach the nginx listener.

## Enable the bridge

The service uses Compose profile `ollama` (not started by default).

**Option A — devcontainer:** add to your local devcontainer override or `devcontainer.json`:

```json
"remoteEnv": { "COMPOSE_PROFILES": "ollama" }
```

Rebuild/reopen the devcontainer.

**Option B — ad hoc:**

```bash
COMPOSE_PROFILES=ollama docker compose -f .devcontainer/docker-compose.yml up -d ollama-bridge
```

## Verify

From the WSL distro (same shell where Docker runs):

```bash
curl -s http://127.0.0.1:11434/api/tags
```

From `workbench`:

```bash
curl -s http://host.docker.internal:11435/api/tags
```

Both should return the same model list.

## OpenCode

OpenCode runs **inside the `workbench` container** — the same environment Cursor uses — so the agent has identical read/write access to the mounted repos and shares `workbench`'s `node_modules` volume, network, and tooling. The CLI is installed into the workbench image ([`.devcontainer/Dockerfile`](../Dockerfile)); it reaches host Ollama through the bridge at `http://host.docker.internal:11435/v1`.

### First-time setup

1. Create the host config/state dirs (so the bind mounts aren't auto-created as root) and drop in a config:

   ```bash
   mkdir -p ~/.config/opencode ~/.local/share/opencode
   cp .devcontainer/opencode.example.json ~/.config/opencode/opencode.json   # then adjust models
   ```

2. **Rebuild the workbench container** so it picks up the OpenCode CLI and the new config mounts (VS Code / Cursor: "Dev Containers: Rebuild Container", or recreate the compose stack). This is required — unlike the old dedicated-container approach, OpenCode now ships in the workbench image.

### Launch

```bash
bash scripts/opencode.sh
```

Run this **from the WSL host shell**. It brings up the host-network `ollama-bridge` (whose bind mount only resolves on the host) and then execs `opencode` inside the running `workbench` container. Arguments pass through, e.g. `bash scripts/opencode.sh -s <session-id>`.

Once the bridge is running, you can equivalently just run `opencode` directly in the Cursor integrated terminal (you are already inside `workbench`).

### Config and state (host-mounted)

The `workbench` service bind-mounts your host OpenCode config and state so models, providers, and sessions persist across container rebuilds:

| Host path | Container path | Override env |
| --- | --- | --- |
| `~/.config/opencode` | `/home/vscode/.config/opencode` | `OPENCODE_CONFIG_DIR` |
| `~/.local/share/opencode` | `/home/vscode/.local/share/opencode` | `OPENCODE_DATA_DIR` |

The important setting in [`opencode.example.json`](../opencode.example.json):

```json
"baseURL": "http://host.docker.internal:11435/v1"
```

Port `11435` is the bridge listener; host Ollama stays on `11434`. Override with `OLLAMA_BRIDGE_PORT` / `OLLAMA_HOST_PORT` in Compose if needed.

### Verify

```bash
# host → Ollama
curl -s http://127.0.0.1:11434/api/tags

# inside workbench → Ollama via the bridge
docker exec "$(docker ps --filter label=com.docker.compose.service=workbench --format '{{.ID}}' | head -n1)" \
  curl -s http://host.docker.internal:11435/api/tags
```

Both should return the same model list.
