
local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events

local stringFormat      = string.format

---------- init local variables ---------

local name = "onebag"
local itemIcons = {}

---------- make global functions local ---------

local function _fctItemIcon (name, parent)

    local itemFrame = EnKai.uiCreateFrame("nKFrame", name, parent) 
    itemFrame:SetWidth(40)
    itemFrame:SetHeight(40)
    
    local itemIcon = EnKai.uiCreateFrame("nkTexture", name .. ".icon", itemFrame)
    itemIcon:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 2, 2)
    itemIcon:SetPoint("BOTTOMRIGHT", itemFrame, "BOTTOMRIGHT", -2, -2)

    local quantityText = EnKai.uiCreateFrame("nkText", name .. ".quantityText", itemIcon)
    quantityText:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT", -2, -2)
    quantityText:SetFontSize(12)
    quantityText:SetFontColor(1, 1, 1, 1)
    quantityText:SetTextFont (addonInfo.id, "Montserrat")

    function itemFrame:SetIcon(addonName, path)
        itemIcon:SetTextureAsync(addonName, path)
    end

    function itemFrame:SetQuantity(quantity)
        if quantity then
            quantityText:SetText(quantity)
            quantityText:SetVisible(true)
        else
            quantityText:SetVisible(false)
        end
    end

    function itemFrame:SetRarity(rarity)
        if rarity == "sellable" then
            itemFrame:SetBackgroundColor(0.5, 0.5, 0.5, 1)
        elseif rarity == "uncommon" then
            itemFrame:SetBackgroundColor(0, 1, 0, 1)
        elseif rarity == "rare" then
            itemFrame:SetBackgroundColor(0, 0, 1, 1)
        elseif rarity == "epic" then
            itemFrame:SetBackgroundColor(0.5, 0, 0.5, 1)
        elseif rarity == "relic" then
            itemFrame:SetBackgroundColor(0.5, 0.5, 0, 1)
        elseif rarity == "transcendent" then
            itemFrame:SetBackgroundColor(1, 0.5, 0, 1)
        elseif rarity == "quest" then
            itemFrame:SetBackgroundColor(0.8, 0.6, 0.2, 1)  -- Darkish yellow color
        else
            itemFrame:SetBackgroundColor(1, 1, 1, 1)
        end
    end

    return itemFrame

end

local function _fctBagUI()

    local bagWindow = EnKai.uiCreateFrame("nkWindowMetro", "nkUI.bagWindow", uiElements.contextTop)
    bagWindow:SetTitle("nkUI Inventory")
    bagWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    bagWindow:SetWidth(600)
    bagWindow:SetHeight(600)
    bagWindow:SetPoint("BOTTOMRIGHT", UI.Native.BagInventory1, "BOTTOMRIGHT")
    bagWindow:SetShadow(true)

    return bagWindow

end

local function _populateBag()

    local from, object, to, x, y = "TOPLEFT", uiElements.oneBag:GetContent(), "TOPLEFT", 5, 0
    local counter = 1
    local firstIcon = nil

    local items = EnKai.inventory.getBagItems()

    for k, v in pairs (items) do

        if itemIcons[k] == nil then
            itemIcons[k] = _fctItemIcon ("nkUI.onebagItem." .. k, uiElements.oneBag)
            itemIcons[k]:SetIcon("Rift", v.icon)
            itemIcons[k]:SetRarity(v.rarity)
            itemIcons[k]:SetQuantity(stringFormat("%d", v.stack))
        end

        itemIcons[k]:SetPoint(from, object, to, x, y)
    
        if counter == 1 then firstIcon = itemIcons[k] end

        counter = counter + 1
        if counter > 10 then
            object, to, x , y = firstIcon, "BOTTOMLEFT", 0, 5
            counter = 1
        else
            object, to, x, y = itemIcons[k], "TOPRIGHT", 5, 0
        end        
    end

end

function _internal.oneBagInit()

    EnKai.inventory.updateDB()
    uiElements.oneBag = _fctBagUI()
    _populateBag()

    Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].Update, function (_, a, b)
        
	end, "nkUI.OneBag.EnKai.InventoryManager.Update")

end