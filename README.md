# setup — Multi-agent dev workspace (template + projects)

Host workspace for running AI-agent squads on local dev infra. Split into **generic, reusable
templates/engines** and **concrete projects** that instantiate them.

```
setup/
├── infra/        ENGINE — one shared Postgres + Redis for the whole host (infractl). Generic.
├── multica/      TEMPLATE — the AI-agent squad blueprint: design docs, squad-doc templates,
│                 manifest-driven scripts. Generic; no project lives here.
├── agent-memory/ ENGINE — local memory service + the cross-runtime MCP shim. Generic.
└── projects/
    └── <slug>/   ONE concrete project — bounds everything project-specific:
                  project.yml (SoR manifest) · squad/ (rendered squad docs) ·
                  infra-profile.yaml · integration.md.   First instance: aaa/
```

## The rule
- **Template/engine dirs (`infra`, `multica`, `agent-memory`) stay pure and generic.** Concrete
  identifiers appear only as the flagged **`aaa`** worked example.
- **`projects/<slug>/` holds everything bounded to a project** — the manifest, the rendered squad
  docs you paste into Multica, the infra profile, the integration notes.
- **Scripts are project-parameterized**, not copied per project: they take a `<slug>` and read
  `projects/<slug>/project.yml` via `multica/scripts/project-meta`.

## Start here
- **Whole-system picture (diagrams)** → [`ARCHITECTURE.md`](ARCHITECTURE.md).
- New to this repo → `multica/README.md` (the squad blueprint) + `infra/README.md` (the stack).
- Instantiate a project → `multica/docs/templates/README.tmpl.md` → "Instantiate a new project".
- The live project → `projects/aaa/README.md`.

## Docs website
All published docs render as a navigable, diagrammed site (MkDocs Material + Mermaid), deployed to
GitHub Pages. Build/preview locally:
```bash
pip install -r requirements-docs.txt
mkdocs serve            # http://127.0.0.1:8000
```
Pushing to `main` builds and publishes to the `gh-pages` branch via `.github/workflows/docs.yml`
(one-time: GitHub → Settings → Pages → source = `gh-pages` branch). Config: `mkdocs.yml`.
