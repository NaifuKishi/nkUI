local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.wardrobe = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local wardrobe      = privateVars.wardrobe
local langTexts     = privateVars.langTexts

local inspectTimeFrame      = Inspect.Time.Frame
local inspectTimeReal       = Inspect.Time.Real
local inspectItemDetail     = Inspect.Item.Detail
local inspectItemFind       = Inspect.Item.Find
local inspectItemList       = Inspect.Item.List
local inspectSystemSecure   = Inspect.System.Secure

local commandItemMove       = Command.Item.Move
local utilityItemSlotEquipment = Utility.Item.Slot.Equipment

local stringFormat          = string.format
local tableInsert           = table.insert
local tableRemove           = table.remove

---------- init variables ---------

data.wardrobeSlots = {'helmet', 'cape', 'shoulders', 'chest', 'gloves', 'belt', 'legs', 'feet', 'focus', 'handmain', 'handoff', 'ranged', 'earring1', 'earring2', 'neck', 'trinket', 'ring1', 'ring2', 'synergy', 'seal'}

local _errorList = {}

---------- local functions ---------

local function _fctEquipMoverCoRoutine (thisList, errorFlag)
    for idx = 1, #thisList, 1 do

        local sourceSlot = LibEKL.Inventory.GetSlotByItemId(thisList[idx].item)

        if not sourceSlot then
            if nkUIWardrobeBackup and nkUIWardrobeBackup[thisList[idx].item] ~= nil then
                sourceSlot = LibEKL.Inventory.querySlotByType(nkUIWardrobeBackup[thisList[idx].item])
            end

            if not sourceSlot then
                local ok, itemDetails = pcall(inspectItemDetail, thisList[idx].item)
                if ok and itemDetails ~= nil then
                    sourceSlot = LibEKL.Inventory.querySlotByType(itemDetails.type)
                end
            end
        end

        if sourceSlot then
            if sourceSlot ~= thisList[idx].to then
                if sourceSlot:find("seqp") == 1 then
                    local tempSlot = LibEKL.Inventory.findFreeBagSlot(wardrobe.getCharData().activeSet and nkUIWardrobe.sets[nkUIWardrobe.activeSet].bag or 1)

                    if not tempSlot then
                        tempSlot = LibEKL.Inventory.findFreeBagSlot()
                    end

                    local err = pcall(commandItemMove, sourceSlot, tempSlot)
                    if err == false then
                        if errorFlag then
                            LibEKL.Tools.Error.Display(addonInfo.identifier, stringFormat(langTexts.wardrobe.errMovingItem, sourceSlot, tempSlot), 1)
                        else
                            tableInsert(_errorList, {item = thisList[idx].item, to = tempSlot})
                            tableInsert(_errorList, {item = thisList[idx].item, to = thisList[idx].to})
                        end
                    end

                    err = pcall(commandItemMove, tempSlot, thisList[idx].to)
                    if err == false then
                        if errorFlag then
                            LibEKL.Tools.Error.Display(addonInfo.identifier, stringFormat(langTexts.wardrobe.errMovingItem, tempSlot, thisList[idx].to), 1)
                        else
                            tableInsert(_errorList, {item = thisList[idx].item, to = thisList[idx].to})
                        end
                    end
                else
                    local err = pcall(commandItemMove, sourceSlot, thisList[idx].to)
                    if err == false then
                        if errorFlag then
                            LibEKL.Tools.Error.Display(addonInfo.identifier, stringFormat(langTexts.wardrobe.errMovingItem, sourceSlot, thisList[idx].to), 1)
                        else
                            tableInsert(_errorList, thisList[idx])
                        end
                    end
                end
            end
        else
            local ok, itemDetails = pcall(inspectItemDetail, thisList[idx].item)
            if ok and itemDetails then
                LibEKL.Tools.Error.Display(addonInfo.identifier, stringFormat(langTexts.wardrobe.errGettingItem, itemDetails.name), 1)
            else
                LibEKL.Tools.Error.Display(addonInfo.identifier, stringFormat(langTexts.wardrobe.errGettingItem, thisList[idx].item), 1)
            end
        end

        coroutine.yield(idx)

    end
end

---------- wardrobe namespace functions ---------

function wardrobe.getCharData()
    if nkUIWardrobe == nil then
        nkUIWardrobe = {
            activeSet = 1,
            sets = {{name = "Set 1", items = {}, bag = 1, bank = 0, icon = ""}}
        }
    end
    return nkUIWardrobe
end

function wardrobe.wearEquip(setNo)
    local charData = wardrobe.getCharData()

    if charData.sets == nil or charData.sets[setNo] == nil then return end

    charData.activeSet = setNo

    if charData.sets[setNo].name ~= nil then
        Command.Console.Display("general", true, stringFormat(langTexts.wardrobe.loadSet, charData.sets[setNo].name), true)
    else
        Command.Console.Display("general", true, stringFormat(langTexts.wardrobe.loadSet, tostring(setNo)), true)
    end

    local setItems = charData.sets[setNo].items

    -- Build equip list
    local realMoveList = {}
    for slot, key in pairs(LibEKL.Tools.Table.Copy(setItems)) do
        tableInsert(realMoveList, {to = utilityItemSlotEquipment(slot), item = key})
    end

    -- Snapshot which slots need to be cleared (no item defined in this set)
    local slotsToUnequip = {}
    local okEquipped, currentEquipped = pcall(inspectItemList, utilityItemSlotEquipment())
    if okEquipped and currentEquipped then
        for _, slotName in ipairs(data.wardrobeSlots) do
            if not setItems[slotName] then
                local okSlot, slotKey = pcall(utilityItemSlotEquipment, slotName)
                if okSlot and slotKey and currentEquipped[slotKey] then
                    tableInsert(slotsToUnequip, slotKey)
                end
            end
        end
    end

    -- After equip coroutine finishes, start the unequip phase
    wardrobe.equipMover(realMoveList, function()
        wardrobe.unequipSlots(slotsToUnequip, charData.sets[setNo].bag or 1)
    end)

    if uiElements.wardrobeUI and uiElements.wardrobeUI:GetVisible() then
        if uiElements.wardrobeUI.onSetChange then
            uiElements.wardrobeUI:onSetChange(setNo)
        end
    end
