local ADDON_NAME = ...

-- Forever uses the Mainline UI, where these only exist under C_*.
local GetItemInfo = C_Item.GetItemInfo
local GetCoinTextureString = C_CurrencyInfo.GetCoinTextureString

local SELL_BATCH_SIZE = 10
local SELL_PASS_DELAY = 0.3
local SELL_MAX_PASSES = 30
local COIN_TEXTURE = "Interface\\MoneyFrame\\UI-GoldIcon"
local COLOR_GOLD = { 1, 0.82, 0 }
local COLOR_SILVER = { 0.78, 0.78, 0.81 }
local COLOR_COPPER = { 0.93, 0.65, 0.37 }

local DEFAULT_CHAR_DB = {
    keep = {},
}

local db
local hookedButtons = {}
local refreshPending = false
local selling = {
    active = false,
    passes = 0,
    attempted = {},
}

local function CopyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                CopyDefaults(target[key], value)
            else
                target[key] = value
            end
        end
    end
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100ATS:|r " .. message)
end

local function GetSlotInfo(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)

    if not info then
        return nil
    end

    return {
        itemID = info.itemID,
        count = info.stackCount,
        locked = info.isLocked,
        quality = info.quality,
        link = info.hyperlink,
        noValue = info.hasNoValue,
    }
end

-- Trash rules

local function GetQuality(info)
    if info.quality and info.quality >= 0 then
        return info.quality
    end

    local _, _, quality = GetItemInfo(info.itemID)
    return quality
end

local function IsGrey(quality)
    return quality == 0
end

-- keep[itemID]: true = never sell, false = always sell, nil = default (grey is trash).
-- Compare against false explicitly, since "not keep[id]" would also match nil.
local function IsTrash(itemID, quality)
    local keep = db.keep[itemID]

    if keep == true then
        return false
    end

    if keep == false then
        return true
    end

    return IsGrey(quality)
end

local function GetStackValue(info)
    if info.noValue then
        return 0
    end

    local sellPrice = select(11, GetItemInfo(info.itemID))

    if not sellPrice then
        return nil
    end

    return sellPrice * info.count
end

-- Value formatting: highest coin type, two decimals for the next one.

local function FormatValue(copper)
    local gold = math.floor(copper / 10000)

    if gold > 0 then
        local silver = math.floor((copper % 10000) / 100)

        if silver > 0 then
            return string.format("%d.%02dg", gold, silver), COLOR_GOLD
        end

        return gold .. "g", COLOR_GOLD
    end

    local silver = math.floor(copper / 100)

    if silver > 0 then
        local rest = copper % 100

        if rest > 0 then
            return string.format("%d.%02ds", silver, rest), COLOR_SILVER
        end

        return silver .. "s", COLOR_SILVER
    end

    return copper .. "c", COLOR_COPPER
end

-- Bag button overlays

local function GetButtonLocation(button)
    return button:GetBagID(), button:GetID()
end

local function GetOverlay(button)
    if button.AutoTrashSellerOverlay then
        return button.AutoTrashSellerOverlay
    end

    local overlay = {}

    overlay.coin = button:CreateTexture(nil, "OVERLAY")
    overlay.coin:SetTexture(COIN_TEXTURE)
    overlay.coin:SetSize(14, 14)
    overlay.coin:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    overlay.coin:Hide()

    overlay.value = button:CreateFontString(nil, "OVERLAY")
    overlay.value:SetFontObject(NumberFontNormalSmall)
    overlay.value:SetPoint("CENTER", button, "CENTER", 0, 0)
    overlay.value:Hide()

    button.AutoTrashSellerOverlay = overlay
    return overlay
end

local function ToggleMark(bag, slot)
    local info = GetSlotInfo(bag, slot)

    if not info then
        return
    end

    local itemID = info.itemID
    local quality = GetQuality(info)
    local link = info.link or select(2, GetItemInfo(itemID)) or ("item " .. itemID)

    if db.keep[itemID] ~= nil then
        db.keep[itemID] = nil

        if IsGrey(quality) then
            Print(link .. " mark removed, back to default (trash).")
        else
            Print(link .. " mark removed, back to default (keep).")
        end
    elseif IsGrey(quality) then
        db.keep[itemID] = true
        Print(link .. " marked as keep.")
    else
        db.keep[itemID] = false
        Print(link .. " marked as trash.")
    end
