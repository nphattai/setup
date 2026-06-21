# Env Model & Execution Flow — squad ⇄ infra ⇄ worktree (blueprint)

> How a task flows from human intake to QA-green, and exactly how each agent gets a
> runnable, correct env. **Generic blueprint** — concrete identifiers are the **`aaa`** first
> instance (`../../../projects/aaa/`); read `<repo-*>`/`<fe-apps>`/`<be-app>` as a project's
> values from `projects/<slug>/project.yml`. Manifest (aaa): `../../../projects/aaa/project.yml`.

## 0. Hierarchy (high → detail)

```mermaid
flowchart TD
    HOST["<b>HOST</b> — one Mac<br/>shared infra: 1 PG + 1 Redis (infractl)"]
    PROJ["<b>PROJECT</b> — projects/&lt;slug&gt;/project.yml<br/><small>SoR: repos · infra · env manifest · squad</small>"]
    SQUAD["<b>SQUAD</b> — 5 agents"]
    WT["<b>WORKTREE</b> per task<br/>feat branch + COMPOSED env"]
    HOST --> PROJ --> SQUAD --> WT
```

Many projects sit on one infra; each project = dedicated DB + Redis prefix + one squad.

## 1. Intake — human-driven, NO auto-pull (concern #1)
- **You** create the Multica issue, assign RS-Lead, write the requirement + AC inline. Atlassian MCP is demoted to *optional status push-back*; agents do not auto-pull Jira.
- **File resources** (mockups, partner PDFs, exported HTML) → drop in
  `~/Work/infina-ai/<proj>/.squad/inbox/<ISSUE-KEY>/`. You cite that path in the issue.
  Lead reads from disk. Figma/Confluence = paste a link (Lead pulls via MCP only if needed).
- Lead → PRD/design → **GATE 1 (human approves)** → slices sub-issues (each cites AC + train + inbox path).

## 2. Infra is human-owned; the manifest captures everything (concern #2)
- **You provision** infra once per project (driven by the manifest):
  `infractl up` · `infractl db-create <key>`. **Agents NEVER create/drop DBs.**
- `projects/<slug>/project.yml` is the single source of truth: repos+path, infra (db/redis/schema/image),
  the **env manifest** (every var → `infra|config|secret`), squad, trains, inbox path.
- `new-worktree.sh` no longer creates DBs — it only *emits* infra vars (assumes DB exists; if not → error "ask human to provision"). The infra-only profile now lives at `projects/<slug>/infra-profile.yaml`.

## 3. The env model (concern #3) — three sources, composed per worktree
A service's runtime env is **composed at run time** from three sources; never one big secret file:

| Source | Examples | Provided by | In a file? | Secret? |
|---|---|---|---|---|
| **infra** | `DB_*`, `DATABASE_URL`, `REDIS_URL` | `infractl env` → `.env.infra` | yes | no (host-local) |
| **config** | `USER_API_URL`, flags, ports, public keys | committed `.env.development`/`.example` | yes | no |
| **secret** | `OPENAI_API_KEY`, `JWT_SECRET`, Twilio | **dotenvx** (`dotenvx run -- …`) | encrypted only | yes |

```mermaid
flowchart LR
    subgraph SRC["3 sources — composed at run time"]
        direction TB
        I["<b>infra</b><br/>DB_* · DATABASE_URL · REDIS_URL<br/><small>infractl env → .env.infra</small>"]
        C["<b>config</b><br/>API URLs · flags · ports · public keys<br/><small>committed .env.development/.example</small>"]
        S["<b>secret</b><br/>OPENAI_API_KEY · JWT_SECRET · Twilio<br/><small>dotenvx (encrypted only)</small>"]
    end
    GATE{"<b>wire-env</b> HARD GATE<br/>validate every required var vs<br/>the repo's .env.example contract"}
    OK["✅ ready<br/>dotenvx run -f .env.&lt;stage&gt; -- &lt;app cmd&gt;"]
    BLOCK["❌ BLOCK — list missing names,<br/>@mention human · never invent a value"]
    I --> GATE
    C --> GATE
    S --> GATE
    GATE -- "all present" --> OK
    GATE -- "any missing" --> BLOCK

    classDef secret fill:#ffebee,stroke:#c62828,color:#b71c1c;
    class S secret;
```

