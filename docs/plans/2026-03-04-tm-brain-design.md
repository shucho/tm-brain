# T&M Brain: Organizational Memory System

> Design document for an organizational knowledge graph and semantic memory layer for Trick and Mortar (T&M), a video production company. This system is the shared brain that all T&M AI tools connect to.

## Problem

T&M generates knowledge across many tools: Fathom meeting transcripts, Pipedrive deal state, Trello project cards, Slack threads, Evernote SOPs, Ramp transactions. Today this knowledge is siloed per tool. There's no way to ask "show me everything about this client across all systems" or "who are the decision-makers at AFS?" without manually checking each tool.

Jones' Open Brain (single `thoughts` table with embeddings) solves this for one person's stream of consciousness. For an organization with structurally different data types (narrative, transactional, procedural), a flat table loses the ability to traverse relationships. "Everything about this client" becomes a vector similarity guess rather than a graph walk.

## Solution

Three tables and a junction, exposed via MCP server. Semantic search (vector) + relational graph (entity/edge traversal) in one Postgres instance.

## Architecture Overview

```
                    ┌─────────────────┐
                    │   MCP Server    │
                    │  (stdio/SSE)    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼──┐   ┌──────▼─────┐   ┌────▼────────┐
    │ pricing-   │   │  Claude    │   │  n8n /      │
    │ bot-v2     │   │  Desktop   │   │  webhooks   │
    │ (MCP       │   │  (MCP      │   │  (HTTP →    │
    │  client)   │   │   client)  │   │   ingest)   │
    └────────────┘   └────────────┘   └─────────────┘
                             │
                    ┌────────▼────────┐
                    │  Postgres 16   │
                    │  + pgvector    │
                    │  (Supabase or  │
                    │   self-hosted) │
                    └─────────────────┘
```

### Consumers

| Consumer | Protocol | Operations |
|----------|----------|------------|
| pricing-bot-v2 | MCP (stdio or SSE) | Read: search memories, get entity graph. Write: store memories from chat sessions |
| Claude Desktop | MCP (stdio) | Read/write: ad-hoc queries, manual memory entry |
| n8n workflows | HTTP → ingest endpoint | Write: Fathom transcripts, Pipedrive events, Trello updates, Slack threads, Ramp transactions |

## Data Model

### Table: `memories`

The semantic layer. Every ingestible event from any source lands here.

```sql
CREATE TABLE memories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content         TEXT NOT NULL,
    embedding       VECTOR(1536),
    kind            TEXT NOT NULL,       -- transcript, deal_event, card_update, sop, message, note, financial
    source_system   TEXT,                -- fathom, pipedrive, trello, slack, evernote, ramp, manual
    source_id       TEXT,                -- external ID for dedup/backlinking
    meta            JSONB DEFAULT '{}',  -- source-specific data (deal_value, card_id, channel, etc.)
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_memories_embedding ON memories USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_memories_kind ON memories (kind);
CREATE INDEX idx_memories_source ON memories (source_system);
CREATE INDEX idx_memories_source_id ON memories (source_system, source_id);
CREATE INDEX idx_memories_meta ON memories USING gin (meta);
CREATE INDEX idx_memories_created ON memories (created_at DESC);
```

**kind values:** `transcript`, `deal_event`, `card_update`, `sop`, `message`, `note`, `financial`

**source_system values:** `fathom`, `pipedrive`, `trello`, `slack`, `evernote`, `ramp`, `manual`

**Deduplication:** `(source_system, source_id)` uniquely identifies an external event. On upsert, update content/embedding/meta if source_id already exists.

### Table: `entities`

Graph nodes. The nouns of T&M's world.

```sql
CREATE TABLE entities (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type     TEXT NOT NULL,       -- person, org, project, tool, venue, concept
    canonical_name  TEXT NOT NULL,
    embedding       VECTOR(1536),        -- for semantic entity resolution
    attributes      JSONB DEFAULT '{}',  -- flexible properties (email, role, pipedrive_id, etc.)
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(entity_type, canonical_name)
);

CREATE INDEX idx_entities_embedding ON entities USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_entities_type ON entities (entity_type);
CREATE INDEX idx_entities_name ON entities (canonical_name);
CREATE INDEX idx_entities_attributes ON entities USING gin (attributes);
```

**entity_type values:** `person`, `org`, `project`, `tool`, `venue`, `concept`

**Semantic entity resolution:** When ingesting "Christine from AFS" and "Christine AFS", compute embedding similarity against existing entities of type `person`. If similarity > threshold (0.92), merge rather than create new. The embedding on the entity enables this without maintaining an alias table.

**attributes examples:**
- Person: `{ "email": "...", "role": "producer", "pipedrive_id": 12345 }`
- Org: `{ "industry": "healthcare", "address": "...", "pipedrive_org_id": 678 }`
- Project: `{ "trello_board_id": "abc", "status": "active", "budget": 50000 }`

