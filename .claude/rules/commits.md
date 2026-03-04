# Commit Rules

## Message Format
```
feat(TASK-XXX): description of what was implemented

Implements: specs/{spec}.md#{section}
Pattern: {pattern-name}
Validates: {test-case-1}, {test-case-2}

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Prefixes
- `feat` — new functionality
- `fix` — bug fix
- `refactor` — restructuring without behavior change
- `docs` — documentation only
- `test` — test additions or fixes

## Trailers (required)
- `Implements:` — spec section this commit satisfies
- `Pattern:` — which `.patterns/` anchor was followed
- `Validates:` — test cases from spec validation table now passing

## Branch Naming
```
feature/TASK-XXX-short-description
fix/TASK-XXX-short-description
```

Task ID in branch name enables `git branch --list "*/TASK-*"` discovery.
