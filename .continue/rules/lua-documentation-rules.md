---
globs: "**/*.lua"
description: This rule applies to all LUA files and functions within the
  project. It ensures that all code is well-documented for better
  maintainability and understanding. Only functions that are part of the
  returned table should be documented.
alwaysApply: true
---

Every LUA file must start with a header comment block that includes:
- File name
- Author (always NaifuKishi)
- Date of creation and date of last modification
- Brief description of the file's purpose
- A list of all public functions (callable from other lua files) in the file
- Version history (if applicable)

Every function must be documented using the following format:
```lua
--[[ 
   _functionName
    Description:
        [Brief description of what the function does]
    Parameters:
        [param1] ([type]): [Description of param1]
        [param2] ([type]): [Description of param2]
    Returns:
        [returnType]: [Description of return value]
    Notes:
        - [Additional notes, warnings, or usage examples if needed and only important things which might not be understandable from the code]
    Available Methods:
        - [Method1]: [Description]
        - [Method2]: [Description]
]]
```

Use inline comments to explain complex logic, non-obvious decisions, or important details.

## Rules for continue.dev

1. **Enforce Documentation**: Always require documentation for new functions, modules, and scripts.
2. **Standardize Format**: Use the provided format for all documentation blocks.
3. **Review Documentation**: Ensure documentation is clear, accurate, and up-to-date during code reviews.
4. **Update Documentation**: Whenever a function or module is updated, ensure its documentation is also updated.
5. **Encourage Clarity**: Prefer clarity and completeness over brevity in documentation.

## Best Practices
- Use descriptive names for functions and variables.
- Keep documentation close to the code it describes.
- Use examples in documentation where helpful.
- Document edge cases and error handling.

## Additional Rule for Lua Tables
- Only document functions that are part of the returned table. Functions defined locally within should not be documented unless they are part of the returned table.