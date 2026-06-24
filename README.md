# silentorb-workbench

Development workspace for **Marloth Story**, **Tome**, and **silentorb-web**.

Dev setup uses **Docker Compose** (see [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml)): a primary `workbench` service, a `tome` service that runs the editor dev servers, and an optional `silentorb-web` service (legacy corporate site).

## Prerequisite: sibling repositories

Clone sibling repos on the host (Compose bind-mounts them into the containers):

```
parent/
  silentorb-workbench/   # this repo
  tome/
  marloth-story/
  silentorb-web/         # optional — corporate website
```

| Host path | Mounted as (workbench) | Role |
| --------- | ---------------------- | ---- |
| `../tome` (sibling) | `repos/tome/` | Tome packages (`tome-db`, `tome-editor`, `tome-static-site`) and tooling docs |
| `../marloth-story` (sibling) | `repos/marloth-story/` | Marloth design graph (`content/`, domain docs, migrations) |
| `../silentorb-web` (sibling) | `repos/silentorb-web/` | Silent Orb website (legacy static generator; optional) |

Compose defaults use `../../tome`, `../../marloth-story`, and `../../silentorb-web` relative to `.devcontainer/`. Override mount sources with `TOME_REPO`, `MARLOTH_REPO`, and `SILENTORB_WEB_REPO` when opening the devcontainer.

Clone silentorb-web: `git clone git@github.com:silentorb/silentorb-web.git`

On devcontainer start, `scripts/devcontainer-start.sh` runs `bun install` in the workbench service. The **`tome` service** runs `scripts/tome-dev-start.sh`, which starts the editor with `TOME_CONTENT_PATH` pointing at marloth-story `content/`. The editor webview is at http://127.0.0.1:5173 and the API at http://127.0.0.1:3847 (no VS Code task needed — servers start automatically with the devcontainer).

### silentorb-web service (optional)

The `silentorb-web` Compose service uses a **Node 16 + yarn** image (runs as the `node` user — not `vscode`). It is enabled by default in `devcontainer.json` (`runServices` + `COMPOSE_PROFILES=silentorb-web`). **Rebuild** the devcontainer after cloning the sibling.

On start, `scripts/devcontainer-start.sh` in silentorb-web runs `yarn install`. Dev server: http://127.0.0.1:8080/ (via **Silentorb Web: dev** task). A planned follow-up will port the site to the Tome stack.

**Troubleshooting:** If `tome` or `silentorb-web` fail to start after a rebuild, a stale Compose stack may be holding ports. On the host:

```bash
docker ps -a --filter name=silentorb-workbench_devcontainer
docker stop $(docker ps -q --filter name=silentorb-workbench_devcontainer) 2>/dev/null
docker rm $(docker ps -aq --filter name=silentorb-workbench_devcontainer) 2>/dev/null
```

Then rebuild. Commit `silentorb-web` devcontainer changes in the **sibling repo** (`../silentorb-web`); workbench compose changes live in this repo.

## VS Code tasks

Run **Tasks: Run Task** from the workbench workspace:

| Task | Purpose |
| ---- | ------- |
| **Test: full suite** | Run all Tome package tests |
| **Tome Editor: build** | Production build of the editor |
| **Tome: build static website** | Static-site tests + `web:build` → `dist/web/` |
| **Tome: serve static website** | Local preview at http://127.0.0.1:8787/ (after build) |
| **Marloth: sync content cache** | Rebuild `repos/marloth-story/data/tome.sqlite` from git content |
| **Silentorb Web: dev** | Legacy site watch + live-server at http://127.0.0.1:8080/ (`silentorb-web` service must be running) |
| **Silentorb Web: build** | Legacy site production build → `repos/silentorb-web/dist/` |

Equivalent shell commands: `bun run test`, `bun run editor:build`, `bash scripts/build-static-site.sh`, `bash scripts/serve-static-site.sh`, `cd repos/marloth-story && bun run content:sync`, and `bash scripts/silentorb-web-compose-exec.sh yarn dev` / `yarn build`.

See [`AGENTS.md`](./AGENTS.md) for agent and developer conventions.
