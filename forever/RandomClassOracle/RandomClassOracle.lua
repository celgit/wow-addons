local ADDON_NAME, ns = ...

local CLASS_POOL = {
    { token = "WARRIOR", name = "Warrior" },
    { token = "PALADIN", name = "Paladin" },
    { token = "SHAMAN", name = "Shaman" },
    { token = "HUNTER", name = "Hunter" },
    { token = "ROGUE", name = "Rogue" },
    { token = "PRIEST", name = "Priest" },
    { token = "MAGE", name = "Mage" },
    { token = "WARLOCK", name = "Warlock" },
    { token = "DRUID", name = "Druid" },
}

local POPUP_TEXT_LEVEL = "You leveled up! Roll the dice and try another class for a level or two?"
local POPUP_TEXT_LEVEL_RESTED = "You leveled up and are now in a rested area! Roll the dice and try another class for a level or two?"
local POPUP_TEXT_DEATH = "Oh noes! Anyway, roll the dice?"
local POPUP_TEXT_RESTED = "Your rested XP ran out! Roll the dice and try another class for a level or two?"
local POPUP_TEXT_REST_AREA = "You're in a rested area! Roll the dice and try another class for a level or two?"
local INN_HINT_TEXT = "Log out at an inn if you can."
local SAME_CLASS_TEXT = "Same class - keep going!"
local MIN_TRIGGER_LEVEL = 6
local SWITCH_TEXT_FORMAT ="Noice, you're now in a rested-area. Time for |cffffffff%s|r"

local DEFAULT_DB = {
    enabledClasses = {},
    soundEnabled = true,
    hardcore = false,
    triggers = {
        level = true,
        levelWaitForRest = false,
        rested = true,
        death = true,
        restArea = false,
    },
    promptCooldownMinutes = 30,
    minimap = {
        hide = false,
        angle = 225,
    },
}

local DEFAULT_CHAR_DB = {
    pendingLevelUp = false,
    pendingReason = nil,
    pendingLevel = nil,
}

local LEGACY_ACCOUNT_KEYS = { "pendingLevelUp", "pendingReason", "pendingLevel", "pendingSnoozed", "recentPicks" }

local CLASS_NAME_TO_TOKEN = {
    Warrior = "WARRIOR",
    Paladin = "PALADIN",
    Hunter = "HUNTER",
    Rogue = "ROGUE",
    Priest = "PRIEST",
    Shaman = "SHAMAN",
    Mage = "MAGE",
    Warlock = "WARLOCK",
    Druid = "DRUID",
}

local diceFrame
local resultText
local hintText
local ShowResult
local activePromptReason
local activePromptExcludeCurrentClass
local activePromptShowInnHint
local activePromptIsPreview
local lastXPExhaustion
local wasResting
local lastRollClass
local hasRolledThisSession
local switchReminderClass

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

local function EnsureEnabledClasses()
    RandomClassOracleDB.enabledClasses = RandomClassOracleDB.enabledClasses or {}

    for _, classToken in pairs(CLASS_NAME_TO_TOKEN) do
        if RandomClassOracleDB.enabledClasses[classToken] == nil then
            RandomClassOracleDB.enabledClasses[classToken] = true
        end
    end
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Class Dice:|r " .. message)
end

local function IsTriggerEnabled(reason)
    return RandomClassOracleDB.triggers[reason] == true
end

local function IsReasonEnabled(reason)
    if reason == "level" then
        return IsTriggerEnabled("level") and not IsTriggerEnabled("levelWaitForRest")
    end

    if reason == "levelRest" then
        return IsTriggerEnabled("level") and IsTriggerEnabled("levelWaitForRest")
    end

    return IsTriggerEnabled(reason)
end

local function RestartCooldown()
    RandomClassOracleCharDB.cooldownStart = time()
end

local function GetCooldownMinutesLeft()
    local startedAt = RandomClassOracleCharDB.cooldownStart

    if not startedAt then
        return 0
    end

    local secondsLeft = RandomClassOracleDB.promptCooldownMinutes * 60 - (time() - startedAt)
    return math.max(0, math.ceil(secondsLeft / 60))
end

