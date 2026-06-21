---
name: root-cause-first
description: Force a deterministic failing repro (red-on-demand) BEFORE any code change when fixing a bug or failing test. A patch before a repro is a guess.
---

# root-cause-first

> Builder discipline. Generic (any stack). Used by RS-Builder.

## When to use
Any bug fix, failing test, or "it's broken" report — before you touch product code.

## The rule
**No patch without a red-on-demand repro.** If you cannot make it fail on command, you do not
understand it yet — and a fix is a guess that will regress.

## Steps
1. **Reproduce deterministically.** Write or find the smallest test/command that fails *because of
   this bug*, every run. Capture the exact failing output (assertion, stack, status code).
2. **Locate the cause, not the symptom.** Trace from the failure to the line that is actually wrong.
   Name the root cause in one sentence ("X returns null when Y is empty, so Z throws").
3. **Confirm the boundary.** Show the same input one level up still behaves — prove you've found the
   real edge, not a coincidence.
4. **Fix the smallest thing.** Change only what the root cause requires. Re-run the repro → green.
5. **Guard it.** Keep the failing test (now passing) so the bug can't silently return.

## HALT ladder (can't reproduce)
1. Re-read the report + any logs/inputs; try the exact stated conditions.
2. Vary one factor at a time (env, data, timing, stage).
3. Add targeted instrumentation (log/trace) — never `cat`/print a secret value.
4. Still no repro after a bounded effort → set the sub-issue **Blocked**, post what you tried and
   what you need (data, repro steps, a staging dump), @mention RS-Lead. **Do not guess-patch.**

## Done when
The bug fails on demand before the change, passes after, and a regression guard remains.
