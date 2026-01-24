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

local dialog
local context = UI.CreateContext("nkUI.auction")
context:SetStrata('dialog')
context:SetLayer(2)

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
                
                local thisSet = result.data[index] -- get current set of up to 50 auctions

                for idx = 1, #thisSet, 1 do

                    local thisAuction = InspectAuctionDetail(thisSet[idx]) -- get details of one auction

                    if thisAuction then
                        local thisValue
                        if thisAuction.buyout and thisAuction.itemStack then
                            thisValue = thisAuction.buyout / thisAuction.itemStack -- get price of single item if is a stack
                        elseif thisAuction.buyout then
                            thisValue = thisAuction.buyout -- get price of single item if is not a stack
                        else
                            thisValue = nil
                        end

                        if thisValue then
                            local id = thisAuction.itemType -- get type of item from auction information
                            if nkUIAuction[shard].items[id] then -- do we know this item type yet?                                

                                if nkUIAuction[shard].items[id].lowestPrice > thisValue then -- is this price highr than the lowest we ever saw? 
                                    nkUIAuction[shard].items[id].lowestPrice = thisValue
                                end

                                if nkUIAuction[shard].items[id].highestPrice < thisValue then -- is this price highr than the highest we ever saw?         
                                    nkUIAuction[shard].items[id].highestPrice = thisValue
                                end

                                -- Update average price calculation
                                nkUIAuction[shard].items[id].totalPrice = nkUIAuction[shard].items[id].totalPrice + thisValue
                                nkUIAuction[shard].items[id].count = nkUIAuction[shard].items[id].count + 1
                                nkUIAuction[shard].items[id].avgPrice = nkUIAuction[shard].items[id].totalPrice / nkUIAuction[shard].items[id].count

                                nkUIAuction[shard].items[id].lastSeen = scanTime
                            else
                                nkUIAuction[shard].items[id] = {
                                    lowestPrice = thisValue,
                                    highestPrice = thisValue,
                                    totalPrice = thisValue,
                                    avgPrice = thisValue,
                                    count = 1,
                                    lastSeen = scanTime
                                }
                            end
                        end
                    end
                    
                    counter = counter + 1                    
                end

                index = index + 1

                dialog:SetMessage(string.format(langTexts.auction.scanProgress, counter / result.count * 100))
--                ahTools:SetProgress(counter / result.count * 100)
                coroutine.yield(auction)

            end           

            dialog:SetVisible(false)
            nkUIAuction[shard].lastScan = scanTime
            
            coroutine.yield()
        end
    )

    LibEKL.Coroutines.Add ({ func = processResults, active = true, para1 = result, para2 = ahTools })                
end

local function ahScan(_, info, auctions) 

    if info.type == "search" and not info.text then           

        if not nkUIAuction then nkUIAuction = {} end

        local shard = Inspect.Shard().name
        
        if not nkUIAuction[shard] then
            nkUIAuction[shard] = { lastScan = nil, items = {}, auctions = {}}
        end

        local counter, totalCounter = 0, 0
        local auctionSet = {}
        local newAuctions = {}
        
        local previousAuctions = nkUIAuction[shard].auctions or {}
        local knownAuctions = {}

        -- build tables of 50 auctions for the later processing

        for thisAuction, v in pairs (auctions) do

            if not previousAuctions[thisAuction] then -- only process new auctions
                table.insert(auctionSet, thisAuction)                        
                knownAuctions[thisAuction] = true -- mark the new auction as known

                counter = counter + 1
                totalCounter = totalCounter + 1
                if counter >= 50 then
                    counter = 0
                    table.insert(newAuctions, auctionSet)
                    auctionSet = {}
                end
            end
        end

        if counter > 0 then
            table.insert(newAuctions, auctionSet)
        end
        
        local removedAuctions = 0

        for k, v in pairs(previousAuctions) do
            if auctions[k] then -- if the auction is still running
                knownAuctions[k] =  true -- mark as known
            else
                removedAuctions = removedAuctions + 1
            end
        end

        Command.Console.Display("general", true, stringFormat(langTexts.auction.newAuctions, totalCounter), true)		        
        Command.Console.Display("general", true, stringFormat(langTexts.auction.removedAuctions, removedAuctions), true)		        

        nkUIAuction[shard].auctions = knownAuctions -- set known to previous plus new auctions

        local result = { count = totalCounter, data = newAuctions}

        ahScanResult(result, ahTools)
    end            

end

function internalFunc.ahScanDialog()

    if not dialog then

        dialog = LibEKL.UICreateFrame("nkWindow", "nkUI.auction.scanDialog", context)
        dialog:ClearAll()
        dialog:SetTitle("nkUI")
        dialog:SetTitleAlign('center')
        dialog:SetWidth(400)
        dialog:SetHeight(150)
        dialog:SetCloseable(false)	
        dialog:SetTitleFont(addonInfo.id, "MontserratBold")
        dialog:SetTitleFontSize(16)
        dialog:SetTitleEffect ( {strength = 3})
        dialog:SetTitleFontColor(1, .8, 0, 1)

        dialog:SetColor({
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
        
        local msg = LibEKL.UICreateFrame("nkText", "nkUI.auction.scanDialog.msg", dialog:GetContent())
        msg:SetText(privateVars.langTexts.msgReload)
        msg:SetPoint("CENTERTOP", dialog:GetContent(), "CENTERTOP", 0, 10)
        msg:SetFontSize(16)
        msg:SetFontColor(1,1,1,1)

        LibEKL.UI.SetFont(msg, addonInfo.id, "MontserratSemiBold")

        dialog:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (LibEKL.UI.getBoundRight() / 2 ) - (dialog:GetWidth() / 2), 100)

        function dialog:SetMessage(newMessage)
            msg:SetText(newMessage)
        end

        Command.Event.Attach(Event.Auction.Scan, ahScan, "nkUI.Auction.Scan")
    else
        dialog:SetVisible(true)
    end

    if not nkUIAuction then nkUIAuction = {} end

    local shard = Inspect.Shard().name
    
    if not nkUIAuction[shard] then
        nkUIAuction[shard] = { lastScan = nil, items = {}, auctions = {}}
    end

    dialog:SetMessage(langTexts.auction.scanStarted)

    Command.Auction.Scan({type = "search"})

end