---
name: inf-e2e-mobile-maestro
description: Scaffold and run Maestro E2E flows for the React Native app on a LOCAL iOS sim / Android emulator. Mobile E2E must be green locally BEFORE merge (merge triggers the EAS build).
---

# inf-e2e-mobile-maestro

> Project: aaa. Used by RS-QA. App: `apps/nomi-mobile` (Expo / React Native) in
> `infina-insurance-partner-webapp`. Maestro is NOT set up yet — first task is to scaffold it.

## When to use
Any mobile (`nomi-mobile`) acceptance criterion needing E2E validation, pre-merge.

## Prereqs (host)
- `brew install maestro` (or `curl -fsSL https://get.maestro.mobile.dev | bash`).
- iOS Simulator (Xcode) and/or Android emulator (Android Studio) booted.
- A local dev build of the app installed on the sim/emulator.

## Scaffold (first time)
1. Create `apps/nomi-mobile/.maestro/` with one flow per critical journey (`<flow>.yaml`):
   `appId`, `launchApp`, then `tapOn` / `assertVisible` / `inputText` steps.
2. Add a short `apps/nomi-mobile/.maestro/README.md` runbook (how to boot a sim, build, run flows).
3. Keep flows data-light and deterministic; no real PII, no prod endpoints.

## Run (per feat, pre-merge)
1. Boot the sim/emulator; install the local build.
2. The app's chat AI routes through the **local BE** (`${API_ORIGIN}/api/copilotkit`) — the device
   holds NO OpenAI key. Ensure the local BE (:3333) is up + wired (`new-worktree.sh` / `wire-env.sh`).
3. `maestro test apps/nomi-mobile/.maestro/<flow>.yaml` (or the whole dir). Capture the run output.
4. **Green LOCALLY is the merge gate.** Merging is what triggers the downstream EAS build — never
   spend an EAS build on un-QA'd code.

## On a bug
Write the minimal failing flow (red on demand) + repro steps, set the sub-issue Blocked, hand back to
RS-Builder (@mention). Never edit production code.

## Done when
The feat's mobile journeys pass locally on a sim/emulator with evidence (run tail), pre-merge.
