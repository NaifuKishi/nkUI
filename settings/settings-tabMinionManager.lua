local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts

---------- init local variables ---------

function settingsUI.uiConfigTabMinionManager(name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox
    local durationCombo, priorityCombo, matchCombo

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame,
            langTexts.settings.activateModule, true, function(newValue)
                nkUISetup.modules.minionManager.activate = newValue
                LibEKL.UI.reloadDialog("nkUI")
            end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        activateCheckbox:SetChecked(nkUISetup.modules.minionManager.activate, true)

        -- ── Auto Send header ──────────────────────────────────────────────

        local autoSendHeader = settingsUI.header(name .. ".autoSendHeader", frame,
            langTexts.minionManager.autoSendHeader)
        autoSendHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        -- ── Duration tier ─────────────────────────────────────────────────

        local lt = langTexts.minionManager

        durationCombo = settingsUI.combobox(name .. ".durationCombo", frame,
            lt.autoSendDurationLabel, true, function(newValue)
                nkUISetup.modules.minionManager.autoSendDuration = newValue
            end)

        durationCombo:SetPoint("TOPLEFT", autoSendHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        durationCombo:SetSelection({
            { label = lt.autoSendDuration1, value = 1 },
            { label = lt.autoSendDuration2, value = 2 },
            { label = lt.autoSendDuration3, value = 3 },
            { label = lt.autoSendDuration4, value = 4 },
        }, false)
        durationCombo:SetSelectedValue(nkUISetup.modules.minionManager.autoSendDuration or 1)
        durationCombo:SetLayer(3)

        -- ── Priority ──────────────────────────────────────────────────────

        priorityCombo = settingsUI.combobox(name .. ".priorityCombo", frame,
            lt.autoSendPriorityLabel, true, function(newValue)
                nkUISetup.modules.minionManager.autoSendPriority = newValue
            end)

        priorityCombo:SetPoint("TOPLEFT", durationCombo, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        priorityCombo:SetSelection({
            { label = lt.autoSendPriority1, value = 1 },
            { label = lt.autoSendPriority2, value = 2 },
            { label = lt.autoSendPriority3, value = 3 },
            { label = lt.autoSendPriority4, value = 4 },
        }, false)
        priorityCombo:SetSelectedValue(nkUISetup.modules.minionManager.autoSendPriority or 1)
        priorityCombo:SetLayer(2)

        -- ── Stat matching ─────────────────────────────────────────────────

        matchCombo = settingsUI.combobox(name .. ".matchCombo", frame,
            lt.autoSendMatchLabel, true, function(newValue)
                nkUISetup.modules.minionManager.autoSendMatch = newValue
            end)

        matchCombo:SetPoint("TOPLEFT", priorityCombo, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        matchCombo:SetSelection({
            { label = lt.autoSendMatch0, value = 0 },
            { label = lt.autoSendMatch1, value = 1 },
            { label = lt.autoSendMatch2, value = 2 },
        }, false)
        matchCombo:SetSelectedValue(nkUISetup.modules.minionManager.autoSendMatch or 1)
        matchCombo:SetLayer(1)

    end

    return frame

end
