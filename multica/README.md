# Multica — generic AI-agent squad template

Reusable, **project-agnostic** blueprint for standing up a Multica AI-agent squad on this host.
Holds the squad design docs, locked decisions, the squad-doc **templates**, env/docker notes, and
the manifest-driven scripts. **No project lives here** — concrete projects live in
`../projects/<slug>/` (first instance: `../projects/aaa/`).

## Template vs instance
```
multica/   ← THIS (template, generic, reusable across projects)
infra/     ← shared local-dev infra engine (generic)
projects/<slug>/   ← one concrete project: manifest + rendered squad docs + infra profile
```

## Layout
```
docs/
  design/      highlevel-design.md · runtime-and-capacity.md · env-and-execution-flow.md  (generic blueprint)
  templates/   00-squad-constitution.tmpl.md + 5 rs-*.tmpl.md + README  (placeholder squad docs)
  decisions/   DECISIONS.md (squad-design decision log)
  archive/     superseded early drafts (history)
env/           NON-PROD .env.example per surface + secret-injector notes
docker/        local-infra strategy + deferred backend-worktree isolation
scripts/       project-meta · bootstrap-host · start-local-stack · new-worktree · wire-env  (manifest-driven)
```

## Read order
1. `docs/design/highlevel-design.md` — architecture, git flow, gates, risks.
2. `docs/templates/README.tmpl.md` — placeholder legend + how to instantiate a project.
3. `docs/templates/00-squad-constitution.tmpl.md` + `rs-*.tmpl.md` — the squad docs to render.
4. `docs/design/runtime-and-capacity.md` — runtimes, auth, cost, plan limits.
5. `docs/design/env-and-execution-flow.md` — the 3-source env model + task→QA flow.
6. `docs/decisions/DECISIONS.md` — why each choice was made.

## The scripts are generic (read the manifest)
All scripts take a `<project>` slug and resolve repos/apps/paths/secrets from
`../projects/<slug>/project.yml` via `scripts/project-meta` — nothing project-specific is baked in.
```
scripts/start-local-stack.sh <project>
scripts/new-worktree.sh <project> <app> <TICKET> <slug> <train> [stage]
scripts/wire-env.sh <project> <app> <worktree-dir> [stage]
```

## Stand up a project
See `docs/templates/README.tmpl.md` → "Instantiate a new project", then the rendered
`../projects/<slug>/squad/README.md` for the Multica setup sequence. Worked example: `../projects/aaa/`.