### Table: `edges`

Graph relationships. The verbs connecting entities.

```sql
CREATE TABLE edges (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_entity   UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    target_entity   UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    relationship    TEXT NOT NULL,       -- works_for, manages, decision_maker, freelances_on, client_of, etc.
    confidence      REAL DEFAULT 1.0,    -- 0.0-1.0, LLM-inferred edges start lower
    attributes      JSONB DEFAULT '{}',  -- relationship-specific metadata
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(source_entity, target_entity, relationship)
);

CREATE INDEX idx_edges_source ON edges (source_entity);
CREATE INDEX idx_edges_target ON edges (target_entity);
CREATE INDEX idx_edges_relationship ON edges (relationship);
CREATE INDEX idx_edges_confidence ON edges (confidence);
```

**relationship values (initial set):**
- Person → Org: `works_for`, `client_of`, `decision_maker`, `influencer`, `freelances_for`
- Person → Project: `manages`, `works_on`, `created`
- Org → Org: `subsidiary_of`, `partner_of`, `vendor_of`
- Project → Org: `for_client`
- (extensible — just a TEXT field, new relationships emerge naturally)

**Confidence scoring:**
- Explicit data (Pipedrive contact → org): `1.0`
- LLM-extracted from single mention: `0.5-0.7`
- Confirmed across multiple memories: bumps toward `1.0`
- A periodic reconciliation job reviews low-confidence edges

### Table: `memory_entities` (junction)

Links memories to the entities mentioned or involved.

```sql
CREATE TABLE memory_entities (
    memory_id       UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
    entity_id       UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    role            TEXT NOT NULL,       -- mentioned, author, subject, assignee, attendee, about
    PRIMARY KEY (memory_id, entity_id, role)
);

CREATE INDEX idx_me_entity ON memory_entities (entity_id);
CREATE INDEX idx_me_memory ON memory_entities (memory_id);
CREATE INDEX idx_me_role ON memory_entities (role);
```

**role values:** `mentioned`, `author`, `subject`, `assignee`, `attendee`, `about`

## MCP Server

### Transport

Stdio for Claude Desktop and pricing-bot-v2. Optionally SSE for remote clients.

### Tools

| Tool | Description | Input | Output |
|------|-------------|-------|--------|
| `search_memories` | Semantic + filtered search across memories | `{ query: string, kind?: string, source_system?: string, entity_id?: string, limit?: number }` | Array of memories with similarity scores, linked entities |
| `get_entity` | Get an entity and its relationships | `{ entity_id?: string, name?: string, type?: string }` | Entity with attributes + connected edges + recent memories |
| `get_entity_graph` | Traverse entity relationships | `{ entity_id: string, depth?: number, relationship_types?: string[] }` | Graph of connected entities and edges |
| `store_memory` | Ingest a new memory with entity extraction | `{ content: string, kind: string, source_system: string, source_id?: string, meta?: object }` | Created memory ID + extracted entities + created edges |
| `upsert_entity` | Create or update an entity | `{ entity_type: string, canonical_name: string, attributes?: object }` | Entity ID (created or updated) |
| `add_edge` | Create or update a relationship | `{ source_entity_id: string, target_entity_id: string, relationship: string, confidence?: number, attributes?: object }` | Edge ID |
| `list_entities` | List entities with optional filters | `{ entity_type?: string, search?: string, limit?: number }` | Array of entities |

### Resources (MCP Resources protocol)

| Resource | URI | Description |
|----------|-----|-------------|
| Entity types | `brain://entity-types` | Available entity types with counts |
| Relationship types | `brain://relationship-types` | Available relationship types with counts |
| Recent activity | `brain://recent` | Last 20 memories ingested |
| Stale clients | `brain://stale-clients?days=90` | Clients with no memories in N days |

## Ingest Pipeline

### Flow

```
Source event (webhook/API)
    │
    ▼
Parse + normalize content
    │
    ▼
Generate embedding (text-embedding-3-small or Gemini embedding)
    │
    ▼
LLM entity extraction pass
    │  "Extract all people, organizations, and projects mentioned.
    │   For each, provide canonical name, type, and any attributes.
    │   Also extract relationships between entities with confidence."
    │
    ▼
Upsert entities (with semantic dedup via embedding similarity)
    │
    ▼
Upsert edges (merge confidence scores)
    │
    ▼
Insert memory + link to entities via junction
```

### Entity Extraction Prompt (template)

