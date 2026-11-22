-- Zone Database for Random Character Journey Addon

local addonName, addon = ...

-- Zone database with all zones and their properties
addon.zoneDatabase = {
    -- Starting Zones
    ["Elwynn Forest"] = {
        level_range = {1, 10},
        themes = {"human", "civilization", "beginner"},
        physical_connections = {"Westfall", "Redridge Mountains"},
        thematic_connections = {}
    },
    ["Dun Morogh"] = {
        level_range = {1, 10},
        themes = {"dwarven", "mountains", "mining"},
        physical_connections = {"Loch Modan"},
        thematic_connections = {}
    },
    ["Teldrassil"] = {
        level_range = {1, 10},
        themes = {"nature", "ancient", "night elf"},
        physical_connections = {"Darkshore"},
        thematic_connections = {}
    },
    
    -- Level 10-20 Zones
    ["Westfall"] = {
        level_range = {10, 20},
        themes = {"human", "rebellion", "criminals"},
        physical_connections = {"Elwynn Forest", "Redridge Mountains", "Duskwood"},
        thematic_connections = {}
    },
    ["Loch Modan"] = {
        level_range = {10, 20},
        themes = {"dwarven", "ruins", "exploration"},
        physical_connections = {"Dun Morogh", "Wetlands"},
        thematic_connections = {}
    },
    ["Darkshore"] = {
        level_range = {10, 20},
        themes = {"nature", "ancient", "ruins"},
        physical_connections = {"Teldrassil", "Ashenvale"},
        thematic_connections = {}
    },
    ["Redridge Mountains"] = {
        level_range = {15, 25},
        themes = {"human", "military", "conflict"},
        physical_connections = {"Elwynn Forest", "Westfall"},
        thematic_connections = {}
    },
    
    -- Level 20-30 Zones
    ["Duskwood"] = {
        level_range = {18, 30},
        themes = {"dark", "undead", "mystery"},
        physical_connections = {"Westfall", "Redridge Mountains"},
        thematic_connections = {}
    },
    ["Wetlands"] = {
        level_range = {20, 30},
        themes = {"dwarven", "exploration", "dragons"},
        physical_connections = {"Loch Modan", "Arathi Highlands"},
        thematic_connections = {}
    },
    ["Ashenvale"] = {
        level_range = {18, 30},
        themes = {"nature", "ancient", "druid"},
        physical_connections = {"Darkshore", "Stonetalon Mountains"},
        thematic_connections = {}
    },
    ["Hillsbrad Foothills"] = {
        level_range = {20, 30},
        themes = {"human", "conflict", "war"},
        physical_connections = {"Arathi Highlands", "Alterac Mountains"},
        thematic_connections = {}
    },
    ["Stonetalon Mountains"] = {
        level_range = {20, 30},
        themes = {"wilderness", "exploration", "conflict"},
        physical_connections = {"Ashenvale", "Desolace"},
        thematic_connections = {}
    },
    
    -- Level 25-40 Zones
    ["Thousand Needles"] = {
        level_range = {25, 35},
        themes = {"wilderness", "travel", "exploration"},
        physical_connections = {"Stonetalon Mountains", "Tanaris"},
        thematic_connections = {}
    },
    ["Arathi Highlands"] = {
        level_range = {30, 40},
        themes = {"kingdoms", "war", "ancient humans"},
        physical_connections = {"Wetlands", "Hillsbrad"},
        thematic_connections = {}
    },
    ["Stranglethorn Vale"] = {
        level_range = {30, 45},
        themes = {"jungle", "pirates", "treasure", "exploration"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Desolace"] = {
        level_range = {30, 40},
        themes = {"wasteland", "forgotten places", "ancient"},
        physical_connections = {"Stonetalon Mountains"},
        thematic_connections = {}
    },
    ["Badlands"] = {
        level_range = {35, 45},
        themes = {"dwarven", "archaeology", "ruins"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Swamp of Sorrows"] = {
        level_range = {35, 45},
        themes = {"corruption", "swamp", "darkness"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Dustwallow Marsh"] = {
        level_range = {35, 45},
        themes = {"wilderness", "dragons", "mystery"},
        physical_connections = {},
        thematic_connections = {}
    },
    
    -- Level 40-60 Zones
    ["Feralas"] = {
        level_range = {40, 50},
        themes = {"nature", "ancient", "ruins"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Tanaris"] = {
        level_range = {40, 50},
        themes = {"desert", "archaeology", "exploration"},
        physical_connections = {"Thousand Needles"},
        thematic_connections = {}
    },
    ["The Hinterlands"] = {
        level_range = {40, 50},
        themes = {"trolls", "wilderness", "ancient"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Searing Gorge"] = {
        level_range = {45, 50},
        themes = {"fire", "dwarven", "industry"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Azshara"] = {
        level_range = {45, 55},
        themes = {"magic", "ancient", "ruins"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Felwood"] = {
        level_range = {48, 55},
        themes = {"corruption", "demons", "nature"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Un'Goro Crater"] = {
        level_range = {48, 55},
        themes = {"ancient", "dinosaurs", "exploration"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Western Plaguelands"] = {
        level_range = {50, 58},
        themes = {"undead", "war", "corruption"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Eastern Plaguelands"] = {
        level_range = {53, 60},
        themes = {"undead", "final battles", "endgame"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Winterspring"] = {
        level_range = {55, 60},
        themes = {"cold", "wilderness", "ancient"},
        physical_connections = {},
        thematic_connections = {}
    },
    ["Silithus"] = {
        level_range = {55, 60},
        themes = {"ancient", "desert", "endgame"},
        physical_connections = {},
        thematic_connections = {}
    }
}

-- Map of theme to connected zones for thematic connections
addon.themeToZones = {
    -- dark zones
    ["dark"] = {"Duskwood", "Western Plaguelands", "Deadwind Pass"},
    
    -- magic zones  
    ["magic"] = {"Azshara", "Alterac Mountains"},
    
    -- ancient zones
    ["ancient"] = {"Teldrassil", "Darkshore", "Duskwood", "Ashenvale", "Feralas", "Azshara", "Un'Goro Crater"},
    
    -- undead zones
    ["undead"] = {"Duskwood", "Western Plaguelands", "Eastern Plaguelands"},
    
    -- nature zones
    ["nature"] = {"Teldrassil", "Darkshore", "Ashenvale", "Feralas", "Felwood", "Winterspring"},
    
    -- dwarven zones
    ["dwarven"] = {"Dun Morogh", "Loch Modan", "Wetlands", "Badlands", "Searing Gorge"},
    
    -- human zones
    ["human"] = {"Elwynn Forest", "Westfall", "Hillsbrad Foothills"},
    
    -- war zones
    ["war"] = {"Redridge Mountains", "Hillsbrad Foothills", "Arathi Highlands", "Western Plaguelands"},
    
    -- ruins zones
    ["ruins"] = {"Darkshore", "Duskwood", "Azshara", "Ashenvale"},
    
    -- exploration zones
    ["exploration"] = {"Loch Modan", "Wetlands", "Stonetalon Mountains", "Thousand Needles", "Tanaris"},
    
    -- wilderness zones
    ["wilderness"] = {"Stonetalon Mountains", "Desolace", "Badlands", "Swamp of Sorrows", "Dustwallow Marsh", "Feralas", "The Hinterlands", "Winterspring"},
    
    -- corruption zones
    ["corruption"] = {"Swamp of Sorrows", "Felwood", "Western Plaguelands"},
    
    -- beginner zones
    ["beginner"] = {"Elwynn Forest", "Dun Morogh", "Teldrassil"},
}

-- Function to get the theme connections for a zone
function addon:GetThematicConnections(zoneName)
    local zoneData = addon.zoneDatabase[zoneName]
    if not zoneData then return {} end
    
    local connections = {}
    
    -- Add zones that match each of this zone's themes
    for _, theme in ipairs(zoneData.themes) do
        if addon.themeToZones[theme] then
            for _, connectedZone in ipairs(addon.themeToZones[theme]) do
                if connectedZone ~= zoneName then
                    table.insert(connections, connectedZone)
                end
            end
        end
    end
    
    -- Remove duplicates 
    local uniqueConnections = {}
    for _, zone in ipairs(connections) do
        if not uniqueConnections[zone] then
            uniqueConnections[zone] = true
        end
    end
    
    local result = {}
    for zone, _ in pairs(uniqueConnections) do
        table.insert(result, zone)
    end
    
    return result
end

-- Helper function to get a random element from an array
function addon:GetRandomElement(array)
    if not array or #array == 0 then
        return nil
    end
    local index = math.random(1, #array)
    return array[index]
end

-- Function to check if a zone is appropriate for a character's level
function addon:IsZoneAppropriateForLevel(zoneName, characterLevel)
    local zoneData = addon.zoneDatabase[zoneName]
    if not zoneData then return false end
    
    local minLevel, maxLevel = unpack(zoneData.level_range)
    return characterLevel >= minLevel and characterLevel <= maxLevel
end

-- Function to get physical connections for a zone
function addon:GetPhysicalConnections(zoneName)
    local zoneData = addon.zoneDatabase[zoneName]
    if not zoneData then return {} end
    
    return zoneData.physical_connections or {}
end