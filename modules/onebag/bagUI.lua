local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag
local langTexts     = privateVars.langTexts

---------- local functions ---------

local inspectCurrencyDetail = Inspect.Currency.Detail

local stringFormat  = string.format
local mathFloor     = math.floor

local context = UI.CreateContext("nkUI.onebag")
context:SetStrata('dialog')
context:SetLayer(2)

-- Creates the main bag UI window
function oneBag.createBagUI(bagName, bagTitle, isBag)

    local currencyText, currencyText, freeBagSlotsText, bagIcon
    
    local bagWindow = LibEKL.UICreateFrame("nkWindow", bagName, context)
    bagWindow:SetTitle(stringFormat(bagTitle, LibEKL.Unit.getPlayerDetails().name))
    bagWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    bagWindow:SetTitleFontSize(16)
    bagWindow:SetTitleEffect({ strength = 3})
    bagWindow:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

    bagWindow:SetWidth(690 * data.bagScale)
    bagWindow:SetHeight(600 * data.bagScale)
    bagWindow:SetLayer(1)    
    
    if isBag then
        bagWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.oneBag.x, nkUISetup.modules.oneBag.y)
    else
        bagWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.oneBag.bankX, nkUISetup.modules.oneBag.bankY)
    end

    bagWindow:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, -(math.pi / 6), 0, 0), -- Negative angle for opposite direction
        color = {
            data.theme.windowStartColor,
            data.theme.windowEndColor
            }
    },  { r = 0, g = 0, b = 0, a = 1, thickness = 1})
    
    bagWindow:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        Command.Cursor(nil)
    end, bagName .. ".Event.Left.Up")

    Command.Event.Attach(LibEKL.Events[bagName].Moved, function(_, x, y)
        if isBag then 
            nkUISetup.modules.oneBag.x = x
            nkUISetup.modules.oneBag.y = y
        else
            nkUISetup.modules.oneBag.bankX = x
            nkUISetup.modules.oneBag.bankY = y
        end
    end, bagName .. ".Moved")

    local function updateCoin(_, currency)
        if currency['coin'] == nil then return end
        
        local details = inspectCurrencyDetail('coin')
        
        if details ~= nil and details.stack ~= nil then
            local platin = mathFloor(details.stack / 10000)
            local gold = mathFloor((details.stack - (platin * 10000)) / 100)
            local silver = details.stack - (platin * 10000) - (gold * 100)
            
            local textFormat = '%d<font color="#efebff">p</font> %d<font color="#eed234">g</font> %d<font color="#a7aba7">s</font>'

            currencyText:SetText(stringFormat(textFormat, platin, gold, silver), true)
        end
    end

    local function setFreeBagSlots()
        local freeBagCount = 0
        local freeBagSlots
        
        if isBag then
            freeBagSlots = LibEKL.Inventory.getAvailableSlots()
        else
            freeBagSlots = LibEKL.Inventory.getAvailableBankSlots()
        end

        if freeBagSlots ~= false then
            freeBagCount = #freeBagSlots
        end

        freeBagSlotsText:SetText(stringFormat("%d",freeBagCount))
    end

    currencyText = LibEKL.UICreateFrame ("nkText", bagName .. ".currencyText", bagWindow)
    currencyText:SetPoint("TOPRIGHT", bagWindow, "TOPRIGHT", -50 * data.bagScale, 12 * data.bagScale)
    currencyText:SetFontSize(12)
    currencyText:SetEffectGlow({ strength = 3})
    currencyText:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    currencyText:SetText("0")

    LibEKL.UI.SetFont(currencyText, addonInfo.id, "MontserratSemiBold")    

    currencyIcon = LibEKL.UICreateFrame("nkTexture", bagName .. ".Currency.icon", bagWindow)
    currencyIcon:SetPoint("CENTERRIGHT", currencyText, "CENTERLEFT", -5 * data.bagScale, 0)
    currencyIcon:SetHeight(12)
    currencyIcon:SetWidth(12)
    currencyIcon:SetTextureAsync("nkUI", "gfx/iconCoins.png")    

    freeBagSlotsText = LibEKL.UICreateFrame ("nkText", bagName .. ".BagSlotsText", bagWindow)
    freeBagSlotsText:SetPoint("CENTERRIGHT", currencyIcon, "CENTERLEFT", -5* data.bagScale, 0)
    freeBagSlotsText:SetFontSize(12)
    freeBagSlotsText:SetEffectGlow({ strength = 3})
    freeBagSlotsText:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    freeBagSlotsText:SetText("0")

    LibEKL.UI.SetFont(freeBagSlotsText, addonInfo.id, "MontserratSemiBold")    

    bagIcon = LibEKL.UICreateFrame("nkTexture", bagName .. ".BagSlotsIcon.icon", bagWindow)
    bagIcon:SetPoint("CENTERRIGHT", freeBagSlotsText, "CENTERLEFT", -5* data.bagScale, 0)
    bagIcon:SetHeight(12)
    bagIcon:SetWidth(12)
    bagIcon:SetTextureAsync("nkUI", "gfx/iconBag.png")    

    Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, function(_, a, b)
        if bagWindow:GetVisible() then
            setFreeBagSlots()
            updateCoin(_, {coin = true})
        end
    end, "nkUI.LibEKL.InventoryManager.Update")

    Command.Event.Attach(Event.Currency, function (_, data)
        if bagWindow:GetVisible() then
            updateCoin(_, data)
        end
    end, "nkUI.OneBag.Currency.Currency")

    setFreeBagSlots()
    updateCoin(_, {coin = true})
        
    local oSetVisible = bagWindow.SetVisible
    function bagWindow:SetVisible(visible)
        if visible then            
            LibEKL.Inventory.updateDB()
            
            if isBag then
                oneBag.populateBag(true) 
                oneBag.getBagSlots()
            else
                oneBag.populateBank(true)
            end

            setFreeBagSlots()
            updateCoin(_, {coin = true})
        else
            if uiElements.oneBagItemTooltip then
                oneBag.hideItemTooltip ()
            end
        end

        oSetVisible(self, visible)
    end
    
    return bagWindow
end