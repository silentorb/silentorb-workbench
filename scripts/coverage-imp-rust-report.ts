#!/usr/bin/env bun
/**
 * Parse imp-rust coverage artifacts and print an agent-friendly report.
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, relative } from "node:path";
import { spawnSync } from "node:child_process";

interface Targets {
  workspaceLineTarget: number;
  workspaceLineMinimum: number;
  crateTargets: Map<string, number>;
}

interface LineSummary {
  total: number;
  covered: number;
  percent: number;
}

interface FileCoverage {
  path: string;
  crate: string | null;
  lines: LineSummary;
}

interface CrateCoverage {
  crate: string;
  lines: LineSummary;
}

interface CoverageData {
  workspace: LineSummary;
  files: FileCoverage[];
  crates: CrateCoverage[];
}

function parseArgs(argv: string[]) {
  let impRust = process.env.IMP_RUST ?? "/workspaces/silentorb-workbench/.mnt/imp-rust";
  let changed = false;
  let strict = false;
  let writeBaseline = false;

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--imp-rust" && argv[i + 1]) {
      impRust = argv[++i];
    } else if (arg === "--changed") {
      changed = true;
    } else if (arg === "--strict") {
      strict = true;
    } else if (arg === "--write-baseline") {
      writeBaseline = true;
    } else if (arg === "--help" || arg === "-h") {
      console.log(`Usage: bun scripts/coverage-imp-rust-report.ts --imp-rust <path> [--changed] [--strict] [--write-baseline]`);
      process.exit(0);
    } else {
      console.error(`Unknown argument: ${arg}`);
      process.exit(1);
    }
  }

  return { impRust, changed, strict, writeBaseline };
}

function parseTargets(impRust: string): Targets {
  const path = join(impRust, "coverage-targets.toml");
  const text = readFileSync(path, "utf8");
  const workspaceLineTarget = readTomlNumber(text, "[workspace]", "line_target") ?? 85;
  const workspaceLineMinimum = readTomlNumber(text, "[workspace]", "line_minimum") ?? 70;
  const crateTargets = new Map<string, number>();

  for (const match of text.matchAll(/\[crates\.([^\]]+)\]\s*\n(?:[^\[]*\n)*?line_target\s*=\s*(\d+)/g)) {
    crateTargets.set(match[1], Number(match[2]));
  }

  return { workspaceLineTarget, workspaceLineMinimum, crateTargets };
}

function readTomlNumber(text: string, section: string, key: string): number | null {
  const sectionIndex = text.indexOf(section);
  if (sectionIndex === -1) return null;
  const nextSection = text.indexOf("\n[", sectionIndex + section.length);
  const block = nextSection === -1 ? text.slice(sectionIndex) : text.slice(sectionIndex, nextSection);
  const match = block.match(new RegExp(`^${key}\\s*=\\s*(\\d+)`, "m"));
  return match ? Number(match[1]) : null;
}

function lineSummary(count: number, covered: number): LineSummary {
  const percent = count === 0 ? 100 : (covered / count) * 100;
  return { total: count, covered, percent };
}

function parseLcov(impRust: string): Map<string, LineSummary> {
  const lcovPath = join(impRust, "lcov.info");
  if (!existsSync(lcovPath)) return new Map();

  const byFile = new Map<string, { hit: number; total: number }>();
  let currentFile: string | null = null;

  for (const rawLine of readFileSync(lcovPath, "utf8").split("\n")) {
    const line = rawLine.trim();
    if (line.startsWith("SF:")) {
      currentFile = line.slice(3);
      if (!byFile.has(currentFile)) byFile.set(currentFile, { hit: 0, total: 0 });
    } else if (line.startsWith("DA:") && currentFile) {
      const [, hits] = line.slice(3).split(",");
      const entry = byFile.get(currentFile)!;
      entry.total += 1;
      if (Number(hits) > 0) entry.hit += 1;
    }
  }

  const result = new Map<string, LineSummary>();
  for (const [file, { hit, total }] of byFile) {
    result.set(normalizePath(file), lineSummary(total, hit));
  }
  return result;
}

function normalizePath(path: string): string {
  return path.replace(/\\/g, "/");
}

function crateFromPath(path: string): string | null {
  const match = path.match(/(?:^|\/)crates\/([^/]+)\//);
  return match ? match[1] : null;
}

function parseCoverageJson(impRust: string, lcovByFile: Map<string, LineSummary>): CoverageData {
  const jsonPath = join(impRust, "coverage.json");
  const raw = JSON.parse(readFileSync(jsonPath, "utf8")) as unknown;

  const files: FileCoverage[] = [];
  let workspaceLines = lineSummary(0, 0);

  const entries = extractJsonEntries(raw);
  for (const entry of entries) {
    const totals = entry.totals as Record<string, { count?: number; covered?: number; percent?: number }> | undefined;
    if (totals?.lines) {
      workspaceLines = lineSummary(totals.lines.count ?? 0, totals.lines.covered ?? 0);
    }

    for (const fileEntry of (entry.files as Array<Record<string, unknown>> | undefined) ?? []) {
      const filename = normalizePath(String(fileEntry.filename ?? ""));
      if (!filename.includes("/crates/") || filename.includes("/tests/")) continue;

      const summary = fileEntry.summary as Record<string, { count?: number; covered?: number }> | undefined;
      const lines = summary?.lines
        ? lineSummary(summary.lines.count ?? 0, summary.lines.covered ?? 0)
        : lcovByFile.get(filename) ?? lineSummary(0, 0);

      files.push({ path: filename, crate: crateFromPath(filename), lines });
    }
  }

  if (files.length === 0 && lcovByFile.size > 0) {
    for (const [path, lines] of lcovByFile) {
      if (!path.includes("/crates/") || path.includes("/tests/")) continue;
      files.push({ path, crate: crateFromPath(path), lines });
    }
    workspaceLines = aggregateLines(files.map((f) => f.lines));
  }

  const crateMap = new Map<string, LineSummary[]>();
  for (const file of files) {
    if (!file.crate) continue;
    const list = crateMap.get(file.crate) ?? [];
    list.push(file.lines);
    crateMap.set(file.crate, list);
  }

  const crates: CrateCoverage[] = [...crateMap.entries()]
    .map(([crate, summaries]) => ({ crate, lines: aggregateLines(summaries) }))
    .sort((a, b) => a.crate.localeCompare(b.crate));

  if (workspaceLines.total === 0 && files.length > 0) {
    workspaceLines = aggregateLines(files.map((f) => f.lines));
  }

  return { workspace: workspaceLines, files, crates };
}

function extractJsonEntries(raw: unknown): Array<Record<string, unknown>> {
  if (Array.isArray(raw)) {
    return raw.flatMap((item) => extractJsonEntries(item));
  }
  if (raw && typeof raw === "object") {
    const obj = raw as Record<string, unknown>;
    if (Array.isArray(obj.data)) {
      return obj.data as Array<Record<string, unknown>>;
    }
    if (obj.totals || obj.files) {
      return [obj];
    }
  }
  throw new Error("Unrecognized coverage.json format");
}

function aggregateLines(summaries: LineSummary[]): LineSummary {
  const total = summaries.reduce((sum, s) => sum + s.total, 0);
  const covered = summaries.reduce((sum, s) => sum + s.covered, 0);
  return lineSummary(total, covered);
}

function getChangedSourceFiles(impRust: string): string[] {
  const result = spawnSync("git", ["-C", impRust, "diff", "--name-only", "HEAD", "--", "crates/*/src"], {
    encoding: "utf8",
  });
  if (result.status !== 0 && result.stderr) {
    // Untracked repo or no commits — fall back to working tree vs empty
    const untracked = spawnSync("git", ["-C", impRust, "ls-files", "--others", "--exclude-standard", "crates"], {
      encoding: "utf8",
    });
    const modified = spawnSync("git", ["-C", impRust, "diff", "--name-only", "--", "crates/*/src"], {
      encoding: "utf8",
    });
    const names = new Set<string>();
    for (const out of [untracked.stdout, modified.stdout]) {
      for (const line of out.split("\n")) {
        const trimmed = line.trim();
        if (trimmed.includes("/src/")) names.add(normalizePath(trimmed));
      }
    }
    return [...names];
  }
  return result.stdout
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0 && line.includes("/src/"))
    .map(normalizePath);
}