**`.env.example` is the CONTRACT.** Each repo commits `.env.example` listing every var it needs
(grouped `# infra / # config / # secret`). The env is multi-level: e.g. webapp has a root
`.env.example` *plus* per-app `apps/nomi/.env`, `apps/admin/.env`.

**Injector = dotenvx** (AWS hosts aaa staging/prod; Railway not in play). **Stages: `local` and
`staging`** (`.env.local`, `.env.staging`). Worktree-portable by design: the **encrypted**
`.env.<stage>` is committed (safe in git) so it travels into every fresh worktree automatically;
only `.env.keys` (the decrypt key, gitignored, host-only) is wired in per worktree. Human
maintains the VALUES per stage; agents run `dotenvx run -f .env.<stage> -- <cmd>` — **USE, never
EXPOSE**: never decrypt to inspect, never print/commit a value. *(Threat note: on one host the
agent technically can read what it runs — protection is policy + NON-PROD-only values, not hard
isolation.)*

**`.env.staging` guardrail.** The `staging` stage exists ONLY to reproduce bugs against real
staging data on AWS. It is **read/repro-only**: never run destructive ops, migrations, or seeds
against staging; never export/paste rows (PII rules, same as `make rehearse`); `.env.prod` is
**off-limits to agents entirely**. Default stage is `local`.

**Contracts already exist — point, don't recreate.** Both repos ship the contract + stage files:
webapp `apps/{nomi,admin,nomi-mobile}/.env.example` (+ workspace-root `.env.example`); services
`apps/insurtech-service/.env.sample` (+ `.env.local`/`.env.staging`/`.env.prod`). We do NOT rename
`.env.sample` → `.env.example`: it's whitelisted in `.dockerignore`/`.railwayignore`, referenced
across docs/plans, and the repo sits on the shared `release` branch. The gate is **name-agnostic**
— it reads the `contract:` path from `projects/<slug>/project.yml`.

**The HARD GATE (user):** before an agent works, `wire-env` validates the composed env against
the repo's `.env.example` — **every required var must resolve to a correct per-stage value**, or
it BLOCKS and reports the missing names. The agent never invents or fetches a value.

### Secrets that must be USED in tests (e.g. OpenAI chat)
- **Web (nomi `/api/copilotkit`, NestJS BE):** `OPENAI_API_KEY` is server-side → injected by
  `dotenvx run` at runtime → chat-AI E2E works, value never exposed.
- **React Native (nomi-mobile):** holds **no key** — AI calls route through the **local BE (:3333)**
  which has the key. RN worktree needs only the BE URL (config). Correct prod architecture; removes
  on-device key handling. *(A genuine on-device call would be a flagged sandbox-key exception.)*

## 4. `wire-env` — the worktree bootstrap (spec)
Run by/after `new-worktree.sh <project> <app> <KEY> <slug> <train> [stage]` (project=slug e.g. `aaa`; app from the manifest; stage defaults to `local`):
1. `infractl env <proj> --write <wt>` → `.env.infra` (infra source). Errors if DB not provisioned.
2. Wire secret material into the worktree: `wire-env` **symlinks both the encrypted `.env.<stage>` and its `.env.keys`** from the source checkout (`APP_REPO_DIR`). Teams gitignore `.env.*`, so these are untracked and do NOT travel with a fresh `git worktree` checkout — linking from one source keeps a single copy and propagates key rotations.
3. **VALIDATE (the hard gate)**: read the surface's `contract:` from `projects/<slug>/project.yml` (name-agnostic — `.env.example` or `.env.sample`); for each key confirm it resolves from infra ∪ config-default ∪ dotenvx for the stage. All required present → ✅ ready. Any missing → ❌ BLOCK, list names, @mention human. Never invent a value.
4. Print the run prefix: `dotenvx run -f .env.<stage> -- <app cmd>` (FE `nx dev <app>` · BE `yarn start` → :3333). Mobile needs no secret — `EXPO_PUBLIC_API_ORIGIN` → local nomi web (:3000).

