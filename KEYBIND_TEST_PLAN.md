# Keybind Labels Feature - Complete Test Plan

## Overview
The keybind labels feature allows players to assign keyboard shortcuts to action bar icons and display those keybinds as labels on the icons themselves. The feature is now complete with all three phases implemented and ready for comprehensive in-game testing.

**Status:** READY FOR TESTING (Commits: 3889fe4, be9b7cc, 486bf68, 59847ac, 8add925)

---

## Feature Components

### Phase 1: Data Layer (Complete)
- SavedVar extension: `slots[n].keyBind` field to store keybind strings
- Backward compatible: keybind field is optional
- Existing characters unaffected

### Phase 2: UI Display (Complete)
- Keybind label text element on each action icon
- Position: Bottom-right corner with -2px offset
- Font: Montserrat Bold, 10pt, white color
- Glow: Subtle (strength=1) for visibility without clutter
- Lazy-created: Only allocates when first keybind assigned

### Phase 3: User Input (Complete)
- Key capture dialog with SetKeyFocus()
- Right-click action icon → Dialog appears
- Press any key → Dialog shows captured key
- Save/Clear/Cancel buttons
- Automatic bar repopulation after save
- Automatic label persistence across sessions

---

## Test Scenarios

### Scenario 1: Basic Keybind Assignment
**Goal:** Verify keybind dialog opens and captures keys correctly

**Steps:**
1. Load nkUI addon in Rift
2. Open action bar (should be visible by default)
3. Right-click any action icon
   - **Expected:** Keybind dialog appears with title "Set Keybind"
   - **Expected:** Dialog shows "Waiting for key input..."
   - **Dialog location:** Near the action icon
4. Press a single key (e.g., "Q")
   - **Expected:** Dialog updates to show "Captured: Q"
   - **Expected:** Text color changes to green
5. Click the "Save" button
   - **Expected:** Dialog closes
   - **Expected:** Console message: "[nkUI] Keybind set to: Q"
   - **Expected:** Label "Q" appears in bottom-right corner of icon
6. **Result:** ✓ PASS if all expected behaviors occur

---

### Scenario 2: Keybind Persistence
**Goal:** Verify keybinds persist across game sessions

**Steps:**
1. Complete Scenario 1 (assign "Q" to an icon)
2. Note the location of the icon with "Q" label
3. Log out of Rift (or /reloadui if supported)
4. Relog / Reload UI
5. Check the same action bar icon
   - **Expected:** Label "Q" is still visible in the same position
   - **Expected:** No additional setup needed
6. Right-click the icon again
   - **Expected:** Dialog opens, shows "Waiting for key input..." (cleared for new entry)
7. **Result:** ✓ PASS if label persists across sessions

---

### Scenario 3: Modifier Keys
**Goal:** Verify modifier key combinations are captured correctly

**Steps:**
1. Right-click an action icon
2. Press: Shift + Q
   - **Expected:** Dialog shows "Captured: Shift" (first key captured)
   - **Note:** Rift API captures individual keys, not combinations like "Shift+Q"
3. Click Clear to try again
4. Press Shift key alone
   - **Expected:** Dialog shows "Captured: Shift"
5. Click Save
   - **Expected:** Label shows "Shift" on the icon
6. **Result:** ✓ PASS if modifier keys are captured as individual keys

---

### Scenario 4: Numeric and Special Keys
**Goal:** Verify various key types are captured

**Steps:**
1. Right-click action icon
2. Press: "1" (numeric key)
   - **Expected:** "Captured: 1"
3. Click Save
   - **Expected:** Icon shows "1" label
4. Right-click again
5. Press: Space key
   - **Expected:** "Captured: space"
6. Click Save
   - **Expected:** Icon shows "space" label
7. **Result:** ✓ PASS if numeric and special keys work

---

### Scenario 5: Clear Keybind (Change)
**Goal:** Verify clearing and reassigning keybinds

