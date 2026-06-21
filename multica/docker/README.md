# Docker Strategy

> **Superseded (DECISIONS #16, 06-21):** local infra is now centralized at `~/Work/setup/infra`
> — one shared PG + Redis, logical isolation (dedicated DB per project, Redis key-prefix). Repos
> declare a `profiles/*.yaml` there instead of owning a running stack. The notes below describe
> the prior per-repo model, kept for transition context. `backend-worktree.compose.yml` is retired.

**Principle: don't duplicate the repos' infra.** Each product repo owns its local stack — this workspace orchestrates them via `../scripts/`, it does not re-declare Postgres/Redis.

## Where local infra actually comes from
- **Backend** (`<repo-be>`): its own `docker/docker-compose.local.yml` → Postgres + Redis, launched by `yarn setup-local` (project `-p app-local`). **Retired** in favor of shared infra (DECISIONS #16).
- **Webapp** (`nomi`/`admin`): Next dev servers talk to BE on `:3333`. **Mobile** (`nomi-mobile`): Expo + local sim/emulator. No extra infra.

Bring everything up with `../scripts/start-local-stack.sh`.

## What lives here (only what the repos don't provide)

### 1. `backend-worktree.compose.yml` — DEFERRED (v1 serializes backend)
Parameterized compose (unique project name + port offsets) to run **parallel backend worktrees** without port/DB collisions. Enable only when backend parallelism is needed (Phase 2). v1 keeps RS-QA/backend tasks serialized — see constitution §Concurrency.

Usage (when enabled):
```
PROJECT=app-wt-SHP1234 PG_PORT=55432 REDIS_PORT=56379 \
  docker compose -p $PROJECT -f docker/backend-worktree.compose.yml up -d
```

### 2. `multica/` — OPTIONAL, pending cloud-vs-self-host decision
If NOT using Multica cloud, a compose to self-host the Multica platform (server + Postgres/pgvector) goes here. Not created yet — confirm the decision first (see decisions/DECISIONS.md).
