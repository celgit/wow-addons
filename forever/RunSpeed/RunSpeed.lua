local ADDON_NAME = ...

-- Normal run speed is 7 yards/second = 100%.
local BASE_SPEED = BASE_MOVEMENT_SPEED or 7
local UPDATE_INTERVAL = 0.2

local BG_ALPHA = 0.35
local PAD_X, PAD_Y = 6, 3
local GAP_BELOW_DINGETA = 4

local DEFAULT_CHAR_DB = {
    locked = false,
    hidden = false,
}

local db
local box
local label
local lastPercent

local function CopyDefaults(target, defaults)
    for key, val in pairs(defaults) do
        if target[key] == nil then
            target[key] = val
        end
    end
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100RunSpeed:|r " .. message)
end

-- While moving, show the actual speed (slows, backpedaling, taxis).
-- Standing still, show the speed you would move at in your current state.
-- In combat (and other restricted states) GetUnitSpeed returns secret values,
-- which addons may not compare or do math on. Returns nil then.
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function GetSpeedPercent()
    local current, run, flight, swim = GetUnitSpeed("player")
    if IsSecret(current) or IsSecret(run) or IsSecret(flight) or IsSecret(swim) then
        return nil
    end
    local speed = current
    if not speed or speed <= 0 then
        if IsFlying and IsFlying() then
            speed = flight
        elseif IsSwimming and IsSwimming() then
            speed = swim
        else
            speed = run
        end
    end
    return math.floor((speed or 0) / BASE_SPEED * 100 + 0.5)
end

local function SavePosition()
    local point, _, relativePoint, x, y = box:GetPoint(1)
    db.point = { point, relativePoint, x, y }
end

local function RestorePosition()
    box:ClearAllPoints()
    local p = db.point
    if p then
        box:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    elseif _G.DingETAFrame then
        box:SetPoint("TOP", _G.DingETAFrame, "BOTTOM", 0, -GAP_BELOW_DINGETA)
    elseif Minimap then
        box:SetPoint("TOP", Minimap, "BOTTOM", 0, -24)
    else
        box:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -60, -230)
    end
end

local function Update()
    if db.hidden then
        box:Hide()
        return
    end
    box:Show()

    local percent = GetSpeedPercent()
    if percent then
        lastPercent = percent
        label:SetText(string.format("|cffffd100Speed|r %d%%", percent))
    elseif lastPercent then
        -- Secret right now: keep the last value, greyed out.
        label:SetText(string.format("|cffffd100Speed|r |cff808080%d%%|r", lastPercent))
    else
        label:SetText("|cffffd100Speed|r |cff808080-|r")
    end
    box:SetSize(math.ceil(label:GetStringWidth()) + PAD_X * 2, math.ceil(label:GetStringHeight()) + PAD_Y * 2)
end

local function CreateBox()
    box = CreateFrame("Frame", "RunSpeedFrame", UIParent, "BackdropTemplate")
    box:SetFrameStrata("LOW")
    box:SetClampedToScreen(true)
    box:SetMovable(true)
    box:EnableMouse(true)
    box:RegisterForDrag("LeftButton")
    box:SetScript("OnDragStart", function(self)
        if not db.locked then
            self:StartMoving()
        end
    end)
    box:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    box:SetBackdropColor(0, 0, 0, BG_ALPHA)

    label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")

    RestorePosition()
end

SLASH_RUNSPEED1 = "/runspeed"
SlashCmdList.RUNSPEED = function(message)
    local cmd = (message or ""):match("^%s*(.-)%s*$"):lower()
    if cmd == "lock" then
        db.locked = true
        Print("Box locked.")
    elseif cmd == "unlock" then
        db.locked = false
        Print("Box unlocked, drag it to move.")
    elseif cmd == "hide" then
        db.hidden = true
        Print("Box hidden. /runspeed show brings it back.")
    elseif cmd == "show" then
        db.hidden = false
    elseif cmd == "resetpos" then
        db.point = nil
        RestorePosition()
    else
        Print("/runspeed lock | unlock | show | hide | resetpos")
    end
    Update()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON_NAME then
            return
        end
        self:UnregisterEvent("ADDON_LOADED")
        RunSpeedCharDB = RunSpeedCharDB or {}
        db = RunSpeedCharDB
        CopyDefaults(db, DEFAULT_CHAR_DB)
    elseif event == "PLAYER_LOGIN" then
        -- Created here so DingETAFrame exists to anchor below, whatever the load order.
        CreateBox()
        Update()
        C_Timer.NewTicker(UPDATE_INTERVAL, Update)
    end
end)
