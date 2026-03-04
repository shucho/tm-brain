# Stigwheel: Stigmergic AI Development Framework

> A coordination methodology for Claude Code where agents leave environmental traces that guide future behavior—enabling autonomous, aligned development without central planning or persistent memory.

---

## Philosophy

**Stigmergy's Core Insight:** Coordination happens through the environment, not through communication. An action leaves a trace; perceiving the trace stimulates the next action.

**The Problem with Pure Ralph:** Each iteration starts fresh. Context is lost. Agents must re-orient every time. Plans can drift from intent. There's no mechanism ensuring alignment with higher patterns.

**Stigwheel's Solution:** Embed coordination signals directly into the codebase—in frontmatter, anchors, git history, and file structure. Future agents don't need to "understand" the project; they perceive traces and respond.

**The Hierarchy:**
```
CLAUDE.md (operational truths)
    ↓ references
.patterns/*.anchor.yaml (pattern definitions)
    ↓ constrain
specs/*.md (feature requirements)
    ↓ implemented by
src/**/* (code with @anchor markers)
    ↑ links back via frontmatter
```

**Core Principles:**
1. **Traces, not tasks** — Work leaves discoverable marks
2. **Anchors, not assumptions** — Every file declares what it is
3. **Validation in place** — Status lives with the spec, not separately
4. **Alignment by structure** — Hierarchy prevents drift
5. **Machine-readable coordination** — Agents grep, not comprehend

---

## Architecture

```
project/
├── CLAUDE.md                      # Operational patterns (LEAN)
├── .patterns/                     # Pattern definitions (anchors)
│   ├── api-route.anchor.yaml
│   ├── db-mutation.anchor.yaml
│   └── ui-component.anchor.yaml
├── specs/                         # Requirements with embedded validation
│   ├── authentication.md
│   ├── teams.md
│   └── events.md
├── claude/
│   ├── loop.sh                    # Orchestration script
│   ├── PROMPT_plan.md             # Planning mode instructions
│   ├── PROMPT_build.md            # Building mode instructions
│   └── PLAN.md                    # Agent-generated task list
└── src/
    └── ...                        # Code with frontmatter/anchors
```

---

## The Stigmergic Stack

### Layer 1: Frontmatter (Every File)

Every source file carries its coordination context:

```typescript
/**
 * ---
 * @anchor: .patterns/api-route
 * @spec: specs/teams.md#team-creation
 * @task: TASK-007
 * @validated: 2024-01-15
 * ---
 */
export async function POST(request: Request) {
  // ...
}
```

**Why this works:**
- Created when file is created (zero extra effort)
- Machine-readable (`grep -r "@spec: specs/teams.md"`)
- Links implementation to intent
- Future agents instantly know: what pattern, what spec, what task

**Alternative for non-comment languages (JSON, YAML, SQL):**
```yaml
# config/teams.yaml
_meta:
  anchor: .patterns/config-file
  spec: specs/teams.md#team-config
  validated: 2024-01-15

teams:
  max_size: 25
  # ...
```

---

### Layer 2: Pattern Anchors

Anchor files define reusable patterns. They are the "pheromone trails" that guide consistent implementation.

```yaml
# .patterns/api-route.anchor.yaml
name: api-route
version: 1
description: HTTP endpoint handler pattern

structure:
  location: "src/api/**/*.ts"
  naming: "{resource}.ts or {resource}/{action}.ts"
  exports:
    - "GET, POST, PUT, DELETE as named exports"
    - "Each export is async (request: Request) => Response"

conventions:
  - Zod schema defined at top of file for input validation
  - Return Response.json() for all responses
  - Errors use standard { error: string, code: string } shape
  - Auth check via getSession(request) helper

example: |
  import { z } from 'zod';
  import { getSession } from '@/lib/auth';

  const CreateTeamSchema = z.object({
    name: z.string().min(1).max(100),
  });

  export async function POST(request: Request) {
    const session = await getSession(request);
    if (!session) return Response.json({ error: 'Unauthorized' }, { status: 401 });

    const body = CreateTeamSchema.parse(await request.json());
    // ... implementation
    return Response.json({ team });
  }

implementations:
  # Auto-maintained by agents
  - path: src/api/teams.ts
    task: TASK-007
    validated: 2024-01-15
  - path: src/api/events.ts
    task: TASK-012
    validated: 2024-01-18

usage_count: 8
last_used: 2024-01-20
```

