# Project: [Name]

## Stack
- [Framework/language]
- [Database]
- [Key libraries]

## Commands
```bash
# npm run dev          # Dev server
# npm run typecheck    # MUST pass before commit
# npm run lint         # MUST pass before commit
# npm run test         # MUST pass before commit
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
- API routes: Zod schema at top, Response.json() returns
- DB mutations: Soft delete via deleted_at column
- UI components: testID on all interactive elements

## Conventions
- Frontmatter: `@anchor`, `@spec`, `@task`, `@validated` on every source file
- Commits: `feat(TASK-XXX): description` + `Implements:`, `Pattern:`, `Validates:` trailers
- Validation: ✅ done, 🟡 partial, 🔴 not started
- Branches: `feature/TASK-XXX-description` or `fix/TASK-XXX-description`
