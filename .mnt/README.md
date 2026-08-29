# `.mnt/` — bind-mounted sibling repositories

Host sibling repos are mounted here by [`.devcontainer/docker-compose.yml`](../.devcontainer/docker-compose.yml). Contents are gitignored; only this README is tracked.

| Mount | Default host source |
| ----- | ------------------- |
| `tome/` | `../tome` |
| `marloth-story/` | `../marloth-story` |
| `silentorb-web/` | `../silentorb-web` |
| `translucence/` | `../translucence` |
| `imp-ts/` | `../imp-ts` |
| `imp-rust/` | `../imp-rust` |
| `imp-spec/` | `../imp-spec` |

Override mount sources with `TOME_REPO`, `MARLOTH_REPO`, `SILENTORB_WEB_REPO`, `TRANSLUCENCE_REPO`, `IMP_REPO`, `IMP_RUST_REPO`, and `IMP_SPEC_REPO` when opening the devcontainer.

Scripts resolve paths via [`scripts/mnt-paths.sh`](../scripts/mnt-paths.sh).