**Why anchors work:**
- Single source of truth for "how we do X"
- Agents read anchor before implementing
- Implementations list provides discovery
- Usage metrics enable pattern evolution

---

### Layer 3: Specs with Embedded Validation

Specs are not just requirements—they track their own validation status.

```markdown
# specs/teams.md

---
patterns:
  - api-route
  - db-mutation
  - ui-component
depends_on:
  - specs/authentication.md
---

## Overview
Users can create and manage teams within their organization.

## Requirements

### Team Creation
- Users can create teams with a name (required, 1-100 chars)
- Teams belong to exactly one organization
- Creator becomes team owner automatically

### Team Management
- Owners can rename teams
- Owners can delete teams (soft delete)

## Data Model

```sql
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  organization_id UUID REFERENCES organizations(id),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
```

## Validation Status

<!-- STIGMERGIC: This section is the trace. Agents update it after verification. -->

| Test Case | Status | Verified | Task | Notes |
|-----------|--------|----------|------|-------|
| Create team with valid name | ✅ | 2024-01-15 | TASK-007 | |
| Reject empty team name | ✅ | 2024-01-15 | TASK-007 | |
| Reject duplicate name in org | 🔴 | | | Not implemented |
| List teams for user | 🟡 | 2024-01-16 | TASK-008 | Needs pagination |
| Soft delete team | 🔴 | | | |
| Deleted teams hidden from list | 🔴 | | | |

## Implementation Trace

<!-- STIGMERGIC: Auto-maintained list of files implementing this spec -->

| File | Pattern | Task | Status |
|------|---------|------|--------|
| src/api/teams.ts | api-route | TASK-007 | ✅ |
| src/db/schema/teams.ts | db-schema | TASK-006 | ✅ |
| src/components/teams/TeamList.tsx | ui-component | TASK-008 | 🟡 |
| src/components/teams/CreateTeamForm.tsx | ui-component | TASK-007 | ✅ |
```

**Why embedded validation works:**
- Status lives with the spec (single source of truth)
- Agents see immediately what's done vs pending
- Implementation trace shows the full picture
- No separate TODO.md to keep in sync

---

### Layer 4: Git as Trace Medium

Commits are permanent traces. Make them stigmergically useful.

**Commit Message Format:**
```
feat(TASK-007): implement team creation API

Implements: specs/teams.md#team-creation
Pattern: api-route
Validates: create-team-valid-name, reject-empty-name

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Why this works:**
- `Implements:` links commit to spec section
- `Pattern:` declares which pattern was followed
- `Validates:` lists test cases this commit satisfies
- Future agents can `git log --grep="Implements: specs/teams.md"` to find all related work

**Branch Naming:**
```
feature/TASK-007-team-creation
fix/TASK-012-team-delete-cascade
```

Task ID in branch name enables: `git branch --list "*/TASK-*"` to see active work.

---

### Layer 5: PLAN.md (The Active Trace)

Unlike Ralphwheel's IMPLEMENTATION_PLAN.md, Stigwheel's PLAN.md is leaner—it references specs rather than duplicating requirements.

```markdown
# PLAN.md

Generated: 2024-01-20T10:30:00Z
Mode: build

## Active Context

Current spec focus: specs/teams.md
Dependency chain: auth ✅ → navigation ✅ → teams 🟡 → events 🔴

## Queue

