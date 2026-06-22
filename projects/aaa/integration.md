# Worked example — wiring the `aaa` repo to shared infra

Target: `infina-insurance-partner-services` (NX monorepo; app `apps/insurtech-service`) at
`~/Work/infina-ai/aaa/infina-insurance-partner-services`. **Config-only — no app code change.**

## What the app already does (why no code change)
- **Postgres** — `@infinavn/common` `PGConfig` reads `DB_HOST / DB_PORT / DB_NAME / DB_USERNAME
  / DB_PASSWORD`. `data-source.ts` (typeorm CLI) + Makefile dump/restore use `DATABASE_URL`.
  Inside the DB the app uses schema **`ins`** + table prefix **`ins_`** (`constant.ts`).
- **Redis** — `storage.module.ts` and `app.module.ts` both do
  `new Redis(url, { keyPrefix: 'ins_' })`. Already safe on a shared Redis.
- Default creds (`dev`/`dev`) match the infra stack; only `DB_NAME` differs (repo default → the
  dedicated `infina_insurance_partner_services`, derived by infractl from the project key). NB:
  `aaa` is just the parent folder holding both repos, not a database name.

## Steps
```bash
# 1. shared infra up (once; standard ports 5432/6379)
cd ~/Work/setup/infra && ./infractl up

# 2. dedicated DB for this project
./infractl db-create infina-insurance-partner-services        # -> db infina_insurance_partner_services

# 3. inject the connection contract into the repo's .env (local stage — the plain, gitignored file the app reads)
#    Run ONCE — `>>` appends, so re-running duplicates the vars. To refresh, delete the old
#    infra block first, or use `--write` to drop a standalone .env.infra and merge it by hand.
#    (In a worktree, wire-env writes .env.infra separately — this step is for the root checkout.)
./infractl env infina-insurance-partner-services >> \
  ~/Work/infina-ai/aaa/infina-insurance-partner-services/.env

# 4. run migrations against it (from the repo)
cd ~/Work/infina-ai/aaa/infina-insurance-partner-services
make migrate          # or: yarn migration-run   (CREATE EXTENSION vector runs here)

# 5. start the app — it now talks to shared infra
```
**Stop running** the repo's own `yarn setup-local` (`docker compose -p app-local`) — it would
clash on 5432/6379 with the shared stack.

## Injected vars (`infractl env infina-insurance-partner-services`)
```
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=infina_insurance_partner_services
DB_USERNAME=dev
DB_PASSWORD=dev
DATABASE_URL=postgresql://dev:dev@127.0.0.1:5432/infina_insurance_partner_services
REDIS_URL=redis://127.0.0.1:6379
```

## Worktrees & concurrency
All worktrees of this repo share the one DB + schema `ins` + Redis `ins_` → **backend stays
serialized** (multica #12). To run backend worktrees in parallel later: key per-worktree
(`infina-insurance-partner-services-SHP-1234`) so each gets its own DB — free (no new
container), costs a `make migrate` per worktree DB.

## `make rehearse` (PII)
`rehearse` (dump staging → restore local → migrate → backfill → verify) lands the dump in this
**shared** Postgres. Same PII rules as the constitution: local only, never export rows. The
dedicated DB keeps it in one database, but the server is shared on this host.

## Governance
This wiring belongs in the product repo and goes via ticket/PR (multica #8 — agents never
push to `release`/`master`). The infra side (this repo) is done; the repo side is a config
change for RS-Builder to land.
