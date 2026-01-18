local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag
local langTexts     = privateVars.langTexts

local stringFind    = string.find

---------- local functions ---------

-- Creates an item category UI element
function oneBag.createItemCategory(name, parent)
    local categoryFrame = LibEKL.UICreateFrame("nkFrame", name .. ".categoryFrame", parent)
    categoryFrame:SetHeight(60 * data.bagScale)

    local categoryText = LibEKL.UICreateFrame("nkText", name .. ".categoryText", categoryFrame)
    categoryText:SetFontSize(14 * data.bagScale)
    categoryText:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", -3, 0)
    categoryText:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
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
        return langTexts.itemCategories.various
    elseif stringFind(category, "consumable") then
        return langTexts.itemCategories.consumable
    elseif stringFind(category, "armor") then
        return langTexts.itemCategories.armor
    elseif stringFind(category, "artifact") then
        return langTexts.itemCategories.artifact
    elseif stringFind(category, "quest") then
        return langTexts.itemCategories.quest
    elseif stringFind(category, "fish") then
        return langTexts.itemCategories.fishing
    elseif stringFind(category, "meat") then
        return langTexts.itemCategories.meat
    elseif stringFind(category, "butchering") then
        return langTexts.itemCategories.butchering
    elseif stringFind(category, "cloth") then
        return langTexts.itemCategories.cloth
    elseif stringFind(category, "weapon") then
        return langTexts.itemCategories.weapon
    elseif stringFind(category, "misc") then
        if rarity == "sellable" then
            return langTexts.itemCategories.trash
        else
            return langTexts.itemCategories.various
        end
    elseif stringFind(category, "crafting ingredient") then
        return langTexts.itemCategories.craftingMaterial
    elseif stringFind(category, "crafting recipe") then
        return langTexts.itemCategories.craftingRecipe
    elseif stringFind(category, "crafting material") or stringFind(category, "crafting augment") then
        return langTexts.itemCategories.craftingMaterial
    elseif stringFind(category, "container") then
        return langTexts.itemCategories.container
    elseif stringFind(category, "armor costume") then
        return langTexts.itemCategories.costume
    elseif stringFind(category, "dimension") then
        return langTexts.itemCategories.dimension
    elseif stringFind(category, "planar vessel") then
        return langTexts.itemCategories.planarFocus
    elseif stringFind(category, "planar lesser") then
        return langTexts.itemCategories.planarLesser
    elseif stringFind(category, "planar greater") then
        return langTexts.itemCategories.planarGreater
    end

    return category
end