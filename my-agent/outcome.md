# Rubric: weekly consistency audit

Grade each criterion pass/fail independently.

1. **Mirror pairs**: report.md gives an explicit verdict (identical / differs) for all 3 mirror pairs (overview HTML, overview.css, build-sheet example JSON). Each differing pair includes the diff hunk and the chosen sync direction.
2. **References**: report.md lists every broken repo path from README.md, CLAUDE.md, CONTRIBUTING.md, SKILL.md files and references/*.md as file:line, each with the file's actual current location or "deleted". Runtime/build-kit paths are not flagged.
3. **Validity**: report.md states that every tracked .json file was parsed and both overview HTML files were checked for a relative overview.css link and no `<style>` block, and names any failures.
4. **Stale facts**: every stale-fact finding cites a platform.claude.com docs URL and a short quote. Facts that couldn't be checked are labelled "unverified", not stale.
5. **Evidence, no invention**: every finding carries file:line evidence or command output. Nothing is reported that the tree doesn't show.
6. **Deliverables**: /mnt/session/outputs/report.md exists, with today's date and the audited commit SHA in its title. If checks 1-3 found anything fixable, /mnt/session/outputs/fix.patch exists, fixes those findings, and passes `git apply --check` on the audited tree. If nothing was fixable, the report says "No fixes needed".
