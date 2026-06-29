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

Copy [`.devcontainer/opencode.example.json`](../opencode.example.json) to `~/.config/opencode/opencode.json` (adjust models). The important setting:

```json
"baseURL": "http://host.docker.internal:11435/v1"
```

Port `11435` is the bridge listener; host Ollama stays on `11434`. Override with `OLLAMA_BRIDGE_PORT` / `OLLAMA_HOST_PORT` in Compose if needed.
