# Self-Review — `~/Work/setup` end-to-end (multica · agent-memory · infra), aaa as worked example

Date: 2026-06-21 10:18 · Reviewer: Claude (self-review) · Scope: all three pillars + their live state, using the `aaa` repos (`infina-insurance-partner-{services,webapp}`) as the E2E example.

## Verdict — E2E readiness

| Pillar | State | Can run E2E today? |
|---|---|---|
| **infra** (shared PG+Redis) | **LIVE, healthy, verified** | ✅ Yes — aaa DB created, integration is genuinely config-only |
| **agent-memory** (capture/recall) | **LIVE, healthy** | ✅ Yes — but only for the 2 Claude-Code agents (see F4) |
| **multica** (5-agent squad) | **DESIGN-COMPLETE, NOT PROVISIONED** | ❌ No — squad not created; 4 hard blockers open |

**Bottom line:** infra + memory are real and working. The multi-agent squad is a paper design — no Multica project, no agents, 5 skills unwritten, no bot account. So "full end-to-end agent work" **cannot run yet**. The plumbing a squad would *use* is ready; the squad itself is not.

## Live state (verified this session)

- `dev-infra-postgres-1` (pgvector/pg18) + `dev-infra-redis-1` — both **healthy**, 25 min uptime, bound 127.0.0.1:5432/6379.
- DB `infina_insurance_partner_services` **exists** (`infractl status`).
- `agentmemory` container up; :3111 REST + :3113 dashboard listening; `CLIProxyAPI :8317` → **200** (LLM enrichment backend alive).
- aaa repos present: `infina-insurance-partner-services`, `-webapp`, `oneclaw`.
- aaa "config-only" claim **validated against real code**: `new Redis(url, { keyPrefix: REDIS_KEY_PREFIX })` in `app.module.ts:40` + `storage.module.ts:22` → already shared-Redis-safe. (PGConfig DB_* read lives in `@infinavn/common`, per doc.)
- gitignore hygiene **clean**: captured memory data + all `.env*` ignored, nothing sensitive tracked.

## aaa end-to-end walkthrough — where it works, where it stops

1. `infractl up` → shared PG+Redis. ✅ works
2. `infractl db-create infina-insurance-partner-services` → dedicated DB. ✅ works (verified live)
3. `infractl env … >> .env.local` → inject connection contract. ✅ works (caveat F2)
4. `make migrate` → schema `ins`, pgvector extension. ✅ (repo-side, untested here)
5. **Squad picks up a `SHP-####` from Jira → Builder cuts `feat/…` from train → PR → Reviewer → QA → human gates.** ❌ **stops here** — squad doesn't exist yet.

So pillars 1–4 (the infra runway) are ready end-to-end; step 5 (the actual agent loop) is unbuilt.

## Findings (severity-ordered)

### Blockers to "full E2E" (multica, all known/tracked — confirming, not discovering)
- **B1. Squad not provisioned.** No Multica project/agents created. README status + DECISIONS "Deferred" confirm.
- **B2. 5 custom skills unwritten.** Only `skills/README.md` stub exists; `root-cause-first`, `safe-refactor`, `inf-api-contract`, `inf-e2e-mobile-maestro`, `builder-dev-loop` are specs, not `SKILL.md`s. Builder/Reviewer/QA cards reference them.
- **B3. No bot GitHub account.** Agents would run under owner's personal token → the only merge-block is branch protection w/ "include administrators". **Not verified that this protection is actually configured on the GitHub repos** — if it isn't, there is *no* safety net. Verify on GitHub before any dry-run.
- **B4. Unconfirmed prerequisites:** model IDs (Qwen/GPT-5.x), staging URLs, secret-injector choice (dotenvx/doppler/op), Multica cloud-vs-self-host.