end

function wardrobe.unequipSlots(slotsToUnequip, bagNo)
    if #slotsToUnequip == 0 then return end

    -- Re-verify at runtime which slots still have items (equip phase may have changed things)
    local stillEquipped = {}
    local okEquipped, currentEquipped = pcall(inspectItemList, utilityItemSlotEquipment())
    if okEquipped and currentEquipped then
        for _, slotKey in ipairs(slotsToUnequip) do
            if currentEquipped[slotKey] then
                tableInsert(stillEquipped, slotKey)
            end
        end
    end

    if #stillEquipped == 0 then return end

    -- Pre-allocate one unique bag slot per item to avoid reusing the same
    -- slot before the previous move is server-confirmed
    local assignedSlots = {}
    local usedSlots = {}
    for idx = 1, #stillEquipped do
        local freeSlot = nil
        for bag = bagNo, 8 do
            local okBag, bagContents = pcall(inspectItemList, Utility.Item.Slot.Inventory(bag))
            if okBag and bagContents then
                for slotKey, item in pairs(bagContents) do
                    if item == false and not usedSlots[slotKey] then
                        freeSlot = slotKey
                        break
                    end
                end
            end
            if freeSlot then break end
        end
        if freeSlot then
            usedSlots[freeSlot] = true
            tableInsert(assignedSlots, {from = stillEquipped[idx], to = freeSlot})
        end
    end

    if #assignedSlots == 0 then return end

    local unequipCoRoutine = coroutine.create(function()
        for idx = 1, #assignedSlots do
            pcall(commandItemMove, assignedSlots[idx].from, assignedSlots[idx].to)
            coroutine.yield(idx)
        end
    end)

    LibEKL.Coroutines.Add({func = unequipCoRoutine, counter = #assignedSlots, active = true})
end

function wardrobe.equipMover(moveList, afterEquipCallback)
    local callBack = function()
        if #_errorList > 0 then
            wardrobe.errorMover()
        end
        if afterEquipCallback then afterEquipCallback() end
    end

    if #moveList == 0 then
        callBack()
        return
    end

    local moveCoRoutine = coroutine.create(function()
        _fctEquipMoverCoRoutine(moveList, false)
    end)

    LibEKL.Coroutines.Add({func = moveCoRoutine, counter = #moveList, active = true, callBack = callBack})
end

function wardrobe.errorMover()
    local callBack = function()
        _errorList = {}
    end

    local moveCoRoutine = coroutine.create(function()
        _fctEquipMoverCoRoutine(_errorList, true)
    end)

    LibEKL.Coroutines.Add({func = moveCoRoutine, counter = #_errorList, active = true, callBack = callBack})
end

function wardrobe.tooltipInfo()
    local type, id = Inspect.Tooltip()

    if type ~= 'item' then return end

    local charData = wardrobe.getCharData()
    local setNames = {}

    for idx, setData in ipairs(charData.sets) do
        if setData.items then
            for slot, itemId in pairs(setData.items) do
                if itemId == id then
                    tableInsert(setNames, setData.name)
                    break
                end
            end
        end
    end

    if #setNames > 0 then
        local tooltipText = langTexts.wardrobe.partOfSets .. table.concat(setNames, ", ")
        Command.Console.Display("general", true, tooltipText, true)
    end
end

function wardrobe.showUI()
    LibEKL.Inventory.updateDB()

    if uiElements.wardrobeUI == nil then
        -- wardrobeUI.lua will create this
        internalFunc.wardrobeShowUI()
    else
        uiElements.wardrobeUI:SetVisible(true)
    end
end

---------- addon internal function block ---------

function internalFunc.wardrobeInit()

    local charData = wardrobe.getCharData()

    -- Apply defaults
    if charData.activeSet == nil then charData.activeSet = 1 end
    if charData.sets == nil or #charData.sets == 0 then
        charData.sets = {{name = "Set 1", items = {}, bag = 1, bank = 0, icon = ""}}
    end

    
    -- Pre-cache item types
    if nkUIWardrobeBackup == nil then nkUIWardrobeBackup = {} end

    for setId, setData in ipairs(charData.sets) do
        if setData.items then
            for slot, itemId in pairs(setData.items) do
                local ok, itemDetails = pcall(inspectItemDetail, itemId)
                if ok and itemDetails ~= nil then
                    nkUIWardrobeBackup[itemId] = itemDetails.type
                end
            end
        end
    end

    -- Attach tooltip handler
    Command.Event.Attach(Event.Tooltip, wardrobe.tooltipInfo, "nkUI.wardrobe.Tooltip")

end