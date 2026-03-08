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
local mathFloor     = math.floor

---------- Wardrobe Config Dialog ---------

function internalFunc.wardrobeShowUI()

    if uiElements.wardrobeUI then
        uiElements.wardrobeUI:SetVisible(true)
        return
    end

    local charData = wardrobe.getCharData()

    local window = LibEKL.UICreateFrame("nkWindow", "nkUI.wardrobeUI", uiElements.settingsContext)
    window:SetWidth(450)
    window:SetHeight(400)
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
    setCombo:SetText(langTexts.wardrobe.setLabel)
    setCombo:SetFont(addonInfo.id, "MontserratSemiBold")
    setCombo:SetLabelColor(data.theme.labelColor)
    setCombo:SetWidth(290)
    setCombo:SetColorInner(0, 0, 0, .2)
    setCombo:SetColorBorder(0, 0, 0, .2)
    setCombo:SetColorSelected({r = 0.25, g = 0.35, b = 0.55, a = 0.85})
    setCombo:SetEffectGlow({strength = 3})
    setCombo:SetLayer(10)

    -- "Name:" label beside the rename field
    local nameLabel = LibEKL.UICreateFrame("nkText", "nkUI.wardrobeUI.nameLabel", content)
    nameLabel:SetPoint("TOPLEFT", setCombo, "BOTTOMLEFT", 0, 12)
    nameLabel:SetWidth(52)
    nameLabel:SetHeight(22)
    nameLabel:SetText("Name:")
    nameLabel:SetFontSize(13)
    nameLabel:SetTextFont(addonInfo.id, "MontserratSemiBold")
    nameLabel:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    nameLabel:SetEffectGlow({strength = 2})

    -- Set name edit field
    local setNameField = LibEKL.UICreateFrame("nkTextfield", "nkUI.wardrobeUI.setName", content)
    setNameField:SetPoint("TOPLEFT", setCombo, "BOTTOMLEFT", 57, 12)
    setNameField:SetWidth(233)
    setNameField:SetInnerColor({r = 0.13, g = 0.15, b = 0.20, a = 1})
    setNameField:SetFocusColor({r = 0x66 / 255, g = 0x56 / 255, b = 0x2e / 255, a = 1})
    setNameField:SetBorderColor({r = 0, g = 0, b = 0, a = 1})

    -- Equipment header
    local equipHeader = LibEKL.UICreateFrame("nkText", "nkUI.wardrobeUI.equipHeader", content)
    equipHeader:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, 12)
    equipHeader:SetText(langTexts.wardrobe.txtEquipSlotsUIHeader)
    equipHeader:SetFontSize(13)
    equipHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")
    equipHeader:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    equipHeader:SetEffectGlow({strength = 3})

    -- Equipment slots (4x5 grid, 44px slots, 5px gap)
    local SLOT_SIZE = 44
    local SLOT_GAP  = 5

    local equipSlots = {}
    for idx = 1, 20 do
        local col = (idx - 1) % 4
        local row = mathFloor((idx - 1) / 4)

        local slotFrame = LibEKL.UICreateFrame("nkFrame", "nkUI.wardrobeUI.equipSlot" .. idx, content)
        slotFrame:SetWidth(SLOT_SIZE)
        slotFrame:SetHeight(SLOT_SIZE)
        slotFrame:SetBackgroundColor(0, 0, 0, 0.35)

        if idx == 1 then
            slotFrame:SetPoint("TOPLEFT", equipHeader, "BOTTOMLEFT", 0, 8)
        else
            if col == 0 then
                local firstOfPrevRow = equipSlots[(row - 1) * 4 + 1]
                slotFrame:SetPoint("TOPLEFT", firstOfPrevRow, "BOTTOMLEFT", 0, SLOT_GAP)
            else
                slotFrame:SetPoint("TOPLEFT", equipSlots[idx - 1], "TOPRIGHT", SLOT_GAP, 0)
            end
        end

        local slotName = data.wardrobeSlots[idx]
        local slot = LibEKL.UICreateFrame("nkTexture", "nkUI.wardrobeUI.equipSlot" .. idx .. ".tex", slotFrame)
        slot:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
        slot:SetWidth(38)
        slot:SetHeight(38)
        slot:SetTextureAsync("nkUI", "gfx/equipslot_" .. slotName .. ".png")

        slotFrame.slot     = slot
        slotFrame.slotName = slotName

        equipSlots[idx] = slotFrame
    end

    -- Button column (right of equipment grid)
    local BTN_WIDTH = 185
    local BTN_GAP   = 8

    local function makeButton(btnName, text, anchor)
        local btn = LibEKL.UICreateFrame("nkButton", btnName, content)
        if anchor == nil then
            btn:SetPoint("TOPLEFT", equipSlots[4], "TOPRIGHT", 15, 0)
        else
            btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, BTN_GAP)
        end
        btn:SetText(text)
        btn:SetWidth(BTN_WIDTH)
        btn:SetScale(.9)
        btn:SetFont(addonInfo.id, "MontserratSemiBold")
        btn:SetLabelColor(data.theme.labelColor)
        btn:SetEffectGlow({strength = 3})
        btn:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
        btn:SetBorderColor({r = 0, g = 0, b = 0, a = .7, thickness = 1})
        return btn
    end

    local equipButton        = makeButton("nkUI.wardrobeUI.equipBtn",        langTexts.wardrobe.btWearTitle,    nil)
    local newButton          = makeButton("nkUI.wardrobeUI.newBtn",          langTexts.wardrobe.btNewSetTitle,  equipButton)
    local copyButton         = makeButton("nkUI.wardrobeUI.copyBtn",         langTexts.wardrobe.btCopySetTitle, newButton)
    local deleteButton       = makeButton("nkUI.wardrobeUI.deleteBtn",       langTexts.wardrobe.btDeleteSetTitle, copyButton)
    local currentEquipButton = makeButton("nkUI.wardrobeUI.currentEquipBtn", langTexts.wardrobe.btLoadGear,    deleteButton)

    -- Button event handlers

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.equipBtn"].Clicked, function()
        local selectedIdx = setCombo:GetSelectedValue()
        if selectedIdx and selectedIdx > 0 then
            LibEKL.Events.AddInsecure(function()
                wardrobe.wearEquip(selectedIdx)
            end)
        end
    end, "nkUI.wardrobeUI.equipBtn.Clicked")

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.newBtn"].Clicked, function()
        local cd = wardrobe.getCharData()
        tableInsert(cd.sets, {
            name  = stringFormat(langTexts.wardrobe.txtEquipment, #cd.sets + 1),
            items = {},
            bag   = 1,
            bank  = 0,
            icon  = ""
        })
        local newIdx = #cd.sets
        cd.activeSet = newIdx
        window.updateComboBox()
        window:onSetChange(newIdx)
    end, "nkUI.wardrobeUI.newBtn.Clicked")

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.copyBtn"].Clicked, function()
        local cd = wardrobe.getCharData()
        local selectedIdx = setCombo:GetSelectedValue()
        if selectedIdx and selectedIdx > 0 and cd.sets[selectedIdx] then
            tableInsert(cd.sets, {
                name  = stringFormat(langTexts.wardrobe.txtCopiedSet, cd.sets[selectedIdx].name),
                items = LibEKL.Tools.Table.Copy(cd.sets[selectedIdx].items),
                bag   = cd.sets[selectedIdx].bag,
                bank  = cd.sets[selectedIdx].bank,
                icon  = cd.sets[selectedIdx].icon
            })
            local newIdx = #cd.sets
            cd.activeSet = newIdx
            window.updateComboBox()
            window:onSetChange(newIdx)
        end
    end, "nkUI.wardrobeUI.copyBtn.Clicked")

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.deleteBtn"].Clicked, function()
        local cd = wardrobe.getCharData()
        if #cd.sets <= 1 then
            LibEKL.UI.infoDialog(langTexts.wardrobe.errLastSet)
            return
        end
        local selectedIdx = setCombo:GetSelectedValue()
        if selectedIdx and selectedIdx > 0 then
            LibEKL.UI.confirmDialog(langTexts.wardrobe.msgRemoveSetConfirm,
                function()
                    tableRemove(cd.sets, selectedIdx)
                    if cd.activeSet > #cd.sets then cd.activeSet = #cd.sets end
                    window.updateComboBox()
                    if #cd.sets > 0 then
                        window:onSetChange(cd.activeSet)
                    else
                        for idx, slotFrame in ipairs(equipSlots) do
                            if slotFrame.slot then
                                slotFrame.slot:SetTextureAsync("nkUI", "gfx/equipslot_" .. data.wardrobeSlots[idx] .. ".png")
                            end
                        end
                    end
                end,
                function() end)
        end
    end, "nkUI.wardrobeUI.deleteBtn.Clicked")

    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.currentEquipBtn"].Clicked, function()
        LibEKL.UI.confirmDialog(langTexts.wardrobe.msgLoadCurrentEquip,
            function()
                local cd = wardrobe.getCharData()
                local selectedIdx = setCombo:GetSelectedValue()
                if not selectedIdx or selectedIdx <= 0 or not cd.sets[selectedIdx] then return end

                LibEKL.Events.AddInsecure(function()
                    local slotKeyToName = {}
                    for _, slotName in ipairs(data.wardrobeSlots) do
                        local ok, slotKey = pcall(Utility.Item.Slot.Equipment, slotName)
                        if ok and slotKey then slotKeyToName[slotKey] = slotName end
                    end

                    local ok, equipped = pcall(Inspect.Item.List, Utility.Item.Slot.Equipment())
                    if not ok or not equipped then return end

                    cd.sets[selectedIdx].items = {}
                    for slotKey, itemId in pairs(equipped) do
                        if itemId then
                            local mappedSlot = slotKeyToName[slotKey]
                            if mappedSlot then
                                cd.sets[selectedIdx].items[mappedSlot] = itemId
                                local ok2, details = pcall(Inspect.Item.Detail, itemId)
                                if ok2 and details and details.type and nkUIWardrobeBackup then
                                    nkUIWardrobeBackup[itemId] = details.type
                                end
                            end
                        end
                    end

                    window:onSetChange(selectedIdx)
                end)
            end,
            function() end)
    end, "nkUI.wardrobeUI.currentEquipBtn.Clicked")

    -- Combo changed
    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.setCombo"].ComboChanged, function(_, newValue)
        if newValue and newValue.value then
            window:onSetChange(newValue.value)
        end
    end, "nkUI.wardrobeUI.setCombo.ComboChanged")

    -- Name field: live rename
    Command.Event.Attach(LibEKL.Events["nkUI.wardrobeUI.setName"].TextfieldChanged, function(_, newValue)
        local cd = wardrobe.getCharData()
        local selectedIdx = setCombo:GetSelectedValue()
        if selectedIdx and selectedIdx > 0 and cd.sets[selectedIdx] then
            cd.sets[selectedIdx].name = newValue
        end
    end, "nkUI.wardrobeUI.setName.TextfieldChanged")

    -- Update helpers
    function window.updateComboBox()
        local cd = wardrobe.getCharData()
        local items = {}
        for idx, setData in ipairs(cd.sets) do
            tableInsert(items, {label = setData.name, value = idx})
        end
        setCombo:SetSelection(items, false)
        if cd.activeSet and cd.activeSet <= #cd.sets then
            setCombo:SetSelectedValue(cd.activeSet)
        end
    end

    function window:onSetChange(setIdx)
        local cd = wardrobe.getCharData()
        if not cd.sets[setIdx] then return end

        setNameField:SetText(cd.sets[setIdx].name)

        for idx, slotFrame in ipairs(equipSlots) do
            local slot   = data.wardrobeSlots[idx]
            local itemId = cd.sets[setIdx].items[slot]
            local tex    = slotFrame.slot
            if tex then
                if itemId then
                    local ok, itemDetails = pcall(Inspect.Item.Detail, itemId)
                    if ok and itemDetails then
                        tex:SetTextureAsync("Rift", itemDetails.icon)
                    end
                else
                    tex:SetTextureAsync("nkUI", "gfx/equipslot_" .. slot .. ".png")
                end
            end
        end
    end

    -- Initialize
    window.updateComboBox()
    local cd = wardrobe.getCharData()
    if cd.activeSet and cd.activeSet <= #cd.sets then
        window:onSetChange(cd.activeSet)
    end

    window:SetVisible(true)
    uiElements.wardrobeUI = window
end
