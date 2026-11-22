-- Journey Generation Logic for Random Character Journey Addon

local addonName, addon = ...

-- Character journey data structure
addon.characterJourneys = {}

-- Generate a new journey for a character
function addon:GenerateNewJourney()
    local playerName = UnitName("player")
    local playerClass = select(2, UnitClass("player"))
    local playerLevel = UnitLevel("player")
    
    -- Get character info from saved variables or create new entry
    if not addon.characterJourneys[playerName] then
        addon.characterJourneys[playerName] = {
            name = playerName,
            class = playerClass,
            level = playerLevel,
            journeys = {}
        }
    end
    
    local characterData = addon.characterJourneys[playerName]
    
    -- Create new journey
    local newJourney = {
        name = self:GenerateJourneyName(playerClass),
        chapters = {}
    }
    
    -- Get starting zone based on class and level
    local startZone = self:GetStartingZone(playerClass, playerLevel)
    local chapter = {
        level_range = {startZone.level_range[1], startZone.level_range[2]},
        zone = startZone.name,
        chapter_number = 1
    }
    
    table.insert(newJourney.chapters, chapter)
    
    -- Add to journeys list
    table.insert(characterData.journeys, newJourney)
    
    -- Show the journey
    self:ShowJourney(newJourney)
end

-- Generate a journey name based on class
function addon:GenerateJourneyName(playerClass)
    local names = {
        ["Mage"] = {"The Unfortunate Scholar", "The Arcane Explorer", "The Forgotten Elementalist"},
        ["Warlock"] = {"The Shadowed Wanderer", "The Forbidden Seeker", "The Curious Conjurer"},
        ["Priest"] = {"The Holy Pilgrimage", "The Divine Sojourner", "The Sacred Traveler"},
        ["Druid"] = {"The Nature's Path", "The Wild Journey", "The Forest Wanderer"},
        ["Paladin"] = {"The Sacred Quest", "The Holy Pilgrimage", "The Righteous Journey"},
        ["Rogue"] = {"The Questionable Road", "The Hidden Path", "The Secret Way"},
        ["Hunter"] = {"The Wild Pursuit", "The Forest Chase", "The Nature's Call"},
        ["Shaman"] = {"The Elemental Path", "The Spirit Journey", "The Ancient Way"},
        ["Warrior"] = {"The Battle Born", "The Iron Path", "The Champion's Journey"}
    }
    
    local nameList = names[playerClass] or {"The Adventurer"}
    return self:GetRandomElement(nameList)
end

-- Get appropriate starting zone for character based on class and level
function addon:GetStartingZone(playerClass, playerLevel)
    -- Get all starting zones (level 1-10)
    local startingZones = {}
    for zoneName, zoneData in pairs(addon.zoneDatabase) do
        if zoneData.level_range[1] == 1 and zoneData.level_range[2] == 10 then
            table.insert(startingZones, {name = zoneName, data = zoneData})
        end
    end
    
    -- For level 1-10 characters, select based on class preferences
    if playerLevel >= 1 and playerLevel <= 10 then
        -- Return a random starting zone
        return self:GetRandomElement(startingZones)
    elseif playerLevel > 10 then
        -- Return any zone appropriate for the character's level
        local validZones = {}
        for _, zoneData in pairs(addon.zoneDatabase) do
            if self:IsZoneAppropriateForLevel(zoneData.name, playerLevel) then
                table.insert(validZones, {name = zoneData.name, data = zoneData})
            end
        end
        return self:GetRandomElement(validZones)
    end
    
    -- Fallback to default
    return self:GetRandomElement(startingZones)
end

