#!/usr/bin/env bash
# Bring up the local stack on the SHARED dev infra (DECISIONS #16) for a project.
# GENERIC: repo facts come from projects/<project>/project.yml via `project-meta`.
# Do NOT run the repos' own `yarn setup-local` — it spawns a second Postgres/Redis that
# clashes with the shared stack on 5432/6379. This points the repos at shared infra.
# Apps auto-load their plain, gitignored `.env` (local stage) — no secret injector wrapper.
#
# Usage: start-local-stack.sh <project>
set -euo pipefail

PROJECT="${1:?usage: start-local-stack.sh <project>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRACTL="$(cd "$HERE/../../infra" && pwd)/infractl"

eval "$("$HERE/project-meta" "$PROJECT")"   # -> PROJ_ROOT INFRA_KEY REPOS

echo "== Shared infra: one Postgres + one Redis (127.0.0.1:5432/6379) =="
"$INFRACTL" up
"$INFRACTL" db-create "$INFRA_KEY"

IFS=';' read -r -a repos <<< "${REPOS:-}"
for tuple in "${repos[@]:-}"; do
  [ -n "$tuple" ] || continue
  IFS='|' read -r rtype rdir rname <<< "$tuple"
  if [ "$rtype" = backend ]; then
    echo "== Backend ($rname): point at shared infra + migrate =="
    "$INFRACTL" env "$INFRA_KEY" --write "$rdir"     # writes $rdir/.env.infra
    ( cd "$rdir" && yarn migration-run ) || echo "  (migrations skipped/failed — check)"
    echo "  Start the API in another shell:  (cd $rdir && yarn start)   # :3333"
  else
    echo "== Frontend ($rname): regen API types against local BE, then dev =="
    ( cd "$rdir" && USER_API_URL=http://localhost:3333 ADMIN_API_URL=http://localhost:3333 yarn gen:api ) \
      || echo "  (gen:api needs BE running on :3333 first)"
    echo "  Start an app:  (cd $rdir && nx dev <app>)   # use the repo's nx project name; mobile: nx start <app>"
  fi
done
echo
echo "Shared-infra local stack staged for '$PROJECT'. Bring up the API + the app you need, then assign work in Multica."
