# agentmemory-mcp — cross-runtime memory shim

A tiny **stdio MCP server** over the agentmemory REST API (`:3111`). Gives any
MCP-capable runtime (Claude, Codex, OpenCode, Antigravity `agy`) the same shared memory.

The agentmemory plugin only captures **Claude Code** sessions (via hooks). This shim
adds **recall + explicit save** for the non-Claude squad runtimes too — and fixes the
plugin's default Claude MCP entry, which shipped broken (`agentmemory-mcp` binary not
on PATH + `host.docker.internal` URL that doesn't resolve from a host process).

## Tools
- `memory_search({ query, limit?, cwd? })` → `POST /agentmemory/search` — recall lessons for the current repo.
- `memory_save({ text, tags?, cwd? })` → `POST /agentmemory/observe` — persist a lesson.

Project is auto-resolved from cwd via the git common-dir (mirrors the capture hooks),
so worktrees collapse to the parent repo bucket (DECISIONS #15). Never save secrets/PII.

## Hybrid capture policy (squad constitution)
- **Claude (Lead/Builder):** auto-captures via hooks → use `memory_search` only, never `memory_save` (avoids double-write).
- **Non-Claude (Reviewer/QA/Research):** `memory_search` to recall + `memory_save` to persist.

## Env
| Var | Default | Purpose |
|---|---|---|
| `AGENTMEMORY_URL` | `http://localhost:3111` | REST base. Host clients use `127.0.0.1`; only in-container clients use `host.docker.internal`. |
| `AGENTMEMORY_SECRET` | _(none)_ | Bearer token, if the REST API is secured. |
| `AGENTMEMORY_PROJECT_NAME` | _(none)_ | Force a bucket, overriding git resolution. |

## Install
```bash
cd ~/Work/setup/agent-memory/mcp && npm install
```

## Wiring (all done — reference)
```bash
SHIM=/Users/tainguyen/Work/setup/agent-memory/mcp/agentmemory-mcp.mjs
URL=http://127.0.0.1:3111
codex  mcp add agentmemory --env AGENTMEMORY_URL=$URL -- node "$SHIM"
# Antigravity `agy` (replaces the dead gemini CLI): NO `mcp add` subcommand — it's FILE-BASED.
#   Add to ~/.gemini/config/mcp_config.json (unified, IDE+CLI) — or ~/.gemini/antigravity-cli/mcp_config.json (CLI-only):
#     { "mcpServers": { "agentmemory": { "command":"node", "args":["$SHIM"], "env":{"AGENTMEMORY_URL":"$URL"} } } }
# OpenCode: ~/.config/opencode/opencode.jsonc  -> mcp.agentmemory (type local)
# Claude:   ~/.claude.json                     -> mcpServers.agentmemory (type stdio)
```

## Smoke test
```bash
printf '%s\n' \
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"0"}}}' \
'{"jsonrpc":"2.0","method":"notifications/initialized"}' \
'{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
| node agentmemory-mcp.mjs
```
