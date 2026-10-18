# `.mnt/` — bind-mounted sibling repositories

Host sibling repos are mounted here by [`.devcontainer/docker-compose.yml`](../.devcontainer/docker-compose.yml). Contents are gitignored; only this README is tracked.

| Mount | Default host source |
| ----- | ------------------- |
| `tome/` | `../tome` |
| `marloth-story/` | `../marloth-story` |
| `silentorb-web/` | `../silentorb-web` |
| `translucence/` | `../translucence` |
| `imp-ts/` | `../imp-ts` |
| `imp-spec/` | `../imp-spec` |
| `imp-cypher/` | `../imp-cypher` |
| `tome-neo4j/` | `../tome-neo4j` |

Override mount sources with `TOME_REPO`, `MARLOTH_REPO`, `SILENTORB_WEB_REPO`, `TRANSLUCENCE_REPO`, `IMP_REPO`, `IMP_SPEC_REPO`, `IMP_CYPHER_REPO`, and `TOME_NEO4J_REPO` when opening the devcontainer.

**imp-cypher:** optional Imp → Cypher translator at `imp-cypher/`. Run `bash scripts/run-in-imp-cypher.sh run test` from the workbench root (requires sibling `imp-ts/`). Compile-only — no Neo4j.

**tome-neo4j:** optional Neo4j graph backend packages at `tome-neo4j/`. Run `bash scripts/run-in-tome-neo4j.sh run test` from the workbench root (requires siblings `tome/`, `imp-ts/`, `imp-cypher/`). Neo4j Community sidecar: `docker compose` inside that repo — not part of default workbench `runServices`.

Scripts resolve paths via [`scripts/mnt-paths.sh`](../scripts/mnt-paths.sh).
