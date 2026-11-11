---
name: plan-bump
description: >-
  Silentorb version bump / preview bump / commit-and-bump for tome releases.
  Use when the user says preview bump, bump, commit and preview bump, or
  commit and bump.
---

# Plan bump workflow

This skill owns **preview bump**, **bump**, **commit and preview bump**, and
**commit and bump**. It does **not** replace plan-commit (from installed
`silentorb-agents-publishing`).

## Relationship to plan-commit

Follow the installed `silentorb-agents-publishing` **plan-commit** skill for
baseline, verify, and commit execution. Do not re-copy those steps here.
Verify matrix: workbench `AGENTS.md` § Plan verification / test commands.

| User says | What to do |
| --- | --- |
| **commit** / **commit per the plan** | Plan-commit only — no version bumps or tags |
| **preview bump** | This skill’s preview path (advisory) |
| **commit and preview bump** | Plan-commit execution first (work commits as-is), then **preview bump** |
| **bump** | This skill’s bump path (requires clean trees) |
| **commit and bump** | Plan-commit execution first, then **bump** (two-step history) |

- Plain **commit** never bumps versions or creates tags.
- **Bump** requires **clean** working trees in every repo that will receive a
  version commit — if dirty, refuse and tell the user to **commit** or
  **commit and bump** first.
- **Commit and bump** is always two commits (or commit sets): work first, then
  version + lockfile (+ tag). Never fold the root version bump into the feature
  commit.
- Do **not** print a bump preview automatically after plan implementation or
  after plain **commit**. Preview only when the user asks (**preview bump** or
  **commit and preview bump**).
- Plans do not need a full version matrix in Commit strategy — run
  **preview bump** when a release classification is wanted.

### User trigger (bump-related)

Say **preview bump** to see what a release would bump (advisory). Say
**commit and preview bump** to commit then print that preview. Say **bump**
alone when ready to release (work already committed). Say **commit and bump**
when a tome release tag is wanted in one go.

## Preview bump

When the user says **preview bump** (alone, or after other work):

1. Find the latest local tome tag matching `v*` (e.g.
   `git describe --tags --match 'v*' --abbrev=0` in `.mnt/tome`). If none,
   treat the full history / settled range as in-scope.
2. Analyze packages touched **since that tag…HEAD** in `.mnt/tome` and
   `.mnt/imp-ts` (include uncommitted changes only if they are part of the
   settled release range the user is previewing — prefer committed history;
   note dirty trees if present).
3. Print the advisory preview. Do **not** run bump scripts, refresh lockfiles
   for versioning, create tags, or commit.

Preview must list:

| Item | What to print |
| --- | --- |
| Workspace packages | Each touched package: current version → proposed `minor` or `patch` next version, one-line why |
| Cascades | Dependents that would move because of a `minor` bump / `workspace:` range rewrite |
| Root release package | e.g. `tome` root: current → proposed next version + level |
| Resulting git tag | e.g. `v0.3.0` matching the proposed root version |
| Ordinary commit note | Remind that plain **commit** does **not** bump versions or create tags; only **bump** / **commit and bump** do |

Classify `minor` vs `patch` using that repo’s versioning rules (see workbench /
tome AGENTS). Treat the preview as advisory; **re-classify at bump time** if
the diff changed.

## Commit and preview bump

When the user says **commit and preview bump**:

1. Run **commit** execution for all planned repos (work commits as-is; no
   version bumps) per plan-commit.
2. Then run **preview bump** (advisory only — no bump scripts or tags).

## Bump

When the user says **bump** (tome release; today the only taggable repo):

1. Require **clean** working trees in every repo that will receive a version
   commit (at least `.mnt/tome`; also `.mnt/imp-ts` when imp packages will
   bump). If dirty, refuse and tell the user to **commit** or
   **commit and bump** first.
2. Find the latest local tome tag matching `v*` (e.g.
   `git describe --tags --match 'v*' --abbrev=0` in `.mnt/tome`). If none,
   treat the full history / settled range as in-scope.
3. Classify packages touched **since that tag…HEAD** in `.mnt/tome` and
   `.mnt/imp-ts` (`minor` vs `patch` per repo versioning rules). Do **not**
   require a prior **preview bump**; if one was printed earlier, still
   re-classify from current HEAD.
4. **Tome full-suite gate (required):** run `bash scripts/run-in-tome.sh run test`
   (weighted full suite from workbench root). If it fails, **cancel the bump**
   — do not run `bump-version`, refresh lockfiles for versioning, commit
   version changes, or create a tag. Report the failure and stop; the user must
   fix tests (or explicitly waive) before retrying **bump**.
5. Run `bash scripts/bump-version.sh <package> <level>` for each touched
   **workspace** package (cascades/ranges as the script already does), then
   bump root `tome` (`minor` if any workspace minor / release-worthy API epoch;
   else `patch`). Refresh lockfiles as in **Version bumps** below.
6. Commit **version + lockfile only** changes — one commit per affected repo —
   with messages matching recent `git log` style (why-focused).
7. Create a **local** annotated tag: `bash scripts/git-tag-version.sh tome`
   (`v<version>` matching root `package.json`).
8. **Do not push** the commit(s) or the tag. Report the tag name so the user
   can push when ready (e.g. for GHCR semver).

Supported tag repos today: `tome` → `.mnt/tome`.

**Preview bump** does not run this suite (advisory only). **Commit and bump**
inherits the gate via step 2 → **bump**.

## Commit and bump

When the user says **commit and bump**:

1. Run **commit** execution for all planned repos (work commits as-is; no
   version bumps) per plan-commit.
2. Then run **bump** (dedicated version commits + local `v*` tag).

This is always a **two-step** history: work commit(s) first, then bump
commit(s) + tag — never fold the root version bump into the feature commit.

**Do not** print a bump preview as part of **commit and bump** unless the user
also asked for preview.

## Version bumps (reconcile at bump time)

Plans may include draft bump levels and lockfile notes — treat these as
**starting points**, not contracts. The same tension applies as commit scope:

- Complex plans cannot list every file change.
- The user may request additional changes after implementation and **before**
  committing or bumping — expected, not plan failure.
- **At bump time**, re-snapshot commits since the last `v*` tag (or the settled
  range), re-classify bump levels (`minor` vs `patch`) for each touched
  package, run `bash scripts/bump-version.sh` from the workbench root as
  needed, refresh lockfiles (`bun install` in each repo root whose lockfile
  resolves affected dependents), and include version + lockfile changes in the
  **bump** commit(s).
- Version bumps happen **after** the change set is settled and **committed**,
  not when the plan is written and not during plain **commit**.
- Root release versions (e.g. `tome`) bump only on **bump** /
  **commit and bump**, never on ordinary commits.
- A **preview bump** is advisory; always re-run the classification when
  executing bump.

Lockfile refresh rule: any imp-ts package change → refresh both `.mnt/imp-ts`
and `.mnt/tome` lockfiles; tome-only changes → `.mnt/tome` only.
