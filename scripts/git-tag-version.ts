#!/usr/bin/env bun
/**
 * Create a local annotated git tag from a repo-root package.json version.
 * Does not push.
 *
 * Usage (from silentorb-workbench root):
 *   bash scripts/git-tag-version.sh <repo-key>
 *
 * Repo keys: tome → .mnt/tome
 *
 * Agents run this as the last step of **bump** / **commit and bump** after the
 * dedicated version commit — not on plain **commit**.
 * See `.cursor/rules/plan-commit-workflow.mdc`.
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";

const workbenchRoot = join(import.meta.dir, "..");
const tomeRoot = process.env.TOME ?? join(workbenchRoot, ".mnt/tome");

const repoRoots: Record<string, string> = {
  tome: tomeRoot,
};

function usage(): never {
  console.error("Usage: bash scripts/git-tag-version.sh <repo-key>");
  console.error(`Known keys: ${Object.keys(repoRoots).join(", ")}`);
  process.exit(1);
}

const repoKey = process.argv[2];
if (!repoKey || !(repoKey in repoRoots)) usage();

const repoRoot = repoRoots[repoKey];
const manifestPath = join(repoRoot, "package.json");
let version: string;
try {
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8")) as { version?: string };
  if (!manifest.version || !/^\d+\.\d+\.\d+$/.test(manifest.version)) {
    throw new Error(`Root package.json missing semver version: ${manifestPath}`);
  }
  version = manifest.version;
} catch (err) {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
}

const tag = `v${version}`;

async function git(args: string[], cwd: string): Promise<{ code: number; stdout: string; stderr: string }> {
  const proc = Bun.spawn(["git", ...args], {
    cwd,
    stdout: "pipe",
    stderr: "pipe",
  });
  const [stdout, stderr, code] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  return { code, stdout: stdout.trim(), stderr: stderr.trim() };
}

const status = await git(["status", "--porcelain"], repoRoot);
if (status.code !== 0) {
  console.error(status.stderr || "git status failed");
  process.exit(1);
}
if (status.stdout) {
  console.error(`Working tree is dirty in ${repoRoot}; commit first, then tag.`);
  console.error(status.stdout);
  process.exit(1);
}

const existing = await git(["rev-parse", "--verify", `refs/tags/${tag}`], repoRoot);
if (existing.code === 0) {
  console.error(`Tag already exists: ${tag}`);
  process.exit(1);
}

const create = await git(["tag", "-a", tag, "-m", `Release ${tag}`], repoRoot);
if (create.code !== 0) {
  console.error(create.stderr || `Failed to create tag ${tag}`);
  process.exit(1);
}

const head = await git(["rev-parse", "--short", "HEAD"], repoRoot);
console.log(`Created local tag ${tag} on ${head.stdout || "HEAD"} in ${repoRoot}`);
console.log("Not pushed — push the commit and tag when ready for GHCR semver publish.");
