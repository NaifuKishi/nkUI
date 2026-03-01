local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local wardrobe      = privateVars.wardrobe
local langTexts     = privateVars.langTexts

local stringFormat  = string.format
local tableInsert   = table.insert
local tableRemove   = table.remove

---------- Wardrobe Config Dialog ---------

function internalFunc.wardrobeShowUI()
    
    if uiElements.wardrobeUI then
        uiElements.wardrobeUI:SetVisible(true)
        return
    end

    local charData = wardrobe.getCharData()

    local window = LibEKL.UICreateFrame("nkWindow", "nkUI.wardrobeUI", uiElements.settingsContext)
    window:SetWidth(750)
    window:SetHeight(600)
    window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (LibEKL.UI.getBoundRight() / 2) - (window:GetWidth() / 2), 200)
    window:SetTitle(langTexts.wardrobe.windowTitle)
    window:SetTitleFont(addonInfo.id, "MontserratBold")
    window:SetTitleFontSize(16)
    window:SetTitleEffect({strength = 3})
    window:SetCloseable(true)
    window:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

    window:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),
        color = {
            {r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0},
            {r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1}
        }
    }, {
        r = 0x66 / 255,
        g = 0x56 / 255,
        b = 0x2e / 255,
        a = 1,
        cap = "round",
        miter = "miter",
        thickness = 2
    })

    local content = window:GetContent()

    -- Set selection combobox
    local setCombo = LibEKL.UICreateFrame("nkCombobox", "nkUI.wardrobeUI.setCombo", content)
    setCombo:SetPoint("TOPLEFT", content, "TOPLEFT", 10, 10)
    setCombo:SetText(langTexts.wardrobe.setLabel, true)
    setCombo:SetFont(addonInfo.id, "MontserratSemiBold")
    setCombo:SetLabelColor(data.theme.labelColor)
    setCombo:SetWidth(400)
    setCombo:SetColorInner(0, 0, 0, .2)
    setCombo:SetColorBorder(0, 0, 0, .2)
    setCombo:SetEffectGlow({strength = 3})

    -- Set name edit field (with pencil icon)
    local setNameField = LibEKL.UICreateFrame("nkTextfield", "nkUI.wardrobeUI.setName", content)
    setNameField:SetPoint("TOPLEFT", setCombo, "BOTTOMLEFT", 0, 15)
    setNameField:SetWidth(350)
    setNameField:SetInnerColor({r = 0.13, g = 0.15, b = 0.20, a = 1})
    setNameField:SetFocusColor({r = 0x66 / 255, g = 0x56 / 255, b = 0x2e / 255, a = 1})
    setNameField:SetBorderColor({r = 0, g = 0, b = 0, a = 1})
    --setNameField:SetFont(addonInfo.id, "MontserratSemiBold")
    --setNameField:SetFontSize(14)
    --setNameField:SetColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
    --setNameField:SetEffectGlow({strength = 3})

    -- Equipment/Inventory display (simplified, stacked vertically)
    local equipHeader = LibEKL.UICreateFrame("nkText", "nkUI.wardrobeUI.equipHeader", content)
    equipHeader:SetPoint("TOPLEFT", setNameField, "BOTTOMLEFT", 0, 20)
    equipHeader:SetText(langTexts.wardrobe.txtEquipSlotsUIHeader)
    equipHeader:SetFontSize(14)
    equipHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")
    equipHeader:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    equipHeader:SetEffectGlow({strength = 3})

    -- Equipment slots display (20 slots, 4x5 grid)
    local equipSlots = {}
    for idx = 1, 20 do
        local col = (idx - 1) % 4
        local row = math.floor((idx - 1) / 4)
        local slotFrame = LibEKL.UICreateFrame("nkFrame", "nkUI.wardrobeUI.equipSlot" .. idx, content)
        slotFrame:SetWidth(35)
        slotFrame:SetHeight(35)

        if idx == 1 then
            slotFrame:SetPoint("TOPLEFT", equipHeader, "BOTTOMLEFT", 0, 10)
        else
            if col == 0 then
                local prevRow = equipSlots[(row - 1) * 4 + 4]
                slotFrame:SetPoint("TOPLEFT", prevRow, "BOTTOMLEFT", 0, 5)
            else
                slotFrame:SetPoint("TOPLEFT", equipSlots[idx - 1], "TOPRIGHT", 5, 0)
            end
        end

        local slot = LibEKL.UICreateFrame("nkTexture", "nkUI.wardrobeUI.equipSlot" .. idx .. ".tex", slotFrame)
        slot:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
        slot:SetWidth(30)
        slot:SetHeight(30)
        slot:SetTextureAsync("nkUI", "gfx/equipslot_blank.png")
        
        slotFrame.slot = slot

        equipSlots[idx] = slotFrame
    end

    -- Buttons
    local equipButton = LibEKL.UICreateFrame("nkButton", "nkUI.wardrobeUI.equipBtn", content)
    equipButton:SetPoint("TOPLEFT", setCombo, "TOPRIGHT", 20, 0)
    equipButton:SetText(langTexts.wardrobe.btWearTitle)
    equipButton:SetScale(.9)
    equipButton:SetFont(addonInfo.id, "MontserratSemiBold")
    equipButton:SetLabelColor(data.theme.labelColor)
    equipButton:SetEffectGlow({strength = 3})
    equipButton:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
    equipButton:SetBorderColor({r = 0, g = 0, b = 0, a = .7, thickness = 1})

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.equipBtn"].Clicked, function()
        local charData = wardrobe.getCharData()
        local selectedIdx = setCombo:GetSelectedIndex()
        if selectedIdx and selectedIdx > 0 then
            LibEKL.Events.AddInsecure(function()
                wardrobe.wearEquip(selectedIdx)
            end)
        end
    end, "nkUI.wardrobeUI.equipBtn.Clicked")

    local newButton = LibEKL.UICreateFrame("nkButton", "nkUI.wardrobeUI.newBtn", content)
    newButton:SetPoint("TOPLEFT", equipButton, "BOTTOMLEFT", 0, 10)
    newButton:SetText(langTexts.wardrobe.btNewSetTitle)
    newButton:SetScale(.9)
    newButton:SetFont(addonInfo.id, "MontserratSemiBold")
    newButton:SetLabelColor(data.theme.labelColor)
    newButton:SetEffectGlow({strength = 3})
    newButton:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
    newButton:SetBorderColor({r = 0, g = 0, b = 0, a = .7, thickness = 1})

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.newBtn"].Clicked, function()
        local charData = wardrobe.getCharData()
        tableInsert(charData.sets, {
            name = stringFormat(langTexts.wardrobe.txtEquipment, #charData.sets + 1),
            items = {},
            bag = 1,
            bank = 0,
            icon = ""
        })
        window.updateComboBox()
    end, "nkUI.wardrobeUI.newBtn.Clicked")

    local copyButton = LibEKL.UICreateFrame("nkButton", "nkUI.wardrobeUI.copyBtn", content)
    copyButton:SetPoint("TOPLEFT", newButton, "BOTTOMLEFT", 0, 5)
    copyButton:SetText(langTexts.wardrobe.btCopySetTitle)
    copyButton:SetScale(.9)
    copyButton:SetFont(addonInfo.id, "MontserratSemiBold")
    copyButton:SetLabelColor(data.theme.labelColor)
    copyButton:SetEffectGlow({strength = 3})
    copyButton:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
    copyButton:SetBorderColor({r = 0, g = 0, b = 0, a = .7, thickness = 1})

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.copyBtn"].Clicked, function()
        local charData = wardrobe.getCharData()
        local selectedIdx = setCombo:GetSelectedIndex()
        if selectedIdx and selectedIdx > 0 and charData.sets[selectedIdx] then
            tableInsert(charData.sets, {
                name = charData.sets[selectedIdx].name .. " " .. stringFormat(langTexts.wardrobe.txtCopiedSet, ""),
                items = LibEKL.Tools.Table.Copy(charData.sets[selectedIdx].items),
                bag = charData.sets[selectedIdx].bag,
                bank = charData.sets[selectedIdx].bank,
                icon = charData.sets[selectedIdx].icon
            })
            window.updateComboBox()
        end
    end, "nkUI.wardrobeUI.copyBtn.Clicked")

    local deleteButton = LibEKL.UICreateFrame("nkButton", "nkUI.wardrobeUI.deleteBtn", content)
    deleteButton:SetPoint("TOPLEFT", copyButton, "BOTTOMLEFT", 0, 5)
    deleteButton:SetText(langTexts.wardrobe.btDeleteSetTitle)
    deleteButton:SetScale(.9)
    deleteButton:SetFont(addonInfo.id, "MontserratSemiBold")
    deleteButton:SetLabelColor(data.theme.labelColor)
    deleteButton:SetEffectGlow({strength = 3})
    deleteButton:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
    deleteButton:SetBorderColor({r = 0, g = 0, b = 0, a = .7, thickness = 1})

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.deleteBtn"].Clicked, function()
        local charData = wardrobe.getCharData()
        if #charData.sets <= 1 then
            LibEKL.UI.confirmDialog(langTexts.wardrobe.errLastSet, function() end, function() end)
            return
        end
        local selectedIdx = setCombo:GetSelectedIndex()
        if selectedIdx and selectedIdx > 0 then
            LibEKL.UI.confirmDialog(langTexts.wardrobe.msgRemoveSetConfirm,
                function()
                    tableRemove(charData.sets, selectedIdx)
                    if charData.activeSet > #charData.sets then
                        charData.activeSet = #charData.sets
                    end
                    window.updateComboBox()
                end,
                function() end)
        end
    end, "nkUI.wardrobeUI.deleteBtn.Clicked")

    local currentEquipButton = LibEKL.UICreateFrame("nkButton", "nkUI.wardrobeUI.currentEquipBtn", content)
    currentEquipButton:SetPoint("TOPLEFT", deleteButton, "BOTTOMLEFT", 0, 5)
    currentEquipButton:SetText(langTexts.wardrobe.btLoadGear)
    currentEquipButton:SetScale(.9)
    currentEquipButton:SetFont(addonInfo.id, "MontserratSemiBold")
    currentEquipButton:SetLabelColor(data.theme.labelColor)
    currentEquipButton:SetEffectGlow({strength = 3})
    currentEquipButton:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
    currentEquipButton:SetBorderColor({r = 0, g = 0, b = 0, a = .7, thickness = 1})

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.currentEquipBtn"].Clicked, function()
        LibEKL.UI.confirmDialog(langTexts.wardrobe.msgLoadCurrentEquip,
            function()
                local charData = wardrobe.getCharData()
                local selectedIdx = setCombo:GetSelectedIndex()
                if selectedIdx and selectedIdx > 0 and charData.sets[selectedIdx] then
                    charData.sets[selectedIdx].items = {}
                    for idx, slot in ipairs(data.wardrobeSlots) do
                        local ok, itemId = pcall(function()
                            local items = Inspect.Item.List(Utility.Item.Slot.Equipment(slot))
                            if items then
                                for k, v in pairs(items) do
                                    return v
                                end
                            end
                        end)
                        if ok and itemId then
                            charData.sets[selectedIdx].items[slot] = itemId
                        end
                    end
                    window:onSetChange(selectedIdx)
                end
            end,
            function() end)
    end, "nkUI.wardrobeUI.currentEquipBtn.Clicked")

    -- Update function
    function window.updateComboBox()
        local charData = wardrobe.getCharData()
        local items = {}
        for idx, setData in ipairs(charData.sets) do
            tableInsert(items, {label = setData.name, value = idx})
        end
        setCombo:SetSelection(items)
        if charData.activeSet and charData.activeSet <= #charData.sets then
            setCombo:SetSelectedValue(charData.activeSet)
        end
    end

    function window:onSetChange(setIdx)
        local charData = wardrobe.getCharData()
        if charData.sets[setIdx] then
            setNameField:SetText(charData.sets[setIdx].name)
            for idx, slotFrame in ipairs(equipSlots) do
                local slot = data.wardrobeSlots[idx]
                local itemId = charData.sets[setIdx].items[slot]
                if itemId then
                    local ok, itemDetails = pcall(Inspect.Item.Detail, itemId)
                    if ok and itemDetails then

                        local tex = slotFrame.slot
                        if tex then
                            tex:SetTextureAsync("Rift", itemDetails.icon)
                        end
                    end
                else
                    local tex = slotFrame.slot

                    if tex then
                        tex:SetTextureAsync("nkUI", "gfx/equipslot_blank.png")
                    end
                end
            end
        end
    end

    -- Setup combo change event
    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.setCombo"].ComboChanged, function(_, newValue)
        if newValue and newValue.value then
            window:onSetChange(newValue.value)
        end
    end, "nkUI.wardrobeUI.setCombo.ComboChanged")

    -- Update name field changes
    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.setName"].TextfieldChanged, function(_, newValue)
        local charData = wardrobe.getCharData()
        local selectedIdx = setCombo:GetSelectedIndex()
        if selectedIdx and selectedIdx > 0 and charData.sets[selectedIdx] then
            charData.sets[selectedIdx].name = newValue
        end
    end, "nkUI.wardrobeUI.setName.TextfieldChanged")

    -- Initialize UI
    window.updateComboBox()
    local charData = wardrobe.getCharData()
    if charData.activeSet and charData.activeSet <= #charData.sets then
        window:onSetChange(charData.activeSet)
    end

    window:SetVisible(true)
    uiElements.wardrobeUI = window
end
