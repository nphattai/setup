# Architecture overview

One picture of the whole `setup` workspace, then pointers into each domain's detailed docs.
The split is deliberate: **generic engines + a reusable template** on one side, **concrete projects**
that instantiate them on the other (see the root [README](README.md)).

## The big picture

How the two always-on **engines**, the **template**, and a concrete **project** fit together on one Mac.

```mermaid
flowchart TB
    subgraph HOST["🖥️  One Mac (host)"]
        direction TB

        subgraph ENG["Engines — generic, always-on"]
            direction LR
            INFRA["infra/<br/><b>infractl</b><br/>shared Postgres + Redis"]
            MEM["agent-memory/<br/><b>agentmemory</b> container<br/>+ MCP shim"]
        end

        subgraph TMPL["Template — generic, no project lives here"]
            MULTICA["multica/<br/>squad blueprint · doc templates<br/>manifest-driven scripts"]
        end

        subgraph PROJ["projects/aaa — first concrete instance"]
            direction TB
            MANIFEST["project.yml<br/><i>single source of truth</i>"]
            SQUAD["squad/ — 5 rendered agent docs<br/>(RS-Lead/Builder/Reviewer/QA/Research)"]
            WT["worktrees<br/>feat/SHP-####-…"]
        end
    end

    MULTICA -- "render templates → " --> SQUAD
    MANIFEST -- "drives scripts (slug → repos/db/env)" --> MULTICA
    MULTICA -- "new-worktree + wire-env" --> WT
    INFRA -- ".env.infra (DATABASE_URL · REDIS_URL)" --> WT
    SQUAD -- "agents run in" --> WT
    WT -- "Claude Code hooks capture sessions" --> MEM

    classDef engine fill:#e8eaf6,stroke:#3f51b5,color:#1a237e;
    classDef tmpl fill:#e0f2f1,stroke:#00897b,color:#004d40;
    classDef proj fill:#fff3e0,stroke:#fb8c00,color:#e65100;
    class INFRA,MEM engine;
    class MULTICA tmpl;
    class MANIFEST,SQUAD,WT proj;
```

**Read it as:** the manifest (`projects/<slug>/project.yml`) parameterises Multica's generic scripts;
those render the squad docs and spin up worktrees; the shared infra engine injects DB/Redis env into
each worktree; agents work there and their Claude Code sessions are captured by the memory engine.

## Repository map — engine vs template vs project

```mermaid
flowchart LR
    ROOT["setup/"]
    ROOT --> I["infra/ — ENGINE<br/><small>shared PG+Redis for the whole host</small>"]
    ROOT --> M["multica/ — TEMPLATE<br/><small>squad blueprint + scripts (generic)</small>"]
    ROOT --> A["agent-memory/ — ENGINE<br/><small>memory service + cross-runtime MCP</small>"]
    ROOT --> P["projects/&lt;slug&gt;/ — INSTANCE<br/><small>everything project-specific</small>"]
    P --> AAA["aaa/ (first instance)<br/><small>project.yml · squad/ · infra-profile.yaml · integration.md</small>"]

    classDef engine fill:#e8eaf6,stroke:#3f51b5,color:#1a237e;
    classDef tmpl fill:#e0f2f1,stroke:#00897b,color:#004d40;
    classDef proj fill:#fff3e0,stroke:#fb8c00,color:#e65100;
    class I,A engine;
    class M tmpl;
    class P,AAA proj;
```

**The rule:** template/engine dirs stay pure and generic; concrete identifiers appear only inside
`projects/<slug>/`. Scripts are project-parameterised (take a `<slug>`, read the manifest) — never copied per project.

## The runtime hierarchy

One host carries many projects; each project is one squad over one isolated slice of shared infra.

```mermaid
flowchart TD
    H["HOST — one Mac<br/>shared infra: 1 Postgres + 1 Redis (infractl)"]
    H --> P1["PROJECT a (project.yml)<br/>= dedicated DB + Redis prefix"]
    H --> P2["PROJECT b …<br/>= dedicated DB + Redis prefix"]
    P1 --> S1["SQUAD (5 agents)"]
    S1 --> W1["WORKTREE per task<br/>feat branch + composed env"]
    S1 --> W2["WORKTREE per task<br/>feat branch + composed env"]

    classDef host fill:#ede7f6,stroke:#5e35b1,color:#311b92;
    class H host;
```

> Isolation is **logical**: Postgres enforces a database per project; Redis is a per-project key
> prefix the app applies. Backend worktrees of one project share its DB → backend work serialises
> (a deliberate v1 trade-off with a free per-worktree upgrade path). See
> [infra high-level design](infra/docs/design/highlevel-design.md).

## Where to go next

| Domain | Start here | Deep dives |
|---|---|---|
| **Infra engine** | [infra/README](infra/README.md) | [high-level design](infra/docs/design/highlevel-design.md) · [ADR 0001](infra/docs/decisions/0001-shared-instance-logical-isolation.md) |
| **Multica template** | [multica/README](multica/README.md) | [high-level design](multica/docs/design/highlevel-design.md) · [env & execution flow](multica/docs/design/env-and-execution-flow.md) · [runtime & capacity](multica/docs/design/runtime-and-capacity.md) · [decisions](multica/docs/decisions/DECISIONS.md) |
| **Agent-memory engine** | [agent-memory/README](agent-memory/README.md) | [architecture](agent-memory/docs/architecture.md) · [runbook](agent-memory/docs/runbook.md) · [LLM backend](agent-memory/docs/llm-backend.md) |
| **Project aaa** | [projects/aaa/README](projects/aaa/README.md) | [infra integration](projects/aaa/integration.md) · [squad setup](projects/aaa/squad/README.md) |

The diagrams for each domain (infra topology, squad git-flow & gates, the 3-source env model, the
memory data flow) live inside those domain docs — linked above and rendered inline on this site.
