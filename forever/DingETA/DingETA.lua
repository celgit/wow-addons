local ADDON_NAME = ...

-- ETA uses XP gained in the last WINDOW seconds. When that is too thin (just
-- logged in, or AFK long enough that the window is empty) it falls back to
-- the "this level" rate: XP this level / /played time this level, like Titan.
local WINDOW = 15 * 60
local MIN_WINDOW_SPAN = 2 * 60
local MIN_LEVEL_TIME = 60
local PLAYED_SUPPRESS_SECONDS = 5

-- Default spot: under the minimap, below the coordinates text.
local DEFAULT_OFFSET_Y = -24
local BG_ALPHA = 0.35
local PAD_X, PAD_Y = 6, 3
local ROW_GAP = 2
local ROW_COUNT = 4

-- Kills left uses the median base XP (rested bonus removed) of the last few
-- kills, so a single elite or grey mob does not move the estimate.
local KILL_HISTORY = 5

local DEFAULT_CHAR_DB = {
    locked = false,
    hidden = false,
    sessionXP = 0,
    samples = {},
    kills = {},
}

local db
local box
local rows = {}
local lastXP, lastMax
local levelBase, levelBaseAt -- /played time this level, and GetTime() when it arrived
local suppressPlayedUntil = 0
local killPattern, restedKillPattern

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
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100DingETA:|r " .. message)
end

-- Formatting

local function FormatNumber(n)
    n = math.floor(n + 0.5)
    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(n)
    end
    return tostring(n)
end

local function FormatRate(perHour)
    if not perHour then
        return "-"
    end
    if perHour >= 10000 then
        return string.format("%.1fk", perHour / 1000)
    end
    return FormatNumber(perHour)
end

local function FormatDuration(seconds)
    if not seconds or seconds < 0 or seconds ~= seconds or seconds == math.huge then
        return "?"
    end
    if seconds < 60 then
        return "<1m"
    end
    local minutes = math.floor(seconds / 60 + 0.5)
    if minutes < 60 then
        return minutes .. "m"
    end
    local hours = math.floor(minutes / 60)
    if hours >= 100 then
        return ">99h"
    end
    return string.format("%dh %02dm", hours, minutes % 60)
end

-- Turns a Blizzard format string ("%s dies, you gain %d experience.") into a
-- Lua pattern with captures, so it follows the client's locale.
local function BuildPattern(fmt)
    if type(fmt) ~= "string" then
        return nil
    end
    local p = fmt:gsub("%%%d?%$?([sd])", "\001%1")
    p = p:gsub("[%^%$%(%)%.%[%]%*%+%-%?%%]", "%%%0")
    p = p:gsub("\001s", "(.-)")
    p = p:gsub("\001d", "(%%d+)")
    return "^" .. p
end

local function IsAtMaxLevel()
    if IsXPUserDisabled and IsXPUserDisabled() then
        return true
    end
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel()
    if maxLevel and UnitLevel("player") >= maxLevel then
        return true
    end
    return (UnitXPMax("player") or 0) <= 0
end

-- /played without chat spam

local function WrapPlayedDisplay(owner, key)
    local original = owner and owner[key]
    if type(original) ~= "function" then
        return
    end
    owner[key] = function(...)
        if GetTime() < suppressPlayedUntil then
            return
        end
        return original(...)
    end
end

local function InstallPlayedFilter()
    -- Older UI code uses the global, newer uses ChatFrameUtil. Wrap whichever exists.
    WrapPlayedDisplay(_G, "ChatFrame_DisplayTimePlayed")
    WrapPlayedDisplay(_G.ChatFrameUtil, "DisplayTimePlayed")
end

local function RequestPlayed()
    suppressPlayedUntil = GetTime() + PLAYED_SUPPRESS_SECONDS
    RequestTimePlayed()
end

-- Rates

local function GetLevelTime()
    if not levelBase then
        return nil
    end
    return levelBase + (GetTime() - levelBaseAt)
end

