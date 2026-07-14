# AGENTS Guide

## Workspace purpose

**silentorb-workbench** orchestrates development across Tome tooling and domain projects. Sibling repositories are **bind-mounted** from the host at top-level container paths by [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml) (not cloned at container start). Open [`silentorb-workbench.code-workspace`](./silentorb-workbench.code-workspace) so each repo is a separate indexed workspace folder.

| Container path | Workspace folder | Repository role |
| -------------- | ---------------- | --------------- |
| `/workspaces/tome` | `tome` | Domain-agnostic Tome packages (`tome-db`, `tome-flatfile`, `tome-sqlite`, `tome-server`, `tome-http`, `tome-editor`, `tome-static-site`) and tooling docs |
| `/workspaces/marloth-story` | `marloth-story` | Marloth design corpus (`content/`, domain ontology, migrations, deploy) |
| `/workspaces/silentorb-web` | `silentorb-web` | Silent Orb corporate website (Tome static site; optional mount) |
| `/workspaces/silentorb-workbench` | `workbench` | Devcontainer, scripts, this guide |

**Prerequisite:** clone `tome` and `marloth-story` as siblings of this repo on the host (`../tome`, `../marloth-story`), or set `TOME_REPO` / `MARLOTH_REPO` when opening the devcontainer. Optionally clone `silentorb-web` (`../silentorb-web`, or `SILENTORB_WEB_REPO`). **Tome** owns package dependencies (`/workspaces/tome/bun.lock`, `/workspaces/tome/node_modules`). The workbench root orchestrates dev scripts and the devcontainer.

For Marloth-specific writing goals, graph editing workflow, and design corpus conventions, read `/workspaces/marloth-story/AGENTS.md` after cloning.

For package-level Tome notes, read each package's `AGENTS.md` under `/workspaces/tome/packages/`.

## Project context

- Open [`silentorb-workbench.code-workspace`](./silentorb-workbench.code-workspace) in VS Code / Cursor (the devcontainer opens it automatically).
- Dev setup is **Docker Compose**: `workbench` (dev shell) + `tome` (editor dev servers). See [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml).
- **Silent Orb site:** `bash scripts/build-silentorb-web.sh` → `/workspaces/silentorb-web/dist/`; serve with `bash scripts/serve-silentorb-web.sh` (port 8080). Content: `/workspaces/silentorb-web/content/`.
- **Tome tooling** lives under `/workspaces/tome/packages/`; `node_modules` lives at `/workspaces/tome/node_modules` (Docker volume; gitignored in tome). Static site build output for Marloth: `/workspaces/marloth-story/dist/web/`.
- **Design corpus** lives under `/workspaces/marloth-story/content/` (git-tracked graph) with a local SQLite cache at `/workspaces/marloth-story/data/tome.sqlite` (gitignored).
- Set `TOME_CONTENT_PATH` to the content root when it is not discoverable by walking up from CWD — default: `/workspaces/marloth-story/content` (not `content/data`).
- On devcontainer start, the **`tome` Compose service** runs `/workspaces/tome/scripts/dev-start.sh` (`bun install --frozen-lockfile` from `/workspaces/tome/bun.lock`, then `editor:dev`) with `TOME_CONTENT_PATH` set to marloth `content/`. The workbench service only checks mounts ([`scripts/devcontainer-start.sh`](./scripts/devcontainer-start.sh)). **Rebuild the tome service image** after changing `/workspaces/tome/.devcontainer/Dockerfile`. Re-run / restart the tome service after changing `/workspaces/tome/bun.lock` or package dependencies.
- **Static site build** (test + build): `bash scripts/build-static-site.sh` runs tome-static-site tests and `web:build` via `/workspaces/tome`.
- Run Tome package commands with `bash scripts/run-in-tome.sh …`, VS Code tasks, or from `/workspaces/tome/` — not `bun run` at the workbench root.

## Terminology

| Term | Meaning |
| ---- | ------- |
| **Project feature** | A workspace capability documented in `/workspaces/tome/docs/features/` (e.g. tome-db, tome-editor). Use this phrase when discussing tooling or agent specs—not graph nodes. |
| **Node** | Any entity in the design graph (SQLite `nodes` table). Replaces legacy *record* / *vertex* in docs and API. |
| **Relationship** | A link between two nodes with a **relationship type** and properties. Stored as one JSON file per edge under `content/data/relationships/` (archive under `content/archive/relationships/`); SQLite cache expands to directed projections. |
| **Page** | UI representation of a node in the editor (`NodePageView`, page title, sections, `getNodePageDetail`). Not the same as a raw export file. |
| **Feature** (unqualified) | A **design node** (story/game feature idea) in the Marloth corpus, unless context clearly means a project feature. |
| **Schema** | Git-tracked relationship rules in `/workspaces/marloth-story/content/model/schema.json`. Not SQLite DDL. |
| **Type table** | Any node used as an `IS_A` target and/or declared in `table-schemas.json`—not a permanent import label. |
| **Extension** | Externally packaged library of Tome components, loaded at runtime from project config (project feature—not a design graph node). |
| **Extension component** | One integration unit within an extension (`kind` + `implementationId`). |

## Working conventions

