---
name: Lua Best Practices
language: lua
globs: "**/*.lua"
alwaysApply: false
description: Enforces Lua best practices for RIFT addon development
---

# Lua Best Practices Rules

## Code Style
- id: lua-indentation
  pattern: "^  "
  message: "Use 2 spaces for indentation, not 4 or tabs."
  severity: warning

- id: lua-camel-case
  pattern: "[a-z][a-zA-Z0-9]*_[a-zA-Z0-9]+"
  message: "Use camelCase for variables and functions (e.g., `calculateTotalDamage`)."
  severity: warning

- id: lua-line-length
  pattern: ".{81,}"
  message: "Keep line length under 80 characters for readability."
  severity: info

## Variable Declarations
- id: lua-local-variables
  pattern: "(?!local )[a-zA-Z_][a-zA-Z0-9_]* ="
  message: "Prefer `local` variables over global variables."
  severity: warning

- id: lua-avoid-unused
  pattern: "_ = [^\n]+"
  message: "Avoid unused variables; use `_` for intentionally unused variables."
  severity: info

- id: lua-localized-global-naming
  pattern: "_[a-z][a-zA-Z0-9]*"
  message: "Use camelCase for localized globals (e.g., `inspectTimeFrame = Inspect.Time.Frame`). Avoid underscores unless for special cases."
  severity: info

## Function Design
- id: lua-function-size
  pattern: "function[^)]+\)\n(?:[^\n]++\n){30,}"
  message: "Keep functions small and focused (max 30 lines)."
  severity: warning

- id: lua-descriptive-names
  pattern: "function [a-z]\""
  message: "Use descriptive function names (e.g., `calculate_total_damage`)."
  severity: info

## Table Usage
- id: lua-table-initialization
  pattern: "local t = {}"
  message: "Initialize tables with appropriate size hints when known."
  severity: info

- id: lua-array-indexing
  pattern: "t\[0\]"
  message: "Use 1-based indexing for arrays in Lua."
  severity: warning

## Error Handling
- id: lua-use-pcall
  pattern: "[^p]call\("
  message: "Use `pcall` or `xpcall` for protected calls."
  severity: warning

- id: lua-assert-usage
  pattern: "assert\("
  message: "Use `assert` for precondition checking with descriptive messages."
  severity: info

## Performance
- id: lua-localize-globals
  pattern: "_G\.[a-zA-Z_][a-zA-Z0-9_]"
  message: "Localize frequently used global functions."
  severity: warning

- id: lua-avoid-string-concat
  pattern: "\.\.\."
  message: "Avoid string concatenation in loops; use `table.concat`."
  severity: warning

## Loop Optimization
- id: lua-use-ipairs
  pattern: "for i=1,#t do"
  message: "Use `ipairs` for array iteration."
  severity: info

- id: lua-use-pairs
  pattern: "for k,v in [^p]+"
  message: "Use `pairs` for hash table iteration."
  severity: info

## Memory Management
- id: lua-weak-references
  pattern: "setmetatable\({}, {__mode = '[kv]'}"
  message: "Use weak references to avoid memory leaks where appropriate."
  severity: info

## LuaJIT Optimizations
- id: lua-avoid-table-creation
  pattern: "for[^\n]+do[^\n]+{[^\n]+}"
  message: "Avoid table creation in loops; preallocate when possible."
  severity: warning

## Documentation
- id: lua-document-functions
  pattern: "function[^(]+\\(\)"
  message: "Document function parameters and return values."
  severity: info

- id: lua-module-docs
  pattern: "-- @module"
  message: "Document module APIs and usage examples."
  severity: info
