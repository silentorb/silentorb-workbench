# AGENTS Guide

## Workspace purpose

**silentorb-workbench** orchestrates development across Tome tooling and domain projects. Sibling repositories are **bind-mounted** from the host under [`.mnt/`](./.mnt/) by [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml) (not cloned at container start). Open this repo in VS Code / Cursor; the devcontainer uses it as the single workspace folder.

| Container path | Repository role |
| -------------- | --------------- |
| `.mnt/tome` | Domain-agnostic Tome packages (`tome-db`, `tome-flatfile`, `tome-sqlite`, `tome-server`, `tome-http`, `tome-editor`, `tome-static-site`) and tooling docs |
| `.mnt/marloth-story` | Marloth design corpus (`content/`, domain ontology, migrations, deploy) |
| `.mnt/silentorb-web` | Silent Orb corporate website (Tome static site; optional mount) |
| `.mnt/translucence` | Translucence Bible-article corpus (`content/`; optional mount) |
| `.mnt/imp-ts` | Imp DAG transmission format (TypeScript; required by `tome` service) |
| `.mnt/imp-rust` | Imp Rust implementation (optional mount; workbench only) |
| `.mnt/imp-spec` | Standalone language-neutral Imp spec docs — graph IR, NodeLibrary catalogs, registry, typecheck, graph-resolve (optional; workbench only). Not imp-ts/packages/imp-core-types (TypeScript binding). Imp Translator and runtime specs live in `.mnt/imp-ts/docs/features/`. |
| `/workspaces/silentorb-workbench` | Devcontainer, scripts, this guide |

**Prerequisite:** clone `tome` and `marloth-story` as siblings of this repo on the host (`../tome`, `../marloth-story`), or set `TOME_REPO` / `MARLOTH_REPO` when opening the devcontainer. Optionally clone `silentorb-web` (`../silentorb-web`, or `SILENTORB_WEB_REPO`) and `translucence` (`../translucence`, or `TRANSLUCENCE_REPO`). Mount `imp-ts` (`../imp-ts`, or `IMP_REPO`) — required for the **`tome` Compose service** because tome’s Bun workspaces include `../imp-ts/packages/*` (`tome-query`). **Tome** owns package dependencies (`.mnt/tome/bun.lock`, `.mnt/tome/node_modules`). The workbench root orchestrates dev scripts and the devcontainer.

Scripts resolve mount paths via [`scripts/mnt-paths.sh`](./scripts/mnt-paths.sh).

For Marloth-specific writing goals, graph editing workflow, and design corpus conventions, read `.mnt/marloth-story/AGENTS.md` after cloning.

For Translucence (interconnected Bible articles and modular arguments), read `.mnt/translucence/AGENTS.md` after cloning.

For package-level Tome notes, read each package's `AGENTS.md` under `.mnt/tome/packages/`.

