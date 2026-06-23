# silentorb-workbench

Development workspace for **Marloth Story** and **Tome**.

Dev setup uses **Docker Compose** (see [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml)): a primary `workbench` service and a `tome` service that runs the editor dev servers.

## Prerequisite: sibling repositories

Clone `tome` and `marloth-story` as **siblings** of this repo on the host (Compose bind-mounts them into the containers):

```
parent/
  silentorb-workbench/   # this repo
  tome/
  marloth-story/
```

| Host path | Mounted as (workbench) | Role |
| --------- | ---------------------- | ---- |
| `../tome` (sibling) | `repos/tome/` | Tome packages (`tome-db`, `tome-editor`, `tome-static-site`) and tooling docs |
| `../marloth-story` (sibling) | `repos/marloth-story/` | Marloth design graph (`content/`, domain docs, migrations) |

Compose defaults use `../../tome` and `../../marloth-story` relative to `.devcontainer/`. Override mount sources with `TOME_REPO` and `MARLOTH_REPO` when opening the devcontainer.

On devcontainer start, `scripts/devcontainer-start.sh` runs `bun install` in the workbench service. The **`tome` service** runs `scripts/tome-dev-start.sh`, which starts the editor with `TOME_CONTENT_PATH` pointing at marloth-story `content/`. The editor webview is at http://127.0.0.1:5173 and the API at http://127.0.0.1:3847 (no VS Code task needed — servers start automatically with the devcontainer).

## VS Code tasks

Run **Tasks: Run Task** from the workbench workspace:

| Task | Purpose |
| ---- | ------- |
| **Test: full suite** | Run all Tome package tests |
| **Tome Editor: build** | Production build of the editor |
| **Tome: build static website** | Static-site tests + `web:build` → `dist/web/` |
| **Tome: serve static website** | Local preview at http://127.0.0.1:8787/ (after build) |
| **Marloth: sync content cache** | Rebuild `repos/marloth-story/data/tome.sqlite` from git content |

Equivalent shell commands: `bun run test`, `bun run editor:build`, `bash scripts/build-static-site.sh`, `bash scripts/serve-static-site.sh`, and `cd repos/marloth-story && bun run content:sync`.

See [`AGENTS.md`](./AGENTS.md) for agent and developer conventions.
