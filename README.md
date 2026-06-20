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

On devcontainer start, `scripts/devcontainer-start.sh` runs `bun install` in the workbench service. The **`tome` service** runs `scripts/tome-dev-start.sh`, which starts the editor with `TOME_CONTENT_PATH` pointing at marloth-story `content/`.

**Static site build:** `bash scripts/build-static-site.sh` (or VS Code task **Tome: build static website**) runs tome-static-site tests and `web:build` inside the workbench container.

See [`AGENTS.md`](./AGENTS.md) for agent and developer conventions.
