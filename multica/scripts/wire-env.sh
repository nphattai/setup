#!/usr/bin/env bash
# wire-env.sh — compose + VALIDATE a worktree's runtime env before an agent works.
# GENERIC: all project specifics come from projects/<project>/project.yml via `project-meta`.
#
# Env is composed at run time from three sources (never one big secret file):
#   infra   : infractl env  -> .env.infra        non-secret, host-local (backend only)
#   config  : the repo's committed defaults in the stage file
#   secret  : dotenvx-encrypted .env.<stage>     human-maintained values
#
# HARD GATE: every REQUIRED secret for the surface (manifest secrets.required_local[app])
# must resolve NON-EMPTY for the stage, else this BLOCKS and lists the missing names
# (never invents a value). It also WARNs on contract keys absent from the composed env.
# Validation NEVER prints a secret value: it reads key NAMES from files, and the per-key
# non-empty check tests `dotenvx get`'s output without echoing it.
#
# Usage: wire-env.sh <project> <app> <worktree-dir> [stage]
#   project = a slug under projects/  (a dir holding project.yml)
#   app     = an app name declared in that project's manifest
#   stage   = local (default) | staging   (.env.prod is OFF-LIMITS to agents)
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

# 0) wire secret material from the source checkout into the worktree. Teams typically gitignore
#    `.env.*`, so the encrypted stage file + its `.env.keys` do NOT travel with a fresh `git worktree`
#    checkout — symlink them from the source repo (one source of truth; key rotations propagate).
if [ -n "$ENVREL" ] && [ -n "${APP_REPO_DIR:-}" ] && [ "$WT" != "$APP_REPO_DIR" ]; then
  appdir="$(dirname "$ENVREL")"
  for rel in "$ENVREL" "$appdir/.env.keys"; do
    if [ -e "$APP_REPO_DIR/$rel" ] && [ ! -e "$WT/$rel" ]; then
      mkdir -p "$WT/$(dirname "$rel")"
      ln -s "$APP_REPO_DIR/$rel" "$WT/$rel" && echo "wire-env: linked $rel from source checkout"
    fi
  done
fi

# 1) infra vars (backend only). DB is HUMAN-provisioned; fail with guidance if absent.
if [ "$KIND" = backend ]; then
  "$INFRACTL" env "$INFRA_KEY" --write "$WT" \
    || { echo "wire-env: infractl env failed — human must run: infractl db-create $INFRA_KEY"; exit 1; }
  echo "wire-env: wrote $WT/.env.infra (shared infra DB+Redis)"
fi

# key NAMES present in the composed env (no values emitted)
keys_present() {
  { [ -f "$WT/.env.infra" ] && grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$WT/.env.infra"
    [ -n "$ENVREL" ] && [ -f "$WT/$ENVREL" ] && grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$WT/$ENVREL"
  } 2>/dev/null | sed 's/=$//' | sort -u
}

# is a key set to a NON-EMPTY value? (never echoes the value)
is_set() {
  local k="$1" v=""
  if command -v dotenvx >/dev/null 2>&1 && [ -n "$ENVREL" ] && [ -f "$WT/$ENVREL" ]; then
    v="$(cd "$WT" && dotenvx get "$k" -f "$ENVREL" 2>/dev/null || true)"
  fi
  [ -n "$v" ] && return 0
  # fallback (pre-dotenvx plain file, or infra var): a non-empty `KEY=value` line
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
    printf 'wire-env: note (contract keys not in composed env — optional/unused?): %s\n' "${warn_absent[*]}"
else
  echo "wire-env: WARN contract '${CONTRACT:-<none>}' missing in worktree — cannot check completeness"
fi

if [ "${#missing[@]}" -gt 0 ]; then
  echo "wire-env: ❌ BLOCKED — required env missing/empty for $APP ($STAGE): ${missing[*]}"
  echo "  Human must set these in $ENVREL (dotenvx). Agent: report BLOCKED by name, @mention RS-Lead. Never invent a value."
  exit 1
fi

echo "wire-env: ✅ env ready for $APP ($STAGE)."
echo "  Run via: (cd $WT && dotenvx run -f $ENVREL -- <cmd>)   # FE: nx dev/start $APP · BE: yarn start (:3333)"
