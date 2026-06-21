---
name: safe-refactor
description: Behavior-preserving refactors only. Pin current behavior with a characterization test FIRST, then restructure without changing any observable contract or scope.
---

# safe-refactor

> Builder discipline. Generic (any stack). Used by RS-Builder.

## When to use
Restructuring code for clarity/maintainability where the externally observable behavior must NOT
change (no new feature, no bug fix bundled in).

## The rule
A refactor that changes behavior is not a refactor — it's an undocumented change. Prove sameness.

## Steps
1. **Characterize first.** Before editing, add/confirm a test that captures the *current* observable
   behavior (inputs → outputs, including the edge you're about to touch). It must be green now.
2. **Restructure in small steps.** Rename/extract/inline/move — one mechanical change at a time,
   re-running tests between steps. Keep public contracts identical: function signatures, exported
   types, API responses, DB schema, env vars, config keys.
3. **No scope creep.** Do not fix bugs, add features, change deps, or "improve" untouched code in the
   same diff. If you find a real bug, file it separately (root-cause-first) — don't smuggle it in.
4. **Diff review.** The change should read as pure restructuring. If a reviewer can't tell behavior
   is preserved from the diff + tests, add the missing characterization.

## Red flags (stop, split the work)
- A test had to change its *assertions* (not just its imports/structure) → behavior changed.
- A public signature/type/schema/contract moved → call it out; likely needs Lead/human review.
- The diff touches files unrelated to the structure you set out to change.

## Done when
All pre-existing + characterization tests pass unchanged, no contract moved, diff is restructure-only.
