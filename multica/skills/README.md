# Custom Skills (authored)

Repo-local skills the squad cards reference (not in the ck catalog). Each is a portable `SKILL.md`
(frontmatter `name` + `description`, then when-to-use + steps). Following the template-vs-project
split: **generic skills live here**; **project-specific skills live under `projects/<slug>/skills/`.**

## Generic (here — reusable across projects)
| Skill | Used by | Purpose |
|---|---|---|
| `root-cause-first/` | Builder | Repro-before-patch: red-on-demand before any fix; HALT ladder if can't repro |
| `safe-refactor/` | Builder | Behavior-preserving change: characterization test first, no contract/scope change |
| `builder-dev-loop/` | Builder | One-AC-at-a-time implement→verify→iterate loop + DoD checklist (Nx+yarn stack) |

## Project-specific (e.g. `projects/aaa/skills/`)
| Skill | Used by | Purpose |
|---|---|---|
| `inf-api-contract/` | Builder, Reviewer | `yarn gen:api` BE↔FE sync; flag contract/`api.gen.ts` changes for mandatory human review |
| `inf-e2e-mobile-maestro/` | QA | Scaffold + run Maestro flows on local iOS sim / Android emulator; green-before-merge |

## Porting into the product repos
These are the **source stubs**. To make them attachable by all agents/runtimes, copy each skill dir
into the relevant product repo's `.claude/skills/<name>/SKILL.md` (via ticket/PR — agents never push
to `release`/`master`). Generic skills can be shared across a project's repos; the `inf-*` skills go
into the repo whose commands they wrap. Refine with `/ck:skill-creator` if needed.