**Steps:**
1. Assign "Q" to an icon (see Scenario 1)
2. Verify "Q" label visible
3. Right-click the icon again
4. Dialog shows "Waiting for key input..."
5. Press a different key (e.g., "E")
   - **Expected:** "Captured: E"
6. Click Save
   - **Expected:** Label changes from "Q" to "E"
   - **Expected:** Console message: "[nkUI] Keybind set to: E"
7. **Result:** ✓ PASS if keybind can be overwritten

---

### Scenario 6: Clear Key Button
**Goal:** Verify the "Clear key" button in the dialog

**Steps:**
1. Right-click action icon
2. Press a key (e.g., "Q")
   - **Expected:** "Captured: Q"
3. Click "Clear key" button
   - **Expected:** Text changes to "(cleared)"
   - **Expected:** Text color changes to red
4. Click Save
   - **Expected:** Dialog closes
   - **Expected:** No keybind label appears on icon
   - **Expected:** SavedVar cleared (no console confirmation, just no label)
5. **Result:** ✓ PASS if keybind can be cleared

---

### Scenario 7: Clear Slot Button
**Goal:** Verify "Clear Slot" button removes item and keybind

**Steps:**
1. Place an ability on action bar
2. Assign keybind "Q" to it (see Scenario 1)
3. Verify ability icon visible with "Q" label
4. Right-click the icon
5. Click "Clear Slot" button
   - **Expected:** Dialog closes
   - **Expected:** Entire slot is cleared (ability icon disappears)
   - **Expected:** Keybind label disappears
   - **Expected:** Slot is now empty/blank
6. **Result:** ✓ PASS if slot and keybind both cleared

---

### Scenario 8: Multiple Bars and Roles
**Goal:** Verify keybinds work across different action bars and roles

**Steps:**
1. Assign "Q" to an icon on main action bar
2. Assign "E" to an icon on the left action bar
3. Verify both labels visible
4. If playing character with multiple roles (e.g., Warrior Paragon):
   - Switch to different role
   - **Expected:** Action bars repopulate but keybinds persist
   - (Keybinds may be role-specific in SavedVars structure)
5. **Result:** ✓ PASS if keybinds display correctly across bars

---

### Scenario 9: Dialog Button Spacing
**Goal:** Verify dialog buttons are properly positioned

**Steps:**
1. Right-click action icon
2. Check dialog layout:
   - **Expected:** "Clear key" button on left
   - **Expected:** "Clear Slot" button next to it
   - **Expected:** "Save" button next to that
   - **Expected:** "Cancel" button on right
   - **Expected:** All buttons aligned horizontally
   - **Expected:** Buttons don't overlap
   - **Expected:** Dialog is readable at all resolutions
3. **Result:** ✓ PASS if layout is clean and readable

---

### Scenario 10: Cancel Button
**Goal:** Verify Cancel discards changes

**Steps:**
1. Right-click action icon (assume no existing keybind)
2. Press "Q"
   - **Expected:** "Captured: Q"
3. Click "Cancel" button
   - **Expected:** Dialog closes without saving
   - **Expected:** No label appears on icon
   - **Expected:** No console message
4. **Result:** ✓ PASS if Cancel doesn't save

---

### Scenario 11: Label Visibility During Combat
**Goal:** Verify keybind labels remain visible and don't interfere with combat