### Now
- [ ] **TASK-009**: Implement team soft delete
  - Spec: specs/teams.md#team-management
  - Pattern: api-route, db-mutation
  - Validates: soft-delete-team, deleted-teams-hidden
  - Files: src/api/teams.ts, src/db/mutations/teams.ts

### Next
- [ ] **TASK-010**: Add duplicate name validation
  - Spec: specs/teams.md#team-creation
  - Validates: reject-duplicate-name-in-org

### Blocked
- [ ] **TASK-011**: Team member invitations
  - Blocked by: TASK-009 (need delete working first for test cleanup)

## Completed This Session

- [x] **TASK-008**: Team list UI with pagination
  - Validated: list-teams-for-user (partial - needs edge cases)
  - Commit: abc123f

## Learnings

<!-- STIGMERGIC: Patterns discovered during this session, to be promoted to .patterns/ or CLAUDE.md -->

- Soft delete pattern: Set `deleted_at`, filter with `WHERE deleted_at IS NULL`
- Pagination: Use cursor-based, not offset (see TASK-008 commit)
```

**Why this works:**
- References specs, doesn't duplicate them
- Shows dependency chain (what's blocked on what)
- Captures learnings for promotion to patterns
- Completed items reference commits (trace linkage)

---

## The Loop

```bash
#!/bin/bash
# claude/loop.sh - The Stigwheel Loop

MODE="${1:-build}"
MAX="${2:-50}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PROMPT="$SCRIPT_DIR/PROMPT_${MODE}.md"

echo "Stigwheel Loop - Mode: $MODE, Max: $MAX iterations"

for i in $(seq 1 $MAX); do
  echo ""
  echo "════════════════════════════════════════════════════"
  echo "  Iteration $i of $MAX ($MODE mode)"
  echo "════════════════════════════════════════════════════"

  cd "$PROJECT_ROOT" && claude --dangerously-skip-permissions --print < "$PROMPT"

  echo ""
  echo "Iteration $i complete. Continuing in 2s..."
  sleep 2
done
```

**Two Modes:**

| Mode | When | What It Does |
|------|------|--------------|
| `plan` | Starting feature, need alignment | Reads specs, generates PLAN.md, identifies patterns |
| `build` | Plan exists | Implements one task, updates traces, commits |

---

## PROMPT_plan.md (Planning Mode)

```markdown
You are a Stigwheel planning agent. Your job: read traces, generate aligned plan.

## Phase 0: Perceive Traces

1. Read CLAUDE.md for operational context
2. Read .patterns/*.anchor.yaml for available patterns
3. Read specs/*.md - focus on:
   - Frontmatter (dependencies, patterns used)
   - Validation Status tables (what's ✅, 🟡, 🔴)
   - Implementation Trace tables (what files exist)
4. Read claude/PLAN.md if it exists
5. Check git log for recent work: `git log --oneline -20`

## Phase 1: Identify Gaps

For each spec with 🔴 or 🟡 validation items:
- What's missing?
- What patterns apply?
- What are the dependencies?

**CRITICAL: Search before assuming.**
Before listing something as missing:
- `grep -r "relevant term" src/`
- Check .patterns/*.anchor.yaml implementations lists
- Check spec Implementation Trace tables

## Phase 2: Generate PLAN.md

Create/update claude/PLAN.md:
- Reference specs by path and section
- Reference patterns by anchor file
- List validation cases each task will satisfy
- Note dependencies and blockers
- Order by dependency chain

## Phase 3: Alignment Check

Before finishing, verify:
- [ ] Every task links to a spec section
- [ ] Every task declares which patterns it follows
- [ ] Every task lists validation cases it will satisfy
- [ ] Dependencies are correctly ordered
- [ ] No orphan tasks (tasks not linked to specs)

## Output

Summarize:
- Specs analyzed
- Tasks generated
- Recommended starting point
- Any alignment concerns
```

---

## PROMPT_build.md (Building Mode)

```markdown
You are a Stigwheel building agent. Your job: implement one task, leave traces.

## Phase 0: Perceive Traces

1. Read claude/PLAN.md - identify highest priority incomplete task
2. Read the spec section referenced by that task
3. Read the pattern anchor files referenced by that task
4. Search for related implementations:
   - Check pattern anchor implementations lists
   - Check spec Implementation Trace tables
   - `grep -r "@spec: specs/{spec-name}" src/`

**CRITICAL: Follow existing patterns exactly.**
The anchor file is your blueprint. Match its conventions.

## Phase 1: Implement

Follow the pattern anchor precisely:
- Location as specified
- Naming as specified
- Structure as specified
- Conventions as specified

Add frontmatter to new files:
```typescript
/**
 * ---
 * @anchor: .patterns/{pattern-name}
 * @spec: specs/{spec-name}.md#{section}
 * @task: TASK-XXX
 * @validated: null
 * ---
 */