local function IsCooldownActive()
    return GetCooldownMinutesLeft() > 0
end

local function IsInRestArea()
    return IsResting() == true
end

local function GetRestStateText()
    if not GetRestState then
        return "unknown"
    end

    local restState = GetRestState()

    if restState == 1 then
        return "Rested"
    end

    if restState == 2 then
        return "Normal"
    end

    return "Unknown"
end

local function PrintStatus()
    Print("Pending level-up: " .. tostring(RandomClassOracleCharDB.pendingLevelUp))
    Print("Pending reason: " .. tostring(RandomClassOracleCharDB.pendingReason))
    Print("Pending level: " .. tostring(RandomClassOracleCharDB.pendingLevel))
    Print("Resting area: " .. tostring(IsInRestArea()))
    Print("Rest state: " .. GetRestStateText())
    Print("Rested XP: " .. tostring(GetXPExhaustion()))
    Print("Rolled this session: " .. tostring(hasRolledThisSession == true))
    Print("Hardcore: " .. tostring(RandomClassOracleDB.hardcore))
    Print("Triggers: level-up " .. tostring(IsTriggerEnabled("level"))
        .. " (wait for rested area " .. tostring(IsTriggerEnabled("levelWaitForRest")) .. ")"
        .. ", rested XP " .. tostring(IsTriggerEnabled("rested"))
        .. ", rested area " .. tostring(IsTriggerEnabled("restArea"))
        .. ", death " .. tostring(IsTriggerEnabled("death")))
    Print("Cooldown: " .. tostring(RandomClassOracleDB.promptCooldownMinutes) .. " min, "
        .. tostring(GetCooldownMinutesLeft()) .. " min left")
    Print("Location: " .. tostring(GetZoneText()) .. " / " .. tostring(GetSubZoneText()))
end

local function PlayDiceSound()
    if not RandomClassOracleDB.soundEnabled or not SOUNDKIT then
        return
    end

    local sound = SOUNDKIT.READY_CHECK or SOUNDKIT.IG_QUEST_LIST_OPEN or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON

    if sound then
        PlaySound(sound)
    end
end

local function CreateDiceFrame()
    if diceFrame then
        return diceFrame
    end

    diceFrame = CreateFrame("Frame", "RandomClassDiceFrame", UIParent, "BasicFrameTemplateWithInset")
    diceFrame:SetSize(320, 170)
    diceFrame:SetPoint("CENTER")
    diceFrame:SetMovable(true)
    diceFrame:EnableMouse(true)
    diceFrame:RegisterForDrag("LeftButton")
    diceFrame:SetScript("OnDragStart", diceFrame.StartMoving)
    diceFrame:SetScript("OnDragStop", diceFrame.StopMovingOrSizing)
    diceFrame:Hide()

    diceFrame.title = diceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    diceFrame.title:SetPoint("TOPLEFT", 14, -8)
    diceFrame.title:SetText("Random Class Dice")

    local intro = diceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    intro:SetPoint("TOP", 0, -48)
    intro:SetText("The dice say:")

    resultText = diceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    resultText:SetPoint("TOP", intro, "BOTTOM", 0, -14)
    resultText:SetText("-")

    hintText = diceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintText:SetPoint("TOP", resultText, "BOTTOM", 0, -10)
    hintText:SetText("")

    local closeButton = CreateFrame("Button", nil, diceFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(96, 24)
    closeButton:SetPoint("BOTTOM", 0, 16)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        diceFrame:Hide()
    end)

    return diceFrame
end

local function GetClassPool()
    return CLASS_POOL
end

local function IsClassEnabled(classToken)
    EnsureEnabledClasses()
    return RandomClassOracleDB.enabledClasses[classToken] ~= false
end

local function GetEnabledClassCount()
    local enabledCount = 0

    for _, classInfo in ipairs(GetClassPool()) do
        if IsClassEnabled(classInfo.token) then
            enabledCount = enabledCount + 1
        end
    end

    return enabledCount
end

ns.GetClassPool = GetClassPool
ns.IsClassEnabled = IsClassEnabled

