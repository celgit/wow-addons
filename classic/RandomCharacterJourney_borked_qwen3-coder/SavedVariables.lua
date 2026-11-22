-- Saved Variables Handler for Random Character Journey Addon

local addonName, addon = ...

-- Initialize saved variables
function addon:InitSavedVariables()
    if not RandomCharacterJourneyDB then
        RandomCharacterJourneyDB = {}
    end
    
    if not RandomCharacterJourneyDB.journeys then
        RandomCharacterJourneyDB.journeys = {}
    end
    
    -- Copy saved data to in-memory data structure
    addon.characterJourneys = RandomCharacterJourneyDB.journeys or {}
end

-- Save journey data to saved variables
function addon:SaveJourneyData()
    RandomCharacterJourneyDB.journeys = addon.characterJourneys
end

-- Load journey data from saved variables
function addon:LoadJourneyData()
    addon:InitSavedVariables()
end

-- Initialize on enable
function addon:OnEnable()
    print("Random Character Journey addon loaded!")
    
    -- Load saved data
    addon:LoadJourneyData()
    
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

-- Override journey generation to save after creating new journey
function addon:GenerateNewJourney()
    print("Generating new journey...")
    -- Generate the journey using parent method
    addon.GenerateNewJourney = addon.GenerateNewJourney_orig or addon.GenerateNewJourney
    addon:GenerateNewJourney_orig()
    
    -- Save to persistent storage
    addon:SaveJourneyData()
end

-- Override next chapter to save after advancing
function addon:MoveToNextChapter()
    print("Moving to next chapter...")
    -- Advance the journey using parent method  
    addon.MoveToNextChapter = addon.MoveToNextChapter_orig or addon.MoveToNextChapter
    addon:MoveToNextChapter_orig()
    
    -- Save to persistent storage
    addon:SaveJourneyData()
end

-- Override reroll to save after creating new journey
function addon:RerollJourney()
    print("Rerolling current journey...")
    -- Reroll the journey using parent method
    addon.RerollJourney = addon.RerollJourney_orig or addon.RerollJourney
    addon:RerollJourney_orig()
    
    -- Save to persistent storage
    addon:SaveJourneyData()
end

-- Initialize saved variables when the addon loads
addon:InitSavedVariables()