function targetForCrate(crate: string, targets: Targets): number {
  return targets.crateTargets.get(crate) ?? targets.workspaceLineTarget;
}

function statusLabel(percent: number, target: number, minimum: number): string {
  if (percent < minimum) return "below minimum";
  if (percent < target) return "below target";
  return "ok";
}

function formatPercent(n: number): string {
  return `${n.toFixed(1)}%`;
}

function printReport(
  impRust: string,
  data: CoverageData,
  targets: Targets,
  changedFiles: string[],
  showChangedOnly: boolean,
): boolean {
  const ws = data.workspace;
  const wsStatus = statusLabel(ws.percent, targets.workspaceLineTarget, targets.workspaceLineMinimum);
  const today = new Date().toISOString().slice(0, 10);

  console.log(`## imp-rust coverage (${today})\n`);
  console.log(
    `Workspace: ${formatPercent(ws.percent)} lines ` +
      `(target ${targets.workspaceLineTarget}%, minimum ${targets.workspaceLineMinimum}%) — ${wsStatus.toUpperCase()}\n`,
  );

  console.log("| Crate | Lines | Target | Status |");
  console.log("| ----- | ----- | ------ | ------ |");
  for (const { crate, lines } of data.crates) {
    const target = targetForCrate(crate, targets);
    const status = statusLabel(lines.percent, target, targets.workspaceLineMinimum);
    console.log(`| ${crate} | ${formatPercent(lines.percent)} | ${target}% | ${status} |`);
  }
  console.log("");

  const changedSet = new Set(changedFiles.map((f) => normalizePath(f)));
  const changedCoverage = data.files.filter((f) => {
    const rel = normalizePath(relative(impRust, f.path.startsWith("/") ? f.path : join(impRust, f.path)));
    return changedSet.has(rel) || changedSet.has(f.path) || [...changedSet].some((c) => f.path.endsWith(c));
  });

  if (showChangedOnly) {
    if (changedFiles.length === 0) {
      console.log("Changed files: (none detected under crates/*/src/)\n");
    } else {
      console.log("Changed files:");
      for (const changed of changedFiles) {
        const file = data.files.find((f) => f.path.endsWith(changed) || f.path.includes(changed));
        if (file) {
          const crateTarget = file.crate ? targetForCrate(file.crate, targets) : targets.workspaceLineTarget;
          const note =
            file.lines.percent < crateTarget ? " — below crate target, add integration tests" : "";
          console.log(`- ${changed} — ${formatPercent(file.lines.percent)}${note}`);
        } else {
          console.log(`- ${changed} — (no coverage data; new or uninstrumented)`);
        }
      }
      console.log("");
    }
  }

  const belowTarget = data.files.filter((f) => {
    if (!f.crate) return false;
    const target = targetForCrate(f.crate, targets);
    return f.lines.percent < target && f.path.includes("/src/");
  });

  if (belowTarget.length > 0) {
    console.log("Files below crate target:");
    for (const file of belowTarget.sort((a, b) => a.lines.percent - b.lines.percent)) {
      const rel = file.path.includes("/crates/") ? file.path.slice(file.path.indexOf("crates/")) : file.path;
      console.log(`- ${rel} — ${formatPercent(file.lines.percent)}`);
    }
    console.log("");
  }

  if (wsStatus === "below minimum" || data.crates.some((c) => statusLabel(c.lines.percent, targetForCrate(c.crate, targets), targets.workspaceLineMinimum) === "below minimum")) {
    return false;
  }
  return true;
}

