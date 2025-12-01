---
name: LUA Design Patterns
globs: "**/*.lua"
alwaysApply: true
description: Enforces Lua design patterns, readability, and performance optimizations.
---

  # =============================================
  # 1. Readability and Understandability
  # =============================================
  - id: lua-readable-naming
    pattern: "[a-z_][a-zA-Z0-9_]*"
    message: "Use snake_case for variables and functions (e.g., `calculate_total`)."
    languages: [lua]
    severity: warning

  - id: lua-function-length
    pattern: "function[^)]+)\n([^\n]{50,})"
    message: "Functions should be short (max 30 lines) for readability. Consider breaking this function down."
    languages: [lua]
    severity: warning

  - id: lua-comment-blocks
    pattern: "--\n--.*\n--.*"
    message: "Use block comments (--[[ ... ]]) for multi-line explanations."
    languages: [lua]
    severity: info

  - id: lua-inline-comments
    pattern: "--[^\n]+"
    message: "Use inline comments sparingly. Prefer descriptive function/variable names."
    languages: [lua]
    severity: info

  # =============================================
  # 2. Design Patterns
  # =============================================
  - id: lua-module-pattern
    pattern: "local M = {}\n.*\nreturn M"
    message: "Encapsulate code in modules using `local M = {}; return M`."
    languages: [lua]
    severity: info

  - id: lua-avoid-globals
    pattern: "[A-Z][a-zA-Z0-9_]* = "
    message: "Avoid global variables. Use `local` to limit scope."
    languages: [lua]
    severity: warning

  - id: lua-closure-pattern
    pattern: "function[^(]+\([^)]*\)\n.*\n.*end"
    message: "Consider using closures for data encapsulation."
    languages: [lua]
    severity: info

  # =============================================
  # 3. Performance Optimizations
  # =============================================
  - id: lua-localize-frequent-access
    pattern: "_G\.[a-zA-Z_][a-zA-Z0-9_]*"
    message: "Localize frequently accessed globals (e.g., `local print = print`)."
    languages: [lua]
    severity: warning

  - id: lua-avoid-table-creation-in-loops
    pattern: "for[^d]+do.*{.*}.*end"
    message: "Avoid creating tables inside loops. Reuse or pre-allocate tables."
    languages: [lua]
    severity: warning

  - id: lua-string-concat-optimization
    pattern: ".."
    message: "Use `table.concat` for large string concatenations."
    languages: [lua]
    severity: warning

  # =============================================
  # 4. Commenting Guidelines
  # =============================================
  - id: lua-function-docstring
    pattern: "function[^(]+\([^)]*\)"
    message: "Add a docstring (--[[ ... ]]) above functions to explain purpose, args, and return values."
    languages: [lua]
    severity: warning

  - id: lua-complex-logic-comment
    pattern: "if[^t]+then.*else"
    message: "Add comments for complex logic (e.g., `-- Handle edge case: ...`)."
    languages: [lua]
    severity: info

  - id: lua-todo-comments
    pattern: "-- TODO:"
    message: "Use `-- TODO:` for temporary notes. Resolve before merging."
    languages: [lua]
    severity: warning

  # =============================================
  # 5. Error Handling
  # =============================================
  - id: lua-error-handling
    pattern: "pcall\("
    message: "Use `pcall` for error-prone operations and handle errors gracefully."
    languages: [lua]
    severity: warning

  - id: lua-assert-with-message
    pattern: "assert\("
    message: "Use `assert(value, 'message')` for debugging critical assumptions."
    languages: [lua]
    severity: info

  # =============================================
  # 6. Code Structure
  # =============================================
  - id: lua-consistent-indentation
    pattern: "^\s{2,}"
    message: "Use 2 spaces for indentation. Avoid tabs."
    languages: [lua]
    severity: warning

  - id: lua-line-length
    pattern: ".{80,}"
    message: "Limit lines to 80 characters for readability."
    languages: [lua]
    severity: warning