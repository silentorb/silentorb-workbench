#!/usr/bin/env bun
/**
 * Clone workspace sibling repos declared in workspace.repos.json into repos/.
 * Idempotent: skips existing clones; use --update to git fetch.
 */
import { existsSync } from "node:fs";
import { mkdir, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";

type RepoEntry = {
  name: string;
  url: string;
  ref?: string;
};

type WorkspaceReposManifest = {
  reposDir: string;
  repos: RepoEntry[];
};

const WORKBENCH_ROOT = resolve(import.meta.dir, "..");

function parseArgs(argv: string[]) {
  return {
    dryRun: argv.includes("--dry-run"),
    update: argv.includes("--update"),
  };
}

function validateManifest(raw: unknown): WorkspaceReposManifest {
  if (typeof raw !== "object" || raw === null) {
    throw new Error("Manifest must be a JSON object");
  }
  const obj = raw as Record<string, unknown>;
  if (typeof obj.reposDir !== "string" || obj.reposDir.length === 0) {
    throw new Error('Manifest "reposDir" must be a non-empty string');
  }
  if (!Array.isArray(obj.repos) || obj.repos.length === 0) {
    throw new Error('Manifest "repos" must be a non-empty array');
  }
  const repos: RepoEntry[] = obj.repos.map((entry, index) => {
    if (typeof entry !== "object" || entry === null) {
      throw new Error(`repos[${index}] must be an object`);
    }
    const repo = entry as Record<string, unknown>;
    if (typeof repo.name !== "string" || repo.name.length === 0) {
      throw new Error(`repos[${index}].name must be a non-empty string`);
    }
    if (typeof repo.url !== "string" || repo.url.length === 0) {
      throw new Error(`repos[${index}].url must be a non-empty string`);
    }
    if (repo.ref !== undefined && typeof repo.ref !== "string") {
      throw new Error(`repos[${index}].ref must be a string when set`);
    }
    return {
      name: repo.name,
      url: repo.url,
      ref: repo.ref as string | undefined,
    };
  });
  return { reposDir: obj.reposDir, repos };
}

async function loadManifest(): Promise<WorkspaceReposManifest> {
  const manifestPath =
    process.env.WORKSPACE_REPOS_MANIFEST ??
    join(WORKBENCH_ROOT, "workspace.repos.json");
  const text = await readFile(manifestPath, "utf8");
  return validateManifest(JSON.parse(text));
}

async function runGit(cwd: string, args: string[]): Promise<void> {
  const proc = Bun.spawn(["git", ...args], {
    cwd,
    stdout: "inherit",
    stderr: "inherit",
  });
  const exitCode = await proc.exited;
  if (exitCode !== 0) {
    throw new Error(`git ${args.join(" ")} failed with exit code ${exitCode}`);
  }
}

async function main(): Promise<void> {
  const { dryRun, update } = parseArgs(process.argv.slice(2));
  const manifest = await loadManifest();
  const reposDir = resolve(
    WORKBENCH_ROOT,
    process.env.WORKSPACE_REPOS_DIR ?? manifest.reposDir,
  );

  if (!dryRun) {
    await mkdir(reposDir, { recursive: true });
  }

  for (const repo of manifest.repos) {
    const target = join(reposDir, repo.name);
    const gitDir = join(target, ".git");

    if (existsSync(gitDir)) {
      console.log(`skip ${repo.name} (already cloned at ${target})`);
      if (update) {
        if (dryRun) {
          console.log(`  would run: git -C ${target} fetch`);
        } else {
          await runGit(target, ["fetch", "origin"]);
        }
      }
      continue;
    }

    const cloneArgs = ["clone", "--origin", "origin"];
    if (repo.ref) {
      cloneArgs.push("--branch", repo.ref);
    }
    cloneArgs.push(repo.url, target);

    if (dryRun) {
      console.log(`would clone ${repo.url} -> ${target}${repo.ref ? ` (ref=${repo.ref})` : ""}`);
      continue;
    }

    console.log(`clone ${repo.url} -> ${target}${repo.ref ? ` (ref=${repo.ref})` : ""}`);
    await runGit(reposDir, cloneArgs);
  }
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(`install-repos: ${message}`);
  process.exit(1);
});
