# Plan — Fill the agent-memory gap for non-Claude runtimes

> ⚠️ **PARTIALLY SUPERSEDED (2026-06-21) by DECISIONS #23:** the "keep gemini CLI" decision below
> was reversed — Google deprecated the Gemini CLI (sign-in disabled). **RS-Research now runs on the
> Antigravity CLI (`agy`)**, and the memory shim is wired into `agy` via `~/.gemini/config/mcp_config.json`
> (file-based; there is no `gemini mcp add` / `agy mcp add`). The rest of this plan (Claude/Codex/OpenCode wiring) stands.

Date: 2026-06-21 · Origin: self-review F4 · Owner: tai

## Decisions locked (review + user)
- **Shared DB stays.** FE worktrees concurrent, backend serial. Per-worktree DB NOT adopted (DECISIONS 06-21 note).
- **Non-Claude agents need recall + explicit save.**
- **Runtime mapping:** Lead/Builder = Claude (auto-captured via hooks) · Reviewer = **OpenCode** (installed v1.17.9, **Go sub authed ✅**) · QA = **Codex** · Research = **gemini CLI** (headless).
- **Q1 resolved → Hybrid tool exposure.** All agents get `memory_search`. Capture: Claude auto-captures via hooks (does NOT call `memory_save`); non-Claude call `memory_save` explicitly. One shim exposes both tools; constitution governs who calls what. (Avoids Claude double-write; gives Claude deliberate mid-task recall.)
- **Q3 resolved → keep gemini CLI, keep Antigravity, uninstall neither.** No headless `antigravity` CLI exists (GUI IDE only) → gemini CLI is the Research runtime. Antigravity stays because its OAuth grant powers CLIProxyAPI → agent-memory LLM enrichment (ADR-0001; account `henry16198@gmail.com`). They coexist on `~/.gemini`.

## Verified reality (why MCP is the path)
- agentmemory in this setup = **hooks → REST only** on `:3111`. The advertised "53 MCP tools" are **not deployed** (no MCP server binary, `mcpServers: NONE`). Working endpoints:
  - `POST /agentmemory/search` `{query, project, limit}` → `{results, tokens_used, truncated}` (recall)
  - `POST /agentmemory/observe` `{project, …}` (capture/save)
  - `POST /agentmemory/session/start` · `GET /agentmemory/{memories,lessons,health}`
- Claude capture+recall is **automatic via hooks**; Codex/OpenCode/gemini have **no connection** to memory today.
- Codex/gemini have **no granular hooks** (`hooks.codex.json` uses Claude event names stock Codex never fires; Codex real surface = `notify` + MCP). The **one common surface** across all runtimes = **MCP servers** (`codex mcp`, `gemini mcp`, OpenCode `opencode.json.mcp`).
- Latent bug: the squad constitution tells agents to call `memory_smart_search`/`memory_save` — **not wired for anyone** (Claude included). This plan fixes that too.

## Approach — one stdio MCP shim over REST (KISS · DRY)
Single small Node stdio MCP server backed by the existing REST API. No new service, no container change.

`agent-memory/mcp/agentmemory-mcp.mjs` exposes **2 tools**:
- `memory_search({ query, limit=5 })` → `POST :3111/agentmemory/search` → returns results.
- `memory_save({ text, tags=[] })` → `POST :3111/agentmemory/observe` tagged as a lesson.

Both **auto-resolve `project`** by reusing the hooks' `resolveProject` logic (git common-dir → real repo name) so worktrees collapse to one repo bucket (DECISIONS #15). One file, ~80–120 lines, `@modelcontextprotocol/sdk` stdio transport. Lives in the setup repo = single source of truth; every runtime points at the same path.

## Wiring per runtime (after shim built)
| Runtime | Command |
|---|---|
| Codex | `codex mcp add agentmemory -- node ~/Work/setup/agent-memory/mcp/agentmemory-mcp.mjs` |
| OpenCode | add to each aaa repo's `opencode.json`: `"mcp": { "agentmemory": { "type":"local", "command":["node","~/Work/setup/agent-memory/mcp/agentmemory-mcp.mjs"], "enabled":true } }` |
| gemini CLI (Research) | `gemini mcp add agentmemory node ~/Work/setup/agent-memory/mcp/agentmemory-mcp.mjs` |
| Claude (Lead/Builder) | add to `~/.claude/settings.json` `mcpServers` → use `memory_search` only; capture stays on hooks (don't call `memory_save`) |

## Constitution reconciliation (multica)
Update `00-squad-constitution.md` §Memory:
- Rename tools to the shim's `memory_search` / `memory_save`.
- State: Claude (Lead/Builder) auto-captures via hooks; non-Claude (Reviewer/QA/Research) get recall + explicit save via the MCP shim; **automatic per-tool capture stays Claude-only in v1** (acceptable — explicit lesson save + shared recall is the 80%).

## Steps (ordered) — ALL DONE 2026-06-21
1. ~~OpenCode auth~~ ✅ (Go sub authed).
2. ✅ Built `agent-memory/mcp/agentmemory-mcp.mjs` + `README.md` (tools `memory_search`/`memory_save`, auto-resolve project). Smoke passed: save→200, search returned real facts.
3. ✅ Registered in Claude (`~/.claude.json` — fixed the broken default entry), Codex (`codex mcp add`), OpenCode (`~/.config/opencode/opencode.jsonc`), gemini CLI (`gemini mcp add -s user`). Global scope — project resolves at runtime from cwd. (Used global OpenCode config; per-repo `opencode.json` don't exist.)
4. ✅ Verified: gemini "Connected", OpenCode "connected", Codex registered (stdio), Claude patched (loads next session).
5. ✅ Constitution §Memory rewritten (hybrid) + DECISIONS #17 appended + `.gitignore` for `mcp/node_modules`.

**Follow-up:** restart this Claude session (or reload MCP) to pick up the fixed `agentmemory` server, then confirm `memory_search` is callable here.

## Risks / to confirm during impl
- `search` returned empty this session — verify it's project-name/consolidation lag, not a payload mismatch (match `resolveProject` + `prompt-submit.mjs` body exactly).
- `memory_save` endpoint: `/observe` is the capture path; confirm whether a dedicated lesson-write exists, else tag the observation as a lesson.
- Antigravity may consume `~/.gemini` (shares config with gemini CLI) — confirm whether it picks up `gemini mcp` servers or needs its own registration.
- `host.docker.internal` not needed — runtimes hit `127.0.0.1:3111` directly (REST is host-published).

## Open questions
- None blocking. (OpenCode Go ✅ · Claude=hybrid ✅ · Research=gemini CLI ✅.) Remaining unknowns are impl-time: exact `/observe` payload for `memory_save`, whether a dedicated lesson-write endpoint exists, and whether Antigravity-IDE picks up `gemini mcp` servers (not needed for the squad).
