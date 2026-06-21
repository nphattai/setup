# Squad templates — generic blueprint

These are the **pure, project-agnostic** Multica squad docs. A concrete project copies them into
`projects/<slug>/squad/`, fills the placeholders from `projects/<slug>/project.yml`, and pastes
the rendered text into the Multica UI. The first rendered instance is **`projects/aaa/squad/`** —
read it alongside these to see a worked example.

## Files
| Template | Renders to | Purpose |
|---|---|---|
| `00-squad-constitution.tmpl.md` | `squad/00-squad-constitution.md` | L1 shared rules (git/DoD/security/secrets/concurrency/memory) — squad Instructions tab |
| `rs-lead.tmpl.md` | `squad/rs-lead.md` | Tech-lead/orchestrator card |
| `rs-builder.tmpl.md` | `squad/rs-builder.md` | Implementer card |
| `rs-reviewer.tmpl.md` | `squad/rs-reviewer.md` | Static reviewer card |
| `rs-qa.tmpl.md` | `squad/rs-qa.md` | E2E QA card |
| `rs-research.tmpl.md` | `squad/rs-research.md` | On-demand research card |

## Placeholders (fill from `project.yml`)
| Token | Meaning | aaa value |
|---|---|---|
| `<slug>` | project slug (`project:`) | `aaa` |
| `<squad>` | squad name (`squad.name`) | `infina-insurance-dev` |
| `<org>` | GitHub org | `RealStake` |
| `<repo-fe>` | frontend repo (`repos.*.type: frontend`) | `infina-insurance-partner-webapp` |
| `<repo-be>` | backend repo (`repos.*.type: backend`) | `infina-insurance-partner-services` |
| `<fe-apps>` | frontend app keys | `nomi`, `admin`, `nomi-mobile` |
| `<be-app>` | backend app key | `insurtech-service` |
| `<local-path>` | project checkout root (`local_path`) | `~/Work/infina-ai/aaa` |
| `<tracker>` / `<KEY>` | issue tracker + key prefix | Jira / `SHP-####` |

> The infractl project key (`infra.key`) and Redis prefix (`infra.redis.key_prefix`) live in
> `project.yml` and are consumed by the **scripts/infractl**, not substituted into these docs.

## The 3-layer model (DRY)
```
L1 SQUAD CONSTITUTION  (this template → squad Instructions tab — all agents inherit)
L2 ROLE PROMPT         (per-agent card — the specialized lens)
L3 RUNTIME/MODEL       (per-agent card Properties — auth + model)
```

## Instantiate a new project
1. `mkdir -p projects/<slug>/squad` and author `projects/<slug>/project.yml` (copy aaa's manifest, edit).
2. Copy these templates into `projects/<slug>/squad/` (drop the `.tmpl`).
3. Replace every `<token>` with the project value (the table above + the manifest).
4. Wire the engine: `scripts/new-worktree.sh <slug> <app> …` and `scripts/start-local-stack.sh <slug>`
   already read the manifest — no edits needed.
5. Follow the rendered `squad/README.md` setup sequence to stand the squad up in Multica.

> Model assignments (Opus/Codex/OpenCode-Go/Antigravity `agy`) are the **recommended lean-5 archetype** —
> see `../design/runtime-and-capacity.md`. Override per project if cost/quota differs.
