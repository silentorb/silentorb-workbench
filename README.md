# silentorb-workbench

Development workspace for **Marloth Story**, **Tome**, **silentorb-web**, and **Translucence**.

Dev setup uses **Docker Compose** (see [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml)): a primary `workbench` service and a `tome` service that runs the editor dev servers.

Open this repo in VS Code / Cursor (the devcontainer opens it as the workspace folder). Sibling repositories bind-mount under [`.mnt/`](./.mnt/).

## Prerequisite: sibling repositories

Clone sibling repos on the host (Compose bind-mounts them into `.mnt/` inside the container):

```
parent/
  silentorb-workbench/   # this repo
  tome/
  marloth-story/
  silentorb-web/         # optional — corporate website
  translucence/          # optional — Bible-article corpus
  imp-ts/                # Imp (DAG transmission; required by tome service / tome-query)
  imp-rust/              # optional
  imp-spec/              # optional
```

| Host path | Mounted as (container) |
| --------- | ---------------------- |
| `../tome` (sibling) | `.mnt/tome` |
| `../marloth-story` (sibling) | `.mnt/marloth-story` |
| `../silentorb-web` (sibling) | `.mnt/silentorb-web` (optional) |
| `../translucence` (sibling) | `.mnt/translucence` (optional) |
| `../imp-ts` (sibling) | `.mnt/imp-ts` (required by `tome` service) |
| `../imp-rust` (sibling) | `.mnt/imp-rust` (optional) |
| `../imp-spec` (sibling) | `.mnt/imp-spec` (optional; language-neutral Imp specs for agents) |
| this repo | `/workspaces/silentorb-workbench` |

Compose defaults use `../../tome`, `../../marloth-story`, `../../silentorb-web`, `../../translucence`, and `../../imp-ts` relative to `.devcontainer/`. Override mount sources with `TOME_REPO`, `MARLOTH_REPO`, `SILENTORB_WEB_REPO`, `TRANSLUCENCE_REPO`, `IMP_REPO`, `IMP_RUST_REPO`, and `IMP_SPEC_REPO` when opening the devcontainer.

Clone silentorb-web: `git clone git@github.com:silentorb/silentorb-web.git`

On devcontainer start, the **`workbench` service** waits for sibling repo mounts (no dependency install). The **`tome` service** builds from [`.mnt/tome/docker/Dockerfile.dev`](./.mnt/tome/docker/Dockerfile.dev) (local build — not a GHCR pull), runs `bun install --frozen-lockfile` from `.mnt/tome/bun.lock` into a Docker volume at `.mnt/tome/node_modules`, then starts the editor with `TOME_CONTENT_PATH` pointing at marloth-story `content/` (override `TOME_CONTENT_PATH` / `TOME_DB_PATH` to point at another corpus). Rebuild the tome image after changing `docker/install-runtime.sh` or `Dockerfile.dev`; lockfile-only changes only need a service restart. The offline **release** image (`docker/Dockerfile.release`, published to `ghcr.io/silentorb/tome`) is documented in [`.mnt/tome/docs/features/container.md`](./.mnt/tome/docs/features/container.md). The editor webview is at http://127.0.0.1:5173 and the API at http://127.0.0.1:3847 (no VS Code task needed — servers start automatically with the devcontainer).

**Multi-corpus (opt-in):** leave the default Marloth-only session alone for day-to-day work. To open several corpora in one editor session, set `TOME_CORPORA` (and a dedicated session `TOME_DB_PATH` that is **not** any corpus’s own sqlite file), for example in a gitignored `.devcontainer/.env`:

```bash
TOME_CORPORA=marloth=/workspaces/silentorb-workbench/.mnt/marloth-story/content,translucence=/workspaces/silentorb-workbench/.mnt/translucence/content,silentorb-web=/workspaces/silentorb-workbench/.mnt/silentorb-web/content
TOME_DB_PATH=/workspaces/silentorb-workbench/.mnt/tome/data/tome-session.sqlite
```

