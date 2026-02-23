# Settings Auditor

Audit the nkUI settings system for consistency issues.

## Instructions

You are auditing the nkUI settings system. Perform the following steps:

### Step 1 — Extract all declared defaults

Read `settings/settings.lua` in full. Extract every leaf key defined inside the `_defaults` table (the nested Lua table starting at `local _defaults = {`). Represent each as a dot-path, e.g. `modules.unitFrames.combatAlpha`, `modules.actionBars.activate`, etc.

### Step 2 — Find all settings reads in modules

Search every `.lua` file under `modules/` for patterns that read from the settings object. Common patterns:
- `data.settings.modules.<module>.<key>`
- `data.settings.<key>`
- `nkUISetup.<key>`

Use Grep to find these. Collect all unique key paths referenced.

### Step 3 — Cross-reference

Compare the two lists:

**Orphaned defaults** — keys declared in `_defaults` that are never read in any module file.
**Missing defaults** — keys read in modules that have no corresponding entry in `_defaults`.
**Type mismatches** — keys where a default is a number/boolean but the module treats it as the other type (flag if you spot any obvious ones).

### Step 4 — Report

Output a clear report with three sections:
1. ✅ Healthy settings (count only)
2. ⚠️ Orphaned defaults (list each with the dot-path)
3. ❌ Missing defaults (list each with the dot-path and the file:line where it's used)

If everything is consistent, say so. Be concise — no need to repeat the healthy list.
