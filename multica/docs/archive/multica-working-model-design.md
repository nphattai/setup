# Multica Working-Model Design

> Design for how *you* (RealStake) work inside Multica, derived from Quang Tran's `oneclaw-dev` squad. Created 2026-06-19.

## 1. Locked decisions

| Concern | Runtime / Model | Notes |
|---|---|---|
| Architecture, PRD, design, **implementation** | **Claude** | One brain owns spec→design→build. Long-horizon coherence. |
| Code review (static) | **Codex** | Reads diffs/PRs. Type & contract rigor, line-citable. |
| Research | **Gemini** | Long-context synthesis, web + whole-repo reasoning. |
| **QA / E2E / backend-debug** | **Codex (2nd agent)** | Runs the app. Distinct from review (static vs dynamic). |

## 2. QA strategy (the open concern)

**Model choice is secondary to host toolchain.** A model can't test what its host can't boot.

| Test target | Host requirement | Tool |
|---|---|---|
| Web app E2E | Node + browsers | Playwright |
| React Native E2E | **macOS + Xcode iOS Sim + Android emulator** | **Maestro** (YAML flows, agent-friendly; > Detox) |
| Backend debug | Services bootable (Docker, DB, env) | App's own test runner + log/trace reading |

**Decision: QA runtime = Codex (high reasoning), as a separate agent from the reviewer.**
- Review = static (diff). QA = dynamic (run). Different activities → blind-spot risk low even on same model family.
- Reuses Codex keys already provisioned. No extra runtime.

**Two hard rules:**
1. **QA proves, Claude fixes.** QA writes failing test + repro steps, moves issue to `Blocked`/back to Builder. Never let the tester also be the fixer.
2. **Split QA by host only if forced.** All on your Mac → one `QA` agent, 3 modes (web/mobile/backend). If web+backend on Linux and RN on Mac → two agents (`QA-Web-Backend`, `QA-Mobile`). Start with one (YAGNI).

## 3. Squad roster (lean start → grow)

