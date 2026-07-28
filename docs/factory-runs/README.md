# Startup Factory — daily run records

One file per morning run of the `turnkey-startup-factory` skill
(`.claude/skills/turnkey-startup-factory/`), named `YYYY-MM-DD.md` using the
`templates/daily-run.md` structure.

Why this folder exists: the skill avoids repeating recently used keyword
bundles. Each run MUST read the most recent records here first and pick a
**different topic combination** from `templates/keyword-pool.csv`, then commit
its own record so the rotation continues.

Rules for the scheduled run:
- Mode: `daily_run` (screen 4 candidates → rank → winner summary). Build a full
  launch kit only when the winner passes the build gate.
- Never take public, financial, or outreach actions — records and summaries only.
- Commit each record to the working branch; the PR carries the history.