-- Move to the next chapter in a journey 
function addon:MoveToNextChapter()
    local playerName = UnitName("player")
    
    if not addon.characterJourneys[playerName] or #addon.characterJourneys[playerName].journeys == 0 then
        print("You don't have any journey yet. Use /journey generate to create one.")
        return
    end
    
    -- Get the current journey
    local characterData = addon.characterJourneys[playerName]
    local currentJourney = characterData.journeys[#characterData.journeys]
    
    if not currentJourney or #currentJourney.chapters == 0 then
        print("No chapters to advance to. Use /journey generate to create one.")
        return
    end
    
    -- Get the last chapter to determine where to go next
    local lastChapter = currentJourney.chapters[#currentJourney.chapters]
    local lastZone = lastChapter.zone
    
    -- Generate a new chapter based on the rules
    local newChapter = self:GenerateNextChapter(lastZone, characterData)
    
    if newChapter then
        table.insert(currentJourney.chapters, newChapter)
        print("New chapter added to your journey!")
        self:ShowChapter(newChapter)
    else
        print("Could not generate next chapter. Try /journey reroll to start over.")
    end
end

-- Generate next chapter based on previous zone and character data
function addon:GenerateNextChapter(prevZone, characterData)
    -- Get all zones that are appropriate for this character's level (within 5 levels of current chapter)
    local playerLevel = UnitLevel("player")
    local currentLevel = playerLevel
    
    local validZones = {}
    
    for zoneName, zoneData in pairs(addon.zoneDatabase) do
        if self:IsZoneAppropriateForLevel(zoneName, currentLevel) then
            -- Don't repeat the same zone unless it's a new journey
            table.insert(validZones, {name = zoneName, data = zoneData})
        end
    end
    
    -- Remove zones that were already in this journey
    local uniqueZones = {}
    for _, zoneData in ipairs(validZones) do
        local isAlreadyInJourney = false
        for _, chapter in ipairs(characterData.journeys[#characterData.journeys].chapters) do
            if chapter.zone == zoneData.name then
                isAlreadyInJourney = true
                break
            end
        end
        
        if not isAlreadyInJourney then
            table.insert(uniqueZones, zoneData)
        end
    end
    
    -- If no zones available, try a wider range
    if #uniqueZones == 0 then
        for _, zoneData in ipairs(validZones) do
            table.insert(uniqueZones, zoneData)
        end
    end
    
    -- Check if the previous zone's thematic connections are valid
    local prevZoneObj = addon.zoneDatabase[prevZone]
    if not prevZoneObj then return nil end
    
    -- Add thematic connections to valid zones
    local thematicConnections = self:GetThematicConnections(prevZone)
    
    -- Find valid zones connected by theme or physical location
    local connectedZones = {}
    for _, zoneData in ipairs(uniqueZones) do
        -- Check if this zone connects physically or thematically to previous zone
        local physConnections = self:GetPhysicalConnections(prevZone)
        local isPhysConnected = false
        for _, connection in ipairs(physConnections) do
            if connection == zoneData.name then
                isPhysConnected = true
                break
            end
        end
        
        local isThematicConnected = false
        for _, theme in ipairs(thematicConnections) do
            if theme == zoneData.name then
                isThematicConnected = true
                break
            end
        end
        
        -- Weight these connections appropriately
        if isPhysConnected or isThematicConnected then
            table.insert(connectedZones, {zone = zoneData, priority = 2}) -- High priority
        else
            table.insert(connectedZones, {zone = zoneData, priority = 1}) -- Normal priority
        end
    end
    
    -- Select from connected zones with weights
    local availableZones = {}
    for _, data in ipairs(connectedZones) do
        local zone = data.zone
        local priority = data.priority
        
        -- Add multiple instances based on priority for weighting
        for i = 1, priority do
            table.insert(availableZones, zone)
        end
    end
    
    -- Return the first one or a random one
    if #availableZones > 0 then
        local selectedZone = self:GetRandomElement(availableZones)
        return {
            level_range = {selectedZone.data.level_range[1], selectedZone.data.level_range[2]},
            zone = selectedZone.name,
            chapter_number = #characterData.journeys[#characterData.journeys].chapters + 1
        }
    else
        -- As a last resort, just pick a random valid zone  
        local randomZone = self:GetRandomElement(uniqueZones)
        if randomZone then
            return {
                level_range = {randomZone.data.level_range[1], randomZone.data.level_range[2]},
                zone = randomZone.name,
                chapter_number = #characterData.journeys[#characterData.journeys].chapters + 1
            }
        end
    end
    
    return nil
end

-- Reroll the current journey
function addon:RerollJourney()
    local playerName = UnitName("player")
    
    if not addon.characterJourneys[playerName] or #addon.characterJourneys[playerName].journeys == 0 then
        print("You don't have any journey yet. Use /journey generate to create one.")
        return
    end
    
    -- Remove the current journey and generate a new one
    table.remove(addon.characterJourneys[playerName].journeys)
    
    -- Generate a fresh journey for this character
    self:GenerateNewJourney()
end

-- Show a specific journey
function addon:ShowJourney(journey)
    print("=== " .. journey.name .. " ===")
    print("Journey for " .. UnitName("player"))
    print("")
    
    for i, chapter in ipairs(journey.chapters) do
        print("Chapter " .. i .. ":")
        print("  Zone: " .. chapter.zone)
        print("  Level Range: " .. chapter.level_range[1] .. "-" .. chapter.level_range[2])
        print("")
    end
end

-- Show a specific chapter  
function addon:ShowChapter(chapter)
    print("=== Chapter " .. chapter.chapter_number .. " ===")
    print("Your journey takes you to " .. chapter.zone)
    print("Level Range: " .. chapter.level_range[1] .. "-" .. chapter.level_range[2])
end

-- Show current journey information
function addon:ShowCurrentJourney()
    local playerName = UnitName("player")
    
    if not addon.characterJourneys[playerName] or #addon.characterJourneys[playerName].journeys == 0 then
        print("You haven't started any journey yet. Use /journey generate to create one.")
        return
    end
    
    local currentJourney = addon.characterJourneys[playerName].journeys[#addon.characterJourneys[playerName].journeys]
    self:ShowJourney(currentJourney)
end

-- Initialize random seed
math.randomseed(os.time())