Start lean. Add reviewers/monitor only when volume justifies cost (Quang's full 7-agent squad ran ~$569/30d, 447M tokens).

### Phase 1 — Lean (4 agents) ✅ start here
| Agent | Role | Runtime | Responsibility |
|---|---|---|---|
| `RS-Lead` | leader | Claude | Intake → PRD → tech design → break into sub-issues → spec-conformance. Owns human gates. |
| `RS-Builder` | builder | Claude | Implements sub-issues on feature branches. PRs into feature branch. **Never merges/deletes.** |
| `RS-Reviewer` | code-reviewer | Codex | Reviews PRs: type-correctness, API contracts, regressions. Line-citable. |
| `RS-QA` | qa | Codex | E2E (web/mobile/backend modes). Proves bugs, kicks back to Builder. |

`RS-Research` (Gemini) added on-demand for spikes — not a standing squad member at first.

### Phase 2 — Grow (when PR volume / blind spots demand)
- Split `RS-Reviewer` into specialist lenses like Quang: `Reviewer-Contract` (Codex), `Reviewer-Architecture` (Gemini whole-repo), `Reviewer-Orchestration`.
- Add `RS-Monitor` (cheap runtime) as watchdog for stuck/failed tasks.
- Split QA by platform if hosts diverge.

## 4. Workflow (assign → execute → review → QA → merge)

```
                ┌─────────── HUMAN GATE 1 (approve PRD/design) ───────────┐
                ▼                                                          │
 Request → RS-Lead: PRD + tech design + sub-issues (RS-NN) ───────────────┘
                │
                ▼
 RS-Builder claims sub-issue → feature branch → code → PR into feature branch
                │
                ▼
 RS-Reviewer (Codex) reviews diff ──fail──► back to RS-Builder
                │ pass
                ▼
 RS-QA (Codex) runs E2E ──bug──► failing test + repro → RS-Builder fixes
                │ pass
                ▼
                ┌─────────── HUMAN GATE 2 (you merge) ───────────┐
                ▼
            Merge to main
```

**Agents never self-merge.** Humans hold both gates: (1) design sign-off, (2) merge.

## 5. Kanban lifecycle

`Backlog → Todo → In Progress → In Review → Done` + `Blocked` (mirrors Quang's `QUA-*` board).
- Issues prefixed per project (e.g. `RS-1`, `RS-2`).
- Lead creates parent issues; sub-issues (slices) owned by Builder.
- `Blocked` = QA found a bug or agent flagged a blocker → human/Lead triages.

## 6. Projects & repos

- **New Project** → attach **GitHub repo** (`RealStake/<repo>`) or **Local directory**.
- One project per repo/app. Web app + RN app + backend = likely 2–3 projects (or one mono-project if monorepo).
- Code executes on **your** machine/infra — never transits Multica servers.

## 7. Skills to write early (compound across agents)

Write once, every agent reuses. Candidates for RealStake:
- `rs-branch-pr` — branch naming + PR-into-feature-branch convention (enforces "never merge to main").
- `rs-e2e-web` — Playwright setup/run/report.
- `rs-e2e-mobile` — Maestro flow run on iOS sim / Android emulator.
- `rs-backend-repro` — boot services, reproduce bug, capture logs/traces.
- `rs-review-checklist` — type/contract/regression review rubric for Codex.

## 8. Cost control

- Quang baseline: 7 agents, ~$569 + 447M tokens / 30d. Lean 4-agent start ≈ a fraction of that.
- Watch the analytics dashboard (Cost/Tokens/Time/Tasks, 30D). One bad day (6/18 spiked to ~230M tokens) dominates spend → cap autopilots, scope issues tightly.
- Prefer Sonnet for Builder grunt work, reserve Opus for Lead design if budget-sensitive.

## 9. Setup steps

```bash
# 1. Install (macOS)
brew install multica-ai/tap/multica
multica setup

# 2. Start daemon, verify runtimes in Settings (auto-detects installed CLIs):
#    - Claude Code, Codex, Gemini must be installed + authed on this Mac
# 3. Provision QA host toolchain on this Mac:
#    - Node + npx playwright install
#    - Xcode + iOS Simulator; Android Studio + emulator; brew install maestro
# 4. Create project → attach RealStake/<repo>
# 5. Create agents (Phase 1 roster), assign runtime + role + instructions
# 6. Create squad "realstake-dev", leader = RS-Lead, add the 4 agents + you (reviewer/member)
# 7. Assign first issue to RS-Lead → watch the loop
```

## 10. Agent instruction skeletons (paste into each agent)

- **RS-Lead:** "Product intake, PRD, tech design, orchestration, spec-conformance. Break work into small sub-issues. Two human gates: design approval + merge. Never write production code yourself — delegate to RS-Builder."
- **RS-Builder:** "Implement assigned sub-issues only. Work on a feature branch. Open PRs into the feature branch. Never merge or delete branches. Report blockers immediately."
- **RS-Reviewer (Codex):** "Review PR diffs for type-correctness, API-contract coherence, regressions. Cite concrete lines. Approve or request changes — do not edit code."
- **RS-QA (Codex):** "Spec-driven E2E. Modes: web (Playwright), mobile (Maestro), backend (boot + repro). Prove bugs with a failing test + repro steps, move issue to Blocked, hand back to RS-Builder. Never fix code yourself."

## Open questions
1. **Repo topology** — monorepo (web+mobile+backend together) or separate repos? Determines 1 vs 3 Multica projects.
2. **QA host** — is this Mac the daemon host for *all* runtimes, or split across machines? Affects whether one or two QA agents.
3. **Budget ceiling** — target $/month? Drives Sonnet-vs-Opus for Builder and how many reviewers in Phase 2.
4. **cliproxy** — Quang routed qwen/gpt-5.5 via cliproxy. You're not using those now; revisit only if you add specialist reviewers in Phase 2.
5. **Autopilots** — any recurring work (nightly E2E, dependency bumps) worth a cron trigger? Defer until the manual loop is proven.
