local _, ns = ...

local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Dice_01"
local DEFAULT_ANGLE = 225

local button
local dropDownMenu

local function UpdatePosition()
    local angle = math.rad(RandomClassOracleDB.minimap.angle or DEFAULT_ANGLE)
    local radius = (Minimap:GetWidth() / 2) + 10

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate()
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()

    cursorX, cursorY = cursorX / scale, cursorY / scale
    RandomClassOracleDB.minimap.angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
    UpdatePosition()
end

local function GetMenuItems()
    return {
        { text = "Random Class Dice", isTitle = true },
        { text = "Roll", func = ns.Roll },
        { text = "Show result window", func = ns.ShowResultWindow },
        { text = "Print last result", func = ns.PrintLastResult },
        { text = "Print status", func = ns.PrintStatus },
        {
            text = "Sound",
            checked = function()
                return RandomClassOracleDB.soundEnabled == true
            end,
            func = function()
                ns.SetSoundEnabled(not RandomClassOracleDB.soundEnabled)
            end,
        },
        {
            text = "Hardcore",
            checked = function()
                return RandomClassOracleDB.hardcore == true
            end,
            func = function()
                ns.SetHardcore(not RandomClassOracleDB.hardcore)
            end,
        },
        { text = "Options", func = ns.OpenOptions },
        { text = "Reset pending roll", func = ns.ResetPending },
        {
            text = "Hide minimap button",
            func = function()
                ns.SetMinimapShown(false)
            end,
        },
    }
end

local function OpenModernMenu(owner, items)
    MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
        for _, item in ipairs(items) do
            if item.isTitle then
                rootDescription:CreateTitle(item.text)
            elseif item.checked then
                rootDescription:CreateCheckbox(item.text, item.checked, item.func)
            else
                rootDescription:CreateButton(item.text, item.func)
            end
        end
    end)
end

local function OpenDropDownMenu(items)
    if not dropDownMenu then
        dropDownMenu = CreateFrame("Frame", "RandomClassDiceMinimapMenu", UIParent, "UIDropDownMenuTemplate")
    end

    UIDropDownMenu_Initialize(dropDownMenu, function(_, level)
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()

            info.text = item.text
            info.isTitle = item.isTitle
            info.notCheckable = item.checked == nil
            info.func = item.func

            if item.checked then
                info.checked = item.checked()
                info.isNotRadio = true
            end

            UIDropDownMenu_AddButton(info, level)
        end
    end, "MENU")

    ToggleDropDownMenu(1, nil, dropDownMenu, "cursor", 0, 0)
end

local function OpenMenu(owner)
    local items = GetMenuItems()

    if MenuUtil and MenuUtil.CreateContextMenu then
        OpenModernMenu(owner, items)
    else
        OpenDropDownMenu(items)
    end
end

local function ShowTooltip(self)
    local lastRollClass = ns.GetLastRollClass()

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Random Class Dice")

    if lastRollClass then
        GameTooltip:AddLine("Last roll: |cffffffff" .. lastRollClass .. "|r")
    else
        GameTooltip:AddLine("No roll yet this session.", 0.7, 0.7, 0.7)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: show result window", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: menu", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: move button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

function ns.CreateMinimapButton()
    button = CreateFrame("Button", "RandomClassDiceMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture(ICON_TEXTURE)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    icon:SetPoint("TOPLEFT", 7, -6)

    button:SetScript("OnClick", function(self, mouseButton)
        GameTooltip:Hide()

        if mouseButton == "RightButton" then
            OpenMenu(self)
        else
            ns.ShowResultWindow()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:LockHighlight()
        self:SetScript("OnUpdate", OnDragUpdate)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdatePosition()

    if RandomClassOracleDB.minimap.hide then
        button:Hide()
    end
end

function ns.SetMinimapShown(shown, silent)
    RandomClassOracleDB.minimap.hide = not shown

    if button then
        button:SetShown(shown)
    end

    if silent then
        return
    end

    if shown then
        ns.Print("Minimap button shown.")
    else
        ns.Print("Minimap button hidden. Use /rcd minimap to show it again.")
    end
end
