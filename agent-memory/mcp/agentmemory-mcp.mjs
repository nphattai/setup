#!/usr/bin/env node
// agentmemory-mcp — stdio MCP shim over the agentmemory REST API (:3111).
//
// Gives any MCP-capable runtime (Codex, OpenCode, Antigravity `agy`, Claude) two tools:
//   • memory_search — recall prior lessons/observations for the current repo
//   • memory_save   — persist a durable lesson (non-Claude agents; Claude uses hooks)
//
// Project is auto-resolved from cwd via the git common-dir, mirroring the capture
// hooks so linked worktrees collapse to their parent repo bucket (agent-memory
// DECISIONS #15). No new service — this is a thin client over the existing REST API.
//
// Env: AGENTMEMORY_URL (default http://localhost:3111) · AGENTMEMORY_SECRET (optional
//      bearer) · AGENTMEMORY_PROJECT_NAME (force a bucket, overrides git resolution).

import { execSync } from "node:child_process";
import { basename } from "node:path";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const REST_URL = process.env.AGENTMEMORY_URL || "http://localhost:3111";
const SECRET = process.env.AGENTMEMORY_SECRET || "";

function authHeaders() {
  const h = { "Content-Type": "application/json" };
  if (SECRET) h.Authorization = `Bearer ${SECRET}`;
  return h;
}

// Mirror of the capture hooks' resolveProject (scripts/_project.ts): git common-dir
// → real repo name, so a worktree maps to its parent repo, not the worktree folder.
function resolveProject(cwd) {
  const explicit = process.env.AGENTMEMORY_PROJECT_NAME;
  if (explicit && explicit.trim()) return explicit.trim();
  const dir = cwd && cwd.trim() ? cwd : process.cwd();
  try {
    const common = execSync(
      "git rev-parse --path-format=absolute --git-common-dir",
      { cwd: dir, stdio: ["ignore", "pipe", "ignore"], timeout: 500 },
    ).toString().trim();
    if (common) {
      const repo = common.replace(/[/\\]\.git[/\\]?$/, "");
      if (repo && repo !== common) return basename(repo);
    }
  } catch {}
  try {
    const top = execSync("git rev-parse --show-toplevel", {
      cwd: dir,
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 500,
    }).toString().trim();
    if (top) return basename(top);
  } catch {}
  return basename(dir);
}

async function rest(path, body) {
  const res = await fetch(`${REST_URL}${path}`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error(`agentmemory ${path} → HTTP ${res.status}`);
  return res.json();
}

const server = new McpServer({ name: "agentmemory", version: "1.0.0" });

server.registerTool(
  "memory_search",
  {
    title: "Search agent memory",
    description:
      "Recall prior lessons/observations for the current repo before doing real work. " +
      "Returns facts captured across past sessions. Call this at the start of a task.",
    inputSchema: {
      query: z.string().describe("What to recall, e.g. 'how we handled SHP-1234 claims migration'"),
      limit: z.number().int().min(1).max(20).optional().describe("Max results (default 5)"),
      cwd: z.string().optional().describe("Working dir used to resolve the repo bucket (defaults to server cwd)"),
    },
  },
  async ({ query, limit, cwd }) => {
    const project = resolveProject(cwd);
    const out = await rest("/agentmemory/search", { query, project, limit: limit ?? 5 });
    const results = out?.results || [];
    if (!results.length) {
      return { content: [{ type: "text", text: `No memories for "${query}" in project "${project}".` }] };
    }
    const text = results
      .map((r, i) => {
        const o = r.observation || r;
        const concepts = (o.concepts || []).join(", ");
        const facts = (o.facts || []).map((f) => `  - ${f}`).join("\n");
        return `[${i + 1}] (${project})${concepts ? ` concepts: ${concepts}` : ""}\n${facts}`;
      })
      .join("\n\n");
    return { content: [{ type: "text", text }] };
  },
);

server.registerTool(
  "memory_save",
  {
    title: "Save a lesson to agent memory",
    description:
      "Persist a durable, reusable lesson after real work. For non-Claude agents " +
      "(Reviewer/QA/Research) — Claude agents capture automatically via hooks and " +
      "should NOT call this. NEVER save secrets, credentials, or PII.",
    inputSchema: {
      text: z.string().describe("The lesson — concise, reusable, grounded in what happened"),
      tags: z.array(z.string()).optional().describe("Tags, e.g. ['infina-insurance:claims']"),
      cwd: z.string().optional().describe("Working dir used to resolve the repo bucket"),
    },
  },
  async ({ text, tags, cwd }) => {
    const project = resolveProject(cwd);
    await rest("/agentmemory/observe", {
      hookType: "mcp_save",
      sessionId: `mcp_${Date.now().toString(36)}`,
      project,
      cwd: cwd || process.cwd(),
      timestamp: new Date().toISOString(),
      data: { lesson: text, tags: tags ?? [] },
    });
    return {
      content: [{ type: "text", text: `Saved lesson to "${project}"${tags?.length ? ` [${tags.join(", ")}]` : ""}.` }],
    };
  },
);

const transport = new StdioServerTransport();
await server.connect(transport);
