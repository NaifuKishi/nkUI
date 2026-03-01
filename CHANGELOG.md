# Changelog

## [1.4.2] - 2025-02-28

### Added
- **OneBag Settings Tab**: New dedicated settings tab for the OneBag module with controls to:
  - Toggle OneBag module activation
  - Enable/disable bank module
  - Adjust OneBag size scale (30-300%)
- **Settings Organization**: Bank module and size settings moved from Basic theme tab to new OneBag tab for better organization

### Fixed
- **Auction System**:
  - Fixed persistent timestamp storage in auction tooltips (now uses `os.time()` instead of `Inspect.Time.Real()`)
  - Fixed "time since last scan" display to show correct elapsed time across client restarts
  - Improved auction tooltip display formatting
  - Fixed auction icon visibility when auction house is not opened
  - Replaced auction data SavedVariables structure for better data persistence

- **Action Bar**:
  - Fixed keybind not persisting in SavedVars on action bar
  - Fixed keybind preservation when replacing ability on action icon

- **Tooltips**: Fixed item tooltip display issues

- **Map Performance**: Multiple performance optimizations to reduce CPU usage during map rendering

- **Auction Scanning**: Optimized browse grid population to use coroutines, preventing CPU watchdog timeout during large scans with `Command.System.Watchdog.Quiet()`

- **Typos**: Fixed various text typos throughout the addon

- **Settings**: Fixed settings dialog error

### Changed
- Auction scan processing is now distributed over multiple frames using coroutines to prevent addon CPU overload

---

## [1.4.1] - Previous Release

For changes in 1.4.1 and earlier, see git history.