### High — affects real throughput / coverage
- **F4. Memory covers only 2 of 5 agents.** Capture is Claude-Code-hook-based → only RS-Lead/Builder are captured (DECISIONS #15 admits this). But the **constitution tells *all* agents** to `memory_smart_search`/`memory_save`. Reviewer (OpenCode), QA (Codex), Research (Gemini) have no capture and likely no MCP wiring to :3111. → constitution instruction ≠ reality for 60% of the squad. Either wire agentmemory as an MCP tool for those runtimes, or scope the constitution's Memory section to Claude-Code agents only.
- **F5. Backend serialization is the central throughput cap.** By design (#12/#16) all backend worktrees share one DB → backend work is **strictly serial** despite Builder concurrency 2–3. For a backend-heavy insurance product this is the main limiter on parallel E2E. The documented "free" fix (per-worktree DB key, e.g. `…-SHP-1234`) is **not implemented**. Implementing it in `infractl` + `new-worktree.sh` is the highest-leverage unlock.
- **F6. Single-Mac SPOF.** infra + memory + CLIProxyAPI + agent daemons all on one Mac; sleep kills the squad (caffeinate is the only mitigation). Memory store is one bind-mount with **manual** backup only — no scheduled backup for accumulating lessons.

### Medium — doc/config drift (cheap fixes)
- **F1. `infra/README.md` self-contradicts on ports.** Layout line says compose is "ports **55432 / 56379**"; every other line (quick-start, ports table) + `compose/infra.yml` + `infractl` say **5432/6379**. The 55432/56379 string is stale — **fix it** (misleads anyone reading the layout section).
- **F2. Two env-injection mechanisms, unclear which the app loads.** `infractl env --write` writes **`.env.infra`**; aaa-integration.md step 3 instead **appends to `.env.local`**. The app reads `.env.local` (not `.env.infra`), so `--write` alone wouldn't take effect, and the append form **duplicates vars if run twice** (no idempotency). Pick one path; if keeping append, dedupe or document "run once".
- **F3. `aaa` naming is overloaded in the worked example.** aaa-integration.md lines 11/51 imply the DB is `aaa`; the real derived name is `infina_insurance_partner_services` (`aaa` is just the parent folder). Confusing — tighten wording.
- **F7. Plaintext proxy token in a doc.** `agent-memory/docs/runbook.md:57` hardcodes `Bearer sk-cliproxy-bmad-2026`. Low sensitivity (local proxy) but it contradicts the constitution's "never paste secret values" posture — replace with a `$TOKEN` placeholder.

## Per-pillar scorecard

- **infra — 9/10.** Clean, minimal, KISS, validated against real app code, live & healthy. Loses a point only for F1/F2 doc drift. The serialization cap (F5) is a known, accepted v1 trade-off with a documented exit.
- **agent-memory — 7/10.** Solid single-container design, running, good ADRs/runbook, clean gitignore. Gaps: partial-squad coverage (F4), SPOF + manual backup (F6), token-in-doc (F7).
- **multica — design 9/10, execution 0/10.** Genuinely excellent design (grounded in real repos, DRY 3-layer governance, sane git flow, honest risk register). But it's entirely unbuilt (B1–B4). Best-documented, least-real pillar.

## Recommended next actions (highest leverage first)
1. **Verify GitHub branch protection** on both repos incl. "include administrators" (B3) — this is the load-bearing safety net; cheap to check, catastrophic if missing.
2. **Implement per-worktree DB keying** in `infractl`/`new-worktree.sh` (F5) — unblocks parallel backend at zero container cost; the single biggest throughput win.
3. **Reconcile the Memory constitution section with capture reality** (F4) — decide MCP-wire-all vs scope-to-Claude, before agents are told to call tools they don't have.
4. **Fix the cheap doc drifts** F1/F2/F3/F7 (minutes each).
5. Then proceed with the multica provisioning sequence (B1/B2) and the one-`SHP-####` dry-run.

## Unresolved questions
1. Is branch protection ("include administrators") actually configured on the two GitHub repos? (B3 — assumed, not verified.)
2. Is agentmemory exposed as an **MCP tool** (`memory_smart_search`/`memory_save`) to OpenCode/Codex/Gemini, or only as Claude-Code hooks? (F4.)
3. Does the aaa app load `.env.infra` at all, or only `.env.local`? (F2 — determines whether `infractl env --write` is even functional for this repo.)
4. Multica cloud vs self-host — still open; gates whether non-host runtimes (Reviewer/QA/Research) can even run captured on this Mac.
