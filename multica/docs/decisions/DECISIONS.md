# Locked Decisions

> Squad-design decision log (the blueprint's rationale). Grounded in the **`aaa`** first instance —
> entries cite aaa repos/squad (`infina-insurance-dev`) as the worked example; the decisions
> themselves generalize to any project. Append-only; supersede with a dated note rather than rewriting.

| # | Decision | Rationale | Date |
|---|---|---|---|
| 1 | **One Multica project, both repos, one squad** | Features cross FE↔BE; Lead needs full-stack visibility to slice | 06-19 |
| 2 | **Lean 5 team** (Lead, Builder, Reviewer, QA, Research) | Cheapest to grasp; grow into Quang's specialist model later | 06-19 |
| 3 | **Runtimes**: Lead+Builder=Claude, Reviewer=OpenCode Go (Qwen 3.7 Max), QA=Codex (GPT-5.x), Research=Gemini | One model per concern by strength; review off Plus to free QA's quota | 06-20 |
| 4 | **Hybrid orchestration** — Lead plans/gates, execution flows kanban-pull | Lead not a per-PR bottleneck; saves Claude quota | 06-20 |
| 5 | **3-layer governance** — squad constitution → role prompt → runtime config | DRY: shared rules written once | 06-20 |
| 6 | **Jira = source of truth**; `SHP-####` drives branch/PR/Multica-issue; Atlassian MCP → Lead | No double-tracker; humans live in Jira | 06-20 |
| 7 | **Release-train git flow** — `feat/*` from `release-<slug>` → train → `release` (QA) → `master` (prod) | Bundles features shipping together; trains promote independently | 06-20 |
| 8 | **3 human gates**: design approval · merge→`release` · merge→`master`. Agents never merge to release/master | Humans own product intent + prod; agents own execution | 06-20 |
| 9 | **Mostly-bundled + hotfix exception**; `hotfix/*`→`master` for urgent prod | Trains for normal work; fast path for emergencies | 06-20 |
| 10 | **Versioning**: single synced tag `vX.Y.Z` across BE/web/mobile; **async deploy**; BE backward-compat with previous mobile | Mobile can't deploy in lockstep (app-store lag) | 06-20 |
| 11 | **Secrets: USE vs EXPOSE** — agents run env-consuming cmds, never print/commit values; human provisions NON-PROD env via injector (dotenvx/doppler/op) | Unblocks QA/debug without leak path; PII-safe | 06-20 |
| 12 | **Concurrency**: worktrees; FE parallel, **backend serialized** (shared local DB/ports); Lead1/Builder2-3/Reviewer2/QA1/Research1 | Local infra contention caps backend parallelism | 06-20 |
| 13 | **Mobile QA = local Maestro, green pre-merge**; EAS build fires downstream of merge | No EAS spend on un-QA'd code | 06-20 |
| 14 | **Docker: don't duplicate repo infra**; orchestrate via scripts; deferred backend-worktree isolation | Repos own their compose; avoid two sources of truth | 06-20 |
| 15 | **Worktree memory grain = per-repo** (agentmemory default). Worktrees resolve via `git --git-common-dir` to the real repo (`infina-insurance-partner-webapp`/`-services`), NOT the `wt/SHP-####` codename. No `AGENTMEMORY_PROJECT_NAME` override in `new-worktree.sh`. | Aligns with `agent-memory` ADR-0003; unified repo history, no per-ticket fragmentation. Only RS-Lead/Builder (Claude Code) are captured — Reviewer/QA/Research runtimes aren't, and capture requires agents on *this host* (gated by cloud-vs-self-host). | 06-21 |
| 16 | **Centralized local infra at `~/Work/setup/infra`** — one shared PG + Redis on standard ports (5432/6379), **logical** isolation (dedicated DB per project; each app namespaces its own Redis keys). **Supersedes #14.** Per-project grain → **#12 backend-serialization stands** (worktrees share the project DB). Retires `docker/backend-worktree.compose.yml`. Integration is **config-only, zero app code**: app reads discrete `DB_*` vars (via `@infinavn/common`), already self-prefixes Redis (`ins_`) + uses PG schema `ins`. Remaining: point repo `setup-local`/`make` at injected env (via ticket/PR, #8). | One host, multiple squads/projects; per-worktree containers too expensive. Cheap (2 containers); DB-per-project PG-enforced; app already shared-Redis-safe. See `infra/docs/decisions/0001-*` + `projects/aaa/integration.md`. | 06-21 |

| 17 | **Cross-runtime memory via one stdio MCP shim** (`agent-memory/mcp/agentmemory-mcp.mjs`) over REST :3111, tools `memory_search`+`memory_save`. Wired into Claude/Codex/OpenCode/gemini. Hybrid capture: Claude auto-captures via hooks (search only); non-Claude `memory_save` explicitly. Replaces the plugin's broken default Claude entry (`agentmemory-mcp` bin absent + `host.docker.internal` URL unreachable from host). | All 5 agents share one memory + one tool vocabulary; non-Claude runtimes had zero memory access before. KISS — thin client, no new service. See `plans/260621-1028-fill-memory-gap-nonclaude-runtimes/`. | 06-21 |

| 18 | **RS-Builder = Opus (`claude-opus-4-8`) with Sonnet fallback.** Supersedes #3's Builder=Sonnet. Auto-drop to Sonnet under Max weekly-cap pressure; if it walls, give Builder its own Max login (+$100). | User pref — quality per task over cap thrift; fallback keeps throughput. | 06-21 |
| 19 | **QA moves left — local QA green PRE-PR-to-train.** E2E (web/backend/mobile) runs in the worktree against shared infra and must be green before `feat→release-<slug>` opens. Supersedes the §5 post-staging-QA-first flow; post-staging is integration smoke only. | Local infra makes pre-merge E2E cheap; train only ever holds QA-passed code. | 06-21 |
| 20 | **Brief intake = MCP-pulled + local drop folder.** Jira (entry) + Figma MCP (design) + Confluence (partner docs); ad-hoc local files in `~/Work/infina-ai/<proj>/.squad/inbox/SHP-####/`. Lead cites the brief path + links in each sub-issue spec. | Covers both system-of-record resources and ad-hoc local mocks without double-entry. | 06-21 |
| 21 | **Worktree env auto-wired to shared infra in `new-worktree.sh`.** Backend worktree → `infractl up`+`db-create`+`env --write` (.env.infra: dedicated DB + Redis prefix); FE → local BE API URL. Secrets via injector at run time. Retires `start-local-stack.sh`'s old `yarn setup-local` (clashed on 5432/6379). | Closes the gap between worktree creation and a runnable env; one command to start work. | 06-21 |

| 22 | **RS-Lead is the sole funnel into a train + QA is green-per-feat.** Builders push the feat branch only; **only RS-Lead opens & merges the `feat→release-<slug>` PR**, after QA-green-per-feat + Reviewer-approved + checks green (lightweight train-entry gate). QA validates each feat individually in its worktree pre-merge — never the integrated train; post-staging stays integration-smoke. Refines #19 and the §6 git constitution (Builder no longer opens/merges the train PR). | Single funnel keeps each train coherent + tightens the no-merge surface; per-feat QA means the train only ever holds independently-green features. Trade-off: Lead re-touches each feature — kept lightweight (verify 3 greens, not re-review). | 06-21 |

| 23 | **RS-Research migrates from Gemini CLI → Antigravity CLI (`agy`).** Google deprecated the standalone Gemini CLI / Gemini Code Assist for individuals (sign-in disabled; migration deadline 2026-06-18). `agy` (install `curl -fsSL https://antigravity.google/cli/install.sh \| bash`, binary `~/.local/bin/agy`) is the replacement — Google-account OAuth (or `ANTIGRAVITY_API_KEY` for headless), exposes Gemini 3.1 Pro/3.5 Flash (+ Claude/GPT-OSS). Supersedes #3's `Research=Gemini`. **Open:** verify Multica supports `agy` as a runtime; if not, fall back to OpenCode pointed at the local CLIProxyAPI (:8317, Antigravity-backed). The memory shim wiring (#17) must also move from the dead `gemini` CLI to `agy`. | Forced migration — old client rejected at sign-in. Antigravity OAuth already on-host (backs the memory proxy), so auth reuse is clean. | 06-21 |

## Confirmations / reaffirmations
- **2026-06-21 — per-worktree DB explicitly NOT adopted.** Reviewed (self-review report) as the top
  throughput unlock; owner decided to **keep the shared per-project DB**: FE worktrees run
  concurrent, backend worktrees run **one-at-a-time (serial)** to avoid migration/seed conflict.
  #12/#16 stand. Revisit only if backend throughput becomes the bottleneck.

## Interim risks (tracked)
- **No bot GitHub account** → agents run under owner's personal account; merge-block enforced by branch protection ("include administrators"), not token. Provision bot in Phase 0.

## Deferred / open
- Author 5 custom skills (root-cause-first, safe-refactor, inf-api-contract, inf-e2e-mobile-maestro, builder-dev-loop).
- Multica **cloud vs self-host** (affects `docker/multica/`).
- Confirm model IDs, staging URLs, secret-injector choice.
