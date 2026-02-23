# Localization Sync

Audit and synchronize the nkUI locale files.

## Instructions

You are auditing the nkUI localization system. The locale files live in `locales/`:
- `localizationEN.lua` — English (the canonical reference)
- `localizationFR.lua` — French
- `localizationDE.lua` — German

Each file populates `privateVars.langTexts` with a table of string keys.

### Step 1 — Extract keys from each locale

Read all three locale files. Extract every key defined in the `langTexts` table, including nested table keys (represent as dot-paths, e.g. `lowerBar.social`, `oneBag.bagTitle`).

### Step 2 — Find all langTexts references in code

Search every `.lua` file in the project (excluding `locales/` itself) for patterns that read locale strings:
- `langTexts.<key>`
- `privateVars.langTexts.<key>`

Collect all unique key paths referenced.

### Step 3 — Cross-reference

**Missing from FR/DE** — keys present in EN but absent in FR or DE (list per locale).
**Extra in FR/DE** — keys in FR or DE that don't exist in EN (possible outdated translations).
**Unused keys** — keys defined in EN that are never referenced in any code file.
**Missing from all locales** — key paths referenced in code that aren't defined in any locale file.

### Step 4 — Report

Output a structured report:
1. ✅ Fully synced keys (count only)
2. 🌐 Missing translations per locale (EN key → which locales are missing it)
3. 🗑️ Unused locale keys (defined but never referenced in code)
4. ❌ Keys used in code but missing from all locales (file:line reference)
5. ⚠️ Extra keys in FR/DE not in EN

If the user's message includes a new key to add (e.g. `/locale-sync add myNewKey "My new string"`), scaffold it into all three locale files after the audit, placing it alphabetically near similar keys.