- Make focused changes that address the requested task only.
- Avoid unrelated refactors unless they are required to complete the task safely.
- Prefer small, incremental edits that are easy to review.
- **Prototypal stage — no backwards compatibility.** These repos are pre-release; there are no external consumers to protect. When you change an interface or format, **delete** the old path rather than preserving or widening it — no dual-format validators, case-insensitive fallbacks, normalization shims, deprecation warnings, or legacy code branches. Backwards-compatibility scaffolding only adds noise and convolution at this stage. Migrate existing data/content in the same change instead of supporting both shapes.
- **Prototypal stage — lock-step interfaces.** The workspace repos must stay mutually compatible at all times. Any interface change is applied to **every** dependent consumer in the same change so no repo is left on the old interface. The "Propagate tome breaking changes" bullet below is the concrete instance of this rule.
- **Propagate tome breaking changes to all dependent repos:** This workspace exists to develop interrelated repos in unison. When a change in `/workspaces/tome/` breaks an upstream interface that dependents rely on — content-model schema or version bumps (e.g. `views.json`, `workspace.json`, `schema.json`, `associations.json`), package/API signatures, CLI flags, or build/output contracts — update **every dependent repo in the same change**, not just the one in front of you. Dependents are at least `/workspaces/marloth-story/` and `/workspaces/silentorb-web/` (both consume tome as the static-site generator). Verify each still builds (`bash scripts/build-static-site.sh` for marloth, `bash scripts/build-silentorb-web.sh` for silentorb-web) before considering the tome change complete. A tome breaking change is not done while a neighboring repo is left on the old interface.
- **Regression tests:** When fixing a bug in table views (database tables, relation tables, Properties section, ordered-collection tables, dynamic fields, or related API endpoints), add a regression test in the same change that would have failed before the fix. Seed test relationships using **composite types** from `content/model/associations.json` (via `ContentStore` / `seedTestCompositeRelationships`) when the bug involves graph traversals — do not rely only on direct `db.upsertRelationship` with legacy unidirectional types. Do not close a bug fix without a test unless the user explicitly waives it.
- **Script language:** agentic scripts should use **TypeScript** (Bun) by default — place durable tooling under `/workspaces/tome/packages/` with tests and a shell wrapper in `scripts/` when appropriate. **One-off temporary scripts** (exploratory, throwaway, not intended to be maintained) may still be written in Python.

## Implementation expectations

- Read existing files before editing to preserve intent and style.
- Keep assumptions explicit in commit or PR notes when behavior is unclear.
- Run relevant checks or tests when changing code, if such checks are available.
- Add self-documentation to files under `/workspaces/tome/docs/` or `/workspaces/marloth-story/docs/` when making agent-relevant updates.

## Feature documentation

Authoritative design specs for **project features** live in `/workspaces/tome/docs/features/` (one file per major workspace capability). They state requirements, design rationale, and behavior so agents need not re-analyze the repo for basics.

**Do not read all feature docs by default.** When your task matches a row, read only that file (and the package `AGENTS.md` if editing that package). Treat the feature doc as the source of truth over implementation when they disagree—update code or the doc explicitly.

For **design data** (what nodes mean, how they relate conceptually), read `/workspaces/marloth-story/docs/ontology.md` **in addition to** schema-specific docs below (after cloning).

| If your task involves… | Read |
| ---------------------- | ---- |
| Design domain model, node types, relationships, traceability | `/workspaces/marloth-story/docs/ontology.md` |
| SQLite property graph, `/workspaces/marloth-story/data/tome.sqlite`, `/workspaces/tome/packages/tome-db/` | `/workspaces/tome/docs/features/tome-db.md` (+ ontology when interpreting data) |
| Sets (`set` trait, type tables, archive hub) | `/workspaces/tome/docs/features/sets.md` |
| Web markdown editor, `/workspaces/tome/packages/tome-editor/` | `/workspaces/tome/docs/features/tome-editor.md` |
| Config-driven API host, `/workspaces/tome/packages/tome-server/` | `/workspaces/tome/docs/features/tome-server.md` |
| Graph Explorer, LOD layers, anchor-scoped graph viz | `/workspaces/tome/docs/features/graph-explorer.md` |
| Editing story/design content in the graph | `/workspaces/marloth-story/docs/ontology.md` + `/workspaces/tome/docs/features/tome-db.md` + `/workspaces/marloth-story/AGENTS.md` |
| Ordered collections, scene order, drag-and-drop reorder | `/workspaces/tome/docs/features/ordered-collections.md` |
| Dynamic table view fields, computed columns | `/workspaces/tome/docs/features/dynamic-table-fields.md` + `/workspaces/tome/docs/dynamic-fields/` |
| Table view tabs, `views.json` | `/workspaces/tome/docs/features/views.md` |
| Type table columns, `table-schemas.json` | `/workspaces/tome/docs/features/table-schemas.md` |
| Static website generation (Astro) | `/workspaces/tome/docs/features/static-website.md` |
| Static website deploy (GitHub Actions → S3/CloudFront) | `/workspaces/marloth-story/docs/features/static-website-deploy.md` |
| Extension system (runtime-loaded packages, page blocks) | `/workspaces/tome/docs/features/extensions.md` |

See also `/workspaces/tome/docs/features/README.md` for the feature-doc template and how to add new features.

## Refactoring guides

Multi-session migration specs (agent-oriented). Start at the overview; do not read every session doc by default.

| If your task involves… | Read |
| --- | --- |
| Marloth → Tome decoupling (workspace config migration) | `/workspaces/marloth-story/docs/refactoring/00-overview.md` |

## Future expansion

- Architecture overview
- Standard test and validation commands
- Language/framework-specific coding conventions