local function PruneSamples(now)
    local cutoff = now - WINDOW
    local kept = {}
    for _, sample in ipairs(db.samples) do
        if sample.t >= cutoff and sample.t <= now then
            kept[#kept + 1] = sample
        end
    end
    db.samples = kept
end

local function GetWindowRate(now)
    if not db.trackStart then
        return nil
    end
    local span = now - math.max(now - WINDOW, db.trackStart)
    if span < MIN_WINDOW_SPAN then
        return nil
    end
    local total = 0
    for _, sample in ipairs(db.samples) do
        total = total + sample.xp
    end
    if total <= 0 then
        return nil
    end
    return total / span * 3600
end

local function GetLevelRate()
    local levelTime = GetLevelTime()
    local xp = UnitXP("player")
    if not levelTime or levelTime < MIN_LEVEL_TIME or xp <= 0 then
        return nil
    end
    return xp / levelTime * 3600
end

local function GetSessionRate(now)
    if not db.sessionStart then
        return nil
    end
    local span = now - db.sessionStart
    if span < MIN_WINDOW_SPAN or db.sessionXP <= 0 then
        return nil
    end
    return db.sessionXP / span * 3600
end

local function GetToLevel()
    return UnitXPMax("player") - UnitXP("player")
end

local function EtaText(rate)
    if not rate or rate <= 0 then
        return "-"
    end
    return FormatDuration(GetToLevel() / rate * 3600)
end

-- Returns the rate the box shows, and whether it is the fallback.
local function GetMainRate(now)
    local windowRate = GetWindowRate(now)
    if windowRate then
        return windowRate, false
    end
    return GetLevelRate(), true
end

-- XP tracking

local function StartNewSession()
    local now = GetTime()
    db.sessionStart = now
    db.sessionXP = 0
    db.trackStart = now
    db.samples = {}
end

local function OnXPUpdate()
    local xp, max = UnitXP("player"), UnitXPMax("player")
    if lastXP then
        local gain
        if xp >= lastXP then
            gain = xp - lastXP
        else
            -- XP only goes down at a ding. Handling it here means we do not
            -- depend on whether PLAYER_XP_UPDATE or PLAYER_LEVEL_UP fires first.
            gain = (lastMax - lastXP) + xp
        end
        if gain > 0 then
            table.insert(db.samples, { t = GetTime(), xp = gain })
            db.sessionXP = db.sessionXP + gain
        end
    end
    lastXP, lastMax = xp, max
end

local function Median(list)
    local n = #list
    if n == 0 then
        return nil
    end
    local sorted = {}
    for i, v in ipairs(list) do
        sorted[i] = v
    end
    table.sort(sorted)
    if n % 2 == 1 then
        return sorted[(n + 1) / 2]
    end
    return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

-- Kill messages: "X dies, you gain 312 experience. (+156 exp Rested bonus)".
-- Captures are assumed in format order (name, total, bonus), as in enUS.
local function OnCombatXPGain(message)
    if not message then
        return
    end
    local total, bonus
    if restedKillPattern then
        local _, t, b = message:match(restedKillPattern)
        if t then
            total = tonumber(t)
            bonus = tonumber((b or ""):match("%d+"))
        end
    end
    if not total and killPattern then
        local _, t = message:match(killPattern)
        total = tonumber(t)
    end
    if not total or total <= 0 then
        return
    end

    bonus = bonus or 0
    local base = total - bonus
    if base <= 0 then
        return
    end
    if bonus > 0 then
        db.restedRatio = bonus / base
    end
    table.insert(db.kills, base)
    while #db.kills > KILL_HISTORY do
        table.remove(db.kills, 1)
    end
end

local function GetKillsLeft(toLevel)
    local base = Median(db.kills)
    if not base or base <= 0 then
        return nil
    end
    local rested = GetXPExhaustion() or 0
    local ratio = db.restedRatio or 1
    if rested <= 0 or ratio <= 0 then
        return math.ceil(toLevel / base)
    end
    -- Assumes each rested kill uses up as much rested as the bonus it gives:
    -- kills give base * (1 + ratio) until rested is gone, then base.
    local restedPhaseXP = rested * (1 + ratio) / ratio
    if toLevel <= restedPhaseXP then
        return math.ceil(toLevel / (base * (1 + ratio)))
    end
    return math.ceil(rested / (base * ratio) + (toLevel - restedPhaseXP) / base)
end

local function OnEnteringWorld(isInitialLogin)
    local now = GetTime()
    -- GetTime() is system uptime; if it went backwards the PC was rebooted.
    local stale = not db.sessionStart or db.sessionStart > now
    if isInitialLogin or stale then
        StartNewSession()
    end
    lastXP, lastMax = UnitXP("player"), UnitXPMax("player")
    if not levelBase then
        C_Timer.After(2, RequestPlayed)
    end
end

-- Box

local function ShowTooltip(self)
    local now = GetTime()
    local toLevel = GetToLevel()
    local windowRate = GetWindowRate(now)
    local levelRate = GetLevelRate()
    local sessionRate = GetSessionRate(now)
    local _, isFallback = GetMainRate(now)

    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Ding ETA")
    GameTooltip:AddDoubleLine("Last 15 min", FormatRate(windowRate) .. " xp/h, ding " .. EtaText(windowRate),
        1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("This level", FormatRate(levelRate) .. " xp/h, ding " .. EtaText(levelRate),
        1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("Session", FormatRate(sessionRate) .. " xp/h, ding " .. EtaText(sessionRate),
        1, 1, 1, 1, 1, 1)
    if isFallback then
        GameTooltip:AddLine("Box shows level pace (15 min window has too little data).", 0.6, 0.6, 0.6, true)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("XP left",
        string.format("%s (%d%%)", FormatNumber(toLevel), math.floor(toLevel / UnitXPMax("player") * 100 + 0.5)),
        0.8, 0.8, 0.8, 1, 1, 1)
    local killsLeft = GetKillsLeft(toLevel)
    if killsLeft then
        GameTooltip:AddDoubleLine("Kills left",
            string.format("%d (%s base xp, median of %d)", killsLeft, FormatNumber(Median(db.kills)), #db.kills),
            0.8, 0.8, 0.8, 1, 1, 1)
    end
    local rested = GetXPExhaustion()
    if rested and rested > 0 then
        GameTooltip:AddDoubleLine("Rested", FormatNumber(rested) .. " xp", 0.8, 0.8, 0.8, 0.44, 0.69, 0.94)
    end
    GameTooltip:AddDoubleLine("Time this level", FormatDuration(GetLevelTime()), 0.8, 0.8, 0.8, 1, 1, 1)
    if db.sessionStart then
        GameTooltip:AddDoubleLine("Session",
            FormatDuration(now - db.sessionStart) .. ", " .. FormatNumber(db.sessionXP) .. " xp",
            0.8, 0.8, 0.8, 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(db.locked and "Locked. /dingeta unlock to move." or "Drag to move. /dingeta lock",
        0.6, 0.6, 0.6)
    GameTooltip:Show()
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
    elseif Minimap then
        box:SetPoint("TOP", Minimap, "BOTTOM", 0, DEFAULT_OFFSET_Y)
    else
        box:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -60, -230)
    end
end

local function CreateBox()
    box = CreateFrame("Frame", "DingETAFrame", UIParent, "BackdropTemplate")
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
    box:SetScript("OnEnter", ShowTooltip)
    box:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    box:SetBackdropColor(0, 0, 0, BG_ALPHA)

    local previous
    for i = 1, ROW_COUNT do
        local row = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        if previous then
            row:SetPoint("TOP", previous, "BOTTOM", 0, -ROW_GAP)
        else
            row:SetPoint("TOP", box, "TOP", 0, -PAD_Y)
        end
        rows[i] = row
        previous = row
    end

    RestorePosition()
end

local function SetRow(i, text)
    rows[i]:SetText(text or "")
    rows[i]:SetShown(text ~= nil)
end

local function Update()
    if not box then
        return
    end
    if db.hidden or IsAtMaxLevel() then
        box:Hide()
        return
    end
    box:Show()

    local now = GetTime()
    PruneSamples(now)

    local toLevel = GetToLevel()

    SetRow(1, "|cffffd100Ding ETA|r")

    local rate, isFallback = GetMainRate(now)
    if rate and rate > 0 then
        -- Grey ETA = fallback to level pace.
        local color = isFallback and "|cffaaaaaa" or "|cffffffff"
        SetRow(2, string.format("%s%s|r  %s xp/hr", color, EtaText(rate), FormatRate(rate)))
    else
        SetRow(2, "|cffaaaaaa...|r")
    end

    local killsLeft = GetKillsLeft(toLevel)
    if killsLeft then
        SetRow(3, string.format("%d kills", killsLeft))
    else
        SetRow(3, nil)
    end

    local rested = GetXPExhaustion()
    if rested and rested > 0 then
        SetRow(4, string.format("|cff70b0f0Rested %s xp|r", FormatNumber(rested)))
    else
        SetRow(4, nil)
    end

    -- Stack only the visible rows, so a hidden middle row leaves no gap.
    local width, height = 0, PAD_Y * 2
    local previous
    for _, row in ipairs(rows) do
        if row:IsShown() then
            row:ClearAllPoints()
            if previous then
                row:SetPoint("TOP", previous, "BOTTOM", 0, -ROW_GAP)
            else
                row:SetPoint("TOP", box, "TOP", 0, -PAD_Y)
            end
            previous = row
            width = math.max(width, row:GetStringWidth())
            height = height + row:GetStringHeight() + ROW_GAP
        end
    end
    box:SetSize(math.ceil(width) + PAD_X * 2, math.ceil(height - ROW_GAP))

    if GameTooltip:IsOwned(box) then
        ShowTooltip(box)
    end
end

-- Slash command

SLASH_DINGETA1 = "/dingeta"
SlashCmdList.DINGETA = function(message)
    local cmd = (message or ""):match("^%s*(.-)%s*$"):lower()
    if cmd == "lock" then
        db.locked = true
        Print("Box locked.")
    elseif cmd == "unlock" then
        db.locked = false
        Print("Box unlocked, drag it to move.")
    elseif cmd == "hide" then
        db.hidden = true
        Print("Box hidden. /dingeta show brings it back.")
    elseif cmd == "show" then
        db.hidden = false
    elseif cmd == "reset" then
        StartNewSession()
        lastXP, lastMax = UnitXP("player"), UnitXPMax("player")
        Print("Session and 15 min window reset.")
    elseif cmd == "resetpos" then
        db.point = nil
        RestorePosition()
    else
        Print("/dingeta lock | unlock | show | hide | reset | resetpos")
    end
    Update()
end

-- Events

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON_NAME then
            return
        end
        self:UnregisterEvent("ADDON_LOADED")

        DingETACharDB = DingETACharDB or {}
        db = DingETACharDB
        CopyDefaults(db, DEFAULT_CHAR_DB)

        killPattern = BuildPattern(COMBATLOG_XPGAIN_FIRSTPERSON)
        restedKillPattern = BuildPattern(COMBATLOG_XPGAIN_EXHAUSTION1)
        InstallPlayedFilter()
        CreateBox()

        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_XP_UPDATE")
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("TIME_PLAYED_MSG")
        self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
        self:RegisterEvent("UPDATE_EXHAUSTION")

        C_Timer.NewTicker(1, Update)
    elseif event == "PLAYER_ENTERING_WORLD" then
        OnEnteringWorld(...)
        Update()
    elseif event == "PLAYER_XP_UPDATE" then
        local unit = ...
        if unit and unit ~= "player" then
            return
        end
        OnXPUpdate()
        Update()
    elseif event == "PLAYER_LEVEL_UP" then
        levelBase, levelBaseAt = 0, GetTime()
        Update()
    elseif event == "TIME_PLAYED_MSG" then
        local _, thisLevel = ...
        levelBase, levelBaseAt = thisLevel, GetTime()
        Update()
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        OnCombatXPGain((...))
    elseif event == "UPDATE_EXHAUSTION" then
        Update()
    end
end)