For Imp (universal DAG transmission format; successor to [imp-kotlin](https://github.com/silentorb/imp-kotlin), graph layer only):

| Task | Read |
| --- | --- |
| Language-neutral specs (graph IR, NodeLibrary catalogs, typecheck) | `.mnt/imp-spec/AGENTS.md` → package spec under `docs/packages/` |
| Imp Translators (SQL, React Flow) and runtime (execution) | `.mnt/imp-ts/docs/features/` |
| TypeScript binding (implementation, tests, versioning) | `.mnt/imp-ts/AGENTS.md` + package `AGENTS.md` |
| Rust binding (foundation crates) | `.mnt/imp-rust/AGENTS.md` — `bash scripts/run-in-imp-rust.sh test`; coverage: `bash scripts/coverage-imp-rust.sh` |

## Project context

- Open this repo in VS Code / Cursor (the devcontainer opens it automatically).
- Dev setup is **Docker Compose**: `workbench` (dev shell) + `tome` (editor dev servers). See [`.devcontainer/docker-compose.yml`](./.devcontainer/docker-compose.yml).
- **Silent Orb site:** `bash scripts/build-silentorb-web.sh` → `.mnt/silentorb-web/dist/`; serve with `bash scripts/serve-silentorb-web.sh` (port 8080). Content: `.mnt/silentorb-web/content/`.
- **Tome tooling** lives under `.mnt/tome/packages/`; `node_modules` lives at `.mnt/tome/node_modules` (Docker volume; gitignored in tome). Static site build output for Marloth: `.mnt/marloth-story/dist/web/`.
- **Design corpus** lives under `.mnt/marloth-story/content/` (git-tracked graph) with a local SQLite cache at `.mnt/marloth-story/data/tome.sqlite` (gitignored). Translucence is a second corpus at `.mnt/translucence/content/` (cache: `.mnt/translucence/data/tome.sqlite`).
- Set `TOME_CONTENT_PATH` to the content root when it is not discoverable by walking up from CWD — default: `.mnt/marloth-story/content` (not `content/data`). Override `TOME_CONTENT_PATH` / `TOME_DB_PATH` when opening the devcontainer to point the editor at another corpus (e.g. translucence). For an opt-in **multi-corpus** editor session, set `TOME_CORPORA` and a dedicated session `TOME_DB_PATH` — corpora may include marloth, translucence, and silentorb-web; see `.mnt/tome/docs/features/multi-corpus.md` (default remains Marloth-only).
- On devcontainer start, the **`tome` Compose service** builds from [`.mnt/tome/docker/Dockerfile.dev`](./.mnt/tome/docker/Dockerfile.dev), runs `bun install --frozen-lockfile` from `.mnt/tome/bun.lock` into a Docker volume at `.mnt/tome/node_modules`, then starts `editor:dev` with `TOME_CONTENT_PATH` set to marloth `content/` unless overridden. The workbench service only checks mounts ([`scripts/devcontainer-start.sh`](./scripts/devcontainer-start.sh)). **Rebuild the tome service image** after changing `.mnt/tome/docker/Dockerfile.dev` or `docker/install-runtime.sh`. Restart the tome service after changing `.mnt/tome/bun.lock` or package dependencies (dev installs at runtime — no image rebuild required for lockfile-only changes). The **release** image (`docker/Dockerfile.release`, published to GHCR) is separate — see `.mnt/tome/docs/features/container.md`.
- **Static site build** (test + build): `bash scripts/build-static-site.sh` runs tome-static-site tests and `web:build` via `.mnt/tome`.
- Run Tome package commands with `bash scripts/run-in-tome.sh …`, VS Code tasks, or from `.mnt/tome/` — not `bun run` at the workbench root.
- **imp-rust:** optional mount; `bash scripts/run-in-imp-rust.sh …` and `bash scripts/coverage-imp-rust.sh` use the profile-gated **`imp-rust` Compose service** (`compose run --rm`) when the workbench shell has no local `cargo`. Host path: `IMP_RUST_HOST_REPO` (set at devcontainer open) or inferred from the bind mount.

## Terminology

| Term | Meaning |
| ---- | ------- |
| **Project feature** | A workspace capability documented in `.mnt/tome/docs/features/` (e.g. tome-db, tome-editor). Use this phrase when discussing tooling or agent specs—not graph nodes. |
| **Node** | Any entity in the design graph (SQLite `nodes` table). Replaces legacy *record* / *vertex* in docs and API. |
| **Relationship** | A link between two nodes with a **relationship type** and properties. Stored as one JSON file per edge under `content/data/relationships/` (archive under `content/archive/relationships/`); SQLite cache expands to directed projections. |
| **Page** | UI representation of a node in the editor (`NodePageView`, page title, sections, `getNodePageDetail`). Not the same as a raw export file. |
| **Feature** (unqualified) | A **design node** (story/game feature idea) in the Marloth corpus, unless context clearly means a project feature. |
| **Schema** | Git-tracked relationship rules in `.mnt/marloth-story/content/model/schema.json`. Not SQLite DDL. |
| **Type table** | Any node used as an `IS_A` target and/or declared in `table-schemas.json`—not a permanent import label. |
| **Extension** | Externally packaged library of Tome components, loaded at runtime from project config (project feature—not a design graph node). |
| **Extension component** | One integration unit within an extension (`kind` + `implementationId`). |

## Working conventions

- Make focused changes that address the requested task only.
- Avoid unrelated refactors unless they are required to complete the task safely.
- Prefer small, incremental edits that are easy to review.
- **Prototypal stage — no backwards compatibility.** These repos are pre-release; there are no external consumers to protect. When you change an interface or format, **delete** the old path rather than preserving or widening it — no dual-format validators, case-insensitive fallbacks, normalization shims, deprecation warnings, or legacy code branches. Backwards-compatibility scaffolding only adds noise and convolution at this stage. Migrate existing data/content in the same change instead of supporting both shapes.
- **Prototypal stage — lock-step interfaces.** The workspace repos must stay mutually compatible at all times. Any interface change is applied to **every** dependent consumer in the same change so no repo is left on the old interface. The "Propagate tome breaking changes" bullet below is the concrete instance of this rule.
- **Propagate tome breaking changes to all dependent repos:** This workspace exists to develop interrelated repos in unison. When a change in `.mnt/tome/` breaks an upstream interface that dependents rely on — content-model schema or version bumps (e.g. `views.json`, `workspace.json`, `schema.json`, `associations.json`), package/API signatures, CLI flags, or build/output contracts — update **every dependent repo in the same change**, not just the one in front of you. Dependents are at least `.mnt/marloth-story/`, `.mnt/silentorb-web/`, and `.mnt/translucence/` (content corpora / static-site consumers), plus each repo’s **CI workflows** (see § Plan verification). Before considering the tome change complete, run full verify for tome and those dependents per the matrix below (`bash scripts/run-in-tome.sh run test`, `bash scripts/build-static-site.sh`, `bash scripts/build-silentorb-web.sh`, translucence `validate:workspace` when mounted). A tome breaking change is not done while a neighboring repo is left on the old interface.
- **CI is a dependent:** Treat GitHub Actions as a first-class consumer of package scripts, Dockerfiles, and deploy contracts. Tome release CI (`.mnt/tome/.github/workflows/container.yml`) runs the full weighted test suite in the release image; corpus repos have deploy workflows under `.github/workflows/`. Reason about workflows for every affected repo; when CI inputs change, check and update workflows (and related feature docs) in the same change if paths or commands drift. Local full verify must pass so CI is not the first place failures appear — do not defer confidence to a future Actions run.
- **Regression tests:** When fixing a bug in table views (database tables, relation tables, Properties section, composed/grouped table presentations, dynamic fields, or related API endpoints), add a regression test in the same change that would have failed before the fix. Seed test relationships using **composite types** from `content/model/associations.json` (via `ContentStore` / `seedTestCompositeRelationships`) when the bug involves graph traversals — do not rely only on direct `db.upsertRelationship` with legacy unidirectional types. Do not close a bug fix without a test unless the user explicitly waives it.
- **UI tests (Tome React):** New or changed React UI in `.mnt/tome` (editor, interactive page blocks, extension components) should use **`bun:test` + `@testing-library/react` + happy-dom** — prefer essential, durable tests; see `.mnt/tome/AGENTS.md` § Robust UI testing and `.mnt/tome/docs/features/testing.md`.
- **Script language:** agentic scripts should use **TypeScript** (Bun) by default — place durable tooling under `.mnt/tome/packages/` with tests and a shell wrapper in `scripts/` when appropriate. **One-off temporary scripts** (exploratory, throwaway, not intended to be maintained) may still be written in Python.
- **Package versioning:** Run `bash scripts/bump-version.sh <package> <minor|patch> [--install]` from the workbench root (scans `.mnt/imp-ts` and `.mnt/tome` packages, refreshes both lockfiles with `--install`). Reconcile bump levels at **bump** time — not on plain **commit** — see [plan-commit-workflow.mdc](./.cursor/rules/plan-commit-workflow.mdc). Root `tome` version is the container/release version — bump workspace packages + root and create a local `v*` tag only on **bump** / **commit and bump** (`bash scripts/git-tag-version.sh tome`; no push); see `.mnt/tome/AGENTS.md` § Versioning and `.mnt/tome/docs/features/container.md`.

## Implementation expectations

- Read existing files before editing to preserve intent and style.
- Keep assumptions explicit in commit or PR notes when behavior is unclear.
- **Tests while iterating:** surgical / package-scoped checks are fine during development.
- **Plan / change completion:** treating work as done requires the full verify set in § Plan verification (affected repos + direct dependents, including CI considered). Cursor plans enforce this via [plan-commit-workflow.mdc](./.cursor/rules/plan-commit-workflow.mdc) before `commit-await-approval`.
- Add self-documentation to files under `.mnt/tome/docs/`, `.mnt/marloth-story/docs/`, or `.mnt/translucence/docs/` when making agent-relevant updates.

## Plan verification / test commands

Full verify for a repo is that row’s command (not a surgical subset). **Verify set** = each plan-affected repo ∪ its **direct dependents** (dedupe; skip unmounted paths). Local full verify must cover what CI would run for that repo; agents do not push tags or rely on Actions as the first catcher.

| Repo | Full verify (from workbench root unless noted) | Direct dependents to also verify |
| --- | --- | --- |
| `.mnt/tome` | `bash scripts/run-in-tome.sh run test` (weighted full suite; includes typecheck — same entrypoint release CI runs in-container) | marloth-story, silentorb-web, translucence (if mounted); **CI:** `.mnt/tome/.github/workflows/container.yml` |
| `.mnt/imp-ts` | `cd .mnt/imp-ts && bun run test` | tome (and thus tome CI / corpora when tome verify runs) |
| `.mnt/imp-rust` | `bash scripts/coverage-imp-rust.sh --changed` (see [imp-rust-coverage.mdc](./.cursor/rules/imp-rust-coverage.mdc)) | none (note any imp-rust CI if present when editing) |
| `.mnt/marloth-story` | `bash scripts/build-static-site.sh` | **CI:** `.mnt/marloth-story/.github/workflows/deploy-static-site.yml` |
| `.mnt/silentorb-web` | `bash scripts/build-silentorb-web.sh` | **CI:** `.mnt/silentorb-web/.github/workflows/deploy-static-site.yml` |
| `.mnt/translucence` | `cd .mnt/translucence && bun run validate:workspace` | any translucence workflow if present |
| workbench root | no package suite (usually N/A) | none |

**CI column / CI rows:** “also verify” for CI means *reason about and update workflows when inputs drift* — not that the agent must trigger GitHub Actions. See Working conventions § CI is a dependent.

## Feature documentation

Authoritative design specs for **project features** live in `.mnt/tome/docs/features/` (one file per major workspace capability). They state requirements, design rationale, and behavior so agents need not re-analyze the repo for basics.

**Do not read all feature docs by default.** When your task matches a row, read only that file (and the package `AGENTS.md` if editing that package). Treat the feature doc as the source of truth over implementation when they disagree—update code or the doc explicitly.

For **design data** (what nodes mean, how they relate conceptually), read `.mnt/marloth-story/docs/ontology.md` or `.mnt/translucence/docs/ontology.md` **in addition to** schema-specific docs below (after cloning).

| If your task involves… | Read |
| ---------------------- | ---- |
| Design domain model, node types, relationships, traceability | `.mnt/marloth-story/docs/ontology.md` or `.mnt/translucence/docs/ontology.md` |
| SQLite property graph, `.mnt/marloth-story/data/tome.sqlite`, `.mnt/tome/packages/tome-db/` | `.mnt/tome/docs/features/tome-db.md` (+ ontology when interpreting data) |
| Sets (`set` trait, type tables, archive hub) | `.mnt/tome/docs/features/sets.md` |
| Web markdown editor, `.mnt/tome/packages/tome-editor/` | `.mnt/tome/docs/features/tome-editor.md` |
| Tome HTTP / editor API shape (use-case endpoints, no client fan-out transforms) | `.mnt/tome/docs/features/web-api-design.md` |
| Config-driven API host, `.mnt/tome/packages/tome-server/` | `.mnt/tome/docs/features/tome-server.md` |
| Opt-in API/SQL profiling (`TOME_PROFILE`, `/api/debug/profile`) | `.mnt/tome/docs/features/tome-server.md` (§ Request / SQL profiling) + `.mnt/tome/docs/features/container.md` |
| Graph Explorer, LOD layers, anchor-scoped graph viz | `.mnt/tome/docs/features/graph-explorer.md` |
| Editing story/design content in the graph | `.mnt/marloth-story/docs/ontology.md` + `.mnt/tome/docs/features/tome-db.md` + `.mnt/marloth-story/AGENTS.md` |
| Table presentation: scope tabs, row groups, drag-and-drop reorder | `.mnt/tome/docs/features/table-presentation.md` |
| Dynamic properties, computed columns | `.mnt/tome/docs/features/dynamic-properties.md` + `.mnt/tome/docs/dynamic-properties/` |
| Table view tabs, `views.json` | `.mnt/tome/docs/features/views.md` |
| Type table columns, `table-schemas.json` | `.mnt/tome/docs/features/table-schemas.md` |
| Static website generation (Astro) | `.mnt/tome/docs/features/static-website.md` |
| Static website deploy (GitHub Actions → S3/CloudFront) | `.mnt/marloth-story/docs/features/static-website-deploy.md` |
| Extension system (runtime-loaded packages, page blocks) | `.mnt/tome/docs/features/extensions.md` |
| Imp → Tome SQL binder (nodes / path hops) | `.mnt/tome/docs/features/tome-imp-sql.md` |
| Imp data model / NodeLibrary catalogs (language-neutral) | `.mnt/imp-spec/AGENTS.md` → `docs/packages/` |
| Imp Translators and runtime (SQL, React Flow, execution) | `.mnt/imp-ts/docs/features/` |
| Imp TypeScript binding | `.mnt/imp-ts/AGENTS.md` + package `AGENTS.md` |
| Imp-backed custom query table block | `.mnt/tome/docs/features/tome-query.md` |
| Relative event sequencing / timeline | `.mnt/tome/docs/features/tome-sequencing.md` |
| Sequencing constraint resolution | `.mnt/tome/docs/features/tome-sequencing-resolution.md` |
| Multi-corpus editor sessions | `.mnt/tome/docs/features/multi-corpus.md` |
| Graph store API (Base / Queryable, executeImp) | `.mnt/tome/docs/features/graph-store.md` |
| Tome dev / release containers (GHCR) | `.mnt/tome/docs/features/container.md` |
| Test tiers and weighted gating | `.mnt/tome/docs/features/testing.md` |

See also `.mnt/tome/docs/features/README.md` for the feature-doc template and how to add new features.

## Refactoring guides

Multi-session migration specs (agent-oriented). Start at the overview; do not read every session doc by default.

| If your task involves… | Read |
| --- | --- |
| Marloth → Tome decoupling (workspace config migration) | `.mnt/marloth-story/docs/refactoring/00-overview.md` |

## Future expansion

- Architecture overview
- Language/framework-specific coding conventions
