# nkUI v1.4.0 - Changelog

## Release Date
February 28, 2026

## New Features

### Manual System
- **Complete Manual Module**: Replaced the old tutorial system with a comprehensive manual
- **Welcome Page**: Displays nkUI logo, current version, and changelog for latest version
- **Overview Page**: Explains nkUI's purpose and basic features
- **Default UI Setup Guide**: Step-by-step instructions for hiding default RIFT UI elements
- **17 Module Sections**: Detailed documentation for each nkUI module
- **Multi-language Support**: Manual available in English, German, and French

### Lower Bar Enhancements
- **Interactive Location Display**: Click on location to show teleport options
- **Interactive Role Display**: Click on role to switch to another role
- **Enhanced CPU Display**: Click on CPU/FPS display to open nkDebug (if installed)

### Action Bar Improvements
- **Keybind Labels**: Added keybind label display on action bar icons
- **Keybind Dialog**: Right-click action bar slot to open keybind assignment dialog
- **Exclusive Keybinding**: Keybinds are automatically removed from other icons when assigned
- **Keybind Persistence**: Keybinds are saved per character and persist across sessions
- **Auto-reload on Save**: UI automatically reloads when keybind is saved for immediate display

### LibEKL Updates
- **SetFontSize in nkButton**: New method to dynamically set button font sizes
- **formatNumber Function**: New string formatting function for readable number display
- **Improved Button Styling**: Enhanced button rendering and visual consistency
- **Grid Fixes**: Improved grid cell rendering and layout
- **Manager Updates**: Better UI element management and lifecycle handling

## Improvements & Fixes

### General
- **Removed Tutorial System**: Deleted all old tutorial code and graphics (13 files)
- **Cleaned Up Codebase**: Removed tutorial references from all modules
- **Code Quality**: Various code cleanup and optimization
- **Performance**: Removed garbage collection and recycling optimizations (reverted to stable)

### LibEKL Framework
- **Removed LibTransform**: Simplified transform handling
- **Improved Scaling**: Fixed scaling issues when rotating UI elements
- **Strata Bugfix**: Small window layering improvements
- **Window Icon Management**: Fixed missing window element icons
- **Manager Improvements**: Better internal UI management and event handling

### Bug Fixes
- **Grid Cell Rendering**: Fixed issues with grid cells not displaying correctly
- **Window Elements**: Fixed missing icons in various window elements
- **Strata/Layering**: Fixed window strata positioning issues
- **Print/Debug Statements**: Removed leftover debug print statements and dumps
- **General Stability**: Various bug fixes for improved addon stability

### Code Cleanups
- Removed garbage collection code for stability
- Removed recycling optimizations that caused issues
- Cleaned up version handling code
- Removed debug prints and dump statements
- Improved overall code organization

## Breaking Changes
- **Tutorial System Removed**: The old tutorial window is no longer available
- **Manual Button**: Replaces the old tutorial button in settings

## Developer Notes
- All code has been validated with Lua 5.1 syntax checker
- GitHub Actions Release Workflow added for automated ZIP creation
- All manual translations (EN, DE, FR) have been updated
- Submodule (LibEKL) integration improved with recursive checkout in workflow

## Installation
Extract the nkUI.zip to your RIFT Interface/Addons directory:
```
Interface/Addons/nkUI/
```

## Compatibility
- **RIFT Version**: 4.0+
- **Dependencies**: LibEKL, LibMap, LibQB (embedded)
- **Languages**: English, German, French

## Known Issues
None reported at this time.

## Credits
- **Developer**: NaifuKishi
- **Inspired by**: ndUI, ToxiUI, Parrot, ElvUI
- **Contact**: rift@naifukishi.com

---

## Version Comparison: v1.3.2 → v1.4.0

### Major Changes
1. **Tutorial → Manual System**: Complete replacement with comprehensive documentation
2. **Lower Bar Interactivity**: Added three new interactive elements
3. **Action Bar Keybinds**: Full keybind label system implementation
4. **LibEKL Updates**: Button styling and grid improvements
5. **Code Cleanup**: Removed obsolete systems (garbage collection, recycling)

### File Changes
- **New**: `settings/manual.lua` - Manual UI module
- **New**: `.github/workflows/release.yml` - Automated release workflow
- **Deleted**: `settings/tutorial.lua` - Old tutorial system
- **Deleted**: 13 tutorial graphics files (gfx/tutorial*.png)
- **Modified**: `locales/localization*.lua` - Tutorial → Manual translations
- **Modified**: `settings/settings.lua` - Manual button integration
- **Modified**: `main.lua` - Removed tutorial initialization
- **Modified**: `modules/actionbar/keybindDialog.lua` - Keybind system
- **Modified**: `modules/lowerbar/` - Interactive element handling
- **Modified**: `Libs/LibEKL/` - Button styling and grid improvements

### Statistics
- **Commits since v1.3.2**: 15 major commits
- **Files Added**: 2
- **Files Deleted**: 14
- **Files Modified**: 10+
- **Lines of Code Changed**: 1000+