```
You are extracting structured data from organizational content.

Given the following {kind} from {source_system}:

---
{content}
---

Extract:

1. ENTITIES: People, organizations, projects, and other named things mentioned.
   For each: { "name": "...", "type": "person|org|project|...", "attributes": {} }

2. RELATIONSHIPS: How entities relate to each other.
   For each: { "source": "entity name", "target": "entity name", "relationship": "...", "confidence": 0.0-1.0 }

3. MEMORY_ROLES: Which entities are connected to this content and how.
   For each: { "entity": "entity name", "role": "mentioned|author|subject|assignee|attendee|about" }

Return JSON only. Be conservative — only extract entities you're confident about.
Prefer existing canonical names when possible: {existing_entity_names}
```

The `{existing_entity_names}` are fetched before the LLM call (top ~100 entities by recency) to encourage name reuse over proliferation.

### Source-Specific Ingest Adapters

Each source has a thin adapter that normalizes to the common ingest format:

| Source | Trigger | kind | Notes |
|--------|---------|------|-------|
| Fathom | n8n webhook on new transcript | `transcript` | Full transcript text, meta: `{ meeting_title, attendees, duration }` |
| Pipedrive | n8n webhook on deal/person/org change | `deal_event` | meta: `{ deal_id, stage, value, org_name }` |
| Trello | n8n webhook on card create/move/comment | `card_update` | meta: `{ card_id, board_id, list_name, action }` |
| Slack | n8n webhook on tagged messages | `message` | meta: `{ channel, thread_ts, author }` |
| Evernote | Manual or scheduled sync | `sop` | meta: `{ notebook, tags }` |
| Ramp | n8n webhook or scheduled pull | `financial` | meta: `{ amount, vendor, category, receipt_url }` |
| Manual | MCP `store_memory` tool | `note` | Direct entry from Claude Desktop or pricing-bot-v2 |

### Embedding Model

Use OpenAI `text-embedding-3-small` (1536 dimensions) or Google `text-embedding-004`. Choose one and stick with it — mixing embedding models in the same vector column produces garbage similarity scores.

Configuration: embedding model choice should be an env var (`EMBEDDING_MODEL=openai` or `EMBEDDING_MODEL=google`) with the provider API key alongside it.

## Reconciliation Jobs

### Entity Deduplication (weekly)

Query entities with high embedding similarity (> 0.92) that aren't already the same record. Present candidates to an LLM for merge confirmation. On merge: update all `memory_entities` and `edges` references to point to the surviving entity, delete the duplicate.

### Confidence Reinforcement (daily)

For edges with confidence < 0.8, count how many memories link to both the source and target entities. If the co-occurrence count exceeds a threshold, bump confidence. If an edge has confidence < 0.3 and hasn't been reinforced in 90 days, flag for review or deletion.

### Stale Client Detection (daily)

Query: orgs with `client_of` edges where the most recent linked memory is older than N days (configurable, default 90). Output feeds the `brain://stale-clients` MCP resource and can trigger n8n workflows for outreach reminders.

## Tech Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Language | TypeScript | Consistent with pricing-bot-v2, MCP SDK is TypeScript-first |
| MCP SDK | `@modelcontextprotocol/sdk` | Official SDK, handles stdio/SSE transport |
| Database | Postgres 16 + pgvector | Vector + relational in one instance, runs on Dave's TrueNAS Docker |
| DB client | `pg` (node-postgres) or Drizzle ORM | Direct SQL for vector queries, ORM for CRUD |
| Embedding | OpenAI or Google (env-configurable) | text-embedding-3-small (1536 dims) |
| LLM (extraction) | Gemini 2.5 Flash or Claude Haiku | Fast + cheap for structured extraction |
| HTTP ingest | Express or Hono | Thin webhook receiver for n8n, alongside MCP stdio |
| Testing | Vitest | Consistent with pricing-bot-v2 |
| Migrations | Plain SQL files in `migrations/` | Simple, no ORM migration overhead |

## Repo Structure