**Steps:**
1. Assign several keybinds to abilities (Q, E, R, etc.)
2. Verify labels visible on icons
3. Enter combat / engage an enemy
4. Use the abilities (press Q, E, R keys)
   - **Expected:** Abilities execute correctly
   - **Expected:** Keybind labels remain visible on action bar
   - **Expected:** No lag or visual artifacts
   - **Expected:** Bar remains non-interactive (can't accidentally drag)
5. **Result:** ✓ PASS if feature doesn't interfere with combat

---

### Scenario 12: Dynamic Bar Switching
**Goal:** Verify keybind feature doesn't break dynamic bar switching (Rogue stealth, etc.)

**Steps:**
1. For Rogue character: Assign "Q" to an ability
2. Switch stance/stealth (ability bar should change dynamically)
   - **Expected:** New ability bar appears
   - **Expected:** Previous keybind labels gone or hidden
   - **Expected:** No errors in console
3. Exit stance/stealth
   - **Expected:** Original bar returns
   - **Expected:** Keybind labels reappear
4. **Result:** ✓ PASS if dynamic switching works without issues

---

## Console Messages to Expect

When feature works correctly, you should see:

```
[nkUI] Keybind set to: Q
[nkUI] Keybind set to: E
[nkUI] Keybind set to: space
```

No error messages should appear in the console.

---

## Known Limitations

1. **Key Capture:** Rift API captures individual keys, not combinations
   - Pressing Shift+Q captures "Shift" (first modifier detected)
   - This is an API limitation, not a feature limitation

2. **Keybind Storage:** Currently stores as-is in SavedVars
   - Future: Could add keybind validation or normalization

3. **Dialog Position:** Positioned relative to icon
   - May appear off-screen on very small resolutions
   - Future: Smart positioning with screen boundary detection

---

## Debugging Tips

If something goes wrong:

1. **Dialog doesn't appear:**
   - Check: Is the icon clickable? (Try middle-click for macro editor as comparison)
   - Check: Are you right-clicking on an action icon, not empty space?

2. **Label doesn't appear after save:**
   - Check: Did you click "Save" or just "Cancel"?
   - Check: Is the action bar visible? (Try unhiding with /nkui settings)
   - Check: Try reloading UI with /reloadui

3. **Label appears but doesn't save:**
   - Relog to verify if it was actually saved to SavedVars
   - Check: Console for error messages

4. **Dialog off-screen:**
   - Try closing and reopening dialog
   - Try clicking action icon in different screen location
   - Restart game if needed

---

## Test Completion Checklist

- [ ] Scenario 1: Basic keybind assignment
- [ ] Scenario 2: Keybind persistence
- [ ] Scenario 3: Modifier keys
- [ ] Scenario 4: Numeric and special keys
- [ ] Scenario 5: Clear and reassign keybinds
- [ ] Scenario 6: Clear key button
- [ ] Scenario 7: Clear slot button
- [ ] Scenario 8: Multiple bars and roles
- [ ] Scenario 9: Dialog button spacing
- [ ] Scenario 10: Cancel button
- [ ] Scenario 11: Label visibility in combat
- [ ] Scenario 12: Dynamic bar switching (if applicable)

**Overall Result:** ✓ PASS if all scenarios pass

---

## Files Modified (Complete Implementation)

### Phase 1 (Data)
- `modules/actionbar/actionbar.lua` - SavedVar integration
- `modules/actionbar/actionicon.lua` - SetKeyBind() stub

### Phase 2 (Display)
- `modules/actionbar/actionicon.lua` - KeyBind label UI, createKeyBindLabel(), SetKeyBind() implementation

### Phase 3 (Input)
- `modules/actionbar/keybindDialog.lua` - New file, complete key capture dialog

### Bug Fixes
- `modules/actionbar/actionicon.lua` - Added SetKeyBind(nil) to ClearItem()
- `modules/cooldowns/cooldowns.lua` - Fixed data structure access pattern

---

## Next Steps After Testing

1. Gather feedback on:
   - Dialog positioning and usability
   - Label visibility and placement
   - Key capture behavior

2. Potential enhancements:
   - Allow multi-key combinations (requires Rift API enhancements)
   - Custom label text instead of key names
   - Keybind tooltips showing full binding info
   - Global hotkey help dialog listing all bound keys

---

**Last Updated:** Feb 26, 2026
**Ready for In-Game Testing:** YES
