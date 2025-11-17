---
title: LUA Documentation Rules
description: Guidelines for commenting and documenting LUA code in continue.dev
---

# LUA Documentation Rules

## General Documentation Requirements

- **File Header**: Every LUA file must start with a header comment block that includes:
  - File name
  - Author
  - Date of creation
  - Brief description of the file's purpose
  - Version history (if applicable)

- **Function Documentation**: Every function must be documented using the following format:

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
    Process:
        [Step-by-step explanation of the function's logic]
    Notes:
        - [Additional notes, warnings, or usage examples]
    Available Methods:
        - [Method1]: [Description]
        - [Method2]: [Description]
]]
```

- **Inline Comments**: Use inline comments to explain complex logic, non-obvious decisions, or important details.

## Example Documentation

```lua
--[[
   _uiWindowElement
    Description:
        Creates and configures a customizable window element with header, title, close button,
        and various interactive features. This function provides a framework for creating
        draggable, resizable, and collapsible windows with customizable appearance and behavior.
    Parameters:
        name (string): Unique identifier for the window element
        parent (frame): Parent frame to which this window will be attached
    Returns:
        window (frame): The configured window frame with all child elements and functionality
    Process:
        1. Creates the main window frame and its components (header, body, title, etc.)
        2. Sets up default styling and positioning
        3. Configures event handlers for mouse interactions (dragging, resizing, etc.)
        4. Implements various window behaviors (auto-hide, collapse, etc.)
        5. Provides getter and setter methods for window properties
        6. Sets up event system for window state changes
    Notes:
        - The window can be made draggable, resizable, and collapsible
        - Supports auto-hide functionality for both the window body and header
        - Provides customization options for appearance (colors, textures, fonts)
        - Implements secure mode support for restricted environments
        - Includes event system for tracking window state changes
        - Supports reverse-at-border behavior to keep windows within visible area
    Available Methods:
    **Window Behavior Methods:**
        - SetAutoHide(flag, duration): Sets auto-hide behavior for the window body
        - SetAutoHideHeader(flag, duration, delay): Sets auto-hide behavior for the window header
        - SetCollapseable(flag): Sets whether the window is collapsible
        - Collapse(flag): Collapses or expands the window
        - ToggleCollapse(): Toggles the collapse state of the window
        - SetReverseAtBorder(flag): Sets whether the window should reverse at the border
        - ProcessMove(): Processes window movement and adjusts layout if needed
    **Window State Methods:**
        - SetDragable(flag): Sets whether the window is draggable
        - SetCloseable(flag): Sets whether the window is closeable
        - SetResizable(flag): Sets whether the window is resizable
        - ShowContent(flag): Shows or hides the window content
        - DisplayHeader(flag): Shows or hides the window header
        - SetSecureMode(newMode): Sets the secure mode of the window
    **Window Appearance Methods:**
        - SetBackgroundColor(r, g, b, a): Sets the background color of the window body
        - SetArrowTextures(addon, arrowRight, arrowDown): Sets custom arrow textures
        - SetTitleFont(addonId, fontName): Sets custom font for the title
        - SetTitle(newTitle): Sets the window title text
        - SetTitleAlign(newAlign, newOffSet): Sets title alignment and offset
        - SetFontSize(newFontSize): Sets title font size
        - SetTitleColor(r, g, b, a): Sets title color
    **Window Size and Position Methods:**
        - SetWidth(newWidth): Sets the width of the window
        - SetHeight(newHeight): Sets the height of the window
        - SetPoint(from, object, to, x, y): Sets the position of the window
    **UI Element Accessor Methods:**
        - GetContent(): Returns the content body frame
        - GetHeader(): Returns the header frame
        - GetArrow(): Returns the arrow icon frame
        - GetMoveCheckbox(): Returns the move checkbox frame
    **UI Element Visibility Methods:**
        - ShowMoveToggle(flag): Shows or hides the move toggle checkbox
        - ShowAutoHideToggle(flag): Shows or hides the auto-hide toggle arrow
]]
```

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