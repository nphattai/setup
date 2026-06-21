---
name: builder-dev-loop
description: The implement→verify→iterate discipline for an Nx+yarn monorepo. One acceptance criterion at a time; never batch-implement and test once at the end.
---

# builder-dev-loop

> Builder discipline (optional but recommended). Targets the Nx+yarn squad stack. Used by RS-Builder.

## When to use
Implementing any sub-issue with multiple acceptance criteria (AC-1, AC-2, …).

## The loop (per AC, in order)
1. **Read the AC + spec.** The parent tech spec is NOT auto-injected — open it. Restate the AC as a
   concrete expected behavior.
2. **Smallest change** that satisfies just this AC. Reuse an existing util/lib; never add a dep to
   pass an AC. Match `code-standards.md` + existing patterns. Surgical diff, no drive-by refactors.
3. **Verify this AC** before moving on:
   - Webapp: `yarn test` (vitest) for the touched app, `nx lint <app>`, `nx typecheck`.
   - Services: `nx test <be-app>` / `yarn verify`.
4. **Next AC.** Repeat. Do not accumulate untested changes.

## Definition of Done (before flipping to In-Review)
- Every AC met + cited by id.
- Webapp: `yarn test` green · `nx lint <app>` clean · `nx typecheck` clean · if BE-facing types
  changed → `yarn gen:api` re-run + regenerated files committed (see `inf-api-contract`).
- Services: `yarn verify` green · schema changes only via `yarn migration-generate`/`migration-create`
  (never hand-edit migrations).
- Run everything through the injector: `dotenvx run -f .env.<stage> -- <cmd>`. Never print a secret value.
- Push the feat branch (don't open the train PR — that's RS-Lead). Paste the test/typecheck tail as proof.

## Anti-patterns
- "I'll test at the end" → you'll debug a pile of changes at once.
- Implementing AC-2's nice-to-have while on AC-1 → scope creep.
- Asserting DONE without pasting passing output → prove, don't claim.
