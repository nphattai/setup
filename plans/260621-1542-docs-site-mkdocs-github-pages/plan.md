# Plan — Docs website (MkDocs Material + Mermaid → GitHub Pages)

**Created:** 2026-06-21 15:42 · **Slug:** docs-site-mkdocs-github-pages · **Mode:** /cook --auto (user reviews final output)
**Status:** ✅ DONE (2026-06-21) — all artifacts built; `mkdocs build --strict` exit 0 (46 pages, 11 Mermaid diagrams); code-review clean (no blockers). Remaining: owner sets `site_url`/`repo_url` in `mkdocs.yml` once the GitHub remote exists, then enable Pages (Settings → Pages → branch `gh-pages`).

## Goal
A static documentation website that renders **all published `.md`** of `~/Work/setup` natively,
adds **Mermaid diagrams** for high-level architecture/design, and deploys to **GitHub Pages**.

## Locked decisions (user-approved)
- **Tooling:** MkDocs Material. Mermaid via Material's native `pymdownx.superfences` (no extra plugin).
- **Source layout:** `mkdocs-same-dir` plugin → `docs_dir = repo root`, so existing **relative cross-links keep working** and source docs are edited in place (no copying).
- **Diagrams:** Mermaid text in markdown (diffable, renders on GitHub *and* the site).
- **Scope:** include infra / multica / agent-memory / projects-aaa docs (READMEs, design, ADRs, runbooks, skills, squad docs, templates). **Exclude** `plans/`, `plans/reports/`, runtime state (`agent-memory/data`, `agentmemory-home`), node deps, dotfiles.
- **Deploy:** GitHub Action builds on push to `main` → publishes to `gh-pages` branch. `main` stays source-only.

## Expected output (artifacts)
1. `mkdocs.yml` (root) — theme, full nav tree, mermaid, search, exclusions.
2. `requirements-docs.txt` — pinned `mkdocs-material`, `mkdocs-same-dir`.
3. `.github/workflows/docs.yml` — build + deploy to `gh-pages`.
4. `ARCHITECTURE.md` (root) — site-wide overview + master system-topology Mermaid diagram, links into each domain.
5. Mermaid diagrams embedded into the existing high-level docs (replace ASCII art where Mermaid is clearly better):
   - `infra/docs/design/highlevel-design.md` — shared-infra topology + logical isolation.
   - `multica/docs/design/highlevel-design.md` — orchestration (planning-hub + kanban-pull), 3-layer governance, release-train git flow, per-feature workflow gates.
   - `multica/docs/design/env-and-execution-flow.md` — host→project→squad→worktree hierarchy, 3-source composed env, task→QA sequence.
   - `agent-memory/docs/architecture.md` — capture-hooks → engine → embeddings + LLM enrichment data flow.
6. `README.md` (root) — add a one-line pointer to the site + ARCHITECTURE.md.

## Acceptance criteria
- `mkdocs build --strict` succeeds (no broken nav refs / links).
- Every included `.md` reaches the site via nav; `plans/` + runtime state excluded.
- Mermaid blocks render (Material picks up `mermaid` fenced class).
- Existing relative links between docs still resolve on the built site.
- Pushing to `main` triggers the Action → `gh-pages` published; Pages serves it.

## Out of scope
- Rewriting doc prose, versioned docs, blog, search analytics, custom domain.
- Editing scripts / infra / app code. Diagrams only enrich docs.

## Touchpoints / blast radius
- New files: `mkdocs.yml`, `requirements-docs.txt`, `.github/workflows/docs.yml`, `ARCHITECTURE.md`.
- Modified docs (additive — Mermaid replacing ASCII): the 4 design docs above + root README pointer. No code, no script, no contract touched.

## Steps
1. Scaffold config: `mkdocs.yml`, `requirements-docs.txt`, Action.
2. Author `ARCHITECTURE.md` (master diagram + domain map).
3. Embed Mermaid into the 4 design docs.
4. Root README pointer.
5. Verify: local `mkdocs build --strict` in a venv (fallback: CI builds if local Python too old).
6. code-reviewer subagent → acceptance + no-regression check.
7. Finalize: docs-manager sync, journal, offer commit.

## Risks
- `docs_dir=root` copying junk → mitigated by `exclude_docs` (plans, data, node deps, build output).
- System Python 3.9 may not run newest mkdocs-material → pin compatible version; CI uses 3.12 regardless.
- README-as-index handling → nav references exact file paths, Home → `README.md`.
