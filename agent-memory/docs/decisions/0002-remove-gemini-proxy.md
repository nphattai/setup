# 0002 — Remove the gemini-proxy sidecar

- Status: Accepted
- Date: 2026-06-20
- Supersedes the dual-container stack; depends on [0001](0001-use-antigravity-oauth-via-cliproxyapi.md).

## Context

Once the LLM was routed through CLIProxyAPI ([0001](0001-use-antigravity-oauth-via-cliproxyapi.md)),
nothing referenced `gemini-proxy:5005`. The container stayed "healthy" only because its
healthcheck pinged its own `/health` — actual completions were dead (sunset OAuth). It
remained alive solely via `depends_on: gemini-proxy` in compose.

## Decision

Remove `gemini-proxy` entirely:

- Deleted the `gemini-proxy` service block and the `depends_on` from compose.
- `docker rm -f gemini-proxy` and `docker rmi agentmemory-stack/gemini-proxy:local` (~487 MB).
- Dropped its artifacts from the new setup: `gemini-proxy/` source, `Dockerfile.gemini-proxy`,
  `gemini-settings.docker.json`.

## Consequences

- Stack is now a **single container** + the host CLIProxyAPI. Simpler, less to babysit.
- Revival path (if ever needed) is the pristine upstream clone at
  `~/Downloads/agentmemory-stack-guide` (still has `gemini-proxy/` + `Dockerfile.gemini-proxy`);
  not carried forward here by choice.
- The dead Gemini Code Assist credential was parked at `~/gemini-cli-cred.dead.bak`.