function writeBaselineDoc(impRust: string, data: CoverageData): void {
  const docPath = join(impRust, "docs/coverage.md");
  const today = new Date().toISOString().slice(0, 10);
  const rows = data.crates
    .map(({ crate, lines }) => `| ${crate} | ${formatPercent(lines.percent)} | |`)
    .join("\n");

  let doc = readFileSync(docPath, "utf8");
  const baselineBlock = `**Last measured:** ${today}

**Workspace line coverage:** ${formatPercent(data.workspace.percent)}

**Per crate:**

| Crate | Lines | Notes |
| ----- | ----- | ----- |
${rows}
`;

  if (doc.includes("**Last measured:**")) {
    doc = doc.replace(
      /\*\*Last measured:\*\*[\s\S]*?(?=\n## |\n$)/,
      `${baselineBlock.trim()}\n\n`,
    );
  } else {
    doc = doc.replace("(pending first run)", baselineBlock.trim());
    doc = doc.replace("(pending)", formatPercent(data.workspace.percent));
    doc = doc.replace("| (pending) | | |", rows);
  }

  writeFileSync(docPath, doc);
}

function main() {
  const { impRust, changed, strict, writeBaseline } = parseArgs(process.argv.slice(2));
  const targets = parseTargets(impRust);
  const lcovByFile = parseLcov(impRust);
  const jsonPath = join(impRust, "coverage.json");

  if (!existsSync(jsonPath)) {
    console.error(`coverage.json not found at ${jsonPath} — run coverage-imp-rust.sh first`);
    process.exit(1);
  }

  const data = parseCoverageJson(impRust, lcovByFile);
  const changedFiles = changed ? getChangedSourceFiles(impRust) : [];
  const ok = printReport(impRust, data, targets, changedFiles, changed);

  if (writeBaseline) {
    writeBaselineDoc(impRust, data);
    console.log(`Baseline written to ${join(impRust, "docs/coverage.md")}\n`);
  }

  if (strict && !ok) {
    process.exit(1);
  }
}

main();
