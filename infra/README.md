# infra — shared local dev infrastructure

One **Postgres** + one **Redis** container for *all* projects and worktrees on this host.
No per-repo, no per-worktree duplication. Isolation is **logical**:

- **Postgres** — a dedicated **database** per project (Postgres enforces it).
- **Redis** — a per-project **key prefix** (the app must apply it; Redis does not enforce).

This replaces per-repo local stacks as the source of truth for *running* infra; each repo
declares what it needs via `projects/<slug>/infra-profile.yaml`. See [docs/design](docs/design/highlevel-design.md)
and [ADR 0001](docs/decisions/0001-shared-instance-logical-isolation.md).

## Quick start
```bash
cd ~/Work/setup/infra
./infractl up                                   # start shared PG + Redis (standard ports)
./infractl db-create <project-key>              # key from projects/<slug>/project.yml infra.key
./infractl env <project-key> --write /path/to/worktree
# -> writes .env.infra (DB_HOST/PORT/NAME/USERNAME/PASSWORD + DATABASE_URL + REDIS_URL)
```
Worked example (`aaa` instance): [../projects/aaa/integration.md](../projects/aaa/integration.md).
The squad scripts call this for you — see `../multica/scripts/`.

## Layout
```
infractl                 CLI: up · down · wipe · status · db-create · env · psql
compose/infra.yml        the single pg + redis stack (ports 5432 / 6379, 127.0.0.1 only)
docs/design/             architecture + how consumers integrate
# (per-project version/db/prefix contract lives in projects/<slug>/infra-profile.yaml)
docs/decisions/          ADRs (why shared-instance + logical isolation)
```

## Ports (standard — dev-infra is now THE local stack)
| Service | Host | In container |
|---|---|---|
| Postgres | 127.0.0.1:5432 | 5432 |
| Redis | 127.0.0.1:6379 | 6379 |

Repos' own `docker-compose.local.yml` are retired — don't run them alongside this (they'd
clash on 5432/6379).

## Known constraints (read before relying on it)
- **Backend stays serialized.** Per-project DB → worktrees of one repo share it; parallel
  backend tasks clobber migrations/seed. Flip to per-worktree keys later (free) to unblock.
- **Redis isolation is the app's job, not infra's.** Infra provides one Redis; each app must
  namespace its own keys. `insurtech-service` already does (`new Redis(url, {keyPrefix:'ins_'})`).
  A future app that does NOT self-prefix would collide — that's on the app.
- **One PG version for everyone** (`pgvector/pgvector:pg18`). A project needing a different
  major forces a second instance at that point.
- **Single point of failure** for all local dev; a bad migration / PII `rehearse` dump lands
  in the shared server (own DB, shared host).

## Not built yet (extend here)
- `compose/localstack.yml` — AWS emulation (no consumer today).
- `compose/observability.yml` — the one genuinely-shared singleton (Grafana/Jaeger).
