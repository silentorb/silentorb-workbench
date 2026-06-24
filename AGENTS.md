# AGENTS Guide

## Workspace purpose

**silentorb-workbench** is the root development workspace for Tome tooling and domain projects. Sibling repositories are **bind-mounted** from the host into [`repos/`](./repos/) by [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml) (not cloned at container start):

| Mount path | Repository role |
| ---------- | --------------- |
| `repos/tome/` | Domain-agnostic Tome packages (`tome-db`, `tome-editor`, `tome-static-site`) and tooling docs |
| `repos/marloth-story/` | Marloth design corpus (`content/`, domain ontology, migrations, deploy) |
| `repos/silentorb-web/` | Silent Orb corporate website (Tome static site; optional mount) |

**Prerequisite:** clone `tome` and `marloth-story` as siblings of this repo on the host (`../tome`, `../marloth-story`), or set `TOME_REPO` / `MARLOTH_REPO` when opening the devcontainer. Optionally clone `silentorb-web` (`../silentorb-web`, or `SILENTORB_WEB_REPO`). **marloth-story** depends on Tome packages via workspace references across the hoisted root install. The workbench root orchestrates dev scripts, tests, and the devcontainer.

For Marloth-specific writing goals, graph editing workflow, and design corpus conventions, read [`repos/marloth-story/AGENTS.md`](./repos/marloth-story/AGENTS.md) after cloning.

For package-level Tome notes, read each package's `AGENTS.md` under `repos/tome/packages/`.

## Project context

- Open this folder as the VS Code / Cursor workspace root (`/workspaces/silentorb-workbench` in the devcontainer).
- Dev setup is **Docker Compose**: `workbench` (dev shell) + `tome` (editor dev servers). See [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml).
- **Silent Orb site:** `bash scripts/build-silentorb-web.sh` → `repos/silentorb-web/dist/`; serve with `bash scripts/serve-silentorb-web.sh` (port 8080). Content: `repos/silentorb-web/content/`.
- **Tome tooling** lives under `repos/tome/packages/`; ephemeral build output and hoisted dependencies live at the workbench root (`./dist/`, `./node_modules/`).
- **Design corpus** lives under `repos/marloth-story/content/` (git-tracked graph) with a local SQLite cache at `repos/marloth-story/data/tome.sqlite` (gitignored).
- Set `TOME_CONTENT_PATH` to the content root when it is not discoverable by walking up from CWD — default: `repos/marloth-story/content` (not `content/data`).
- All external dependencies and tooling installs should be performed within the devcontainer Dockerfile. On each container start, the workbench service runs [`scripts/devcontainer-start.sh`](./scripts/devcontainer-start.sh) (`bun install` only). The **`tome` Compose service** runs [`scripts/tome-dev-start.sh`](./scripts/tome-dev-start.sh) with `TOME_CONTENT_PATH` set to marloth `content/`. **Rebuild the container** after changing root `package.json` or `bun.lock` — do not run `bun install` manually in a terminal or on the host.
- **Static site build** (test + build): `bash scripts/build-static-site.sh` runs tome-static-site tests and `web:build` in the workbench container.

## Terminology

| Term | Meaning |
| ---- | ------- |
| **Project feature** | A workspace capability documented in `repos/tome/docs/features/` (e.g. tome-db, tome-editor). Use this phrase when discussing tooling or agent specs—not graph nodes. |
| **Node** | Any entity in the design graph (SQLite `nodes` table). Replaces legacy *record* / *vertex* in docs and API. |
| **Relationship** | A link between two nodes with a **relationship type** and properties. Stored compactly in `relationships.json`; SQLite cache expands to directed projections. |
| **Page** | UI representation of a node in the editor (`NodePageView`, page title, sections, `getNodePageDetail`). Not the same as a Notion export file. |
| **Feature** (unqualified) | A **design node** (story/game feature idea) in the Marloth corpus, unless context clearly means a project feature. |
| **Schema** | Git-tracked relationship rules in `repos/marloth-story/content/model/schema.json`. Not SQLite DDL. |
| **Type table** | Any node used as an `IS_A` target and/or with `notion_schema` / `notion_database` metadata—not a permanent import label. |
| **Extension** | Externally packaged library of Tome components, loaded at runtime from project config (project feature—not a design graph node). |
| **Extension component** | One integration unit within an extension (`kind` + `implementationId`). |

## Working conventions

