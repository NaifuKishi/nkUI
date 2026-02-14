local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag
local langTexts     = privateVars.langTexts

local inspectItemDetail = Inspect.Item.Detail
local inspectTimeReal   = Inspect.Time.Real

local stringFormat  = string.format
local mathFloor     = math.floor

local showTooltip   = false

---------- local functions ---------

local function uiItemTooltip ()

    local tooltip = LibEKL.UICreateFrame("nkCanvas", "nkUI.oneBag.tooltip", uiElements.contextTooltip)
    tooltip:SetPoint("TOPLEFT", UI.Native.Tooltip, "BOTTOMLEFT", 5, 5)
    tooltip:SetPoint("BOTTOMRIGHT", UI.Native.Tooltip, "BOTTOMRIGHT", -5, 70)
    
    local stroke = {r = .6, g = .6, b = .6, a = .8, thickness = 1 }
    local path =  {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  
    local fill = {type = "solid", r = 0, g = 0, b = 0, a = .8}

    tooltip:SetShape(path, fill, stroke)

    local currencyIcon = LibEKL.UICreateFrame("nkTexture", "nkUI.oneBag.tooltip.Currency.icon", tooltip)
    currencyIcon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, 10)
    currencyIcon:SetHeight(12)
    currencyIcon:SetWidth(12)
    currencyIcon:SetTextureAsync("nkUI", "gfx/questIconCoin.png")

    local valueText = LibEKL.UICreateFrame("nkText", "nkUI.oneBag.tooltip.valueText", tooltip)
    valueText:SetPoint("CENTERLEFT", currencyIcon, "CENTERRIGHT", 5, 0)
    valueText:SetFontSize(12 * data.bagScale)
    valueText:SetEffectGlow({strength = 3})
    valueText:SetFontColor(1, 1, 1, 1)

    LibEKL.UI.SetFont(valueText, addonInfo.id, "MontserratSemiBold")

    local auctionIcon = LibEKL.UICreateFrame("nkTexture", "nkUI.oneBag.tooltip.Auction.icon", tooltip)
    auctionIcon:SetPoint("TOPLEFT", currencyIcon, "BOTTOMLEFT", 0, 5)
    auctionIcon:SetHeight(12)
    auctionIcon:SetWidth(12)
    auctionIcon:SetTextureAsync("nkUI", "gfx/iconAuction.png")

    local auctionText = LibEKL.UICreateFrame("nkText", "nkUI.oneBag.tooltip.auctionText", tooltip)
    auctionText:SetPoint("CENTERLEFT", auctionIcon, "CENTERRIGHT", 5, 0)
    auctionText:SetFontSize(12 * data.bagScale)
    auctionText:SetEffectGlow({strength = 3})
    auctionText:SetFontColor(1, 1, 1, 1)

    LibEKL.UI.SetFont(auctionText, addonInfo.id, "MontserratSemiBold")

    local bagIcon = LibEKL.UICreateFrame("nkTexture", "nkUI.oneBag.tooltip.BagSlotsIcon.icon", tooltip)
    bagIcon:SetPoint("TOPLEFT", auctionIcon, "BOTTOMLEFT", 0, 5)
    bagIcon:SetHeight(12)
    bagIcon:SetWidth(12)
    bagIcon:SetTextureAsync("nkUI", "gfx/iconPackage.png")

    local countText = LibEKL.UICreateFrame("nkText", "nkUI.oneBag.tooltip.countText", tooltip)
    countText:SetPoint("CENTERLEFT", bagIcon, "CENTERRIGHT", 5, 0)
    countText:SetFontSize(12 * data.bagScale)
    countText:SetEffectGlow({strength = 3})    
    countText:SetFontColor(0x85 / 255, 0xCB / 255, 0xCB / 255, 1)

    LibEKL.UI.SetFont(countText, addonInfo.id, "MontserratSemiBold")

    function tooltip:SetItem(itemID)

        local flag, details = pcall(inspectItemDetail, itemID)        
        local qty = 0

        if flag and details and details.sell then                         
            valueText:SetText(internalFunc.formatCoins(details.sell), true)
        else
            valueText:SetText(langTexts.oneBag.noPrice)
        end

        if not nkUIAuction then nkUIAuction = {} end
        local shard = Inspect.Shard().name
        if not nkUIAuction[shard] then nkUIAuction[shard] = { lastScan = nil, items = {}} end        

        if flag and details and details.type then

            local thisAuctionItem = nkUIAuction[shard].items[details.type]

            if thisAuctionItem then
           
                local difference = math.abs(inspectTimeReal() - thisAuctionItem.lastSeen)
                local days = difference / 3600 / 24

                local coinText = internalFunc.formatCoins(thisAuctionItem.avgPrice)
                
                auctionText:SetText(stringFormat(langTexts.oneBag.auctionPrice, coinText, days), true)
            else
                auctionText:SetText(langTexts.oneBag.noAuction)
            end
        else
            auctionText:SetText(langTexts.oneBag.noAuction)
        end
        
        qty = LibEKL.Inventory.queryQtyById (itemID)

        if qty > 0 then countText:SetText(stringFormat(langTexts.oneBag.youOwn, qty)) end
    end

    return tooltip

end

function oneBag.showItemTooltip (thisItemID)

    if uiElements.oneBagItemTooltip == nil then
        uiElements.oneBagItemTooltip = uiItemTooltip()
    end

    uiElements.oneBagItemTooltip:SetItem(thisItemID)
    --uiElements.oneBagItemTooltip:SetVisible(true)
    showTooltip = true

end

function oneBag.hideItemTooltip ()

    showTooltip = false
    if uiElements.oneBagItemTooltip then uiElements.oneBagItemTooltip:SetVisible(false) end

end

function oneBag.initItemTooltip ()

    UI.Native.Tooltip:EventAttach(Event.UI.Native.Loaded, function()
        
        if not showTooltip then return end

        -- Wird benötigt weil der Ingame Tooltip rumspringt und sonst der Zusatzframe kurz oben Links im Screen angezeigt wird

        LibEKL.Events.AddInsecure(function()            
            uiElements.oneBagItemTooltip:SetVisible(UI.Native.Tooltip:GetLoaded())    
        end, inspectTimeReal(), 0.3) 
        
    end, "nkUI.OneBag.Native.Tooltip.Loaded")

end