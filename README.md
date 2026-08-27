# silentorb-workbench

Development workspace for **Marloth Story**, **Tome**, **silentorb-web**, and **Translucence**.

Dev setup uses **Docker Compose** (see [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml)): a primary `workbench` service and a `tome` service that runs the editor dev servers.

Open [`silentorb-workbench.code-workspace`](./silentorb-workbench.code-workspace) (or let the devcontainer open it) for a **multi-root workspace**: workbench plus each sibling repo as its own indexed folder.

## Prerequisite: sibling repositories

Clone sibling repos on the host (Compose bind-mounts them into the containers):

```
parent/
  silentorb-workbench/   # this repo
  tome/
  marloth-story/
  silentorb-web/         # optional — corporate website
  translucence/          # optional — Bible-article corpus
~/dev/imp/               # Imp (DAG transmission; required by tome service / tome-query)
```

| Host path | Mounted as (container) | Workspace folder |
| --------- | ---------------------- | ---------------- |
| `../tome` (sibling) | `/workspaces/tome` | `tome` |
| `../marloth-story` (sibling) | `/workspaces/marloth-story` | `marloth-story` |
| `../silentorb-web` (sibling) | `/workspaces/silentorb-web` | `silentorb-web` (optional) |
| `../translucence` (sibling) | `/workspaces/translucence` | `translucence` (optional) |
| `~/dev/imp` | `/workspaces/imp` | `imp` (required by `tome` service) |
| this repo | `/workspaces/silentorb-workbench` | `workbench` |

Compose defaults use `../../tome`, `../../marloth-story`, `../../silentorb-web`, and `../../translucence` relative to `.devcontainer/`, and `${HOME}/dev/imp` for `imp`. Override mount sources with `TOME_REPO`, `MARLOTH_REPO`, `SILENTORB_WEB_REPO`, `TRANSLUCENCE_REPO`, and `IMP_REPO` when opening the devcontainer.

Clone silentorb-web: `git clone git@github.com:silentorb/silentorb-web.git`

On devcontainer start, the **`workbench` service** waits for sibling repo mounts (no dependency install). The **`tome` service** builds from `/workspaces/tome/.devcontainer/Dockerfile`, runs `bun install --frozen-lockfile` from `/workspaces/tome/bun.lock` into a Docker volume at `/workspaces/tome/node_modules`, then starts the editor with `TOME_CONTENT_PATH` pointing at marloth-story `content/` (override `TOME_CONTENT_PATH` / `TOME_DB_PATH` to point at another corpus). The editor webview is at http://127.0.0.1:5173 and the API at http://127.0.0.1:3847 (no VS Code task needed — servers start automatically with the devcontainer).

**Multi-corpus (opt-in):** leave the default Marloth-only session alone for day-to-day work. To open several corpora in one editor session, set `TOME_CORPORA` (and a dedicated session `TOME_DB_PATH` that is **not** any corpus’s own sqlite file), for example in a gitignored `.devcontainer/.env`:

```bash
TOME_CORPORA=marloth=/workspaces/marloth-story/content,translucence=/workspaces/translucence/content:readonly
TOME_DB_PATH=/workspaces/tome/data/tome-session.sqlite
```

Rebuild or reopen the devcontainer so Compose applies the change. The session cache must live in a tree the **`tome` service** mounts — it mounts Marloth, Translucence, silentorb-web, tome, and imp, but **not this repo**, so a `/workspaces/silentorb-workbench/…` cache path makes the API die at boot with `EACCES`.

See [`/workspaces/tome/docs/features/multi-corpus.md`](../tome/docs/features/multi-corpus.md).

**WSL launcher (Marloth + Translucence):** from a WSL host shell (outside the devcontainer), run:

```bash
bash scripts/tome.sh
```

This stops any running `tome` Compose service and starts a fresh one with both corpora (read/write). No WSL environment variables are required — the script sets `TOME_CORPORA` and `TOME_DB_PATH` inline. Requires `../translucence` cloned alongside the other sibling repos. Pass `-d` to run detached. Reopening the devcontainer without this script restores the default Marloth-only `tome` service unless you configure `.devcontainer/.env` separately.

Tome commands from the workbench shell: use `bash scripts/run-in-tome.sh …`, VS Code tasks, or `cd /workspaces/tome && bun …`. The workbench root has no `bun.lock` or `node_modules`.

### Silent Orb website (optional)

Build from the workbench folder:

```bash
bash scripts/build-silentorb-web.sh   # → /workspaces/silentorb-web/dist/
bash scripts/serve-silentorb-web.sh   # http://127.0.0.1:8080/
```

VS Code tasks: **Silentorb Web: build** / **Silentorb Web: serve**.

### Translucence (optional)

Bible-article corpus at `/workspaces/translucence/content/`. Sync the SQLite cache with `bash scripts/translucence-content-sync.sh` (VS Code task **Translucence: sync content cache**). The editor stays on Marloth unless you override `TOME_CONTENT_PATH` / `TOME_DB_PATH`, or opt into a multi-corpus session via `TOME_CORPORA` (see above).

## VS Code tasks

Run **Tasks: Run Task** from the **workbench** workspace folder:

| Task | Purpose |
| ---- | ------- |
| **Test: full suite** | Workspace typecheck, then all Tome package tests |
| **Typecheck: all packages** | `tsc --noEmit` across tome (+ Imp) workspace packages |
| **Tome Editor: build** | Production build of the editor |
| **Tome: build static website** | Static-site tests + `web:build` → `/workspaces/marloth-story/dist/web/` |
| **Tome: serve static website** | Local preview at http://127.0.0.1:8787/ (after build) |
| **Marloth: sync content cache** | Rebuild `/workspaces/marloth-story/data/tome.sqlite` from git content |
| **Translucence: sync content cache** | Rebuild `/workspaces/translucence/data/tome.sqlite` from git content |
| **Silentorb Web: build** | Tome static site build → `/workspaces/silentorb-web/dist/` |
| **Silentorb Web: serve** | Local preview at http://127.0.0.1:8080/ (after build) |

Equivalent shell commands: `bash scripts/run-in-tome.sh run test`, `bash scripts/run-in-tome.sh run typecheck`, `bash scripts/run-in-tome.sh run editor:build`, `bash scripts/build-static-site.sh`, `bash scripts/serve-static-site.sh`, `bash scripts/marloth-content-sync.sh`, `bash scripts/translucence-content-sync.sh`, `bash scripts/build-silentorb-web.sh`, and `bash scripts/serve-silentorb-web.sh`.

See [`AGENTS.md`](./AGENTS.md) for agent and developer conventions.
