local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.auction = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events
local auction       = privateVars.auction
local langTexts     = privateVars.langTexts

local InspectTimeReal       = Inspect.Time.Real
local InspectAuctionDetail  = Inspect.Auction.Detail

local stringFormat      = string.format
local stringFind        = string.find
local stringMatch       = string.match

local mathFloor         = math.floor

---------- init variables ---------

local context = UI.CreateContext("nkUI.onebag")
context:SetStrata('dialog')
context:SetLayer(2)

local function build()

    local name = "nkUI.auction"

    local ahToolsWindow = LibEKL.UICreateFrame("nkWindow", name, context)
    ahToolsWindow:SetTitle("Auction Tools")
    ahToolsWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    ahToolsWindow:SetTitleFontSize(16)
    ahToolsWindow:SetTitleEffect({ strength = 3})
    ahToolsWindow:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

    ahToolsWindow:SetWidth(200)
    ahToolsWindow:SetHeight(200)
    ahToolsWindow:SetLayer(1)

    ahToolsWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, 500)

    ahToolsWindow:SetColor({
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

    local itemCounter = LibEKL.UICreateFrame("nkText", name .. ".counter", ahToolsWindow:GetContent())
    itemCounter:SetPoint("TOPLEFT", ahToolsWindow:GetContent(), "TOPLEFT", 10, 10)
    
    local button = LibEKL.UICreateFrame("nkButton", name .. ".button", ahToolsWindow:GetContent())

    button:SetPoint("TOPLEFT", itemCounter, "BOTTOMLEFT", 0, 10)
    button:SetWidth(100)
    button:SetHeight(50)
    button:SetText("Scan")
    button:SetFont(addonInfo.id, "MontserratSemiBold")
	button:SetEffectGlow ({ strength = 3 })
    button:SetLabelColor(data.theme.labelColor)
	button:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
    button:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})

    button:EventAttach(Event.UI.Input.Mouse.Left.Click, function ()
		Command.Auction.Scan({type = "search"})        
	end, name .. "_leftButton_LeftClick")

    ahToolsWindow:SetVisible(false)

    function ahToolsWindow:SetCounter(counter)
        itemCounter:SetText(stringFormat("%d items processed", counter))
    end

    function ahToolsWindow:SetProgress(progress)
        itemCounter:SetText(stringFormat("%d%% done", progress))
    end

    return ahToolsWindow

end

local function ahScanResult(result, ahTools)

    local processResults = coroutine.create(

        function (result, ahTools)
            local counter = 0
            local index = 1
            local scanTime = InspectTimeReal()
            local shard = Inspect.Shard().name
            
            while counter < result.count do
                
                local thisSet = result.data[index]

                for idx = 1, #thisSet, 1 do

                    local thisAuction = InspectAuctionDetail(thisSet[idx])

                    if thisAuction then
                        local thisValue
                        if thisAuction.buyout and thisAuction.itemStack then
                            thisValue = thisAuction.buyout / thisAuction.itemStack
                        elseif thisAuction.buyout then
                            thisValue = thisAuction.buyout
                        else
                            thisValue = nil
                        end

                        if thisValue then
                            local id = thisAuction.itemType
                            if nkUIAuction[shard].items[id] then
                                if nkUIAuction[shard].items[id].lastPrice > thisValue then
                                    nkUIAuction[shard].items[id] = { lastPrice = thisValue, lastSeen = scanTime }
                                end
                            else
                                nkUIAuction[shard].items[id] = { lastPrice = thisValue, lastSeen = scanTime }
                            end
                        end
                    end
                    
                    counter = counter + 1                    
                end

                index = index + 1

                ahTools:SetProgress(counter / result.count * 100)
                coroutine.yield(auction)

            end           

            nkUIAuction[shard].lastScan = scanTime
            
            coroutine.yield()
        end
    )

    LibEKL.Coroutines.Add ({ func = processResults, active = true, para1 = result, para2 = ahTools })                

end

function internalFunc.scanAH()

    local ahTools = build()

    UI.Native.Auction:EventAttach(Event.UI.Native.Loaded, function()
        ahTools:SetVisible(UI.Native.Auction:GetLoaded())
    end, "nkUI.OneBag.Native.Bank.Loaded")

    if not nkUIAuction then nkUIAuction = {} end

    local shard = Inspect.Shard().name
    
    if not nkUIAuction[shard] then
        nkUIAuction[shard] = { lastScan = nil, items = {}}
    end

    Command.Event.Attach(Event.Auction.Scan, 
        function (_, info, auctions)            
            if info.type == "search" then

                local counter, totalCounter = 0, 0
                local auctionSet = {}
                local resultSet = {}

                for thisAuction, v in pairs (auctions) do
                    table.insert(auctionSet, thisAuction)
                    counter = counter + 1
                    totalCounter = totalCounter + 1
                    if counter >= 50 then
                        counter = 0
                        table.insert(resultSet, auctionSet)
                        auctionSet = {}
                    end
                end

                if counter > 0 then
                    table.insert(resultSet, auctionSet)
                end

                local result = { count = totalCounter, data = resultSet}

                ahScanResult(result, ahTools)
            end            
        end,
    "nkUI.Auction.Scan")


end