# Case 03: planted breakage (held back)

Setup: `drift.patch` in this folder is applied to the clone before the audit.

| Check | Expected (on top of case 01's 2 README findings) |
|---|---|
| Validity | `references/build-sheet.example.json` fails to parse (missing comma after `"version": null`, line 13). `references/overview-template.html` has an inlined `<style>` block (line 11) |
| Mirror drift | Both changes also break their mirror pairs (build-sheet JSON, overview HTML). Here **ui/ is the intact side**, so the right fix syncs references/ ← ui/ (the newest commit is not automatically right; a broken copy shouldn't win) |
| fix.patch | Removes the `<style>` line and restores the comma; JSON parses afterwards; applies cleanly to the patched tree |
