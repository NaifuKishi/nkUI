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

    local currencyText, currencyText, freeBagSlotsText, bagIcon, searchIcon, searchFrame, searchInput, toolsFrame, auctionIcon
    
    local bagWindow = LibEKL.UICreateFrame("nkWindow", bagName, context)
    bagWindow:SetTitle(stringFormat(bagTitle, LibEKL.Unit.GetPlayerDetails().name))
    bagWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    bagWindow:SetTitleFontSize(16 * data.bagScale)
    bagWindow:SetTitleEffect({ strength = 3})
    bagWindow:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

    bagWindow:SetWidth(690 * data.bagScale)
    bagWindow:SetHeight(600 * data.bagScale)
    bagWindow:SetLayer(1)

    --bagWindow:GetHeader():SetBackgroundColor(1, 0, 0, 1)
    
    if isBag then
        bagWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.oneBag.x, nkUISetup.modules.oneBag.y)
    else
        bagWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.oneBag.bankX, nkUISetup.modules.oneBag.bankY)
    end

    bagWindow:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, math.pi, 0, 0), -- 180 degree angle
        color = {
            {r = 0.13, g = 0.15, b = 0.20, a = 1, position = 0}, -- Start color
            {r = 0.10, g = 0.11, b = 0.15, a = 1, position = 1}  -- End color
        }
    },  {
        r = 0x66 / 255,
        g = 0x56 / 255,
        b = 0x2e / 255,
        a = 1,
        cap = "round",
        miter = "miter",
        thickness = 2
    })
    
    bagWindow:EventAttach(Event.UI.Input.Mouse.Left.Up, function()            
        if not oneBag.dragItem then return end

        if isBag then
            oneBag.moveToBag(oneBag.dragItem.draggedSlot, oneBag.dragItem.draggedItem)
        else
            oneBag.moveToBank(oneBag.dragItem.draggedSlot, oneBag.dragItem.draggedItem)            
        end

        oneBag.dragItem = nil
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
            local platin = math.floor(details.stack / 10000)
            local gold = math.floor((details.stack - (platin * 10000)) / 100)
            local silver = details.stack - (platin * 10000) - (gold * 100)

            -- Build the coin string with only non-zero values
            local coinParts = {}
            if platin > 0 then
                table.insert(coinParts, string.format("<font color=\"#efebff\">%dp</font>", platin))
            end
            
            if gold > 0 or platin > 0 then
                table.insert(coinParts, string.format("<font color=\"#eed234\">%dg</font>", gold))
            end
            if silver > 0 or (platin > 0 or gold > 0) then
                table.insert(coinParts, string.format("<font color=\"#a7aba7\">%ds</font>", silver))
            end

            -- Combine the parts with spaces
            local coinText = table.concat(coinParts, " ")

            currencyText:SetText(coinText, true)

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
    currencyText:SetPoint("CENTERRIGHT", bagWindow:GetHeader(), "CENTERRIGHT", -50 * data.bagScale, 0)
    currencyText:SetFontSize(12 * data.bagScale)
    currencyText:SetEffectGlow({ strength = 3})
    currencyText:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    currencyText:SetText("0")

    LibEKL.UI.SetFont(currencyText, addonInfo.id, "MontserratSemiBold")    

    currencyIcon = LibEKL.UICreateFrame("nkTexture", bagName .. ".Currency.icon", bagWindow)
    currencyIcon:SetPoint("CENTERRIGHT", currencyText, "CENTERLEFT", -5 * data.bagScale, 0)
    currencyIcon:SetHeight(12 * data.bagScale)
    currencyIcon:SetWidth(12 * data.bagScale)
    currencyIcon:SetTextureAsync("nkUI", "gfx/questIconCoin.png")

    freeBagSlotsText = LibEKL.UICreateFrame ("nkText", bagName .. ".BagSlotsText", bagWindow)
    freeBagSlotsText:SetPoint("CENTERRIGHT", currencyIcon, "CENTERLEFT", -5* data.bagScale, 0)
    freeBagSlotsText:SetFontSize(12 * data.bagScale)
    freeBagSlotsText:SetEffectGlow({ strength = 3})
    freeBagSlotsText:SetFontColor(0x85 / 255, 0xCB / 255, 0xCB / 255, 1)
    freeBagSlotsText:SetText("0")

    LibEKL.UI.SetFont(freeBagSlotsText, addonInfo.id, "MontserratSemiBold")    

    bagIcon = LibEKL.UICreateFrame("nkTexture", bagName .. ".BagSlotsIcon.icon", bagWindow)
    bagIcon:SetPoint("CENTERRIGHT", freeBagSlotsText, "CENTERLEFT", -5* data.bagScale, 0)
    bagIcon:SetHeight(12 * data.bagScale)
    bagIcon:SetWidth(12 * data.bagScale)
    bagIcon:SetTextureAsync("nkUI", "gfx/iconPackage.png")

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

    toolsFrame = LibEKL.UICreateFrame("nkFrame", bagName .. ".ToolsFrame", bagWindow)
    toolsFrame:SetWidth(30 * data.bagScale)
    toolsFrame:SetHeight(30 * data.bagScale)
    toolsFrame:SetPoint("TOPRIGHT", bagWindow, "BOTTOMRIGHT", 0, 5 * data.bagScale)
    toolsFrame:SetBackgroundColor(data.theme.windowStartColor.r, data.theme.windowStartColor.g, data.theme.windowStartColor.b, data.theme.windowStartColor.a)
    toolsFrame:SetLayer(2)

    -- Create search icon
    searchIcon = LibEKL.UICreateFrame("nkTexture", bagName .. ".SearchIcon", toolsFrame)
    searchIcon:SetPoint("CENTERRIGHT", toolsFrame, "CENTERRIGHT", -5, 0)
    searchIcon:SetHeight(20 * data.bagScale)
    searchIcon:SetWidth(20 * data.bagScale)
    searchIcon:SetTextureAsync("nkUI", "gfx/iconSearch.png")

    -- Create search icon
    auctionIcon = LibEKL.UICreateFrame("nkTexture", bagName .. ".auctionIcon", toolsFrame)
    auctionIcon:SetPoint("CENTERRIGHT", searchIcon, "CENTERLEFT", -5, 0)
    auctionIcon:SetHeight(20 * data.bagScale)
    auctionIcon:SetWidth(20 * data.bagScale)
    auctionIcon:SetTextureAsync("nkUI", "gfx/iconAuction.png")    

    -- Create search input frame (initially hidden)
    searchFrame = LibEKL.UICreateFrame("nkFrame", bagName .. ".SearchFrame", searchIcon)
    searchFrame:SetPoint("TOPRIGHT", searchIcon, "TOPLEFT", 0, 0)
    searchFrame:SetWidth(150 * data.bagScale)
    searchFrame:SetHeight(30 * data.bagScale)
    searchFrame:SetVisible(false)
    searchFrame:SetBackgroundColor(0, 0, 0, 1)

    -- Create search input field using the enhanced text field functionality
    searchInput = LibEKL.UICreateFrame("nkTextField", bagName .. ".SearchInput", searchFrame)
    searchInput:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 5, 5)
    searchInput:SetWidth(140 * data.bagScale)
    searchInput:SetHeight(20 * data.bagScale)

    -- Set up enhanced text field properties
    searchInput:SetInnerColor({r = 0, g = 0, b = 0, a = 1})
	searchInput:SetFocusColor (data.theme.labelColor)
	searchInput:SetBorderColor({r = 0, g = 0, b = 0, a = 1})

    auctionIcon:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        internalFunc.ahScanDialog()
    end, bagName .. ".auctionIcon.Left.Down.Click")

    -- Toggle search frame visibility when search icon is clicked
    searchIcon:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        searchFrame:SetVisible(not searchFrame:GetVisible())
        if searchFrame:GetVisible() then
            searchInput:Enter()
        else
            searchInput:Leave()
            searchInput:SetText("")
        end
    end, bagName .. ".SearchIcon.Left.Down.Click")

    -- Add event handlers for the text field
    Command.Event.Attach(LibEKL.Events[bagName .. ".SearchInput"]["TextfieldChanged"], function()
        searchInput:Leave()
        searchFrame:SetVisible(false)

        local searchPattern = searchInput:GetText():lower()

        if isBag then
            oneBag.populateBag(true, searchPattern)
        elseif nkUISetup.modules.oneBag.bankActivate then
            oneBag.populateBank(true, searchPattern)
        end
    end, bagName .. ".SearchInput.TextfieldChanged")

    Command.Event.Attach(LibEKL.Events[bagName .. ".SearchInput"]["FokusLoss"], function()
        searchInput:Leave()
        searchFrame:SetVisible(false)
    end, bagName .. ".SearchInput.FokusLoss")

    setFreeBagSlots()
    updateCoin(_, {coin = true})
        
    local oSetVisible = bagWindow.SetVisible
    function bagWindow:SetVisible(visible)

        if visible then            
            LibEKL.Inventory.updateDB()
            
            if isBag then
                oneBag.populateBag(true) 
                oneBag.getBagSlots()
            elseif nkUISetup.modules.oneBag.bankActivate then
                oneBag.populateBank(true)
            end

            setFreeBagSlots()
            updateCoin(_, {coin = true})
        else
            if uiElements.oneBagItemTooltip then
                oneBag.hideItemTooltip ()
            end
        end

        if bagWindow:GetLeft() > UIParent:GetWidth() then
            local x = UIParent:GetWidth() - bagWindow:GetWidth()            
            if isBag then
                nkUISetup.modules.oneBag.x = x
                bagWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.oneBag.x, nkUISetup.modules.oneBag.y)
            else
                nkUISetup.modules.bankX.x = x
                bagWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.oneBag.bankX, nkUISetup.modules.oneBag.bankY)
            end
        end

        oSetVisible(self, visible)
    end

    function bagWindow:ShowAuction(flag)

        if flag then
            toolsFrame:SetWidth(55)
            auctionIcon:SetVisible(true)
        else
            toolsFrame:SetWidth(30)
            auctionIcon:SetVisible(false)
        end

    end
    
    return bagWindow
end