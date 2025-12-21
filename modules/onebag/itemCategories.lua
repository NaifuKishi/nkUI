local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag

local stringFind    = string.find

---------- local functions ---------

-- Creates an item category UI element
function oneBag.createItemCategory(name, parent)
    local categoryFrame = EnKai.uiCreateFrame("nkFrame", name .. ".categoryFrame", parent)
    categoryFrame:SetHeight(60 * data.uiScale)
    
    local categoryText = EnKai.uiCreateFrame("nkText", name .. ".categoryText", categoryFrame)
    categoryText:SetFontSize(14 * data.uiScale)
    categoryText:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT")
    categoryText:SetFontColor(1, 1, 1, 1)
    categoryText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    categoryText:SetEffectGlow({ strength = 3})
    categoryText:SetLayer(1)
    
    function categoryFrame:SetText(newText)
        categoryText:ClearWidth()
        categoryText:SetText(newText)
    end
    
    function categoryFrame:GetTextWidth()
        return categoryText:GetWidth()
    end
    
    return categoryFrame
end

-- Gets the real category name for an item
function oneBag.getRealCategory(category, rarity)
    if category == nil then
        return "Various"
    elseif stringFind(category, "consumable") then
        return "Consumable"
    elseif stringFind(category, "armor") then
        return "Armor"
    elseif stringFind(category, "artifact") then
        return "Artifact"
    elseif stringFind(category, "quest") then
        return "Quest"
    elseif stringFind(category, "fish") then
        return "Fishing"
    elseif stringFind(category, "meat") then
        return "Meat"
    elseif stringFind(category, "butchering") then
        return "Butchering"
    elseif stringFind(category, "cloth") then
        return "Cloth"
    elseif stringFind(category, "weapon") then
        return "Weapon"
    elseif stringFind(category, "misc") then
        if rarity == "sellable" then
            return "Trash"
        else
            return "Various"
        end
    elseif stringFind(category, "crafting ingredient") then
        return "Crafting material"
    elseif stringFind(category, "crafting recipe") then
        return "Crafting recipe"
    elseif stringFind(category, "crafting material") or stringFind(category, "crafting augment") then
        return "Crafting material"
    elseif stringFind(category, "container") then
        return "Container"
    elseif stringFind(category, "armor costume") then
        return "Costume"
    elseif stringFind(category, "dimension") then
        return "Dimension"
    elseif stringFind(category, "planar vessel") then
        return "Planar Fokus"
    end
    
    return category
end