Rebuild or reopen the devcontainer so Compose applies the change. The session cache must live in a tree the **`tome` service** mounts — use a path under `.mnt/tome/data/` (gitignored in tome).

See [`.mnt/tome/docs/features/multi-corpus.md`](./.mnt/tome/docs/features/multi-corpus.md) when the tome repo is mounted.

**WSL launcher (Marloth + Translucence + Silent Orb):** from a WSL host shell (outside the devcontainer), run from the workbench folder or via an absolute path from any cwd:

```bash
bash scripts/tome.sh
# or from anywhere:
bash /path/to/silentorb-workbench/scripts/tome.sh
```

This brings up the Compose `tome` service with all three corpora (read/write) on the **same Compose project** as the Dev Containers IDE stack (`silentorb-workbench_devcontainer`), so the host launcher and Cursor share one `tome` container. No WSL environment variables are required — the script sets `TOME_CORPORA` and `TOME_DB_PATH` inline. Requires `../translucence` and `../silentorb-web` cloned alongside the other sibling repos. Pass `-d` to run detached. Reopening the devcontainer without this script restores the default Marloth-only `tome` service unless you configure `.devcontainer/.env` separately.

If Compose warns about orphan containers named `devcontainer-marloth-*`, those are leftovers from renamed/removed services under an old project name — not new tome containers piling up. Remove them once with `docker rm` (or `docker compose -p devcontainer -f .devcontainer/docker-compose.yml down --remove-orphans` when that old project is unused).

Tome commands from the workbench shell: use `bash scripts/run-in-tome.sh …`, VS Code tasks, or `cd .mnt/tome && bun …`. The workbench root has no `bun.lock` or `node_modules`.

### Silent Orb website (optional)

Build from the workbench folder:

```bash
bash scripts/build-silentorb-web.sh   # → .mnt/silentorb-web/dist/
bash scripts/serve-silentorb-web.sh   # http://127.0.0.1:8080/
```

VS Code tasks: **Silentorb Web: build** / **Silentorb Web: serve**.

### Translucence (optional)

Bible-article corpus at `.mnt/translucence/content/`. Sync the SQLite cache with `bash scripts/translucence-content-sync.sh` (VS Code task **Translucence: sync content cache**). The editor stays on Marloth unless you override `TOME_CONTENT_PATH` / `TOME_DB_PATH`, or opt into a multi-corpus session via `TOME_CORPORA` (see above).

## VS Code tasks

Run **Tasks: Run Task** from the workbench workspace folder:

| Task | Purpose |
| ---- | ------- |
| **Test: full suite** | Workspace typecheck, then all Tome package tests |
| **Typecheck: all packages** | `tsc --noEmit` across tome (+ Imp) workspace packages |
| **Tome Editor: build** | Production build of the editor |
| **Tome: build static website** | Static-site tests + `web:build` → `.mnt/marloth-story/dist/web/` |
| **Tome: serve static website** | Local preview at http://127.0.0.1:8787/ (after build) |
| **Marloth: sync content cache** | Rebuild `.mnt/marloth-story/data/tome.sqlite` from git content |
| **Translucence: sync content cache** | Rebuild `.mnt/translucence/data/tome.sqlite` from git content |
| **Silentorb Web: build** | Tome static site build → `.mnt/silentorb-web/dist/` |
| **Silentorb Web: serve** | Local preview at http://127.0.0.1:8080/ (after build) |

Equivalent shell commands: `bash scripts/run-in-tome.sh run test`, `bash scripts/run-in-tome.sh run typecheck`, `bash scripts/run-in-tome.sh run editor:build`, `bash scripts/build-static-site.sh`, `bash scripts/serve-static-site.sh`, `bash scripts/marloth-content-sync.sh`, `bash scripts/translucence-content-sync.sh`, `bash scripts/build-silentorb-web.sh`, and `bash scripts/serve-silentorb-web.sh`.

See [`AGENTS.md`](./AGENTS.md) for agent and developer conventions.