end

local UpdateAllButtons

local function OnButtonClick(button, mouseButton)
    if mouseButton ~= "RightButton" or not IsControlKeyDown() then
        return
    end

    local bag, slot = GetButtonLocation(button)

    if not bag or not slot then
        return
    end

    ToggleMark(bag, slot)
    UpdateAllButtons()
end

local function UpdateButton(button)
    if not hookedButtons[button] then
        button:HookScript("OnClick", OnButtonClick)
        hookedButtons[button] = true
    end

    local overlay = GetOverlay(button)
    local bag, slot = GetButtonLocation(button)
    local info = bag and slot and GetSlotInfo(bag, slot)

    if not info or not button:IsShown() then
        overlay.coin:Hide()
        overlay.value:Hide()
        return
    end

    local value = GetStackValue(info)

    -- Coin and value only on items that will be sold; for anything else, use the tooltip.
    if value and value > 0 and IsTrash(info.itemID, GetQuality(info)) then
        local text, color = FormatValue(value)

        overlay.value:SetText(text)
        overlay.value:SetTextColor(color[1], color[2], color[3])
        overlay.value:Show()
        overlay.coin:Show()
    else
        overlay.value:Hide()
        overlay.coin:Hide()
    end
end

-- The combined backpack plus the separate bag frames used when bags are not combined.
local function GetContainerFrames()
    local frames = { ContainerFrameCombinedBags }

    for index = 1, NUM_CONTAINER_FRAMES do
        table.insert(frames, _G["ContainerFrame" .. index])
    end

    return frames
end

-- Item buttons are unnamed children of the container frame, so find them by bag and slot ID.
local function IsItemButton(child)
    if not child.GetBagID or not child.GetID then
        return false
    end

    local bag = child:GetBagID()
    local slot = child:GetID()

    return type(bag) == "number" and type(slot) == "number" and slot > 0 and
        bag >= BACKPACK_CONTAINER and bag <= NUM_BAG_SLOTS
end

local function UpdateContainerFrame(frame)
    if not db or not frame:IsShown() then
        return
    end

    for _, child in ipairs({ frame:GetChildren() }) do
        if IsItemButton(child) then
            UpdateButton(child)
        end
    end
end

UpdateAllButtons = function()
    for _, frame in ipairs(GetContainerFrames()) do
        UpdateContainerFrame(frame)
    end
end

-- Coalesce bursts of events (e.g. many GET_ITEM_INFO_RECEIVED) into one update.
local function ScheduleRefresh()
    if refreshPending then
        return
    end

    refreshPending = true

    C_Timer.After(0.05, function()
        refreshPending = false
        UpdateAllButtons()
    end)
end

-- Tooltip

local function AddTooltipMark(tooltip, bag, slot)
    if not db or not bag or not slot then
        return
    end

    local info = GetSlotInfo(bag, slot)

    if not info then
        return
    end

    local keep = db.keep[info.itemID]

    if keep == true then
        tooltip:AddLine("Auto Trash Seller: Marked as keep", 0.4, 1, 0.4)
        tooltip:Show()
    elseif keep == false then
        tooltip:AddLine("Auto Trash Seller: Marked as trash", 1, 0.82, 0)
        tooltip:Show()
    end
end

-- Selling

local function IsMerchantReady()
    return MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1
end

local function CollectTrash()
    local items = {}
    local pending = 0

    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = GetSlotInfo(bag, slot)

            if info then
                local quality = GetQuality(info)
                local value = GetStackValue(info)

                if value and value > 0 and IsTrash(info.itemID, quality) then
                    if info.locked then
                        pending = pending + 1
                    else
                        table.insert(items, {
                            bag = bag,
                            slot = slot,
                            itemID = info.itemID,
                            count = info.count,
                            value = value,
                            link = info.link,
                        })
                    end
                end
            end
        end
    end

    -- Cheapest first, so the most valuable items end up in the buyback tab.
    table.sort(items, function(a, b)
        return a.value < b.value
    end)

    return items, pending
