-- UI Component for Random Character Journey Addon

local addonName, addon = ...

-- Create the journey info frame
function addon:CreateJourneyFrame()
    -- Create the main frame
    local frame = CreateFrame("Frame", "RandomCharacterJourneyFrame", UIParent)
    frame:SetWidth(300)
    frame:SetHeight(200)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create the title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetText("Random Character Journey")
    title:SetJustifyH("CENTER")
    
    -- Create scrollable text area for journey info
    local scrollFrame = CreateFrame("ScrollFrame", "RandomCharacterJourneyScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
    scrollFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollFrame:SetBackdropColor(0, 0, 0, 0.5)
    
    -- Create the text frame
    local textFrame = CreateFrame("ScrollingMessageFrame", "RandomCharacterJourneyTextFrame", scrollFrame)
    textFrame:SetAllPoints(scrollFrame)
    textFrame:SetFontObject(ChatFontNormal)
    textFrame:SetMaxLines(15)
    textFrame:SetJustifyH("LEFT")
    
    -- Set the scroll frame's child
    scrollFrame:SetScrollChild(textFrame)
    
    -- Add a close button
    local closeButton = CreateFrame("Button", "RandomCharacterJourneyCloseButton", frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Store reference to frame
    addon.journeyFrame = frame
    addon.journeyTextFrame = textFrame
    
    -- Hide by default
    frame:Hide()
    
    return frame
end

-- Update the UI with current journey information
function addon:UpdateJourneyUI()
    if not addon.journeyFrame or not addon.journeyTextFrame then
        addon:CreateJourneyFrame()
    end
    
    local playerName = UnitName("player")
    
    if not addon.characterJourneys[playerName] or #addon.characterJourneys[playerName].journeys == 0 then
        addon.journeyTextFrame:AddMessage("No journey generated yet. Use /journey generate to start.")
        return
    end
    
    local currentJourney = addon.characterJourneys[playerName].journeys[#addon.characterJourneys[playerName].journeys]
    local currentChapter = currentJourney.chapters[#currentJourney.chapters]
    
    -- Clear existing text
    addon.journeyTextFrame:Clear()
    
    -- Add journey title and character info
    addon.journeyTextFrame:AddMessage("=== " .. currentJourney.name .. " ===")
    addon.journeyTextFrame:AddMessage("Character: " .. playerName)
    addon.journeyTextFrame:AddMessage("Class: " .. addon.characterJourneys[playerName].class)
    addon.journeyTextFrame:AddMessage("")
    
    -- Current chapter information
    if currentChapter then
        addon.journeyTextFrame:AddMessage("Current Chapter:")
        addon.journeyTextFrame:AddMessage("  Zone: " .. currentChapter.zone)
        addon.journeyTextFrame:AddMessage("  Level Range: " .. currentChapter.level_range[1] .. "-" .. currentChapter.level_range[2])
        addon.journeyTextFrame:AddMessage("")
    end
    
    -- Next chapter info (if available)
    addon.journeyTextFrame:AddMessage("Next Destination:")
    
    -- Try to find next chapter
    if #currentJourney.chapters >= 1 then
        -- We'll simulate what the next zone might be based on theme/physical connections,
        -- but in a real implementation we'd use the actual journey generation logic
        
        -- For now, we'll get a random valid zone that hasn't been used yet  
        local validZones = {}
        local playerLevel = UnitLevel("player")
        
        for zoneName, zoneData in pairs(addon.zoneDatabase) do
            if addon:IsZoneAppropriateForLevel(zoneName, playerLevel) then
                -- Check if this zone is already in the chapters
                local isInJourney = false
                for _, chapter in ipairs(currentJourney.chapters) do
                    if chapter.zone == zoneName then
                        isInJourney = true
                        break
                    end
                end
                
                if not isInJourney then
                    table.insert(validZones, {name = zoneName, data = zoneData})
                end
            end
        end
        
        if #validZones > 0 then
            local nextZone = addon:GetRandomElement(validZones)
            addon.journeyTextFrame:AddMessage("  " .. nextZone.name)
        else
            -- If we've exhausted all zones, provide a generic message  
            addon.journeyTextFrame:AddMessage("  Your journey continues...")
        end
    else
        addon.journeyTextFrame:AddMessage("  No next chapter yet")
    end
    
    addon.journeyTextFrame:AddMessage("")
    
    -- Journey summary
    addon.journeyTextFrame:AddMessage("Journey History:")
    for i, chapter in ipairs(currentJourney.chapters) do
        addon.journeyTextFrame:AddMessage("  " .. chapter.chapter_number .. ". " .. chapter.zone)
    end
    
    -- Show the frame
    addon.journeyFrame:Show()
end

-- Show the journey UI
function addon:ShowJourneyUI()
    if not addon.journeyFrame then
        addon:CreateJourneyFrame()
    end
    addon:UpdateJourneyUI()
end

-- Initialize the UI when the addon loads
function addon:OnEnable()
    print("Random Character Journey addon loaded!")
    
    -- Create UI frame on enable
    addon:CreateJourneyFrame()
    
    -- Register slash commands
    SlashCmdList["RANDOM_CHARACTER_JOURNEY"] = function(msg)
        addon:HandleCommand(msg)
    end
    SLASH_RANDOM_CHARACTER_JOURNEY1 = "/journey"
end

-- Update the frame when we need to refresh the UI
function addon:RefreshJourneyUI()
    if addon.journeyFrame and addon.journeyFrame:IsVisible() then
        addon:UpdateJourneyUI()
    end
end

-- Initialize the addon when enabled
addon:OnEnable()