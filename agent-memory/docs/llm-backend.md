# LLM backend — CLIProxyAPI + Antigravity OAuth

agentmemory's enrichment LLM is the **host** CLIProxyAPI service, reached at
`http://host.docker.internal:8317` from inside the container.

## Why this, not the alternatives

- The original `gemini-proxy` wrapped the consumer **Gemini Code Assist OAuth** tier,
  which Google **sunset ~2026-06-18** (`IneligibleTierError`). Dead.
- Google's own error points to **Antigravity** as the migration path.
- CLIProxyAPI (v7.1.45+) has a built-in `-antigravity-login` and exposes Antigravity
  models over an OpenAI-compatible API — so agentmemory needs no code change, just a
  base-url/key swap.

See [decisions/0001-use-antigravity-oauth-via-cliproxyapi.md](decisions/0001-use-antigravity-oauth-via-cliproxyapi.md).

## The service

- Binary: `/opt/homebrew/opt/cliproxyapi/bin/cliproxyapi` (Homebrew, runs via launchd
  `homebrew.mxcl.cliproxyapi.plist`).
- Config: `/opt/homebrew/etc/cliproxyapi.conf` — `port: 8317`, `api-keys: [sk-cliproxy-bmad-2026]`,
  `auth-dir: ~/.cli-proxy-api`.
- Auth creds live in `~/.cli-proxy-api/*.json`.

## Login / re-login

```bash
cliproxyapi -antigravity-login     # opens browser OAuth, writes antigravity-*.json
```

**Critical gotcha:** keep ONLY the Antigravity credential in `~/.cli-proxy-api/`.
A stale `gemini-*.json` (Code Assist OAuth) makes round-robin route to the dead
`cloudaicompanion.googleapis.com` backend → `403 SUBSCRIPTION_REQUIRED`. Move any such
file out (parked at `~/gemini-cli-cred.dead.bak`).

## Models

Antigravity exposes its own names (NOT `gemini-2.5-flash`). Listed via:

```bash
curl -s http://localhost:8317/v1/models -H 'Authorization: Bearer sk-cliproxy-bmad-2026'
```

Includes: `gemini-3-flash`, `gemini-3.1-flash-lite`, `gemini-3.1-pro-low`,
`claude-sonnet-4-6`, `claude-opus-4-6-thinking`, etc. agentmemory uses **`gemini-3-flash`**
(`OPENAI_MODEL` in `agentmemory.docker.env`).

## How agentmemory points at it

In `agentmemory.docker.env`:

```
OPENAI_BASE_URL=http://host.docker.internal:8317
OPENAI_API_KEY=sk-cliproxy-bmad-2026
OPENAI_MODEL=gemini-3-flash
EMBEDDING_PROVIDER=local
```

The Antigravity OAuth token auto-refreshes; no recurring action unless Google revokes it.