```

## Phase 2: Validate (Backpressure)

```bash
npm run typecheck   # Types must pass
npm run lint        # Linting must pass
npm run test        # Tests must pass
```

If any fail: fix and retry. Do NOT proceed until all pass.

For data mutations, verify DB state:
```sql
SELECT * FROM table WHERE condition;
```

## Phase 3: Update Traces

After successful validation, update ALL traces:

### 3a. Update spec validation table
Edit specs/{spec}.md - change 🔴 to ✅ for validated cases:
```markdown
| Create team | ✅ | 2024-01-20 | TASK-007 | |
```

### 3b. Update spec implementation trace
Add/update entry in Implementation Trace table:
```markdown
| src/api/teams.ts | api-route | TASK-007 | ✅ |
```

### 3c. Update pattern anchor
Edit .patterns/{pattern}.anchor.yaml - add to implementations:
```yaml
implementations:
  - path: src/api/teams.ts
    task: TASK-007
    validated: 2024-01-20
```

### 3d. Update file frontmatter
Set @validated date in the file itself.

### 3e. Update PLAN.md
Mark task complete, add commit reference.

## Phase 4: Commit

Stage and commit with stigmergic message:
```bash
git add -A
git commit -m "$(cat <<'EOF'
feat(TASK-XXX): description

Implements: specs/{spec}.md#{section}
Pattern: {pattern-name}
Validates: {test-case-1}, {test-case-2}

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## Phase 5: Exit

One task complete. Exit for fresh context.

If ALL spec validation items are ✅: "SPEC COMPLETE: specs/{spec}.md"
If ALL specs complete: "IMPLEMENTATION COMPLETE"

## Trace Update Checklist

Before exiting, verify you updated:
- [ ] Spec validation table (🔴 → ✅)
- [ ] Spec implementation trace
- [ ] Pattern anchor implementations list
- [ ] File frontmatter @validated
- [ ] PLAN.md task status
- [ ] Git commit with proper trailers

**Missing traces = lost coordination. Always update all traces.**
```

---

## CLAUDE.md (Keep Lean)

```markdown
# Project: [Name]

## Stack
- [Framework/language]
- [Database]
- [Key libraries]

## Commands
```bash
npm run dev          # Dev server
npm run typecheck    # MUST pass before commit
npm run lint         # MUST pass before commit
npm run test         # MUST pass before commit
```

