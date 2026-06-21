# 0001 — Use Antigravity OAuth via CLIProxyAPI for the LLM backend

- Status: Accepted
- Date: 2026-06-20

## Context

agentmemory's enrichment (compression, lesson consolidation, graph extraction) needs an
LLM. The original setup used `gemini-proxy`, a sidecar wrapping the **consumer Gemini
Code Assist OAuth** tier. Google **sunset that tier ~2026-06-18**; every call began
returning `IneligibleTierError` / `403`. This silently broke compression (circuit breaker
open), stopped new Lessons, and left the Graph empty. Embeddings are local, so raw capture
kept working — masking the outage.

## Decision

Route the LLM through the **host CLIProxyAPI** (`:8317`) authenticated with **Antigravity
OAuth** (`cliproxyapi -antigravity-login`), which is Google's sanctioned migration path.
agentmemory points at it via OpenAI-compatible env:

```
OPENAI_BASE_URL=http://host.docker.internal:8317
OPENAI_API_KEY=sk-cliproxy-bmad-2026
OPENAI_MODEL=gemini-3-flash
```

## Alternatives considered

- **Gemini API key (AI Studio / Vertex):** valid and simple, but the user already runs
  CLIProxyAPI and prefers OAuth over managing a key; Antigravity also unlocks Claude/GPT
  models through one gateway.
- **Re-login the old gemini-proxy:** impossible — the *tier* is dead, not the token.

## Consequences

- No agentmemory code change — just base-url/key/model.
- Gotcha: a stale `gemini-*.json` cred in `~/.cli-proxy-api/` causes round-robin to hit the
  dead Code Assist backend (`403 SUBSCRIPTION_REQUIRED`); only the Antigravity cred may
  remain. (See [llm-backend.md](../llm-backend.md).)
- Antigravity uses different model names (`gemini-3-flash`, not `gemini-2.5-flash`).
- Verified: `Observation compressed` succeeds; `consolidate-pipeline` returns 200.