```
tm-brain/
├── src/
│   ├── server.ts                  # MCP server entry point (stdio)
│   ├── http.ts                    # HTTP ingest server for n8n webhooks
│   ├── db/
│   │   ├── client.ts              # Postgres connection pool
│   │   ├── memories.ts            # Memory CRUD + vector search
│   │   ├── entities.ts            # Entity CRUD + semantic resolution
│   │   ├── edges.ts               # Edge CRUD + graph traversal
│   │   └── queries.ts             # Complex queries (stale clients, co-occurrence)
│   ├── tools/
│   │   ├── search-memories.ts     # MCP tool: search_memories
│   │   ├── get-entity.ts          # MCP tool: get_entity
│   │   ├── get-entity-graph.ts    # MCP tool: get_entity_graph
│   │   ├── store-memory.ts        # MCP tool: store_memory (includes entity extraction)
│   │   ├── upsert-entity.ts       # MCP tool: upsert_entity
│   │   ├── add-edge.ts            # MCP tool: add_edge
│   │   └── list-entities.ts       # MCP tool: list_entities
│   ├── ingest/
│   │   ├── pipeline.ts            # Core ingest: embed → extract entities → store
│   │   ├── extract.ts             # LLM entity/relationship extraction
│   │   ├── embed.ts               # Embedding generation (provider-agnostic)
│   │   └── adapters/              # Source-specific normalizers
│   │       ├── fathom.ts
│   │       ├── pipedrive.ts
│   │       ├── trello.ts
│   │       ├── slack.ts
│   │       └── ramp.ts
│   ├── reconciliation/
│   │   ├── dedup-entities.ts      # Weekly entity deduplication
│   │   ├── reinforce-confidence.ts # Daily confidence scoring
│   │   └── stale-clients.ts       # Daily stale client detection
│   └── resources/
│       └── index.ts               # MCP resources (entity-types, relationship-types, recent, stale-clients)
├── migrations/
│   ├── 001_create_memories.sql
│   ├── 002_create_entities.sql
│   ├── 003_create_edges.sql
│   └── 004_create_memory_entities.sql
├── tests/
│   ├── db/
│   ├── tools/
│   ├── ingest/
│   └── reconciliation/
├── .env.example
├── package.json
├── tsconfig.json
├── vitest.config.ts
├── CLAUDE.md
├── stigwheel.md
└── specs/
    ├── data-model.md
    ├── mcp-server.md
    ├── ingest-pipeline.md
    └── reconciliation.md
```

~30 source files. The complexity is in the prompts and SQL, not the application code.

## Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/tm_brain

# Embedding provider
EMBEDDING_MODEL=openai           # or "google"
OPENAI_API_KEY=sk-...            # if EMBEDDING_MODEL=openai
GOOGLE_API_KEY=...               # if EMBEDDING_MODEL=google

# LLM for entity extraction
EXTRACTION_MODEL=gemini-2.5-flash  # or "claude-haiku"
GOOGLE_API_KEY=...                 # shared with embedding if google

# HTTP ingest server
INGEST_PORT=3100
INGEST_API_KEY=...               # simple bearer token for n8n webhooks

# Optional: Supabase (if using managed Postgres)
SUPABASE_URL=https://...
SUPABASE_SERVICE_ROLE_KEY=...
```

## Deployment

### Option A: Dave's TrueNAS (recommended)

- Postgres 16 + pgvector in a Docker container (alongside existing infra)
- tm-brain MCP server runs as a Node.js process
- HTTP ingest server on port 3100 behind Cloudflare tunnel
- Claude Desktop connects via stdio (local) or SSE (remote)
- pricing-bot-v2 connects via MCP stdio or SSE

### Option B: Supabase

- Use Supabase Postgres with pgvector extension enabled
- tm-brain runs as a Node.js process wherever (Vercel, Fly, local)
- Same MCP interface, just swap the DATABASE_URL

## Use Cases Served

| Use Case | How |
|----------|-----|
| "Show me everything about AFS" | `get_entity(name: "AFS")` → entity + edges + recent memories |
| "Who are the decision-makers at AFS?" | `get_entity_graph(entity_id: afs_id, relationship_types: ["decision_maker", "influencer"])` |
| 90-day client check-in | `brain://stale-clients?days=90` resource → n8n drafts outreach with context from recent memories |
| Client hierarchy map | `get_entity_graph(entity_id: org_id, depth: 2)` → full people/role graph |
| Meeting notes → Trello | n8n ingests transcript via HTTP → entity extraction creates/links project → pushes action items to Trello |
| "What did we discuss about pricing for healthcare clients?" | `search_memories(query: "pricing healthcare", kind: "transcript")` |
| Ramp/QuickBooks reconciliation | Query memories from both sources linked to same entity, surface mismatches |
| Maggie becomes her own client | `upsert_entity` + `add_edge(relationship: "client_of")` — graph updates, history preserved |

## Integration with pricing-bot-v2

The pricing bot connects to tm-brain as an MCP client, same way it connects to Pipedrive and Trello today. Add to pricing-bot-v2's `.mcp.json`:

```json
{
  "tm-brain": {
    "command": "node",
    "args": ["/path/to/tm-brain/dist/server.js"],
    "env": {
      "DATABASE_URL": "${TM_BRAIN_DATABASE_URL}"
    }
  }
}
```

The pricing agent gains access to organizational memory for context-enriched pricing decisions: "This client has a history of large projects", "Last quote for AFS was $45k, here's what it included."

## Non-Goals (for v1)

- No frontend / UI — this is a headless brain
- No auth layer — access control is at the MCP/HTTP level (API key for webhooks, stdio for trusted local clients)
- No real-time streaming — batch ingest is fine for v1
- No multi-tenant — this is T&M's brain, not a SaaS product
- No full-text search index (BM25) — vector similarity + JSONB filtering is sufficient for v1, add `tsvector` later if needed