function ns.SetClassEnabled(classToken, enabled)
    EnsureEnabledClasses()
    RandomClassOracleDB.enabledClasses[classToken] = enabled == true
end

function ns.EnableAllClasses()
    for _, classInfo in ipairs(GetClassPool()) do
        ns.SetClassEnabled(classInfo.token, true)
    end
end

local function PickClass(excludeCurrentClass)
    local available = {}
    local _, currentClassToken = UnitClass("player")

    for _, classInfo in ipairs(GetClassPool()) do
        local isCurrentClass = excludeCurrentClass and classInfo.token == currentClassToken

        if IsClassEnabled(classInfo.token) and not isCurrentClass then
            table.insert(available, classInfo)
        end
    end

    if #available == 0 then
        return nil
    end

    return available[math.random(#available)]
end

ShowResult = function(excludeCurrentClass, showInnHint)
    if GetEnabledClassCount() == 0 then
        Print("No classes are enabled. Open /rcd options to include at least one class.")
        return false
    end

    local choice = PickClass(excludeCurrentClass)

    if not choice then
        Print("No eligible classes are available. Open /rcd options to include more classes.")
        return false
    end

    local _, currentClassToken = UnitClass("player")
    local isSameClass = choice.token == currentClassToken
    local hint = ""

    if isSameClass then
        hint = SAME_CLASS_TEXT
    elseif showInnHint then
        hint = INN_HINT_TEXT
    end

    CreateDiceFrame()
    resultText:SetText(choice.name)
    hintText:SetText(hint)
    diceFrame:Show()

    lastRollClass = choice.name

    if not activePromptIsPreview then
        if hint == INN_HINT_TEXT and not IsInRestArea() then
            switchReminderClass = choice.name
        else
            switchReminderClass = nil
        end
    end

    PlayDiceSound()
    Print("The dice say: |cffffffff" .. choice.name .. "|r")

    if hint ~= "" then
        Print(hint)
    end

    return true, isSameClass
end

local function PrintLastResult()
    if not lastRollClass then
        Print("No roll yet this session.")
        return
    end

    Print("Last roll: |cffffffff" .. lastRollClass .. "|r")
end

local function ClearPendingState()
    if activePromptIsPreview then
        return
    end

    RandomClassOracleCharDB.pendingLevelUp = false
    RandomClassOracleCharDB.pendingReason = nil
    RandomClassOracleCharDB.pendingLevel = nil
end

local function ClearActivePrompt()
    activePromptReason = nil
    activePromptExcludeCurrentClass = nil
    activePromptShowInnHint = nil
    activePromptIsPreview = nil
end

local function SetPending(reason)
    if hasRolledThisSession then
        return false
    end

    local isLevelUp = reason == "level" or reason == "levelRest"

    RandomClassOracleCharDB.pendingLevelUp = isLevelUp
    RandomClassOracleCharDB.pendingReason = reason
    RandomClassOracleCharDB.pendingLevel = isLevelUp and UnitLevel("player") or nil
    return true
end

StaticPopupDialogs["RANDOM_CLASS_DICE_ROLL"] = {
    text = "Roll the dice and try another class for a level or two?",
    button1 = "Roll",
    button2 = "Skip",
    OnAccept = function()
        local pickedClass, isSameClass = ShowResult(activePromptExcludeCurrentClass, activePromptShowInnHint)

        if pickedClass then
            ClearPendingState()

            if not activePromptIsPreview then
                RestartCooldown()

                if not isSameClass then
                    hasRolledThisSession = true
                end
            end
        end

        ClearActivePrompt()
    end,
    OnCancel = function()
        if not activePromptIsPreview then
            RestartCooldown()
        end

        ClearPendingState()
        ClearActivePrompt()
        Print("Roll skipped.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function GetPopupText(reason)
    if reason == "death" then
        return POPUP_TEXT_DEATH
    end

    if reason == "rested" then
        return POPUP_TEXT_RESTED
    end

    if reason == "restArea" then
        return POPUP_TEXT_REST_AREA
    end

    if reason == "levelRest" then
        return POPUP_TEXT_LEVEL_RESTED
    end

    return POPUP_TEXT_LEVEL
end

local function OpenRollPrompt(reason, isPreview)
    activePromptReason = reason
    activePromptExcludeCurrentClass = reason == "death"
    activePromptShowInnHint = not (reason == "death" and RandomClassOracleDB.hardcore)
    activePromptIsPreview = isPreview

    local dialog = StaticPopupDialogs["RANDOM_CLASS_DICE_ROLL"]

    dialog.text = GetPopupText(reason)

    if reason == "restArea" then
        dialog.button1 = "Roll dice"
        dialog.button2 = "Keep playing"
    else
        dialog.button1 = "Roll"
        dialog.button2 = "Skip"
    end

    StaticPopup_Show("RANDOM_CLASS_DICE_ROLL")
end

local function TryShowPendingPrompt()
    local reason = RandomClassOracleCharDB.pendingReason

    if not reason then
        return
    end

    if not IsReasonEnabled(reason) then
        ClearPendingState()
        return
    end

    if StaticPopup_Visible and StaticPopup_Visible("RANDOM_CLASS_DICE_ROLL") then
        return
    end

    if UnitAffectingCombat("player") or UnitIsDeadOrGhost("player") then
        return
    end

    if reason == "levelRest" and (not IsInRestArea() or IsCooldownActive()) then
        return
    end

    OpenRollPrompt(reason, false)
end

local function QueuePendingPrompt()
    C_Timer.After(0.5, TryShowPendingPrompt)
end

local function CheckRestAreaEntered()
    local isResting = IsInRestArea()
    local hasRestStateSinceLogin = wasResting ~= nil
    local enteredRestArea = hasRestStateSinceLogin and isResting and not wasResting

    wasResting = isResting

    if not enteredRestArea then
        return
    end

    if switchReminderClass then
        local message = string.format(SWITCH_TEXT_FORMAT, switchReminderClass)

        switchReminderClass = nil

        if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
            RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
        end

        Print(message)
        return
    end

    if RandomClassOracleCharDB.pendingReason then
        TryShowPendingPrompt()
        return
    end

    if not IsTriggerEnabled("restArea") or IsCooldownActive() or UnitLevel("player") < MIN_TRIGGER_LEVEL then
        return
    end

    if SetPending("restArea") then
        QueuePendingPrompt()
    end
end

local function QueueRestAreaCheck()
    C_Timer.After(0.5, CheckRestAreaEntered)
end

local function CheckRestedXPDepleted()
    local exhaustion = GetXPExhaustion()
    local hadRestedXP = lastXPExhaustion ~= nil and lastXPExhaustion > 0

    lastXPExhaustion = exhaustion

    if not hadRestedXP or (exhaustion and exhaustion > 0) then
        return
    end

    if not IsTriggerEnabled("rested") or IsCooldownActive() or RandomClassOracleCharDB.pendingReason or UnitLevel("player") < MIN_TRIGGER_LEVEL then
        return
    end

    if SetPending("rested") then
        QueuePendingPrompt()
    end
end

local events = CreateFrame("Frame")

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_UPDATE_RESTING")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_INDOORS")
events:RegisterEvent("UPDATE_EXHAUSTION")
events:RegisterEvent("PLAYER_XP_UPDATE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_UNGHOST")

events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...

        if addonName ~= ADDON_NAME then
            return
        end

        RandomClassOracleDB = RandomClassOracleDB or {}
        CopyDefaults(RandomClassOracleDB, DEFAULT_DB)

        RandomClassOracleCharDB = RandomClassOracleCharDB or {}
        CopyDefaults(RandomClassOracleCharDB, DEFAULT_CHAR_DB)
        RandomClassOracleCharDB.pendingSnoozed = nil

        for _, key in ipairs(LEGACY_ACCOUNT_KEYS) do
            RandomClassOracleDB[key] = nil
        end

        EnsureEnabledClasses()
        ns.RegisterOptions()
        ns.CreateMinimapButton()
        return
    end

    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        local level = newLevel or UnitLevel("player")

        if not IsTriggerEnabled("level") or level <= MIN_TRIGGER_LEVEL then
            return
        end

        local waitsForRestArea = IsTriggerEnabled("levelWaitForRest")
        local reason = waitsForRestArea and "levelRest" or "level"

        if (waitsForRestArea or not IsCooldownActive()) and SetPending(reason) then
            RandomClassOracleCharDB.pendingLevel = level
            QueuePendingPrompt()
        end

        return
    end

    if event == "PLAYER_DEAD" then
        if IsTriggerEnabled("death") then
            SetPending("death")
        end

        return
    end

    if event == "UPDATE_EXHAUSTION" or event == "PLAYER_XP_UPDATE" then
        CheckRestedXPDepleted()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        QueuePendingPrompt()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin = ...

        if isInitialLogin or not RandomClassOracleCharDB.cooldownStart then
            RestartCooldown()
        end

        if isInitialLogin and RandomClassOracleCharDB.pendingReason == "levelRest" then
            ClearPendingState()
        end

        lastXPExhaustion = GetXPExhaustion()
        QueuePendingPrompt()
    end

    if event == "PLAYER_UPDATE_RESTING"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
    then
        QueueRestAreaCheck()
    end
end)

ns.Print = Print
ns.PrintStatus = PrintStatus
ns.PrintLastResult = PrintLastResult
ns.IsTriggerEnabled = IsTriggerEnabled

function ns.SetTriggerEnabled(reason, enabled)
    RandomClassOracleDB.triggers[reason] = enabled == true
end

function ns.GetPromptCooldownMinutes()
    return RandomClassOracleDB.promptCooldownMinutes
end

function ns.SetPromptCooldownMinutes(minutes)
    RandomClassOracleDB.promptCooldownMinutes = math.max(0, math.floor(tonumber(minutes) or 0))
end

function ns.GetLastRollClass()
    return lastRollClass
end

function ns.Roll()
    local pickedClass, isSameClass = ShowResult(false, true)

    if pickedClass then
        ClearPendingState()
        RestartCooldown()

        if not isSameClass then
            hasRolledThisSession = true
        end
    end
end

function ns.ShowResultWindow()
    CreateDiceFrame()
    diceFrame:Show()
end

function ns.SetSoundEnabled(enabled, silent)
    RandomClassOracleDB.soundEnabled = enabled == true

    if not silent then
        Print("Sound enabled: " .. tostring(RandomClassOracleDB.soundEnabled))
    end
end

function ns.SetHardcore(enabled, silent)
    RandomClassOracleDB.hardcore = enabled == true

    if not silent then
        Print("Hardcore: " .. tostring(RandomClassOracleDB.hardcore))
    end
end

function ns.ResetPending()
    RandomClassOracleCharDB.pendingLevelUp = false
    RandomClassOracleCharDB.pendingReason = nil
    RandomClassOracleCharDB.pendingLevel = nil
    Print("Pending roll reset.")
end

SLASH_RANDOMCLASSDICE1 = "/rcd"
SLASH_RANDOMCLASSDICE2 = "/randomclassdice"

SlashCmdList["RANDOMCLASSDICE"] = function(message)
    message = string.lower(strtrim(message or ""))

    if message == "roll" then
        ns.Roll()
        return
    end

    if message == "result" then
        PrintLastResult()
        return
    end

    if message == "show" then
        ns.ShowResultWindow()
        return
    end

    if message == "options" then
        ns.OpenOptions()
        return
    end

    if message == "minimap" then
        ns.SetMinimapShown(RandomClassOracleDB.minimap.hide)
        return
    end

    if message == "status" then
        PrintStatus()
        return
    end

    if message == "testding" then
        OpenRollPrompt("level", true)
        return
    end

    if message == "testdeath" then
        OpenRollPrompt("death", true)
        return
    end

    if message == "sound" then
        ns.SetSoundEnabled(not RandomClassOracleDB.soundEnabled)
        return
    end

    if message == "hardcore" then
        ns.SetHardcore(not RandomClassOracleDB.hardcore)
        return
    end

    if message == "reset" then
        ns.ResetPending()
        return
    end

    Print("Commands: /rcd roll, /rcd result, /rcd options, /rcd minimap, /rcd testding, /rcd testdeath, /rcd show, /rcd status, /rcd sound, /rcd hardcore, /rcd reset")
end
