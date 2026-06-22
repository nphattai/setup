#!/usr/bin/env bash
# wire-env.sh — assemble + VALIDATE a worktree's runtime env before an agent works.
# GENERIC: all project specifics come from projects/<project>/project.yml via `project-meta`.
#
# Conductor flow (no dotenvx): the per-app env file is a PLAIN, gitignored file the human
# maintains in the source checkout. A fresh `git worktree` doesn't carry gitignored files,
# so wire-env COPIES it into the worktree. Two sources make up a worktree's env:
#   env   : COPY the app's stage file from the source checkout  (local → .env · staging → .env.staging)
#   infra : infractl env  -> .env.infra        non-secret, host-local (backend only)
#
# HARD GATE: every REQUIRED secret for the surface (manifest secrets.required_local[app])
# must resolve NON-EMPTY for the stage, else this BLOCKS and lists the missing names
# (never invents a value). It also WARNs on contract keys absent from the assembled env.
# Validation NEVER prints a secret value: it reads key NAMES from files, and the per-key
# non-empty check tests for a non-empty `KEY=value` line without echoing it.
#
# Usage: wire-env.sh <project> <app> <worktree-dir> [stage]
#   project = a slug under projects/  (a dir holding project.yml)
#   app     = an app name declared in that project's manifest
#   stage   = local (default, .env) | staging (.env.staging)   (.env.prod is OFF-LIMITS to agents)
set -euo pipefail

PROJECT="${1:?usage: wire-env.sh <project> <app> <worktree-dir> [stage]}"
APP="${2:?usage: wire-env.sh <project> <app> <worktree-dir> [stage]}"
WT="${3:?usage: wire-env.sh <project> <app> <worktree-dir> [stage]}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRACTL="$(cd "$HERE/../../infra" && pwd)/infractl"

# Resolve the surface from the manifest (KIND · contract · stage file · REQUIRED · infra key).
eval "$("$HERE/project-meta" "$PROJECT" "$APP" "${4:-}")"
STAGE="${4:-$STAGE_DEFAULT}"
CONTRACT="$APP_CONTRACT"; ENVREL="$APP_STAGEFILE"; KIND="$APP_KIND"
read -r -a REQUIRED <<< "${APP_REQUIRED:-}"

[ -d "$WT" ] || { echo "wire-env: worktree '$WT' not found"; exit 2; }

# 0) COPY the app's stage env file from the source checkout into the worktree. The file is
#    gitignored (plain, human-maintained), so a fresh `git worktree` doesn't carry it. Copy
#    (not symlink) so the worktree is self-contained — edits in a worktree never touch the
#    source's `.env`. If the source file is absent, the HARD GATE below reports it by name.
if [ -n "$ENVREL" ] && [ -n "${APP_REPO_DIR:-}" ] && [ "$WT" != "$APP_REPO_DIR" ]; then
  if [ -f "$APP_REPO_DIR/$ENVREL" ]; then
    mkdir -p "$WT/$(dirname "$ENVREL")"
    cp "$APP_REPO_DIR/$ENVREL" "$WT/$ENVREL" && echo "wire-env: copied $ENVREL from source checkout"
  else
    echo "wire-env: WARN source env '$APP_REPO_DIR/$ENVREL' not found — human must create it (plain, gitignored)."
  fi
fi

# 1) infra vars (backend only). DB is HUMAN-provisioned; fail with guidance if absent.
if [ "$KIND" = backend ]; then
  "$INFRACTL" env "$INFRA_KEY" --write "$WT" \
    || { echo "wire-env: infractl env failed — human must run: infractl db-create $INFRA_KEY"; exit 1; }
  echo "wire-env: wrote $WT/.env.infra (shared infra DB+Redis)"
fi

# key NAMES present in the assembled env (no values emitted)
keys_present() {
  { [ -f "$WT/.env.infra" ] && grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$WT/.env.infra"
    [ -n "$ENVREL" ] && [ -f "$WT/$ENVREL" ] && grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$WT/$ENVREL"
  } 2>/dev/null | sed 's/=$//' | sort -u
}

# is a key set to a NON-EMPTY value? (plain file; never echoes the value)
is_set() {
  local k="$1"
  grep -qE "^${k}=.+" "$WT/$ENVREL" "$WT/.env.infra" 2>/dev/null
}

# 2) HARD GATE — required secrets non-empty
missing=()
for k in "${REQUIRED[@]:-}"; do [ -n "${k:-}" ] || continue; is_set "$k" || missing+=("$k"); done

# 3) completeness WARN — uncommented contract keys absent from the composed env
warn_absent=()
if [ -n "$CONTRACT" ] && [ -f "$WT/$CONTRACT" ]; then
  present="$(keys_present)"
  while IFS= read -r k; do
    printf '%s\n' "$present" | grep -qx "$k" || warn_absent+=("$k")
  done < <(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$WT/$CONTRACT" | sed 's/=$//' | sort -u)
  [ "${#warn_absent[@]}" -gt 0 ] && \
    printf 'wire-env: note (contract keys not in assembled env — optional/unused?): %s\n' "${warn_absent[*]}"
else
  echo "wire-env: WARN contract '${CONTRACT:-<none>}' missing in worktree — cannot check completeness"
fi

if [ "${#missing[@]}" -gt 0 ]; then
  echo "wire-env: ❌ BLOCKED — required env missing/empty for $APP ($STAGE): ${missing[*]}"
  echo "  Human must set these in the source checkout's $ENVREL (plain, gitignored). Agent: report BLOCKED by name, @mention RS-Lead. Never invent a value."
  exit 1
fi

echo "wire-env: ✅ env ready for $APP ($STAGE)."
echo "  Run via: (cd $WT && <cmd>)   # the app auto-loads $ENVREL · FE: nx dev/start $APP · BE: yarn start (:3333)"
