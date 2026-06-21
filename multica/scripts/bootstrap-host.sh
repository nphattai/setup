#!/usr/bin/env bash
# Pre-flight check for the agent-host Mac. Verifies runtimes + QA toolchain. Idempotent-ish.
set -euo pipefail

ok(){ printf "  \033[32m✓\033[0m %s\n" "$1"; }
miss(){ printf "  \033[31m✗\033[0m %s\n" "$1"; }
have(){ command -v "$1" >/dev/null 2>&1; }

echo "== Runtimes (CLI + auth) =="
for c in claude codex opencode gh node yarn docker; do
  have "$c" && ok "$c installed" || miss "$c MISSING"
done
# RS-Research: Antigravity CLI `agy` replaces the deprecated Gemini CLI (sign-in disabled 2026-06-18)
have agy && ok "agy (Antigravity CLI) installed" || miss "agy MISSING → curl -fsSL https://antigravity.google/cli/install.sh | bash ; add ~/.local/bin to PATH"
have gh && (gh auth status >/dev/null 2>&1 && ok "gh authed" || miss "gh NOT authed")

echo "== QA toolchain =="
# NB: mobile.dev Maestro (the mobile-UI E2E CLI) is NOT the Homebrew `maestro` cask
# (that's runmaestro.ai, an unrelated GUI). Install via the official script + add ~/.maestro/bin to PATH.
if have maestro && maestro --version >/dev/null 2>&1; then ok "maestro ($(command -v maestro))";
  else miss 'maestro CLI MISSING → curl -fsSL https://get.maestro.mobile.dev | bash ; add ~/.maestro/bin to PATH'; fi
have xcrun && ok "Xcode tools" || miss "Xcode MISSING (iOS sim)"
have adb && ok "Android platform-tools" || miss "Android emulator tooling MISSING"
# Playwright browsers are per-repo (npx playwright install inside webapp)

echo "== Secret injector (pick one) =="
for c in dotenvx doppler op; do have "$c" && ok "$c available"; done

echo "== Manifest tooling (scripts read projects/<slug>/project.yml) =="
have python3 && ok "python3" || miss "python3 MISSING (project-meta needs it)"
python3 -c 'import yaml' 2>/dev/null && ok "PyYAML" || miss "PyYAML MISSING → pip3 install pyyaml"

echo
echo "Next: auth each runtime (claude/codex/opencode login + 'agy login'), subscribe OpenCode Go,"
echo "then run scripts/start-local-stack.sh <project>   (a slug under projects/)"
