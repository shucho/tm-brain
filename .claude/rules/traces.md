# Trace Update Checklist

## After completing any implementation task, update ALL of these:

- [ ] **Spec validation table** — change 🔴/🟡 → ✅ for validated cases in `specs/{spec}.md`
- [ ] **Spec implementation trace** — add/update file entry in `specs/{spec}.md`
- [ ] **Pattern anchor** — add file to `implementations:` in `.patterns/{pattern}.anchor.yaml`
- [ ] **File frontmatter** — set `@validated:` date in the source file
- [ ] **PLAN.md** — mark task complete, add commit reference
- [ ] **Git commit** — use proper format with `Implements:`, `Pattern:`, `Validates:` trailers

## Missing traces = lost coordination.
Every trace connects implementation back to intent. Skip one and future agents lose the thread.
