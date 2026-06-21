# Env & Secrets

**NON-PROD only.** Agents never receive production secrets. Values here are local/dev/test creds.

## Model (constitution §Secret & env management)
- Human provisions the host env once with dev creds.
- Inject via a wrapper so plaintext never sits in a readable file. **Injector = dotenvx** (settled): `dotenvx run -f .env.<stage> -- <cmd>` — encrypted `.env.<stage>` is commit-safe; only `.env.keys` (gitignored) is host-local. The completeness hard gate is `scripts/wire-env.sh <project> <app> <wt> [stage]`.
- Agents may RUN env-consuming commands; **never** print/echo/commit a secret value. Missing var → report by NAME, escalate.

## Files
- `webapp.env.example` — vars the FE apps + codegen need.
- `services.env.example` — vars the BE needs locally.
Copy to the real (git-ignored) location your injector reads; fill with dev values.

## PII
`make rehearse` restores a staging dump (customer PII) locally for data-bug repro. Local-only; never export/paste rows; never rehearse against prod.
