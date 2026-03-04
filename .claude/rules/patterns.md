# Pattern Anchor Rules

## Before implementing anything:
1. Read `.patterns/*.anchor.yaml` for the relevant pattern
2. Follow its `structure`, `conventions`, and `example` exactly
3. Match location, naming, exports, and conventions from the anchor

## After implementing:
1. Add your file to the anchor's `implementations:` list:
   ```yaml
   implementations:
     - path: src/path/to/file.ts
       task: TASK-XXX
       validated: YYYY-MM-DD
   ```
2. Increment `usage_count`
3. Update `last_used` date

## Creating new patterns:
- Only when a convention is used 2+ times
- Place in `.patterns/{pattern-name}.anchor.yaml`
- Include: name, version, description, structure, conventions, example
- Backfill existing implementations into the `implementations:` list
