local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local lowerBar      = privateVars.lowerBar
local wardrobe      = privateVars.wardrobe
local langTexts     = privateVars.langTexts

---------- init local variables ---------

local inspectSystemSecure  = Inspect.System.Secure
local stringFormat         = string.format

---------- local functions ---------

-- Creates and manages the wardrobe set selection display
function lowerBar.lowerBarWardrobe()

    local name = "lowerBar.datasetwardrobe"
    local height = uiElements.lowerBarCanvas:GetHeight()

    local datasetFrame = LibEKL.UICreateFrame("nkFrame", name .. ".frame", lowerBar.contextRestricted)
    datasetFrame:SetHeight(height)
    datasetFrame:SetSecureMode('restricted')
    datasetFrame:SetLayer(2)

    local datasetWardrobe = LibEKL.UICreateFrame("nkText", name .. ".text", lowerBar.contextRestricted)
    datasetWardrobe:SetPoint("CENTER", datasetFrame, "CENTER", -21, 0)
    datasetWardrobe:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetWardrobe:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetWardrobe:SetTextFont(addonInfo.id, "MontserratMedium")
    datasetWardrobe:SetEffectGlow({strength = 1})
    datasetWardrobe:SetSecureMode('restricted')
    datasetWardrobe:SetLayer(5)

    local datasetWardrobeIcon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", datasetFrame)
    datasetWardrobeIcon:SetPoint("CENTERRIGHT", datasetWardrobe, "CENTERLEFT", -5, -2)
    datasetWardrobeIcon:SetSecureMode('restricted')
    lowerBar.setIcon(datasetWardrobeIcon, "gfx/equipslot_chest.png")

    local wardrobeSwitch = LibEKL.UICreateFrame("nkFrame", name .. ".switch", datasetWardrobe)
    wardrobeSwitch:SetPoint("BOTTOMCENTER", datasetWardrobe, "TOPCENTER")
    wardrobeSwitch:SetSecureMode('restricted')
    wardrobeSwitch:SetHeight(1)
    wardrobeSwitch:SetVisible(false)

    local buttonShown = false
    local setDisplay = {}

    local function updateSets()
        if inspectSystemSecure() == true then return end

        local charData = wardrobe.getCharData()
        local object = wardrobeSwitch

        for k, v in pairs(setDisplay) do
            v:SetVisible(false)
        end

        if charData.sets and #charData.sets > 0 then
            datasetWardrobe:SetText(stringFormat(langTexts.wardrobe.lowerBarLabel, charData.sets[charData.activeSet].name or "Set"), true)

            for setIdx = 1, #charData.sets do
                local thisSet
                if setDisplay[setIdx] == nil then
                    thisSet = LibEKL.UICreateFrame("nkText", name .. ".thisSet." .. setIdx, wardrobeSwitch)
                    thisSet:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
                    thisSet:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
                    thisSet:SetEffectGlow({strength = 1})
                    thisSet:SetTextFont(addonInfo.id, "MontserratMedium")
                    thisSet:SetText(charData.sets[setIdx].name)
                    thisSet:SetSecureMode('restricted')

                    -- Use insecure callback since we're in secure context
                    thisSet:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
                        if not inspectSystemSecure() then
                            LibEKL.Events.AddInsecure(function()
                                wardrobe.wearEquip(setIdx)
                            end)
                            buttonShown = false
                            wardrobeSwitch:SetVisible(false)
                        end
                    end, name .. ".thisSet." .. setIdx .. ".Click")

                    setDisplay[setIdx] = thisSet
                else
                    thisSet = setDisplay[setIdx]
                    thisSet:SetTextFont(addonInfo.id, "MontserratMedium")
                end

                thisSet:SetVisible(true)
                thisSet:SetPoint("BOTTOMCENTER", object, "TOPCENTER")

                object = thisSet
            end
        end
    end

    function datasetFrame:Redraw()
        datasetWardrobe:SetFontSize(nkUISetup.modules.lowerBar.fontSize)

        for k, v in pairs(setDisplay) do
            v:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
        end
    end

    updateSets()

    -- Left-click to toggle dropdown
    datasetFrame:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        if inspectSystemSecure() then return end

        buttonShown = not buttonShown
        wardrobeSwitch:SetVisible(buttonShown)
    end, name .. "_Left_Click")

    -- Right-click to open config dialog
    datasetFrame:EventAttach(Event.UI.Input.Mouse.Right.Click, function()
        if inspectSystemSecure() then return end

        LibEKL.Events.AddInsecure(function()
            wardrobe.showUI()
        end)
    end, name .. "_Right_Click")

    return datasetFrame
end
