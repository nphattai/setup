# Project `aaa` — Infina insurance-partner platform

The **first concrete instance** of the Multica squad template (`../../multica/`) + shared infra
engine (`../../infra/`). Everything bounded to this project lives here.

## Contents
| Path | What |
|---|---|
| `project.yml` | **SoR manifest** — repos, apps, env contracts, infra key, secrets, squad. Drives the scripts. |
| `squad/` | The **rendered, concrete** squad docs (paste into Multica): `00-squad-constitution.md` + 5 `rs-*.md` + `README.md`. Rendered from `../../multica/docs/templates/`. |
| `infra-profile.yaml` | The infractl version/db/prefix contract for this project's backend. |
| `integration.md` | Worked example — wiring the backend repo to shared infra (config-only, no app code change). |

## Facts
- **Repos** (at `~/Work/infina-ai/aaa`): `infina-insurance-partner-webapp` (FE: `nomi`/`admin`/`nomi-mobile`)
  · `infina-insurance-partner-services` (BE: `insurtech-service`).
- **Squad:** `mica` (lean-5: RS-Lead/Builder/Reviewer/QA/Research).
- **Infra key:** `infina-insurance-partner-services` → DB `infina_insurance_partner_services`, schema `ins`, Redis prefix `ins_`.
- **Tracker:** Jira, key `SHP-####`. **Trains:** `release-<slug>`.

## Daily use (the scripts target this project by slug)
```bash
# stage the shared local stack for aaa (infra up + db-create + migrate hints)
../../multica/scripts/start-local-stack.sh aaa

# new worktree for a sub-issue (creates branch from train + wires/validates env)
../../multica/scripts/new-worktree.sh aaa nomi SHP-1234 claims-flow release-claims-q3

# re-validate a worktree's env (hard gate) on demand
../../multica/scripts/wire-env.sh aaa insurtech-service <worktree-dir> local
```

## Human-owned, one-time
- Provision the shared DB: `infractl up` + `infractl db-create infina-insurance-partner-services`.
- Create each app's plain, gitignored `.env` (local) with NON-PROD dev values in the repo checkout (+ `.env.staging` if staging repro is needed). `wire-env` copies them into worktrees.
- Keep `project.yml` `secrets.required_local` in step with each repo's `.env.example`/`.env.sample`.

## Stand up the squad in Multica
Follow `squad/README.md` → "Setup order".
