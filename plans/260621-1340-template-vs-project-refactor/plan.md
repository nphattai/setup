# Refactor — Template vs Concrete Project (`aaa` = first instance)

**Goal:** make `infra/` + `multica/` a **pure, generic, reusable** template; move everything
`aaa`-bound into `projects/aaa/`. Drive tooling from the project manifest (no hardcoded brand).
Delete the two stale HTML review artifacts (re-create later).

Decisions (locked 2026-06-21): **Hybrid** (generic engine reads manifest + template→rendered squad
docs) · **Full restructure now** · **Neutral `<placeholder>` tokens**.

## Target tree (end state)
```
~/Work/setup/
├── README.md                       [NEW] template (infra+multica) vs projects/<slug>
├── infra/                          ENGINE — generic
│   ├── README.md                   [EDIT] de-brand; worked example → projects/aaa/integration.md
│   ├── infractl                    [EDIT-light] de-brand example comments (already generic)
│   ├── compose/infra.yml           [keep]
│   └── docs/{design/highlevel-design.md[EDIT], decisions/0001-*.md[EDIT-light]}
│   (DEL) profiles/                 → projects/aaa/infra-profile.yaml
│   (DEL) docs/design/aaa-integration.md → projects/aaa/integration.md
├── multica/                        TEMPLATE — generic squad blueprint
│   ├── README.md                   [EDIT] de-brand; explain template + instantiation
│   ├── docs/
│   │   ├── templates/              [NEW] generic squad docs w/ <placeholders>
│   │   │   └── 00-squad-constitution.tmpl.md, rs-{lead,builder,reviewer,qa,research}.tmpl.md, README.tmpl.md
│   │   ├── design/{highlevel-design,runtime-and-capacity,env-and-execution-flow}.md  [EDIT de-brand]
│   │   ├── decisions/DECISIONS.md  [EDIT-light] de-brand header; keep append-only log
│   │   └── archive/                [keep — history]
│   │   (DEL) agents/               → split into templates/ (generic) + projects/aaa/squad/ (concrete)
│   ├── env/                        [keep; light de-brand example]
│   ├── docker/                     [keep]
│   ├── scripts/
│   │   ├── project-meta            [NEW] python3+PyYAML reader → shell vars from project.yml
│   │   ├── wire-env.sh             [REWRITE] wire-env.sh <project> <app> <wt> [stage]
│   │   ├── new-worktree.sh         [REWRITE] new-worktree.sh <project> <app> <TICKET> <slug> <train> [stage]
│   │   ├── start-local-stack.sh    [REWRITE] start-local-stack.sh <project>
│   │   └── bootstrap-host.sh       [EDIT-light] add python3/PyYAML check; generic
│   └── skills/README.md            [EDIT] mark project-specific (inf-*) vs generic
├── projects/aaa/                   CONCRETE INSTANCE
│   ├── project.yml                 [MOVE+EXPAND from projects/aaa.yml] +local_path +infra.key +repo dirs
│   ├── README.md                   [NEW] aaa overview + instantiate steps
│   ├── squad/{00-squad-constitution,rs-lead,rs-builder,rs-reviewer,rs-qa,rs-research,README}.md  [MOVE concrete]
│   ├── infra-profile.yaml          [MOVE from infra/profiles/]
│   └── integration.md              [MOVE from infra/docs/design/aaa-integration.md]
├── agent-memory/                   [untouched]
└── plans/                          [untouched + this plan]
(DEL) ./setup-architecture-review.html · ./docs/setup-high-level-design-and-flow-review.html → rmdir docs/
```

## Mechanics
- **`project-meta <slug> <app> [stage]`** prints sourceable shell (`PROJ_ROOT`, `INFRA_KEY`,
  `APP_KIND`, `APP_REPO_DIR`, `APP_CONTRACT`, `APP_STAGEFILE`, `APP_REQUIRED`) by reading
  `projects/<slug>/project.yml` with PyYAML. Scripts `eval "$(project-meta …)"` → zero hardcoded brand.
- **project.yml additions:** `infra.key: infina-insurance-partner-services`; confirm `local_path`;
  repo dir derived from `local_path/repos.<r>.name`. `required_local` stays the ONLY copy of REQUIRED.
- **Placeholders:** `<project>` `<slug>` `<squad-name>` `<repo-fe>` `<repo-be>` `<app>` `<local-path>`
  `<jira-prefix>` `<train>`. Templates say "values in projects/<slug>/project.yml".
- **Rendered = current concrete docs.** The existing constitution + 5 cards are already aaa-concrete →
  MOVE them to `projects/aaa/squad/`. Templates = de-branded derivatives in `multica/docs/templates/`.

## Phases
1. **Delete HTML** (2 files) + rmdir `docs/`.
2. **projects/aaa skeleton**: create dir; move+expand `aaa.yml`→`projects/aaa/project.yml`; move squad
   docs, infra-profile, integration; write `projects/aaa/README.md`.
3. **Scripts → generic**: write `project-meta`; rewrite wire-env / new-worktree / start-local-stack to
   `<project>`-arg + manifest; light-edit bootstrap-host. Smoke-test all.
4. **Templates**: de-brand the 6 squad docs into `multica/docs/templates/*.tmpl.md`.
5. **De-brand template docs**: multica design/*, DECISIONS header, README, env README, skills README,
   docker README; infra README, infractl comments, infra highlevel-design, ADR 0001.
6. **Top-level README** explaining the split.
7. **Verify**: `bash -n` + smoke all scripts; grep templates for residual brand tokens; code-reviewer
   subagent; structure sanity.

## Acceptance
- `grep -riE 'infina|insurtech|aaa' multica infra` → only generic/example mentions (no hardcoded paths,
  no `PROJECT_KEY=…`, no per-app case maps). Brand lives in `projects/aaa/` only.
- `wire-env.sh aaa <app> <wt> [stage]` + `new-worktree.sh aaa …` resolve everything from the manifest;
  smoke cases (required-missing→BLOCK, present→READY) still pass.
- 2 HTML files gone; `docs/` removed. Templates render-ready with placeholders; aaa squad docs concrete.

## Out of scope
- Re-creating the HTML review (later, post-finalize). Product-repo dotenvx adoption. Authoring the 5
  custom skills. Touching `agent-memory/`. A 2nd project.
```
