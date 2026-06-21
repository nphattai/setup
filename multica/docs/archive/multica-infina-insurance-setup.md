# Multica Setup — Infina Insurance Partner (insurtech)

> Project-specific, paste-ready setup. Pairs with `multica-working-model-design.md` (general model). Created 2026-06-19.

## 1. Project & repos

**One project, both repos, one squad.** Features cross FE↔BE → Lead needs full-stack visibility to slice work.

- **Project:** `infina-insurance-partner` (or `insurtech`)
- **Repos (attach both):**
  - FE monorepo: `https://github.com/RealStake/infina-insurance-partner-webapp` → 3 surfaces: **user-web**, **admin-web**, **RN mobile app**
  - BE: `https://github.com/RealStake/infina-insurance-partner-services`
- **Squad:** `infina-insurance-dev`, leader = `RS-Lead`, members = the 5 agents + you (human, role: reviewer/merge gate)
- **Issue prefix:** `INF-*`

## 2. Final roster

| Agent | Role | Runtime | Model / auth | Repos | Standing? |
|---|---|---|---|---|---|
| `RS-Lead` | leader | **Claude Code** | Claude Max 5x sub | both | yes |
| `RS-Builder` | builder | **Claude Code** | Claude Max 5x sub (prefer Sonnet) | both | yes |
| `RS-Reviewer` | code-reviewer | **OpenCode CLI** | **OpenCode Go** ($10/mo) → Qwen 3.7 Max | both | yes |
| `RS-QA` | qa | **Codex** | ChatGPT Plus sub (GPT-5.x) | both | yes |
| `RS-Research` | research | **Gemini** | Google AI Ultra (shared w/ memory proxy) | both | on-demand (spikes) |

