# Frontmatter Rules

## Every new source file MUST have a frontmatter block:

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

## Non-comment languages (YAML, JSON, SQL):
```yaml
_meta:
  anchor: .patterns/{pattern-name}
  spec: specs/{spec-name}.md#{section}
  validated: null
```

## Rules
- Set `@validated: null` initially; update to date after verification passes
- `@anchor` links to the pattern definition this file follows
- `@spec` links to the requirement this file implements (include `#section`)
- `@task` is the task ID from PLAN.md
- Frontmatter enables `grep -r "@spec: specs/teams.md" src/` for discovery
