# 0003 — Hook fixes: skip ClaudeProbe, worktree-aware project naming

- Status: Accepted
- Date: 2026-06-20

## Context

Two problems in the capture hooks (`~/.claude/plugins/agentmemory-local/scripts/*.mjs`):

1. **ClaudeProbe noise.** The CodexBar menu-bar app launches throwaway Claude sessions in
   `~/Library/Application Support/CodexBar/ClaudeProbe` for status checks. Each fired
   `session-start`, creating an empty session named `ClaudeProbe` (cwd basename). These
   reached **1867 of 2086 sessions (89%)**, burying real work.
2. **Worktree mis-naming.** `resolveProject` used `git rev-parse --show-toplevel`, so
   Conductor git-worktrees reported their workspace codename (`vancouver`, `austin`,
   `stuttgart`, …) instead of the real repo, fragmenting history across fake projects.

## Decision

Patched the shared `resolveProject` in all 9 capture hooks that emit observations:

- **Skip guard:** if cwd matches `CodexBar/ClaudeProbe`, `process.exit(0)` — never record.
- **Worktree-aware:** resolve via `git rev-parse --path-format=absolute --git-common-dir`,
  strip trailing `/.git`, use that basename → the real parent repo (worktrees included).
  Falls back to `--show-toplevel`, then cwd basename.

Originals saved alongside as `*.mjs.bak.hookfix`. Verified: a worktree `…/repo/austin`
resolves to `repo`; ClaudeProbe path exits 0; non-git dirs use the folder name.

## Consequences

- These files live in `~/.claude/plugins/` (Claude config), **not** in this repo — noted
  here so the change is discoverable. A plugin update may overwrite them; re-apply if so.
- To fully silence probes at the source, disable the check in CodexBar settings (the guard
  handles it regardless).