## 5. Full flow — task → QA-green → report

```mermaid
sequenceDiagram
    autonumber
    actor H as Human
    participant L as RS-Lead
    participant B as RS-Builder
    participant Q as RS-QA
    participant R as RS-Reviewer
    H->>L: create issue + drop resources in .squad/inbox/<KEY>/
    L->>L: read issue + inbox → PRD/design
    H-->>L: GATE 1 — approve design
    L->>B: slice sub-issues (AC + train + inbox path)
    B->>B: new-worktree + wire-env (validate vs .env.example; BLOCK if incomplete)
    B->>B: dotenvx run -- … → implement 1 AC at a time → unit green
    B->>Q: push feat branch (no PR) → In-Review
    Q->>Q: per-feat E2E vs shared infra
    alt bug found
        Q-->>B: back to Builder
    else green per feat
        Q->>R: hand off
        R->>L: static diff review → approve
        L->>L: verify 3 greens → open + merge feat → release-<slug>
        L-->>H: GATE 2/3 — release→staging→master→tag
    end
```

1. Human: create issue + drop resources in `.squad/inbox/<KEY>/` → assign Lead.
2. Lead: read issue + inbox → PRD/design → **GATE 1** → slice sub-issues (AC + train + inbox path).
3. Builder: `new-worktree.sh …` → feat branch + `yarn install` + **wire-env** (`.env.infra` + validate vs `.env.example`; BLOCK if incomplete).
4. Builder: run app via `dotenvx run -- …` (secrets injected, unseen) → implement one AC at a time → unit green.
5. Builder: push feat branch → In-Review → @Lead (no PR).
6. QA: per-feat, in the worktree, `dotenvx run -- …` E2E — web → local BE (keys present); RN → local BE → green per feat. Bug → back to Builder.
7. Reviewer: static diff review → approve.
8. **Lead** (sole funnel): verify 3 greens (QA-per-feat · Reviewer · checks) → open + merge `feat → release-<slug>`.
9. **GATE 2/3 (human):** release-<slug> → release → staging (AWS) → master → tag.

## 6. Script implementation (DONE — generic, manifest-driven)
- `new-worktree.sh <project> <app> …` + `wire-env.sh <project> <app> <wt> [stage]`: no `db-create` (human owns DBs); `wire-env` is the validate gate (reads the `contract:`, fails closed on missing vars), prints the `dotenvx run` prefix. All facts resolve from the manifest via `scripts/project-meta` — no hardcoded project.
- Cards (rendered in `projects/<slug>/squad/`) + constitution template: `dotenvx run -f .env.<stage> --` prefix + the completeness hard gate.
- The infra profile moved to `projects/<slug>/infra-profile.yaml` (the old `infra/profiles/*.yaml` is superseded by the consolidated `project.yml`).

## Resolved (2026-06-21)
1. **Contracts already exist** — services `apps/insurtech-service/.env.sample`, webapp per-app `.env.example`. No new file authored; gate reads `contract:` from the manifest (name-agnostic). Renaming `.env.sample` is unsafe (dockerignore/railwayignore/docs + `release` branch).
2. **Stages = `local` + `staging`** (`.env.staging` for real-staging bug repro, read-only + PII rules; `.env.prod` off-limits to agents).
3. **Mobile→BE confirmed in code**: `apps/nomi-mobile/src/config.ts` → `COPILOT_URL = ${API_ORIGIN}/api/copilotkit`; no `OPENAI_API_KEY` on device. `.env.example` is `EXPO_PUBLIC_*` only (non-secret by design).

## Remaining (project owner, one-time per repo)
- Adopt dotenvx (encrypt `.env.local`/`.env.staging`, keep `.env.keys` gitignored on host). Until then, wire-env's plain-file fallback still validates.
- Verify `apps/admin/.env.example` secret set; reflect any required secret into the manifest `secrets.required_local`.
