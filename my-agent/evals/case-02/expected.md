# Case 02: planted drift (held back)

Setup: `drift.patch` in this folder is applied to the clone before the audit.

| Check | Expected (on top of case 01's 2 README findings) |
|---|---|
| Mirror drift | `ui/overview.css` ≠ `references/overview.css`: `--clay:#b5602d` vs `#ad5724` (around line 12). Sync direction: references/ is canonical, so ui/ gets `#ad5724` |
| Broken references | `references/mock-connectors.md` is now missing (renamed to `mock-connector-patterns.md`). Every mention gets flagged: `SKILL.md:29`, `SKILL.md:135`, plus any mentions in CLAUDE.md, interview.md and the wrap-up skill |
| Validity | Clean |
| fix.patch | Restores the CSS value; fixes the references, either by renaming the file back or by updating every mention; applies cleanly to the patched tree |
