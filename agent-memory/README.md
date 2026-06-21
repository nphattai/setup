# agent-memory

Local memory engine ([agentmemory](https://github.com/) + native `iii`) that captures
Claude Code sessions and serves recall, lessons, and a knowledge graph at
`http://localhost:3113/#dashboard`.

This directory is the **single source of truth** for the setup: Docker stack,
configuration, operations runbook, and the decision records behind the current shape.

## Layout

```
agent-memory/
├── docker-compose.yml        # the stack (single `agentmemory` service)
├── agentmemory.docker.env    # env: LLM wiring, embeddings, feature flags
├── docker/                   # image build context
│   ├── Dockerfile.agentmemory
│   ├── agentmemory-entrypoint.sh
│   └── iii-config.docker.yaml
├── data/                     # memory store (bind mount, runtime state)
├── agentmemory-home/         # engine config (bind mount, runtime state)
├── mcp/                      # stdio MCP shim → memory_search/save for any runtime (see mcp/README.md)
└── docs/
    ├── architecture.md       # components + data flow
    ├── runbook.md            # start/stop/wipe/backup/troubleshoot
    ├── llm-backend.md        # CLIProxyAPI + Antigravity OAuth
    └── decisions/            # ADRs — why it looks like this
```

## Quick start

```bash
cd ~/Work/setup/agent-memory
docker compose up -d
open http://localhost:3113/#dashboard
```

Capture is automatic via Claude Code hooks in `~/.claude/plugins/agentmemory-local/`
(see [docs/architecture.md](docs/architecture.md)).

## Current shape (2026-06-20)

- **One container** (`agentmemory`) — REST :3111, dashboard :3113.
- **LLM backend:** host **CLIProxyAPI :8317** via **Antigravity OAuth** (not a Gemini key, not the old gemini-proxy).
- **Embeddings:** local, in-container (no network).
- The previous `gemini-proxy` sidecar was removed — see [docs/decisions/0002-remove-gemini-proxy.md](docs/decisions/0002-remove-gemini-proxy.md).

For day-to-day operations, see [docs/runbook.md](docs/runbook.md).
