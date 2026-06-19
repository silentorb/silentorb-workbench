# AGENTS Guide

## Workspace purpose

**silentorb-workbench** is the root development workspace for Tome tooling and domain projects. It combines sibling checkouts:

| Subtree | Repository role |
| ------- | --------------- |
| `tome/` | Domain-agnostic Tome packages (`tome-db`, `tome-editor`, `tome-static-site`) and tooling docs |
| `marloth-story/` | Marloth design corpus (`content/`, domain ontology, migrations, deploy) |

**marloth-story** depends on Tome packages via git references in its `package.json` (configured in a later migration step). The workbench root orchestrates dev scripts, tests, and the devcontainer.

For Marloth-specific writing goals, graph editing workflow, and design corpus conventions, read [`marloth-story/AGENTS.md`](./marloth-story/AGENTS.md) once that file exists in the subtree (currently at the monorepo root until directory rearrangement).

For package-level Tome notes, read each package's `AGENTS.md` under `tome/packages/`.

## Project context

- Open this folder as the VS Code / Cursor workspace root (`/workspaces/silentorb-workbench` in the devcontainer).
- **Tome tooling** lives under `tome/packages/`; ephemeral build output and hoisted dependencies live at the workbench root (`./dist/`, `./node_modules/`).
- **Design corpus** lives under `marloth-story/content/` (git-tracked graph) with a local SQLite cache at `marloth-story/data/tome.sqlite` (gitignored).
- Set `TOME_CONTENT_PATH` to the content root when it is not discoverable by walking up from CWD — default: `marloth-story/content` (not `content/data`).
- All external dependencies and tooling installs should be performed within the devcontainer Dockerfile. On each container start, the image `CMD` runs `bun install --frozen-lockfile` in the workspace and then starts the editor dev servers (`bun run editor:dev`). **Rebuild the container** after changing root `package.json` or `bun.lock` — do not run `bun install` manually in a terminal or on the host.

## Terminology

| Term | Meaning |
| ---- | ------- |
| **Project feature** | A workspace capability documented in `tome/docs/features/` (e.g. tome-db, tome-editor). Use this phrase when discussing tooling or agent specs—not graph nodes. |
| **Node** | Any entity in the design graph (SQLite `nodes` table). Replaces legacy *record* / *vertex* in docs and API. |
| **Relationship** | A link between two nodes with a **relationship type** and properties. Stored compactly in `relationships.json`; SQLite cache expands to directed projections. |
| **Page** | UI representation of a node in the editor (`NodePageView`, page title, sections, `getNodePageDetail`). Not the same as a Notion export file. |
| **Feature** (unqualified) | A **design node** (story/game feature idea) in the Marloth corpus, unless context clearly means a project feature. |
| **Schema** | Git-tracked relationship rules in `marloth-story/content/model/schema.json`. Not SQLite DDL. |
| **Type table** | Any node used as an `IS_A` target and/or with `notion_schema` / `notion_database` metadata—not a permanent import label. |

## Working conventions

- Make focused changes that address the requested task only.
- Avoid unrelated refactors unless they are required to complete the task safely.
- Prefer small, incremental edits that are easy to review.
- **Regression tests:** When fixing a bug in table views (database tables, relation tables, Properties section, ordered-association tables, dynamic fields, or related API endpoints), add a regression test in the same change that would have failed before the fix. Seed test relationships using **composite types** from `content/relationship-types.json` (via `ContentStore` / `seedTestCompositeRelationships`) when the bug involves graph traversals — do not rely only on direct `db.upsertRelationship` with legacy unidirectional types. Do not close a bug fix without a test unless the user explicitly waives it.
- **Script language:** agentic scripts should use **TypeScript** (Bun) by default — place durable tooling under `tome/packages/` with tests and a shell wrapper in `scripts/` when appropriate. **One-off temporary scripts** (exploratory, throwaway, not intended to be maintained) may still be written in Python.

## Implementation expectations

- Read existing files before editing to preserve intent and style.
- Keep assumptions explicit in commit or PR notes when behavior is unclear.
- Run relevant checks or tests when changing code, if such checks are available.
- Add self-documentation to files under `tome/docs/` or `marloth-story/docs/` when making agent-relevant updates.

## Feature documentation

Authoritative design specs for **project features** live in `tome/docs/features/` (one file per major workspace capability). They state requirements, design rationale, and behavior so agents need not re-analyze the repo for basics.

**Do not read all feature docs by default.** When your task matches a row, read only that file (and the package `AGENTS.md` if editing that package). Treat the feature doc as the source of truth over implementation when they disagree—update code or the doc explicitly.

For **design data** (what nodes mean, how they relate conceptually), read [`marloth-story/docs/ontology.md`](./marloth-story/docs/ontology.md) **in addition to** schema-specific docs below.

| If your task involves… | Read |
| ---------------------- | ---- |
| Design domain model, node types, relationships, traceability | [`marloth-story/docs/ontology.md`](./marloth-story/docs/ontology.md) |
| SQLite property graph, `marloth-story/data/tome.sqlite`, `tome/packages/tome-db/` | [`tome/docs/features/tome-db.md`](./tome/docs/features/tome-db.md) (+ ontology when interpreting data) |
| Web markdown editor, `tome/packages/tome-editor/` | [`tome/docs/features/tome-editor.md`](./tome/docs/features/tome-editor.md) |
| Graph Explorer, LOD layers, anchor-scoped graph viz | [`tome/docs/features/graph-explorer.md`](./tome/docs/features/graph-explorer.md) |
| Editing story/design content in the graph | [`marloth-story/docs/ontology.md`](./marloth-story/docs/ontology.md) + [`tome/docs/features/tome-db.md`](./tome/docs/features/tome-db.md) + [`marloth-story/AGENTS.md`](./marloth-story/AGENTS.md) |
| Legacy Notion import / mining `marloth-story/exports/` | [`tome/docs/features/notion-import.md`](./tome/docs/features/notion-import.md) |
| Ordered associations, scene order, drag-and-drop reorder | [`tome/docs/features/ordered-associations.md`](./tome/docs/features/ordered-associations.md) |
| Dynamic table view fields, computed columns | [`tome/docs/features/dynamic-table-fields.md`](./tome/docs/features/dynamic-table-fields.md) + [`tome/docs/dynamic-fields/`](./tome/docs/dynamic-fields/) |
| Table view tabs, `views.json` | [`tome/docs/features/views.md`](./tome/docs/features/views.md) |
| Type table columns, `table-schemas.json` | [`tome/docs/features/table-schemas.md`](./tome/docs/features/table-schemas.md) |
| Static website generation (Astro) | [`tome/docs/features/static-website.md`](./tome/docs/features/static-website.md) |
| Static website deploy (GitHub Actions → S3/CloudFront) | [`tome/docs/features/static-website-deploy.md`](./tome/docs/features/static-website-deploy.md) |

See also [`tome/docs/features/README.md`](./tome/docs/features/README.md) for the feature-doc template and how to add new features.

## Refactoring guides

Multi-session migration specs (agent-oriented). Start at the overview; do not read every session doc by default.

| If your task involves… | Read |
| --- | --- |
| Marloth → Tome decoupling (workspace config migration) | [`marloth-story/docs/refactoring/00-overview.md`](./marloth-story/docs/refactoring/00-overview.md) |

## Future expansion

- Architecture overview
- Standard test and validation commands
- Language/framework-specific coding conventions
