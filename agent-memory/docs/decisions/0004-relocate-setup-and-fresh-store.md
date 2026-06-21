# 0004 — Relocate setup to ~/Work/setup and reset the store

- Status: Accepted
- Date: 2026-06-20

## Context

The stack lived in `~/Work/cowork/agentmemory-stack-guide` — a cloned reference "guide"
repo, mixing upstream template with local config. As part of restructuring all local
setup under `~/Work/setup`, agentmemory needed a clean, owned home with its docs and
decisions in one place.

The store had also accumulated junk: 89% ClaudeProbe sessions plus fragmented worktree
projects (pre-fix), and a mid-session wipe had left "Unknown session" stubs.

## Decision

- **New home:** `~/Work/setup/agent-memory` is the single source of truth (compose, env,
  Dockerfile, docs, ADRs).
- **Fresh store:** start `data/` empty at the new location rather than migrating — clean
  slate, no leftover stubs. Pre-relocation backup exists at `~/agentmemory-data.bak.*`.
- **Drop gemini-proxy artifacts** (see [0002](0002-remove-gemini-proxy.md)).
- **Delete the old dir** after verifying the container runs from the new location.

The container is recreated from the new compose so its bind mounts (`./data`,
`./agentmemory-home`) point at the new paths. The named volumes
(`agentmemory-stack_agentmemory_local`, `_cache`) are project-scoped and persist across
the move, so the iii binary and embedding-model cache are NOT re-downloaded.

## Consequences

- Capture, dashboard, and LLM enrichment continue working from the new path.
- History before 2026-06-20 is not carried into the fresh store (recoverable from backup
  if ever needed).
- Future local-setup components follow the same `~/Work/setup/<component>` pattern.
