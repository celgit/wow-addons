-- Random Character Journey Addon
-- Main addon file

local addonName, addon = ...

-- Initialize the addon
function addon:OnEnable()
    print("Random Character Journey addon loaded!")
    
    -- Create UI frame on enable
    addon:CreateJourneyFrame()
    
    -- Register slash commands
    SlashCmdList["RANDOM_CHARACTER_JOURNEY"] = function(msg)
        addon:HandleCommand(msg)
    end
    SLASH_RANDOM_CHARACTER_JOURNEY1 = "/journey"
    
    -- Register short command
    SlashCmdList["RANDOM_CHARACTER_JOURNEY_SHORT"] = function(msg)
        addon:HandleCommand(msg)
    end
    SLASH_RANDOM_CHARACTER_JOURNEY_SHORT1 = "/rcj"
end

-- Handle slash commands
function addon:HandleCommand(msg)
    if msg == "" then
        -- Show current journey and UI
        addon:ShowCurrentJourney()
        addon:ShowJourneyUI()
    elseif string.lower(msg) == "generate" then
        -- Generate a new journey
        addon:GenerateNewJourney()
        addon:RefreshJourneyUI()
    elseif string.lower(msg) == "next" then
        -- Move to the next chapter
        addon:MoveToNextChapter()
        addon:RefreshJourneyUI()
    elseif string.lower(msg) == "reroll" then
        -- Abandon current journey and create a new one
        addon:RerollJourney()
        addon:RefreshJourneyUI()
    elseif string.lower(msg) == "help" then
        -- Show help information
        print("=== Random Character Journey Help ===")
        print("/journey generate - Generate a new journey")
        print("/journey next - Move to the next chapter")
        print("/journey reroll - Start a new journey")
        print("/journey - Show current journey (also opens UI)")
        print("/rcj - Short command for /journey")
        print("")
        print("The addon creates unique randomized journeys for each character.")
        print("Each journey consists of chapters that take you through different zones.")
        print("The world stays the same, but your adventure changes!")
    else
        print("Unknown command. Use /journey help for available commands.")
    end
end

-- Show current journey information
function addon:ShowCurrentJourney()
    print("Random Character Journey - Current Journey Information")
    -- Implementation to show current journey
    addon:ShowCurrentJourney()
end

-- Generate a new journey for the character
function addon:GenerateNewJourney()
    print("Generating new journey...")
    -- Implementation for generating new journey
    addon:GenerateNewJourney()
end

-- Move to next chapter in journey
function addon:MoveToNextChapter()
    print("Moving to next chapter...")
    -- Implementation for moving to next chapter
    addon:MoveToNextChapter()
end

-- Reroll current journey
function addon:RerollJourney()
    print("Rerolling current journey...")
    -- Implementation for rerolling journey
    addon:RerollJourney()
end

-- Show the journey UI
function addon:ShowJourneyUI()
    addon:UpdateJourneyUI()
end

-- Update the frame when we need to refresh the UI
function addon:RefreshJourneyUI()
    if addon.journeyFrame and addon.journeyFrame:IsVisible() then
        addon:UpdateJourneyUI()
    end
end

-- Initialize the addon when enabled
addon:OnEnable()