- Make focused changes that address the requested task only.
- Avoid unrelated refactors unless they are required to complete the task safely.
- Prefer small, incremental edits that are easy to review.
- **Regression tests:** When fixing a bug in table views (database tables, relation tables, Properties section, ordered-association tables, dynamic fields, or related API endpoints), add a regression test in the same change that would have failed before the fix. Seed test relationships using **composite types** from `content/relationship-types.json` (via `ContentStore` / `seedTestCompositeRelationships`) when the bug involves graph traversals — do not rely only on direct `db.upsertRelationship` with legacy unidirectional types. Do not close a bug fix without a test unless the user explicitly waives it.
- **Script language:** agentic scripts should use **TypeScript** (Bun) by default — place durable tooling under `repos/tome/packages/` with tests and a shell wrapper in `scripts/` when appropriate. **One-off temporary scripts** (exploratory, throwaway, not intended to be maintained) may still be written in Python.

## Implementation expectations

- Read existing files before editing to preserve intent and style.
- Keep assumptions explicit in commit or PR notes when behavior is unclear.
- Run relevant checks or tests when changing code, if such checks are available.
- Add self-documentation to files under `repos/tome/docs/` or `repos/marloth-story/docs/` when making agent-relevant updates.

## Feature documentation

Authoritative design specs for **project features** live in `repos/tome/docs/features/` (one file per major workspace capability). They state requirements, design rationale, and behavior so agents need not re-analyze the repo for basics.

**Do not read all feature docs by default.** When your task matches a row, read only that file (and the package `AGENTS.md` if editing that package). Treat the feature doc as the source of truth over implementation when they disagree—update code or the doc explicitly.

For **design data** (what nodes mean, how they relate conceptually), read [`repos/marloth-story/docs/ontology.md`](./repos/marloth-story/docs/ontology.md) **in addition to** schema-specific docs below (after cloning).

| If your task involves… | Read |
| ---------------------- | ---- |
| Design domain model, node types, relationships, traceability | [`repos/marloth-story/docs/ontology.md`](./repos/marloth-story/docs/ontology.md) |
| SQLite property graph, `repos/marloth-story/data/tome.sqlite`, `repos/tome/packages/tome-db/` | [`repos/tome/docs/features/tome-db.md`](./repos/tome/docs/features/tome-db.md) (+ ontology when interpreting data) |
| Web markdown editor, `repos/tome/packages/tome-editor/` | [`repos/tome/docs/features/tome-editor.md`](./repos/tome/docs/features/tome-editor.md) |
| Graph Explorer, LOD layers, anchor-scoped graph viz | [`repos/tome/docs/features/graph-explorer.md`](./repos/tome/docs/features/graph-explorer.md) |
| Editing story/design content in the graph | [`repos/marloth-story/docs/ontology.md`](./repos/marloth-story/docs/ontology.md) + [`repos/tome/docs/features/tome-db.md`](./repos/tome/docs/features/tome-db.md) + [`repos/marloth-story/AGENTS.md`](./repos/marloth-story/AGENTS.md) |
| Legacy Notion import / mining `repos/marloth-story/exports/` | [`repos/tome/docs/features/notion-import.md`](./repos/tome/docs/features/notion-import.md) |
| Ordered associations, scene order, drag-and-drop reorder | [`repos/tome/docs/features/ordered-associations.md`](./repos/tome/docs/features/ordered-associations.md) |
| Dynamic table view fields, computed columns | [`repos/tome/docs/features/dynamic-table-fields.md`](./repos/tome/docs/features/dynamic-table-fields.md) + [`repos/tome/docs/dynamic-fields/`](./repos/tome/docs/dynamic-fields/) |
| Table view tabs, `views.json` | [`repos/tome/docs/features/views.md`](./repos/tome/docs/features/views.md) |
| Type table columns, `table-schemas.json` | [`repos/tome/docs/features/table-schemas.md`](./repos/tome/docs/features/table-schemas.md) |
| Static website generation (Astro) | [`repos/tome/docs/features/static-website.md`](./repos/tome/docs/features/static-website.md) |
| Static website deploy (GitHub Actions → S3/CloudFront) | [`repos/marloth-story/docs/features/static-website-deploy.md`](./repos/marloth-story/docs/features/static-website-deploy.md) |
| Extension system (runtime-loaded packages, page blocks) | [`repos/tome/docs/features/extensions.md`](./repos/tome/docs/features/extensions.md) |

See also [`repos/tome/docs/features/README.md`](./repos/tome/docs/features/README.md) for the feature-doc template and how to add new features.

## Refactoring guides

Multi-session migration specs (agent-oriented). Start at the overview; do not read every session doc by default.

| If your task involves… | Read |
| --- | --- |
| Marloth → Tome decoupling (workspace config migration) | [`repos/marloth-story/docs/refactoring/00-overview.md`](./repos/marloth-story/docs/refactoring/00-overview.md) |

## Future expansion

- Architecture overview
- Standard test and validation commands
- Language/framework-specific coding conventions