## Stigwheel Locations
- Patterns: .patterns/*.anchor.yaml
- Specs: specs/*.md
- Plan: claude/PLAN.md

## Quick Patterns
<!-- One-line reminders only. Details in .patterns/ -->
- API routes: Zod schema at top, Response.json() returns
- DB mutations: Soft delete via deleted_at column
- UI components: testID on all interactive elements

## Conventions
- Frontmatter: @anchor, @spec, @task, @validated
- Commits: feat(TASK-XXX): description + trailers
- Validation: ✅ done, 🟡 partial, 🔴 not started
```

---

## Alignment Verification

Run periodically to detect drift:

```bash
#!/bin/bash
# claude/verify-alignment.sh

echo "=== Stigwheel Alignment Check ==="

echo ""
echo "1. Files missing frontmatter:"
find src -name "*.ts" -o -name "*.tsx" | while read f; do
  if ! grep -q "@anchor:" "$f" 2>/dev/null; then
    echo "   MISSING: $f"
  fi
done

echo ""
echo "2. Orphan files (no spec reference):"
find src -name "*.ts" -o -name "*.tsx" | while read f; do
  if ! grep -q "@spec:" "$f" 2>/dev/null; then
    echo "   ORPHAN: $f"
  fi
done

echo ""
echo "3. Validation status summary:"
for spec in specs/*.md; do
  done=$(grep -c "| ✅" "$spec" 2>/dev/null || echo 0)
  partial=$(grep -c "| 🟡" "$spec" 2>/dev/null || echo 0)
  pending=$(grep -c "| 🔴" "$spec" 2>/dev/null || echo 0)
  echo "   $spec: ✅$done 🟡$partial 🔴$pending"
done

echo ""
echo "4. Pattern usage:"
for pattern in .patterns/*.anchor.yaml; do
  count=$(grep -c "^  - path:" "$pattern" 2>/dev/null || echo 0)
  echo "   $pattern: $count implementations"
done
```

---

## Optional Extension: Database Coordination Table

For projects requiring persistent coordination state (multi-agent, long-running, or distributed work), add a coordination table:

```sql
-- migrations/001_coordination_table.sql

CREATE TABLE _stigwheel_coordination (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- What is this?
  entity_type TEXT NOT NULL,        -- 'file', 'spec', 'task', 'pattern'
  entity_path TEXT NOT NULL,        -- 'src/api/teams.ts', 'specs/teams.md'

  -- Stigmergic traces
  anchor_pattern TEXT,              -- '.patterns/api-route'
  spec_reference TEXT,              -- 'specs/teams.md#team-creation'
  task_id TEXT,                     -- 'TASK-007'

  -- Validation state
  validation_status TEXT,           -- '✅', '🟡', '🔴'
  validated_at TIMESTAMPTZ,
  validated_by TEXT,                -- 'claude-session-xyz', 'human'

  -- Coordination metadata
  locked_by TEXT,                   -- Session ID if currently being worked on
  locked_at TIMESTAMPTZ,

  -- Trace history
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(entity_type, entity_path)
);

-- Index for common queries
CREATE INDEX idx_coordination_spec ON _stigwheel_coordination(spec_reference);
CREATE INDEX idx_coordination_task ON _stigwheel_coordination(task_id);
CREATE INDEX idx_coordination_status ON _stigwheel_coordination(validation_status);

-- Helper view: What needs work?
CREATE VIEW _stigwheel_pending AS
SELECT * FROM _stigwheel_coordination
WHERE validation_status IN ('🔴', '🟡')
  AND (locked_by IS NULL OR locked_at < now() - interval '1 hour')
ORDER BY
  CASE validation_status WHEN '🟡' THEN 1 WHEN '🔴' THEN 2 END,
  created_at;

-- Helper view: What's complete?
CREATE VIEW _stigwheel_complete AS
SELECT spec_reference,
       COUNT(*) FILTER (WHERE validation_status = '✅') as done,
       COUNT(*) FILTER (WHERE validation_status = '🟡') as partial,
       COUNT(*) FILTER (WHERE validation_status = '🔴') as pending
FROM _stigwheel_coordination
WHERE entity_type = 'validation_case'
GROUP BY spec_reference;
```

**When to use the DB table:**

| Scenario | File-based | DB-based |
|----------|------------|----------|
| Single agent, single session | ✅ Sufficient | Overkill |
| Single agent, resumable sessions | ✅ Sufficient | Optional |
| Multiple agents, same codebase | Conflicts | ✅ Required |
| Distributed team + AI | Conflicts | ✅ Required |
| Need locking/reservations | Not possible | ✅ Required |
| Audit trail requirements | Git only | ✅ Full history |

**Usage in prompts:**

```markdown
## Phase 0: Perceive Traces (DB-enabled)

1. Check for available work:
   ```sql
   SELECT * FROM _stigwheel_pending LIMIT 5;
   ```

2. Lock a task before starting:
   ```sql
   UPDATE _stigwheel_coordination
   SET locked_by = 'session-{id}', locked_at = now()
   WHERE task_id = 'TASK-007' AND locked_by IS NULL;
   ```

3. After completion, update and unlock:
   ```sql
   UPDATE _stigwheel_coordination
   SET validation_status = '✅',
       validated_at = now(),
       locked_by = NULL
   WHERE task_id = 'TASK-007';
   ```
```

---

## Migration from Ralphwheel

If you have an existing Ralphwheel project:

### Step 1: Create pattern anchors
```bash
mkdir -p .patterns
# Create anchor files for patterns mentioned in CLAUDE.md
```

### Step 2: Add frontmatter to existing files
```bash
# For each source file, add:
# @anchor: .patterns/{appropriate-pattern}
# @spec: specs/{relevant-spec}.md
# @task: (from git blame or IMPLEMENTATION_PLAN.md)
# @validated: (from validation/TODO.md or null)
```

### Step 3: Migrate validation status into specs
```bash
# Move validation/TODO.md content into each spec's Validation Status table
```

### Step 4: Generate Implementation Trace tables
```bash
# For each spec, list files that implement it:
grep -rl "@spec: specs/teams.md" src/
# Add to spec's Implementation Trace table
```

### Step 5: Update IMPLEMENTATION_PLAN.md → PLAN.md
```bash
# Slim down to reference specs, not duplicate requirements
mv claude/IMPLEMENTATION_PLAN.md claude/PLAN.md
```

---

## Quick Reference

```bash
# Planning mode (perceive traces → generate plan)
./claude/loop.sh plan [iterations]

# Building mode (implement with trace updates)
./claude/loop.sh build [iterations]

# Verify alignment
./claude/verify-alignment.sh

# Find implementations of a spec
grep -rl "@spec: specs/teams.md" src/

# Find files using a pattern
grep -rl "@anchor: .patterns/api-route" src/

# Check validation status
grep -E "^\|.*(✅|🟡|🔴)" specs/*.md

# See pattern usage
grep -c "^  - path:" .patterns/*.anchor.yaml
```

---

## Summary

| Ralphwheel | Stigwheel | Why |
|------------|-----------|-----|
| IMPLEMENTATION_PLAN.md | PLAN.md + spec references | Single source of truth |
| validation/TODO.md | Embedded in specs | Status lives with requirements |
| Patterns in CLAUDE.md | .patterns/*.anchor.yaml | Discoverable, machine-readable |
| Implicit conventions | Frontmatter in every file | Every file declares what it is |
| Manual alignment | verify-alignment.sh | Drift detection automated |
| Memory via plan | Traces in git, files, specs | Coordination without memory |

**The Core Shift:** Ralphwheel coordinates through a plan document that agents read and update. Stigwheel coordinates through environmental traces that agents perceive and respond to. The environment *is* the coordination mechanism.

---

## Attribution

Built on:
- **[Stigmergy](https://en.wikipedia.org/wiki/Stigmergy)** — coordination through environmental modification (Grassé, 1959)
- **[Ralph Wiggum Technique](https://ghuntley.com/ralph/)** by Geoffrey Huntley — the autonomous loop
- **Flywheel Methodology** — self-registering components and validation patterns
- **Heylighen's work on distributed cognition** — theoretical foundation

*"The trace is the message. The environment is the coordinator."*