> **Why OpenCode CLI + OpenCode Go for review:** Go ($10/mo flat, https://opencode.ai/go) gives ~14 open coding models (Qwen 3.7 Max, GLM-5.2, Kimi K2.7 Code, DeepSeek V4 Pro…) with generous **request-based** 5-hr limits — so the reviewer is **off the ChatGPT Plus quota** (QA gets Plus to itself), price is flat/predictable, and Qwen 3.7 Max is the same model Quang trusted for review. Review is read-only/low-risk, so a lighter harness + open model is the right place to economize. Keep it a *separate* agent from QA: review is static (diff), QA is dynamic (run app).

## 3. QA surface map (this monorepo)

| Surface | Path (verify) | Tool | Host need |
|---|---|---|---|
| user-web | `webapp/apps/user-web` | Playwright | Node + browsers |
| admin-web | `webapp/apps/admin-web` | Playwright | Node + browsers |
| RN mobile | `webapp/apps/mobile` | **Maestro** | **macOS + Xcode iOS Sim + Android emulator** |
| backend | `infina-insurance-partner-services` | service test runner + repro | Docker + DB + env |

**Start: one `RS-QA` agent, 4 modes.** Split off `RS-QA-Mobile` only if the macOS/simulator path bottlenecks the others (Phase 2).

## 4. Workflow (full-stack feature)

```
Request → RS-Lead: PRD + tech design spanning FE+BE
            │
   ── HUMAN GATE 1: approve design ──
            │
            ▼  parent issue INF-N, sub-issues per repo/surface:
   INF-N.1 (BE api)  INF-N.2 (user-web)  INF-N.3 (admin-web)  INF-N.4 (mobile)
            │ each: RS-Builder → feature branch (per repo) → PR into feature branch
            ▼
   RS-Reviewer (Codex) reviews each PR ──fail──► back to RS-Builder
            │ pass
            ▼
   RS-QA (GPT-5.x) E2E per surface ──bug──► failing test + repro → RS-Builder
            │ pass
            ▼
   ── HUMAN GATE 2: you merge each repo's PR ──
            ▼
        Merge to main
```

Rules: agents **never self-merge**; **QA proves, Builder fixes**; one feature branch name shared across repos (e.g. `feat/INF-N-claims-flow`).

## 5. Paste-ready agent instructions

### RS-Lead (Claude)
```
You are RS-Lead for infina-insurance-partner (insurtech). Repos: infina-insurance-partner-webapp (user-web, admin-web, RN mobile) and infina-insurance-partner-services (backend).
Responsibilities: product intake → PRD → tech design spanning FE+BE → break into small sub-issues, one per repo/surface (label which surface). Run spec-conformance checks on completed work.
Two human gates you must honor: (1) design approval before any building, (2) human merges — never merge yourself.
Do NOT write production code; delegate implementation to RS-Builder. Keep sub-issues small and independently shippable. Flag cross-repo contract changes explicitly (BE API ↔ FE consumers).
```

### RS-Builder (Claude)
```
You are RS-Builder for infina-insurance-partner. Implement ONLY the sub-issue assigned. Determine the correct repo/surface from the issue.
Branching: use the shared feature branch feat/<ISSUE-KEY>-<slug> in the relevant repo. Open a PR INTO that feature branch. NEVER merge or delete branches; never push to main.
Match existing code conventions in each surface. For cross-repo work, keep BE API contract and FE consumer in sync and note it on the issue. Report blockers immediately rather than guessing.
```

### RS-Reviewer (OpenCode CLI → OpenCode Go, Qwen 3.7 Max)
```
You are RS-Reviewer for infina-insurance-partner. Review PR diffs only — do NOT edit code.
Lens: TypeScript type-correctness, API-contract coherence (BE↔FE), regressions, error handling, and adherence to the issue's spec. Cite concrete file:line. For cross-repo PRs, verify the FE consumer matches the BE contract.
Verdict: approve or request changes with a specific, actionable list. Be brutal and concise.
```

### RS-QA (Codex → ChatGPT Plus, GPT-5.x)
```
You are RS-QA for infina-insurance-partner. Spec-driven E2E. You PROVE bugs; you do NOT fix them.
Modes (pick by the surface under test):
- user-web / admin-web: Playwright E2E.
- mobile (RN): Maestro flows on iOS Simulator / Android emulator (macOS).
- backend: boot services (Docker), reproduce, read logs/stack traces.
On a bug: write a minimal failing test + exact repro steps, move the issue to Blocked, hand back to RS-Builder. On pass: confirm against the issue's acceptance criteria. Never edit production code.
```

### RS-Research (Gemini) — on-demand
```
You are RS-Research for infina-insurance-partner. Investigate spikes: library evaluation, API/SDK docs, insurance-domain regulations, architecture options. Output a concise findings report with sources and a recommendation. Do not modify code.
```

## 6. Skills to write first (compound across agents)

- `inf-branch-pr` — `feat/<ISSUE-KEY>-<slug>` convention, PR-into-feature-branch, no-merge-to-main guard.
- `inf-e2e-web` — Playwright run/report for user-web & admin-web.
- `inf-e2e-mobile` — Maestro flow run on sim/emulator.
- `inf-be-repro` — boot services + DB, reproduce, capture traces.
- `inf-api-contract` — checklist for keeping BE API ↔ FE consumers in sync.

## 7. Setup commands

```bash
brew install multica-ai/tap/multica
multica setup
# Install + auth the runtimes on this Mac:
#   claude   → login with Claude Max 5x          (RS-Lead, RS-Builder)
#   opencode → subscribe to OpenCode Go, then `opencode auth login` → pick Go
#              set model to Qwen 3.7 Max (or GLM-5.2 / DeepSeek V4 Pro)   (RS-Reviewer)
#   codex    → login with ChatGPT Plus           (RS-QA)
#   gemini   → Google AI Ultra                   (RS-Research)
# OpenCode Go: https://opencode.ai/go  ($5 first month, then $10/mo flat)
# QA host toolchain (this Mac):
npx playwright install
brew install maestro          # + Xcode iOS Simulator, Android Studio emulator
# Then in UI:
# 1. New project "infina-insurance-partner" → attach both GitHub repos
# 2. Create the 5 agents (runtime + model + role + instructions above)
# 3. New squad "infina-insurance-dev", leader RS-Lead, add agents + yourself
# 4. Assign first issue to RS-Lead
```

## 7b. Plan capacity & auth (the binding constraint)

In Multica each **runtime logs in once on the host; every agent on that runtime shares one account's quota.** Your spend ceiling on subscriptions is **rate-limit walls, not dollars** — Multica's "$" dashboard is an API-equivalent estimate. (Quang's 447M tokens/30d was only possible because he routed via cliproxy/API, not pure subs.)

| Runtime | Auth | Feeds | Headroom |
|---|---|---|---|
| Claude Code | Claude Max 5x ($100) | RS-Lead **+** RS-Builder (shared) | ⚠️ 2 agents share one account; two weekly caps (all-models + Sonnet). Prefer Sonnet for Builder, Opus sparingly for Lead. OK for bursty work; throttles if both run heavy all day. |
| OpenCode CLI | **OpenCode Go** ($10/mo flat) | RS-Reviewer | ✅ Off the other subs; flat price; **request-metered** 5-hr windows (generous); Qwen 3.7 Max is Quang-validated for review. |
| Codex | ChatGPT Plus ($20) | RS-QA only | ⚠️ Plus Codex is token-metered (since Apr 2026) w/ 5-hr + weekly caps. Now that review moved to OpenCode Go, QA has Plus to itself. If heavy E2E still throttles → point RS-QA at OpenCode Go too (cheap overflow). |
| Gemini | Google AI Ultra | RS-Research (on-demand) + memory proxy | ✅ Keep research non-standing so it doesn't starve the memory proxy. |

**Rules of thumb:**
- Don't stack two heavy agents on one subscription login.
- OpenCode Go ($10/mo) is the cheap overflow valve: if Plus (QA) or even Claude Max (Builder) wall out, OpenCode Go's open models (Qwen 3.7 Max, GLM-5.2, DeepSeek V4 Pro) can absorb load via the OpenCode CLI runtime.
- Open models are a notch below GPT-5.x/Claude on hard reasoning — fine for review/overflow, keep design+build on Claude.
- For 24/7 Quang-scale throughput, layer OpenCode Go + API keys under everything except the Claude pair.

## 8. First issue template (assign to RS-Lead)

```
Title: [PRD] <feature name>
Body:
Goal: <one line>
Surfaces affected: user-web / admin-web / mobile / backend
Acceptance criteria: <bullets>
Constraints: <auth, compliance, data>
Deliverable: PRD + tech design + sub-issues per surface. Stop at human gate 1 for my approval before building.
```

## Open questions
1. **FE monorepo paths** — confirm actual app dir names (`apps/user-web`, etc.); QA skills need exact paths. (Verify when repo is attached.)
2. **OpenCode Go model for RS-Reviewer** — Qwen 3.7 Max (Quang's pick) vs GLM-5.2 vs DeepSeek V4 Pro vs Kimi K2.7 Code? Try Qwen 3.7 Max first; switch if review misses type/contract issues.
3. **Budget ceiling** — Opus vs Sonnet for RS-Lead/RS-Builder. With OpenCode Go ($10) + Plus ($20) + Claude Max ($100) + Ultra, the lean 5-agent start is well under Quang's $569/30d.
4. **CI overlap** — do the repos already have Playwright/Maestro/CI? If so, RS-QA should reuse those harnesses, not reinvent.
