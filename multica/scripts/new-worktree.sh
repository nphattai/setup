#!/usr/bin/env bash
# Create an isolated git worktree for a sub-issue, branched FROM its train, then
# wire + VALIDATE its env (shared infra + copied per-app .env) so an agent can start.
# GENERIC: repo/path/app facts come from projects/<project>/project.yml via `project-meta`.
#
# DB is HUMAN-provisioned (NOT here): run `infractl db-create <key>` once per project.
# Backend worktrees stay SERIALIZED (all share the one project DB).
#
# Usage: new-worktree.sh <project> <app> <TICKET> <slug> <train> [stage]
#   project = a slug under projects/  (a dir holding project.yml)
#   app     = an app name declared in that project's manifest
#   stage   = local (default) | staging
#   e.g.: new-worktree.sh <slug> <fe-app> TICKET-1234 my-slug release-my-slug
set -euo pipefail

[ $# -ge 5 ] || { echo "usage: $0 <project> <app> <TICKET> <slug> <train> [stage]"; exit 1; }
PROJECT=$1; APP=$2; TICKET=$3; SLUG=$4; TRAIN=$5; STAGE=${6:-}
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve PROJ_ROOT + the app's repo dir from the manifest.
eval "$("$HERE/project-meta" "$PROJECT" "$APP" "$STAGE")"
REPO="$APP_REPO_DIR"
[ -d "$REPO" ] || { echo "new-worktree: repo dir not found: $REPO"; exit 1; }

BRANCH="feat/${TICKET}-${SLUG}"
WT="$PROJ_ROOT/wt/${TICKET}-${APP}"

cd "$REPO"
git fetch origin "$TRAIN"
git worktree add -b "$BRANCH" "$WT" "origin/$TRAIN"
echo "Worktree: $WT  (branch $BRANCH from $TRAIN)"
( cd "$WT" && yarn install )   # shares .yarn/cache

# Wire + VALIDATE env (shared infra via infractl + the app's .env copied from the source
# checkout). Fails CLOSED: a missing/empty required var makes wire-env (and this) exit non-zero.
"$HERE/wire-env.sh" "$PROJECT" "$APP" "$WT" "$STAGE"

[ "$APP_KIND" = backend ] && \
  echo "⚠ Backend SERIALIZED: run ONE backend worktree at a time (all share DB $INFRA_KEY)."
