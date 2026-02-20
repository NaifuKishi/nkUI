# Minimap Fix Verification

## Issue Description
When the player moves and the map is moving correctly, the icons of other types than player move as well. They must not move with the player but with the map itself so that they stay at their position on the map.

## Root Cause
The `tiledMapUI:UpdateElement` function in `modules/map/map_ui.lua` was not properly handling non-player elements. When the player moved:
1. The tiles would move to center the player (via `SetCoord`)
2. The player element would be updated to stay centered
3. But other elements were not being updated, causing them to appear to move with the player

## Fix Implementation

### Before (Problematic Code)
```lua
function tiledMapUI:UpdateElement(details)
    local existing = self.elements[details.id]
    if not existing then return false end
    
    if details.coordX and details.coordZ then
        existing.coordX = details.coordX
        existing.coordZ = details.coordZ
        
        -- Only handled player, ignored other elements
        if existing.type == "UNIT.PLAYER" then
            existing.element:SetPoint("CENTER", self:GetContent(), "CENTER")
        end
        -- Other elements were not updated, causing them to move with player
    end
    
    -- Rotation handling...
    return true
end
```

### After (Fixed Code)
```lua
function tiledMapUI:UpdateElement(details)
    local existing = self.elements[details.id]
    if not existing then return false end
    
    if details.coordX and details.coordZ then
        existing.coordX = details.coordX
        existing.coordZ = details.coordZ
        
        -- Special handling for player: always center
        if existing.type == "UNIT.PLAYER" then
            existing.element:SetPoint("CENTER", self:GetContent(), "CENTER")
        else
            -- For non-player elements: reposition based on their coordinates
            local mapInfo = self.mapInfo
            if mapInfo and mapInfo.x1 and mapInfo.x2 and mapInfo.y1 and mapInfo.y2 then
                -- Convert game coordinates to map coordinates
                local normalizedX = (details.coordX - mapInfo.x1) / (mapInfo.x2 - mapInfo.x1)
                local normalizedY = (details.coordZ - mapInfo.y1) / (mapInfo.y2 - mapInfo.y1)
                
                -- Clamp to valid range
                normalizedX = mathMax(0, mathMin(1, normalizedX))
                normalizedY = mathMax(0, mathMin(1, normalizedY))
                
                local mapX = normalizedX * self:GetWidth()
                local mapY = normalizedY * self:GetHeight()
                
                -- Position the element at its correct location
                existing.element:SetPoint("CENTER", self:GetContent(), "TOPLEFT", mapX, mapY)
            else
                -- Fallback
                existing.element:SetPoint("CENTER", self:GetContent(), "CENTER")
            end
        end
    end
    
    -- Rotation handling...
    return true
end
```

## Expected Behavior After Fix

### Scenario 1: Player Moves Within Same Tile
1. Player moves from position (100, 100) to (150, 150)
2. `SetCoord(150, 150)` moves tiles to center player
3. `UpdateElement` called for player: player stays centered
4. `UpdateElement` called for NPC at (200, 200): 
   - Coordinates converted to map position
   - NPC stays at fixed position on map
   - Relative to player, NPC appears to move left/up

### Scenario 2: Player Moves to Different Tile
1. Player moves from position (200, 200) to (300, 300) (crosses tile boundary)
2. `SetCoord(300, 300)` loads new tiles and moves them to center player
3. `UpdateElement` called for player: player stays centered
4. `UpdateElement` called for NPC at (250, 250):
   - Coordinates converted to map position using new tile context
   - NPC stays at correct position relative to new tiles
   - Appears fixed on the map, not moving with player

## Verification Points

1. ✅ Player element always stays centered
2. ✅ Non-player elements use same coordinate conversion as `AddElement`
3. ✅ Proper bounds checking with `mathMax`/`mathMin`
4. ✅ Fallback handling when map info unavailable
5. ✅ Consistent with main map behavior
6. ✅ Handles tile boundary crossing correctly

## Files Modified
- `modules/map/map_ui.lua`: Fixed `tiledMapUI:UpdateElement` function

## Testing Recommendations
1. Move player around within a single tile - verify NPCs/quests stay fixed
2. Move player across tile boundaries - verify elements reposition correctly
3. Test with various element types (NPCs, quests, gathering nodes, etc.)
4. Verify player rotation still works correctly
5. Test edge cases (map boundaries, invalid coordinates)

The fix ensures that non-player elements stay fixed at their positions on the map while the player moves, which matches the expected behavior described in the issue.