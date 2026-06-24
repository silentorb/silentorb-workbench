# silentorb-workbench

Development workspace for **Marloth Story**, **Tome**, and **silentorb-web**.

Dev setup uses **Docker Compose** (see [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml)): a primary `workbench` service and a `tome` service that runs the editor dev servers.

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
| `../silentorb-web` (sibling) | `repos/silentorb-web/` | Silent Orb corporate website (Tome static site; optional) |

Compose defaults use `../../tome`, `../../marloth-story`, and `../../silentorb-web` relative to `.devcontainer/`. Override mount sources with `TOME_REPO`, `MARLOTH_REPO`, and `SILENTORB_WEB_REPO` when opening the devcontainer.

Clone silentorb-web: `git clone git@github.com:silentorb/silentorb-web.git`

On devcontainer start, `scripts/devcontainer-start.sh` runs `bun install` in the workbench service. The **`tome` service** runs `scripts/tome-dev-start.sh`, which starts the editor with `TOME_CONTENT_PATH` pointing at marloth-story `content/`. The editor webview is at http://127.0.0.1:5173 and the API at http://127.0.0.1:3847 (no VS Code task needed — servers start automatically with the devcontainer).

### Silent Orb website (optional)

Build from the workbench root:

```bash
bash scripts/build-silentorb-web.sh   # → repos/silentorb-web/dist/
bash scripts/serve-silentorb-web.sh   # http://127.0.0.1:8080/
```

VS Code tasks: **Silentorb Web: build** / **Silentorb Web: serve**.

## VS Code tasks

Run **Tasks: Run Task** from the workbench workspace:

| Task | Purpose |
| ---- | ------- |
| **Test: full suite** | Run all Tome package tests |
| **Tome Editor: build** | Production build of the editor |
| **Tome: build static website** | Static-site tests + `web:build` → `dist/web/` |
| **Tome: serve static website** | Local preview at http://127.0.0.1:8787/ (after build) |
| **Marloth: sync content cache** | Rebuild `repos/marloth-story/data/tome.sqlite` from git content |
| **Silentorb Web: build** | Tome static site build → `repos/silentorb-web/dist/` |
| **Silentorb Web: serve** | Local preview at http://127.0.0.1:8080/ (after build) |

Equivalent shell commands: `bun run test`, `bun run editor:build`, `bash scripts/build-static-site.sh`, `bash scripts/serve-static-site.sh`, `cd repos/marloth-story && bun run content:sync`, `bash scripts/build-silentorb-web.sh`, and `bash scripts/serve-silentorb-web.sh`.

See [`AGENTS.md`](./AGENTS.md) for agent and developer conventions.
