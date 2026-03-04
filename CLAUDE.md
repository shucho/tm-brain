# Project: T&M Brain

## What This Is
Organizational memory system for Trick and Mortar (T&M). Three-table knowledge graph (memories + entities + edges) with semantic search, exposed via MCP server. No frontend — headless brain that other tools connect to.

## Design Doc
`docs/plans/2026-03-04-tm-brain-design.md` — **read this first.** It contains the full schema, MCP tool specs, ingest pipeline design, and repo structure.

## Stack
- TypeScript
- Postgres 16 + pgvector (Supabase or self-hosted on TrueNAS)
- `@modelcontextprotocol/sdk` (MCP server, stdio + SSE)
- `pg` or Drizzle ORM for database access
- Vitest for testing
- Express or Hono for HTTP ingest endpoint

## Commands
```bash
npm run dev          # Dev server (MCP stdio mode)
npm run dev:http     # HTTP ingest server
npm run typecheck    # MUST pass before commit
npm run lint         # MUST pass before commit
npm run test         # MUST pass before commit
npm run migrate      # Run SQL migrations against DATABASE_URL
```

## Framework
@stigwheel.md — full Stigwheel framework reference

## Stigwheel Locations
- Patterns: `.patterns/*.anchor.yaml`
- Specs: `specs/*.md`
- Plan: `claude/PLAN.md`
- Rules: `.claude/rules/`

## Quick Patterns
<!-- One-line reminders only. Details in .patterns/ -->
- MCP tools: Zod schema for input, registered on MCP server instance
- DB queries: parameterized SQL via pg client, vector ops via pgvector
- Ingest adapters: normalize source event → common format → pipeline

## Key Architecture Decisions
- **Three tables + junction**: `memories`, `entities`, `edges`, `memory_entities` — no table-per-source sprawl
- **Entity extraction at ingest time**: LLM pass extracts entities/relationships when memories are stored, not at query time
- **Semantic entity resolution**: entities have their own embedding vectors for dedup ("Christine from AFS" = "Christine AFS")
- **Confidence scoring on edges**: LLM-inferred relationships start at 0.5-0.7, reinforced by co-occurrence
- **JSONB escape valves**: `meta` on memories, `attributes` on entities for source-specific data

## Conventions
- Frontmatter: `@anchor`, `@spec`, `@task`, `@validated` on every source file
- Commits: `feat(TASK-XXX): description` + `Implements:`, `Pattern:`, `Validates:` trailers
- Validation: done, partial, not started
- Branches: `feature/TASK-XXX-description` or `fix/TASK-XXX-description`