end

local function FinishSelling()
    if not selling.active then
        return
    end

    selling.active = false

    -- Only list items that are actually gone from their slot, so failed sales are left out.
    local sold = {}

    for _, item in pairs(selling.attempted) do
        local info = GetSlotInfo(item.bag, item.slot)

        if not info or info.itemID ~= item.itemID then
            table.insert(sold, item)
        end
    end

    table.sort(sold, function(a, b)
        return a.value < b.value
    end)

    local total = 0

    for _, item in ipairs(sold) do
        total = total + item.value

        local text, color = FormatValue(item.value)
        local valueText = string.format("|cff%02x%02x%02x%s|r",
            math.floor(color[1] * 255), math.floor(color[2] * 255), math.floor(color[3] * 255), text)
        local countText = item.count > 1 and (" x" .. item.count) or ""

        Print("Sold " .. (item.link or ("item " .. item.itemID)) .. countText .. " - " .. valueText)
    end

    if total > 0 then
        Print("Total: " .. GetCoinTextureString(total))
    end
end

local function SellPass()
    if not selling.active then
        return
    end

    if not IsMerchantReady() then
        FinishSelling()
        return
    end

    local items, pending = CollectTrash()

    if #items == 0 and pending == 0 then
        FinishSelling()
        return
    end

    selling.passes = selling.passes + 1

    if selling.passes > SELL_MAX_PASSES then
        FinishSelling()
        return
    end

    for index = 1, math.min(SELL_BATCH_SIZE, #items) do
        local item = items[index]

        C_Container.UseContainerItem(item.bag, item.slot)

        -- Keyed by slot, so a retry of the same slot is not listed twice.
        selling.attempted[item.bag .. ":" .. item.slot] = item
    end

    C_Timer.After(SELL_PASS_DELAY, SellPass)
end

local function StartSelling()
    if selling.active then
        return
    end

    selling.active = true
    selling.passes = 0
    selling.attempted = {}

    -- MerchantFrame is shown by Blizzard's own MERCHANT_SHOW handler, which may run after ours.
    C_Timer.After(0.1, SellPass)
end

-- UpdateItems runs whenever Blizzard redraws a bag frame, including when it opens.
local function InstallBagHooks()
    for _, frame in ipairs(GetContainerFrames()) do
        if frame.UpdateItems then
            hooksecurefunc(frame, "UpdateItems", UpdateContainerFrame)
        end
    end

    hooksecurefunc(GameTooltip, "SetBagItem", AddTooltipMark)
end

local events = CreateFrame("Frame")

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("ITEM_LOCK_CHANGED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")

events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...

        if addonName ~= ADDON_NAME then
            return
        end

        AutoTrashSellerCharDB = AutoTrashSellerCharDB or {}
        CopyDefaults(AutoTrashSellerCharDB, DEFAULT_CHAR_DB)
        db = AutoTrashSellerCharDB

        InstallBagHooks()
        return
    end

    if not db then
        return
    end

    if event == "MERCHANT_SHOW" then
        StartSelling()
        return
    end

    if event == "MERCHANT_CLOSED" then
        FinishSelling()
        return
    end

    ScheduleRefresh()
end)

SLASH_AUTOTRASHSELLER1 = "/ats"
SLASH_AUTOTRASHSELLER2 = "/autotrashseller"

SlashCmdList["AUTOTRASHSELLER"] = function(message)
    message = string.lower(strtrim(message or ""))

    if not db then
        return
    end

    if message == "list" then
        local found = false

        for itemID, keep in pairs(db.keep) do
            local link = select(2, GetItemInfo(itemID)) or ("item " .. itemID)

            Print(link .. (keep and " - keep" or " - trash"))
            found = true
        end

        if not found then
            Print("No marked items.")
        end

        return
    end

    if message == "reset" then
        wipe(db.keep)
        Print("All marks cleared.")
        UpdateAllButtons()
        return
    end

    Print("Commands: /ats list, /ats reset")
end
