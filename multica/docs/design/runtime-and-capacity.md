# Runtime, Auth & Capacity

> Deduped from the early setup drafts. Which runtime each agent uses, how it authenticates, cost, and the rate-limit reality. Architecture lives in `highlevel-design.md`; per-agent config in `../agents/`.

## Runtime → auth map (one login per runtime, shared by all agents on it)
| Runtime | Auth | Agents | ~Cost/mo |
|---|---|---|---|
| Claude Code | Claude Max 5x | RS-Lead (Opus), RS-Builder (**Opus**, Sonnet fallback) | $100 |
| OpenCode CLI | OpenCode Go → Qwen 3.7 Max | RS-Reviewer | $10 |
| Codex | ChatGPT Plus (GPT-5.x) | RS-QA | $20 |
| Antigravity CLI (`agy`) | Google account (replaces deprecated Gemini CLI; shares Antigravity OAuth w/ memory proxy) | RS-Research | existing |

**~$130/mo** for the lean-5 squad. Quang's full setup ran ~$569 API-equivalent / 447M tokens / 30d.

## Capacity reality (the binding constraint = rate-limit walls, not $)
- **Claude Max 5x**: Lead+Builder share one login; two weekly caps (all-models + Sonnet-only). **Both run Opus now** (user pref); **Builder auto-falls-back to Sonnet** when the all-models cap tightens. Higher quality per task, higher burn — keep trains small; if it walls weekly, give Builder its own Max login (+$100).
- **OpenCode Go ($10)**: flat, **request-metered** 5-hr windows (generous). Off the other subs. Qwen 3.7 Max is Quang-validated for review. Doubles as cheap overflow for QA/Builder if their subs wall out.
- **ChatGPT Plus ($20)**: Codex token-metered (since Apr 2026) w/ 5-hr + weekly caps. QA has Plus to itself (review moved to OpenCode Go). If heavy E2E throttles → point QA at OpenCode Go too.
- **Antigravity (`agy`)**: Gemini research is on-demand/light. `agy` (Google's replacement for the deprecated Gemini CLI; install `curl -fsSL https://antigravity.google/cli/install.sh | bash`) shares Antigravity OAuth with the memory proxy — keep RS-Research non-standing.

## Rules of thumb
- Never stack two heavy agents on one subscription login.
- Move the heaviest/spikiest consumer (QA) to OpenCode Go / pay-per-token first if Plus walls hit.
- Open models (Qwen/GLM/DeepSeek via Go) sit a notch below GPT-5.x/Claude on hard reasoning — fine for review/overflow; keep design+build on Claude.
- For 24/7 Quang-scale throughput, layer OpenCode Go + API keys under everything except the Claude pair.

## Model IDs to confirm at setup
- OpenCode Go review model: `opencode models` → exact Qwen 3.7 Max id.
- Codex QA model: exact GPT-5.x id (high reasoning).
- Claude: `claude-opus-4-8` (Lead), `claude-sonnet-4-6` (Builder).
