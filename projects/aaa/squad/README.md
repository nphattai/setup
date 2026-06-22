# `mica` — Agent Team Detail (index)

Per-agent Multica config for the lean-5 squad (the rendered `aaa` instance of `../../../multica/docs/templates/`). Read order: constitution → agent cards. High-level rationale in `../../../multica/docs/design/highlevel-design.md`. Manifest: `../project.yml`.

| File | Agent | Runtime / Model | One-liner |
|---|---|---|---|
| `00-squad-constitution.md` | (all) | — | L1 shared rules: git, DoD, security, status protocol, memory |
| `rs-lead.md` | RS-Lead | Claude Code / Opus | Jira intake → PRD → slice → gates. Plans, never codes |
| `rs-builder.md` | RS-Builder | Claude Code / Opus (Sonnet fallback) | Implements one sub-issue → PR into train. Never merges |
| `rs-reviewer.md` | RS-Reviewer | OpenCode Go / Qwen 3.7 Max | 3-lens static diff review. Read-only |
| `rs-qa.md` | RS-QA | Codex / GPT-5.x | E2E web/mobile/backend. Proves bugs, never fixes |
| `rs-research.md` | RS-Research | Antigravity CLI (`agy`) / Gemini 3.x | On-demand spikes. Read-only reports |

## Multica config surfaces (per agent — from the UI tabs)
Each card specifies: **Properties** (Runtime/Model/Thinking/Visibility/Concurrency) · **Instructions** (paste-ready prompt) · **Skills** · **MCP** · **Environment** · **Custom Args** · **Integrations**.

## Custom skills (authored — referenced by cards; not in the ck catalog)
| Skill | Used by | Source location |
|---|---|---|
| `root-cause-first` | Builder | `../../../multica/skills/` (generic) |
| `safe-refactor` | Builder | `../../../multica/skills/` (generic) |
| `builder-dev-loop` (optional) | Builder | `../../../multica/skills/` (generic) |
| `inf-api-contract` | Builder, Reviewer | `../skills/` (project-specific) |
| `inf-e2e-mobile-maestro` | QA | `../skills/` (project-specific) |

Authored as portable `SKILL.md` stubs. **Port** each into the relevant product repo's
`.claude/skills/<name>/` (via ticket/PR — agents never push to `release`/`master`) so all
agents/runtimes can attach them. See `../../../multica/skills/README.md`.

## MCP servers in play
| Server | Source | Agents |
|---|---|---|
| Atlassian (Jira) | this environment | Lead, Research |
| `nx-mcp` | repo `opencode.json` | Lead, Builder, Reviewer, QA |
| `context7` | parent `.mcp.json.example` | Lead, Builder, Research |
| `chrome-devtools` | parent template | Builder, QA |
| `gkg` | ck | Reviewer |
| `human-mcp` (Gemini vision) | parent template | Research |
| `insurtech-service` MCP (`make mcp-*`) | services repo | QA |

## Setup order
1. **Phase 0 (pre-flight):** branch-protect `master` + `release` (include administrators); provision/confirm gh login; install QA host toolchain (`npx playwright install`, `brew install maestro`, Xcode sim, Android emulator); subscribe OpenCode Go; auth Codex (Plus) + Antigravity `agy` (Google account — replaces deprecated Gemini CLI); set the squad chat integration. Author the 5 custom skills.
2. Create Multica **project** `infina-insurance-partner` → attach both GitHub repos.
3. Paste the **squad constitution** into the squad Instructions tab.
4. Create the 5 **agents** from their cards (runtime, model, instructions, skills, MCP, env, args).
5. Create **squad** `mica`, leader = RS-Lead, add the 5 agents + the human owner (reviewer/member).
6. Dry-run: assign one real `SHP-####` to RS-Lead, walk it through all 3 gates, tune prompts.

## Open follow-ups
- Author the 5 custom skills (own task).
- Provision the GitHub bot account (Phase 0 → removes the interim identity risk).
- Confirm exact OpenCode Go model id (`opencode models`) + GPT-5.x model id for Codex.
- Fill real `STAGING_WEB_URL` / `STAGING_ADMIN_URL`.
