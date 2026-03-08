# nkUI Changelog

## [1.5.0] – 2026-03-08

### New Features

#### Minion Manager
- Added a full-featured **Minion Manager** module for managing and auto-sending minions on adventures
- Displays minion cards with stats, rarity, and equipment details
- Auto-send system: automatically assigns the best minions to adventures based on stat matching
- New settings tab for Minion Manager configuration
- New **Lowerbar dataset** showing active minion adventure status (free / working / finished)
  - Click to claim finished adventures or auto-send new ones
  - Color-coded status display

#### Wardrobe
- Added a **Wardrobe module** for saving and switching equipment outfits
- Full equipment slot overview with individual slot icons for all gear slots (helmet, chest, legs, etc.)
- New **Lowerbar dataset** for quick wardrobe access
- Edit mode for managing saved outfits

#### Auction House
- Added an **Auction House module** for browsing and selling items
  - Browse tab: search and filter auction listings
  - Sell tab: post items directly from your bags
  - Integrated auction tooltip showing price history and statistics
- New settings tab for Auction House configuration
- Auction icon in OneBag is now hidden when the Auction House is not open
- Replaced legacy auction SavedVariables with a new, cleaner data structure

---

### Improvements

#### Action Bar
- Keybinds now persist correctly in SavedVariables when set on action icons
- Keybinds are now preserved when replacing an ability on an action icon

#### Map
- Multiple performance optimisations to reduce frame time during map rendering
- Optimised event handling and element updates

#### Item Tooltip
- Fixed several display issues in the item tooltip
- Improved layout and formatting of the auction price section in tooltips

#### Lowerbar
- Realigned dataset positioning for a more consistent layout
- Updated LibEKL integration for lowerbar elements

#### OneBag
- Added a dedicated **OneBag settings tab** with the option to toggle the module on/off

#### Settings
- Fixed a crash in the SCT (Scrolling Combat Text) settings tab
- Fixed various typos in locale strings (EN, DE, FR)

---

### Bug Fixes

- Fixed keybind not persisting in SavedVars on the action bar
- Fixed incorrect stat matching in the Minion auto-send logic
- Fixed auction tooltip rendering errors
- Fixed a settings panel error in the SCT tab
