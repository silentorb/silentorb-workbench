# silentorb-workbench

Development workspace for **Marloth Story** and **Tome**.

Dev setup uses **Docker Compose** (see [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml)): a primary `workbench` service and an idle `marloth-story` sidecar for CI-parity static site builds.

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
| `../tome` | `repos/tome/` | Tome packages (`tome-db`, `tome-editor`, `tome-static-site`) and tooling docs |
| `../marloth-story` | `repos/marloth-story/` | Marloth design graph (`content/`, domain docs, migrations) |

Override mount sources with `TOME_REPO` and `MARLOTH_REPO` environment variables when opening the devcontainer.

On devcontainer start, `scripts/devcontainer-start.sh` runs `bun install` and starts the editor dev servers. The `marloth-story` sidecar stays idle (`sleep infinity`) until used for CI simulation.

**CI simulation:** `bash scripts/ci-build-static-site.sh` (or VS Code task **Tome: build static website (CI simulation)**) runs the static site test + build inside the sidecar.

See [`AGENTS.md`](./AGENTS.md) for agent and developer conventions.
