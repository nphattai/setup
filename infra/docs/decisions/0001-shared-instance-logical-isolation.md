# 0001 — Shared single instance, logical isolation

- Status: Accepted
- Date: 2026-06-21

## Context
Local dev infra (Postgres, Redis, future LocalStack) was per-repo: each product repo owned
its own `docker-compose.local.yml` (multica DECISIONS #14). As the Multica agent squad and
multiple projects scale on **one host**, we want a single place that defines infra and serves
many projects/worktrees without collision — but per-project/per-worktree *container* stacks
were judged too expensive (N×(PG+Redis) on one machine).

## Decision
One always-on stack (`dev-infra`: one `pgvector/pgvector:pg18` + one `redis:7-alpine`) at
`~/Work/setup/infra`, with **logical** isolation:

- **Postgres:** a dedicated database per project key — enforced by Postgres.
- **Redis:** a per-project key prefix (`<key>:`) — applied by the app's ioredis `keyPrefix`,
  **not** enforced by Redis.

Grain is **per-project** for v1. A thin CLI (`infractl`) starts the stack, creates databases,
and injects `.env.infra` (`DATABASE_URL`, `REDIS_URL`, `REDIS_PREFIX`) into consumer worktrees.
Runs on standard ports (5432/6379) as THE local stack; repos' own compose are retired (don't
run alongside — port clash). No state file — databases listed from PG, prefix derived from key.

## Consequences
- **Supersedes multica DECISIONS #14** ("repos own compose"): central infra owns *running*
  infra; repos declare a `profiles/*.yaml` contract instead.
- **multica DECISIONS #12 (backend serialized) stands.** Per-project DB → worktrees share it,
  so parallel backend would clobber migrations/seed. Not unblocked by this design.
  - *Escape hatch:* switch to per-worktree keys — extra logical DBs, no new container — to
    unblock parallel backend later. Pure key-convention change.
- **Redis isolation is the app's responsibility, and it's already satisfied.**
  `insurtech-service` instantiates `new Redis(url, {keyPrefix:'ins_'})` (and the same for the
  throttler) — every key is namespaced. Infra provides one Redis and injects no prefix. A
  future app that does not self-prefix would collide; that's an app bug, not infra's.
- **PG contract = discrete `DB_*` vars** (`DB_HOST/DB_PORT/DB_NAME/DB_USERNAME/DB_PASSWORD`) via
  `@infinavn/common` `PGConfig`; `DATABASE_URL` additionally for Makefile/typeorm CLI. The app
  further isolates inside its DB via schema `ins` + table prefix `ins_`. Zero app code change.
- **One PG version for all.** A future project needing a different major forces a second
  instance at that point.
- **Single point of failure / shared blast radius** for all local dev; a bad migration or a
  PII `rehearse` dump lands in the shared server (own DB, shared host).
- Retires multica's deferred `docker/backend-worktree.compose.yml` (its per-worktree isolation
  intent is generalized here, or revisited via the per-worktree-key escape hatch).

## Open
- Migrate the repo's `setup-local`/`make` flow to consume `infractl env` output (point at the
  shared infra) instead of `docker compose -p app-local up`. Config-only; via ticket/PR (#8).
