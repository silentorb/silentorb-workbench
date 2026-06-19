# silentorb-workbench

Development workspace for **Marloth Story** and **Tome**.

Sibling repositories are declared in [`workspace.repos.json`](./workspace.repos.json) and cloned into untracked [`repos/`](./repos/) by:

```bash
bun run repos:install
```

| Clone path | Repository |
| ---------- | ---------- |
| `repos/tome/` | Tome packages (`tome-db`, `tome-editor`, `tome-static-site`) and tooling docs |
| `repos/marloth-story/` | Marloth design graph (`content/`, domain docs, migrations) |

On devcontainer start, the Dockerfile `CMD` runs `scripts/devcontainer-start.sh`, which clones repos (when SSH is available), runs `bun install`, and starts the editor dev servers.

See [`AGENTS.md`](./AGENTS.md) for agent and developer conventions.

**Note:** A legacy untracked `marloth-story/` directory at the workspace root (if present) should be removed after migrating to `repos/marloth-story/`.
