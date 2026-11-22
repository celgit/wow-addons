local _, ns = ...

local ADDON_TITLE = "Random Class Dice"

local mainPanel
local classesPanel
local mainCategory
local generalCheckboxes = {}
local triggerCheckboxes = {}
local classCheckboxes = {}

local cooldownBox

local TRIGGERS = {
    { reason = "level", label = "Level up" },
    { reason = "levelWaitForRest", label = "Wait until I'm in a rested area", requires = "level" },
    { reason = "rested", label = "Rested XP runs out" },
    { reason = "restArea", label = "Entering a rested area" },
    { reason = "death", label = "Death" },
}

local function CreateCheckbox(parent, label, offsetY, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(26, 26)
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, offsetY)
    checkbox.label = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    checkbox.label:SetText(label)
    checkbox:SetScript("OnClick", function(self)
        onClick(self:GetChecked() == true)
    end)

    return checkbox
end

local function CreateHeader(panel, title, description)
    local titleText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 16, -16)
    titleText:SetText(title)

    local descriptionText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    descriptionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
    descriptionText:SetText(description)
end

local function RefreshMainPanel()
    generalCheckboxes.sound:SetChecked(RandomClassOracleDB.soundEnabled == true)
    generalCheckboxes.hardcore:SetChecked(RandomClassOracleDB.hardcore == true)
    generalCheckboxes.minimap:SetChecked(not RandomClassOracleDB.minimap.hide)

    for _, checkbox in ipairs(triggerCheckboxes) do
        local isAvailable = not checkbox.requires or ns.IsTriggerEnabled(checkbox.requires)

        checkbox:SetChecked(ns.IsTriggerEnabled(checkbox.reason))
        checkbox:SetEnabled(isAvailable)
        checkbox.label:SetFontObject(isAvailable and "GameFontHighlight" or "GameFontDisable")
    end

    cooldownBox:SetText(tostring(ns.GetPromptCooldownMinutes()))
end

local function RefreshClassesPanel()
    for _, checkbox in ipairs(classCheckboxes) do
        checkbox:SetChecked(ns.IsClassEnabled(checkbox.classToken))
    end
end

local function CreateMainPanel()
    mainPanel = CreateFrame("Frame", "RandomClassDiceOptionsPanel")
    mainPanel.name = ADDON_TITLE

    CreateHeader(mainPanel, ADDON_TITLE, "Rolls your next class when you level up, run out of rested XP, die or enter a rested area.")

    generalCheckboxes.sound = CreateCheckbox(mainPanel, "Play sound on roll", -64, function(checked)
        ns.SetSoundEnabled(checked, true)
    end)

    generalCheckboxes.hardcore = CreateCheckbox(mainPanel, "Hardcore (no inn reminder on death)", -92, function(checked)
        ns.SetHardcore(checked, true)
    end)

    generalCheckboxes.minimap = CreateCheckbox(mainPanel, "Show minimap button", -120, function(checked)
        ns.SetMinimapShown(checked, true)
    end)

    local triggersTitle = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    triggersTitle:SetPoint("TOPLEFT", 16, -164)
    triggersTitle:SetText("Show the roll prompt when:")

    for index, trigger in ipairs(TRIGGERS) do
        local offsetY = -184 - ((index - 1) * 28)
        local checkbox = CreateCheckbox(mainPanel, trigger.label, offsetY, function(checked)
            ns.SetTriggerEnabled(trigger.reason, checked)
            RefreshMainPanel()
        end)

        if trigger.requires then
            checkbox:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 40, offsetY)
        end

        checkbox.reason = trigger.reason
        checkbox.requires = trigger.requires
        table.insert(triggerCheckboxes, checkbox)
    end

    local cooldownOffsetY = -184 - (#TRIGGERS * 28) - 16

    local cooldownLabel = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cooldownLabel:SetPoint("TOPLEFT", 20, cooldownOffsetY)
    cooldownLabel:SetText("Minutes between prompts (0 = no limit):")

    cooldownBox = CreateFrame("EditBox", nil, mainPanel, "InputBoxTemplate")
    cooldownBox:SetSize(40, 20)
    cooldownBox:SetPoint("LEFT", cooldownLabel, "RIGHT", 12, 0)
    cooldownBox:SetAutoFocus(false)
    cooldownBox:SetNumeric(true)
    cooldownBox:SetMaxLetters(3)
    cooldownBox:SetScript("OnEnterPressed", cooldownBox.ClearFocus)
    cooldownBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(ns.GetPromptCooldownMinutes()))
        self:ClearFocus()
    end)
    cooldownBox:SetScript("OnEditFocusLost", function(self)
        ns.SetPromptCooldownMinutes(self:GetText())
        self:SetText(tostring(ns.GetPromptCooldownMinutes()))
    end)

    local cooldownNote = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    cooldownNote:SetPoint("TOPLEFT", cooldownLabel, "BOTTOMLEFT", 0, -8)
    cooldownNote:SetText("Counts from login and from your last answer to a prompt. Deaths always prompt.")

    mainPanel:SetScript("OnShow", RefreshMainPanel)
end

local function CreateClassesPanel()
    classesPanel = CreateFrame("Frame", "RandomClassDiceClassesPanel")
    classesPanel.name = "Classes"
    classesPanel.parent = ADDON_TITLE

    CreateHeader(classesPanel, "Classes", "Classes included in rolls.")

    for index, classInfo in ipairs(ns.GetClassPool()) do
        local checkbox = CreateCheckbox(classesPanel, classInfo.name, -64 - ((index - 1) * 28), function(checked)
            ns.SetClassEnabled(classInfo.token, checked)
        end)

        checkbox.classToken = classInfo.token
        table.insert(classCheckboxes, checkbox)
    end

    local enableAllButton = CreateFrame("Button", nil, classesPanel, "UIPanelButtonTemplate")
    enableAllButton:SetSize(120, 24)
    enableAllButton:SetPoint("TOPLEFT", 16, -64 - (#classCheckboxes * 28) - 12)
    enableAllButton:SetText("Enable All")
    enableAllButton:SetScript("OnClick", function()
        ns.EnableAllClasses()
        RefreshClassesPanel()
    end)

    classesPanel:SetScript("OnShow", RefreshClassesPanel)
end

function ns.RegisterOptions()
    CreateMainPanel()
    CreateClassesPanel()

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        mainCategory = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)
        Settings.RegisterAddOnCategory(mainCategory)
        Settings.RegisterCanvasLayoutSubcategory(mainCategory, classesPanel, classesPanel.name)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(mainPanel)
        InterfaceOptions_AddCategory(classesPanel)
    end
end

function ns.OpenOptions()
    if mainCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(mainCategory.GetID and mainCategory:GetID() or mainCategory.ID)
        return
    end

    if InterfaceOptionsFrame_OpenToCategory then
        -- Older clients do not always scroll to the addon on the first call.
        InterfaceOptionsFrame_OpenToCategory(mainPanel)
        InterfaceOptionsFrame_OpenToCategory(mainPanel)
    end
end
