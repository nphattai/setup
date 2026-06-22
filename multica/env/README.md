# Env & Secrets

**NON-PROD only.** Agents never receive production secrets. Values here are local/dev/test creds.

## Model (constitution §Secret & env management)
- Human provisions the host env once with dev creds.
- **Conductor flow — no injector.** Each app's stage env is a **plain, gitignored file** in the repo checkout: `local` → `.env`, `staging` → `.env.staging`. `scripts/wire-env.sh <project> <app> <wt> [stage]` **copies** it into the worktree and runs the completeness hard gate; the app **auto-loads** `.env` at run time (no `dotenvx run` wrapper, no `.env.keys`).
- Agents may RUN env-consuming commands; **never** print/echo/commit a secret value. Missing var → report by NAME, escalate.

## Files
- `webapp.env.example` — vars the FE apps + codegen need.
- `services.env.example` — vars the BE needs locally.
Copy to the app's real (git-ignored) `.env`; fill with dev values.

## PII
`make rehearse` restores a staging dump (customer PII) locally for data-bug repro. Local-only; never export/paste rows; never rehearse against prod.
