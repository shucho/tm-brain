# Planning Rules

## PLAN.md Structure

`claude/PLAN.md` is the active task queue. It references specs — never duplicates them.

### Required sections:
- **Active Context** — current spec focus, dependency chain with status indicators
- **Queue** — `Now`, `Next`, `Blocked` sections with tasks
- **Completed This Session** — done tasks with commit references
- **Learnings** — patterns discovered during work, candidates for `.patterns/` promotion

### Each task entry must include:
- Task ID (`TASK-XXX`)
- Spec reference (`specs/{name}.md#{section}`)
- Pattern references
- Validation cases it will satisfy
- Blocked-by dependencies (if any)

## Dependency Chains
Show as: `auth ✅ → navigation ✅ → teams 🟡 → events 🔴`

## Planning Mode
Run `./claude/loop.sh plan` to generate/update PLAN.md from current spec and trace state.
