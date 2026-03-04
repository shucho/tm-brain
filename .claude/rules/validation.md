# Validation Rules

## Spec Validation Tables
Each spec has a `## Validation Status` table tracking test cases:

| Status | Meaning |
|--------|---------|
| ✅ | Verified and passing |
| 🟡 | Partially implemented or needs work |
| 🔴 | Not started |

## After verifying a test case:
1. Update the spec's validation table: change 🔴/🟡 → ✅
2. Fill in `Verified` date and `Task` ID columns
3. Add notes for partial (🟡) items explaining what's missing

## Implementation Trace Tables
Each spec has a `## Implementation Trace` table listing files:

```markdown
| File | Pattern | Task | Status |
|------|---------|------|--------|
| src/api/teams.ts | api-route | TASK-007 | ✅ |
```

After implementing, add/update the file's entry in this table.

## Backpressure
Do NOT mark anything ✅ unless typecheck, lint, and tests all pass.
