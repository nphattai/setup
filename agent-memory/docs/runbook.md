# Runbook

All commands run from `~/Work/setup/agent-memory`.

## Lifecycle

```bash
docker compose up -d            # start (reuses existing image)
docker compose up -d --build    # rebuild image first (after Dockerfile/source change)
docker compose restart agentmemory   # restart (does NOT re-read env_file)
docker compose down             # stop + remove container (named volumes kept)
docker compose up -d --force-recreate agentmemory   # re-read env_file after editing it
```

> Editing `agentmemory.docker.env` requires a **recreate** (`up -d --force-recreate`),
> not a plain `restart` — `restart` keeps the old environment.

## Health checks

```bash
curl -s -o /dev/null -w "REST %{http_code}\n" "http://localhost:3111/agentmemory/sessions?limit=1"
curl -s -o /dev/null -w "dashboard %{http_code}\n" http://localhost:3113/
docker logs --tail 30 agentmemory
```

## Wipe the store (fresh start)

The store is a file-based KV under `data/state_store.db`; there is **no delete API**.

```bash
docker stop agentmemory
find data/state_store.db -mindepth 1 -delete    # keeps the dir, clears contents
docker start agentmemory
```

Do NOT wipe while live Claude sessions are running — their `session/start` metadata
is lost and the dashboard shows "Unknown session / missing id" stubs until those
sessions end.

## Backup / restore the store

```bash
# backup
cp -R data/state_store.db ~/agentmemory-data.bak.$(date +%Y%m%d-%H%M%S)
# restore
docker stop agentmemory
rm -rf data/state_store.db && cp -R <backup> data/state_store.db
docker start agentmemory
```

## LLM backend (CLIProxyAPI + Antigravity)

See [llm-backend.md](llm-backend.md). Quick check:

```bash
curl -s http://localhost:8317/v1/chat/completions \
  -H "Authorization: Bearer $CLIPROXY_TOKEN" -H 'Content-Type: application/json' \
  -d '{"model":"gemini-3-flash","messages":[{"role":"user","content":"ping"}],"max_tokens":5}'
```

If completions 403 with `SUBSCRIPTION_REQUIRED`, the Antigravity token likely needs a
re-login: `cliproxyapi -antigravity-login` (and ensure no stale `gemini-*.json` cred
sits in `~/.cli-proxy-api/`).

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Compression failed / circuit_breaker_open` in logs | LLM backend down | Check :8317; re-login Antigravity |
| Graph tab empty | No data yet, or LLM down | Accumulate sessions; verify :8317 |
| "Unknown session" rows | store wiped mid-session | Cosmetic; new sessions are clean |
| Dashboard blank | viewer cache | hard refresh (Cmd+Shift+R) |
| Sessions named wrong (city codenames) | pre-fix hooks | ensure hooks patched (see ADR 0003) |
