local ADDON_NAME = ...

local DB_NAME = "RandomCharacterJourneyDB"
local CHAT_PREFIX = "|cffffd100Journey:|r "
local MAX_HISTORY = 12

local DEFAULT_DB = {
    characters = {},
}

local JOURNEY_TITLES = {
    "The Forgotten Road",
    "The Questionable Road",
    "The Unfortunate Scholar",
    "The Ashen Map",
    "The Long Detour",
    "The Broken Compass",
    "The Wandering Oath",
    "The Lantern Path",
    "The Old Rumor",
    "The Weathered Journal",
    "The Restless Pilgrim",
    "The Stranger's Trail",
}

local CLASS_THEME_WEIGHTS = {
    MAGE = { magic = 4, ancient = 2, ruins = 2, exploration = 1 },
    WARLOCK = { dark = 3, corruption = 3, demons = 3, ruins = 1 },
    PRIEST = { undead = 2, human = 2, ancient = 1, mystery = 1 },
    DRUID = { nature = 4, ancient = 2, wilderness = 2, corruption = 1 },
    PALADIN = { human = 2, war = 2, undead = 3, kingdoms = 1 },
    ROGUE = { criminals = 3, pirates = 2, treasure = 2, exploration = 1, ruins = 1 },
    HUNTER = { wilderness = 3, nature = 2, jungle = 2, exploration = 1 },
    SHAMAN = { ancient = 2, wilderness = 2, nature = 2, fire = 1 },
    WARRIOR = { war = 3, military = 2, conflict = 2, kingdoms = 1 },
}

local RACE_START_HINTS = {
    Human = "Elwynn Forest",
    Dwarf = "Dun Morogh",
    Gnome = "Dun Morogh",
    NightElf = "Teldrassil",
}

local ZONES = {
    { name = "Elwynn Forest", min = 1, max = 10, isStartingZone = true, themes = { "human", "civilization", "beginner" }, physical = { "Westfall", "Redridge Mountains" } },
    { name = "Dun Morogh", min = 1, max = 10, isStartingZone = true, themes = { "dwarven", "mountains", "mining", "beginner" }, physical = { "Loch Modan" } },
    { name = "Teldrassil", min = 1, max = 10, isStartingZone = true, themes = { "nature", "ancient", "night elf", "beginner" }, physical = { "Darkshore" } },

    { name = "Westfall", min = 10, max = 20, themes = { "human", "rebellion", "criminals" }, physical = { "Elwynn Forest", "Redridge Mountains", "Duskwood" } },
    { name = "Loch Modan", min = 10, max = 20, themes = { "dwarven", "ruins", "exploration" }, physical = { "Dun Morogh", "Wetlands" } },
    { name = "Darkshore", min = 10, max = 20, themes = { "nature", "ancient", "ruins" }, physical = { "Teldrassil", "Ashenvale" } },
    { name = "Redridge Mountains", min = 15, max = 25, themes = { "human", "military", "conflict" }, physical = { "Elwynn Forest", "Westfall", "Duskwood" } },

    { name = "Duskwood", min = 18, max = 30, themes = { "dark", "undead", "mystery", "human" }, physical = { "Westfall", "Redridge Mountains", "Deadwind Pass" } },
    { name = "Wetlands", min = 20, max = 30, themes = { "dwarven", "exploration", "dragons" }, physical = { "Loch Modan", "Arathi Highlands" } },
    { name = "Ashenvale", min = 18, max = 30, themes = { "nature", "ancient", "druid", "conflict" }, physical = { "Darkshore", "Stonetalon Mountains" } },
    { name = "Hillsbrad Foothills", min = 20, max = 30, themes = { "human", "conflict", "war" }, physical = { "Arathi Highlands", "Alterac Mountains" } },
    { name = "Stonetalon Mountains", min = 20, max = 30, themes = { "wilderness", "exploration", "conflict" }, physical = { "Ashenvale", "Desolace", "Thousand Needles" } },

    { name = "Thousand Needles", min = 25, max = 35, themes = { "wilderness", "travel", "exploration" }, physical = { "Stonetalon Mountains", "Tanaris" } },
    { name = "Arathi Highlands", min = 30, max = 40, themes = { "kingdoms", "war", "ancient humans" }, physical = { "Wetlands", "Hillsbrad Foothills" } },
    { name = "Alterac Mountains", min = 30, max = 40, themes = { "mountains", "magic", "ruins", "war" }, physical = { "Hillsbrad Foothills" } },
    { name = "Stranglethorn Vale", min = 30, max = 45, themes = { "jungle", "pirates", "treasure", "exploration" }, physical = { "Duskwood" } },
    { name = "Desolace", min = 30, max = 40, themes = { "wasteland", "forgotten places", "ancient" }, physical = { "Stonetalon Mountains", "Feralas" } },
    { name = "Badlands", min = 35, max = 45, themes = { "dwarven", "archaeology", "ruins" }, physical = { "Searing Gorge", "Loch Modan" } },
    { name = "Swamp of Sorrows", min = 35, max = 45, themes = { "corruption", "swamp", "darkness", "mystery" }, physical = { "Deadwind Pass", "Blasted Lands" } },
    { name = "Dustwallow Marsh", min = 35, max = 45, themes = { "wilderness", "dragons", "mystery" }, physical = { "Thousand Needles" } },

    { name = "Feralas", min = 40, max = 50, themes = { "nature", "ancient", "ruins", "wilderness" }, physical = { "Desolace", "Thousand Needles" } },
    { name = "Tanaris", min = 40, max = 50, themes = { "desert", "archaeology", "exploration" }, physical = { "Thousand Needles", "Un'Goro Crater" } },
    { name = "The Hinterlands", min = 40, max = 50, themes = { "trolls", "wilderness", "ancient" }, physical = { "Arathi Highlands", "Western Plaguelands" } },
    { name = "Searing Gorge", min = 45, max = 50, themes = { "fire", "dwarven", "industry" }, physical = { "Badlands", "Burning Steppes" } },
    { name = "Blasted Lands", min = 45, max = 55, themes = { "demons", "war", "wasteland" }, physical = { "Swamp of Sorrows", "Deadwind Pass" } },
    { name = "Azshara", min = 45, max = 55, themes = { "magic", "ancient", "ruins" }, physical = { "Ashenvale", "Felwood" } },
    { name = "Felwood", min = 48, max = 55, themes = { "corruption", "demons", "nature" }, physical = { "Ashenvale", "Winterspring", "Azshara" } },
    { name = "Un'Goro Crater", min = 48, max = 55, themes = { "ancient", "dinosaurs", "exploration" }, physical = { "Tanaris", "Silithus" } },
    { name = "Burning Steppes", min = 50, max = 58, themes = { "fire", "dragons", "war", "orcs" }, physical = { "Searing Gorge", "Redridge Mountains" } },
    { name = "Western Plaguelands", min = 50, max = 58, themes = { "undead", "war", "corruption" }, physical = { "The Hinterlands", "Eastern Plaguelands" } },
    { name = "Eastern Plaguelands", min = 53, max = 60, themes = { "undead", "final battles", "endgame" }, physical = { "Western Plaguelands" } },
    { name = "Winterspring", min = 55, max = 60, themes = { "cold", "wilderness", "ancient" }, physical = { "Felwood" } },
    { name = "Silithus", min = 55, max = 60, themes = { "ancient", "desert", "endgame" }, physical = { "Un'Goro Crater" } },
}

-- Practical Classic ranges, rather than the much lower portal entry requirements.
-- The recommendation shown in game adds two safety levels to both ends.
local DUNGEONS = {
    { name = "The Deadmines", min = 18, max = 23, location = "Westfall" },
    { name = "Shadowfang Keep", min = 22, max = 30, location = "Silverpine Forest", note = "long Alliance journey" },
    { name = "The Stockade", min = 22, max = 30, location = "Stormwind" },
    { name = "Blackfathom Deeps", min = 24, max = 32, location = "Ashenvale" },
    { name = "Gnomeregan", min = 29, max = 38, location = "Dun Morogh" },
    { name = "Scarlet Monastery: Graveyard", min = 28, max = 38, location = "Tirisfal Glades", note = "long Alliance journey" },
    { name = "Scarlet Monastery: Library", min = 29, max = 39, location = "Tirisfal Glades", note = "long Alliance journey" },
    { name = "Razorfen Kraul", min = 30, max = 40, location = "The Barrens", note = "long Alliance journey" },
    { name = "Scarlet Monastery: Armory", min = 32, max = 42, location = "Tirisfal Glades", note = "long Alliance journey" },
    { name = "Scarlet Monastery: Cathedral", min = 35, max = 45, location = "Tirisfal Glades", note = "long Alliance journey" },
    { name = "Razorfen Downs", min = 40, max = 50, location = "The Barrens", note = "long Alliance journey" },
    { name = "Uldaman", min = 42, max = 52, location = "Badlands" },
    { name = "Zul'Farrak", min = 44, max = 54, location = "Tanaris" },
    { name = "Maraudon", min = 46, max = 55, location = "Desolace" },
    { name = "Sunken Temple", min = 50, max = 60, location = "Swamp of Sorrows" },
    { name = "Blackrock Depths", min = 52, max = 60, location = "Blackrock Mountain" },
    { name = "Lower Blackrock Spire", min = 55, max = 60, location = "Blackrock Mountain" },
    { name = "Upper Blackrock Spire", min = 58, max = 60, location = "Blackrock Mountain" },
    { name = "Scholomance", min = 58, max = 60, location = "Western Plaguelands" },
    { name = "Stratholme", min = 58, max = 60, location = "Eastern Plaguelands" },
    { name = "Dire Maul", min = 58, max = 60, location = "Feralas" },
}

local ZONE_STORY_HOOKS = {
    ["Elwynn Forest"] = "trouble is gathering along the roads beneath Stormwind's walls",
    ["Dun Morogh"] = "troggs and old rivalries threaten the settlements below Ironforge",
    ["Teldrassil"] = "the young world tree still carries signs that nature is out of balance",
    ["Westfall"] = "hungry farms and the rise of the Defias reveal a kingdom neglecting its own people",
    ["Loch Modan"] = "excavations, troggs, and a threatened frontier leave work for a wandering adventurer",
    ["Darkshore"] = "the coast hides ancient ruins and a land wounded by corruption",
    ["Redridge Mountains"] = "Lakeshire is holding a fragile line against gnolls, orcs, and a growing war",
    ["Duskwood"] = "the Night Watch stands nearly alone against undead, worgen, and the darkness around Raven Hill",
    ["Wetlands"] = "the road north passes through flooded ruins, dragonkin, and a hard-pressed harbor",
    ["Ashenvale"] = "an ancient forest has become a battleground between nature and encroaching war",
    ["Hillsbrad Foothills"] = "Southshore lies on a frontier shaped by refugees, old loyalties, and open conflict",
    ["Stonetalon Mountains"] = "the mountain passes show the cost of war upon the wilds",
    ["Thousand Needles"] = "the long canyons promise a dangerous road into less familiar lands",
    ["Arathi Highlands"] = "the ruins of Stromgarde stand amid a struggle over fallen human kingdoms",
    ["Alterac Mountains"] = "Syndicate brigands and Crushridge ogres fight over the ruins of a betrayed kingdom",
    ["Stranglethorn Vale"] = "the road south opens onto rival expeditions, ancient trolls, and the lawless trade of Booty Bay",
    ["Desolace"] = "a scarred wilderness preserves ancient powers beneath its desolation",
    ["Badlands"] = "Titan ruins and Dark Iron designs lie scattered across a hostile frontier",
    ["Swamp of Sorrows"] = "lost travelers and old secrets vanish into a swamp steeped in corruption",
    ["Dustwallow Marsh"] = "Theramore's frontier disappears into a marsh of deserters, dragons, and half-buried secrets",
    ["Feralas"] = "primeval wilderness and Highborne ruins wait beyond the western road",
    ["Tanaris"] = "Gadgetzan draws explorers toward desert ruins and rumors buried in the sand",
    ["The Hinterlands"] = "wild highlands conceal troll strongholds and paths toward the plague-stricken north",
    ["Searing Gorge"] = "Dark Iron industry has turned the mountain road into a furnace",
    ["Blasted Lands"] = "the land before the Dark Portal still bears the wounds of demonic war",
    ["Azshara"] = "shattered Highborne ruins preserve dangerous traces of ancient magic",
    ["Felwood"] = "demonic corruption is consuming a forest that might still be saved",
    ["Un'Goro Crater"] = "an isolated crater holds creatures and mysteries from another age",
    ["Burning Steppes"] = "Blackrock's armies and dragons gather beneath a smoke-darkened sky",
    ["Western Plaguelands"] = "the first ruined farms of Lordaeron remain contested by the living and the Scourge",
    ["Eastern Plaguelands"] = "the war against the Scourge reaches the heart of ruined Lordaeron",
    ["Winterspring"] = "ancient secrets endure in a wilderness locked beneath snow",
    ["Silithus"] = "an old and alien threat is stirring beneath the desert",
}

local CLASS_STORY_INTROS = {
    MAGE = "The trail of old magic gives a mage reason to look closer.",
    WARLOCK = "Signs of forbidden power make this more than a rumor to a warlock.",
    PRIEST = "Where fear and suffering spread, a priest may still bring purpose.",
    DRUID = "A wound in the natural world gives a druid reason to answer.",
    PALADIN = "Duty to the Light turns this trouble into a personal summons.",
    ROGUE = "Loose secrets and unsettled debts make the road worth following.",
    HUNTER = "A dangerous frontier offers tracks that few others could follow.",
    SHAMAN = "The land itself carries signs that the elements are disturbed.",
    WARRIOR = "A growing conflict offers a warrior a cause worth testing.",
}

-- These are deliberate travel bridges, not claims that the two zones touch.
-- Each bridge must explain how the character gets from one chapter to the next.
local TRAVEL_TRANSITIONS = {
    {
        from = "Stranglethorn Vale",
        to = "Dustwallow Marsh",
        weight = 18,
        text = "In Booty Bay, passage east leads to Kalimdor. From Ratchet, the road turns south toward Dustwallow Marsh, where Theramore's frontier disappears into dragon-haunted wetlands.",
    },
    {
        from = "Stranglethorn Vale",
        to = "Tanaris",
        weight = 14,
        text = "A ship from Booty Bay carries your story to Kalimdor. Talk in Ratchet of Gadgetzan's expeditions gives the long road south a destination: Tanaris.",
    },
    {
        from = "Dustwallow Marsh",
        to = "Tanaris",
        weight = 18,
        text = "Caravans leaving Theramore carry word of work beyond the Thousand Needles. Following their trail brings the next chapter to the desert of Tanaris.",
    },
    {
        from = "Feralas",
        to = "Tanaris",
        weight = 16,
        text = "Beyond Feralas, the eastern road bends through the Thousand Needles. Rumors from Gadgetzan draw the journey onward into Tanaris.",
    },
    {
        from = "Alterac Mountains",
        to = "The Hinterlands",
        weight = 16,
        text = "Leaving Alterac by way of Hillsbrad and Arathi, reports of troll activity pull the journey east into the Hinterlands.",
    },
    {
        from = "Burning Steppes",
        to = "Western Plaguelands",
        weight = 12,
        text = "News carried through the Alliance roads speaks of a greater war in ruined Lordaeron. The journey turns north toward the first plague-stricken farms.",
    },
    {
        from = "Duskwood",
        to = "Hillsbrad Foothills",
        class = "PALADIN",
        storyFlag = "PALADIN_VERIGANS_FIST",
        weight = 100,
        text = "The road north is not entirely unfamiliar. The trial that earned Verigan's Fist once carried you through Southshore on the way to Shadowfang; returning there opens a new chapter on Hillsbrad's troubled frontier.",
    },
}

local TRANSITION_STORIES = {
    ["Duskwood>Stranglethorn Vale"] = "The trail out of Duskwood follows the southern road. Beyond the forest, the darkness gives way to another kind of danger among Stranglethorn's rival expeditions, trolls, and hidden ruins.",
    ["Hillsbrad Foothills>Alterac Mountains"] = "From Southshore, every report from the north returns to the same place: the ruins of Alterac, where Syndicate brigands and Crushridge ogres fight over a fallen kingdom.",
    ["Westfall>Duskwood"] = "The troubles of Westfall do not end at its eastern bridge. Refugees and uneasy travelers point toward Duskwood, where the Night Watch is losing ground against the darkness.",
    ["Redridge Mountains>Duskwood"] = "The road leaving Lakeshire runs toward a forest even the soldiers speak of carefully. In Duskwood, the Night Watch faces enemies no ordinary militia can contain.",
    ["Wetlands>Arathi Highlands"] = "The northern road out of the Wetlands reaches the broken realm of Stromgarde. In Arathi, old kingdoms and present armies are still fighting over the same ground.",
    ["Arathi Highlands>The Hinterlands"] = "Clues gathered among Arathi's ruined strongholds point east, toward troll powers gathering in the wild highlands beyond the mountains.",
    ["Tanaris>Un'Goro Crater"] = "Explorers in Gadgetzan speak of an isolated crater beyond the desert. Their strange specimens are reason enough to seek the hidden path into Un'Goro.",
    ["Western Plaguelands>Eastern Plaguelands"] = "Every victory in the western farms points deeper into ruined Lordaeron. The source of the war lies east, where the Scourge's hold is strongest.",
    ["Felwood>Winterspring"] = "A high pass escapes Felwood's corruption and climbs into Winterspring. Ancient powers endure there beneath the snow, untouched but not necessarily safe.",
    ["Un'Goro Crater>Silithus"] = "Findings in Un'Goro hint that the ancient world concealed more than one forgotten threat. Beyond the western ridge, something alien stirs beneath Silithus.",
    ["Swamp of Sorrows>Blasted Lands"] = "The southern road leaves the swamp for a land broken by an older invasion. The next answers lie before the Dark Portal in the Blasted Lands.",
    ["Searing Gorge>Burning Steppes"] = "The way through Blackrock Mountain does not end with the Dark Iron. Beyond it, dragons and Blackrock armies gather across the Burning Steppes.",
}

local zoneByName = {}
local frame
local titleText
local bodyText
local journeyScrollFrame
local journeyScrollChild
local RefreshJourneyFrame
local databaseInitialized = false

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

local function InitializeDatabase()
    if databaseInitialized then
        return
    end

    _G[DB_NAME] = _G[DB_NAME] or {}
    RandomCharacterJourneyDB = _G[DB_NAME]
    CopyDefaults(RandomCharacterJourneyDB, DEFAULT_DB)

    for _, zone in ipairs(ZONES) do
        zoneByName[zone.name] = zone
    end

    databaseInitialized = true
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. message)
end

local function Trim(value)
    return string.match(value or "", "^%s*(.-)%s*$")
end

local function Contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end

    return false
end

local function SharesTheme(left, right)
    for _, theme in ipairs(left.themes or {}) do
        if Contains(right.themes, theme) then
            return true
        end
    end

    return false
end

local function GetCharacterKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName and GetRealmName() or "UnknownRealm"
    return realm .. "-" .. name
end

local function GetCharacter()
    InitializeDatabase()

    local key = GetCharacterKey()
    local _, classToken = UnitClass("player")
    local raceName, raceToken = UnitRace("player")
    local faction = UnitFactionGroup("player")

    if not RandomCharacterJourneyDB.characters[key] then
        RandomCharacterJourneyDB.characters[key] = {
            key = key,
            name = UnitName("player"),
            realm = GetRealmName and GetRealmName() or nil,
            class = classToken,
            race = raceToken or raceName,
            faction = faction,
            activeJourney = nil,
            history = {},
            visitedZones = {},
        }
    end

    local character = RandomCharacterJourneyDB.characters[key]
    character.visitedZones = character.visitedZones or {}
    character.name = UnitName("player")
    character.class = classToken
    character.race = raceToken or raceName
    character.faction = faction
    character.level = UnitLevel("player")
    character.location = GetRealZoneText and GetRealZoneText() or GetZoneText()

    if character.location and zoneByName[character.location] then
        local visit = character.visitedZones[character.location]

        if type(visit) ~= "table" then
            visit = { firstSeen = time() }
            character.visitedZones[character.location] = visit
        end

        visit.lastSeen = time()
    end

    return character
end

local function GetRecommendedZoneRange(zone)
    if zone.isStartingZone then
        return zone.min, zone.max + 1
    end

    return zone.min + 2, math.min(60, zone.max + 3)
end

local function IsLevelAppropriate(zone, level)
    local recommendedMin, recommendedMax = GetRecommendedZoneRange(zone)
    return level >= recommendedMin and level <= recommendedMax
end

local function GetRecommendedDungeons(level)
    local recommendations = {}

    for _, dungeon in ipairs(DUNGEONS) do
        local recommendedMin = dungeon.min + 2
        local recommendedMax = math.min(60, dungeon.max + 2)

        if level >= recommendedMin and level <= recommendedMax then
            table.insert(recommendations, {
                name = dungeon.name,
                location = dungeon.location,
                note = dungeon.note,
                min = recommendedMin,
                max = recommendedMax,
            })
        end
    end

    return recommendations
end

local function GetChapterRecommendedRange(chapter)
    local zone = chapter and zoneByName[chapter.zone]

    if zone then
        return GetRecommendedZoneRange(zone)
    end

    return chapter and chapter.recommendedMin or chapter.min, chapter and chapter.recommendedMax or chapter.max
end

local function IsZoneUsedInJourney(journey, zoneName)
    if not journey then
        return false
    end

    for _, chapter in ipairs(journey.chapters or {}) do
        if chapter.zone == zoneName then
            return true
        end
    end

    return false
end

local function PathWouldRepeat(character, journey, candidateName)
    if not journey or not journey.chapters then
        return false
    end

    local path = {}
    for _, chapter in ipairs(journey.chapters) do
        table.insert(path, chapter.zone)
    end
    table.insert(path, candidateName)

    for _, oldJourney in ipairs(character.history or {}) do
        local oldChapters = oldJourney.chapters or {}
        if #oldChapters >= #path then
            local same = true
            for index, zoneName in ipairs(path) do
                if not oldChapters[index] or oldChapters[index].zone ~= zoneName then
                    same = false
                    break
                end
            end

            if same then
                return true
            end
        end
    end

    return false
end

local function CountHistoricPair(character, previousZoneName, candidateName)
    if not previousZoneName then
        return 0
    end

    local count = 0
    for _, oldJourney in ipairs(character.history or {}) do
        local chapters = oldJourney.chapters or {}
        for index = 1, #chapters - 1 do
            if chapters[index].zone == previousZoneName and chapters[index + 1].zone == candidateName then
                count = count + 1
            end
        end
    end

    return count
end

local function CountHistoricStart(character, candidateName)
    local count = 0

    for _, oldJourney in ipairs(character.history or {}) do
        local firstChapter = oldJourney.chapters and oldJourney.chapters[1]
        if firstChapter and firstChapter.zone == candidateName then
            count = count + 1
        end
    end

    return count
end

local function AddWeightForThemes(weight, zone, classToken)
    local classWeights = CLASS_THEME_WEIGHTS[classToken] or {}

    for _, theme in ipairs(zone.themes or {}) do
        weight = weight + (classWeights[theme] or 0)
    end

    return weight
end

local function IsDirectlyConnected(left, right)
    if not left or not right then
        return false
    end

    return Contains(left.physical, right.name) or Contains(right.physical, left.name)
end

local function IsQuestCompleted(questID)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(questID) == true
    end

    if IsQuestFlaggedCompleted then
        return IsQuestFlaggedCompleted(questID) == true
    end

    return false
end

local function IsQuestActive(questID)
    if C_QuestLog and C_QuestLog.IsOnQuest then
        return C_QuestLog.IsOnQuest(questID) == true
    end

    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        return questLogIndex and questLogIndex > 0
    end

    if GetQuestLogIndexByID then
        local questLogIndex = GetQuestLogIndexByID(questID)
        return questLogIndex and questLogIndex > 0
    end

    return false
end

local function HasStoryFlag(storyFlag)
    if storyFlag ~= "PALADIN_VERIGANS_FIST" then
        return false
    end

    for _, questID in ipairs({ 1654, 1806 }) do
        if IsQuestCompleted(questID) or IsQuestActive(questID) then
            return true
        end
    end

    return GetItemCount and (GetItemCount(6953, true) or 0) > 0
end

local function MeetsTransitionRequirements(character, transition)
    if transition.class and transition.class ~= character.class then
        return false
    end

    if transition.completedQuests then
        local foundCompletedQuest = false

        for _, questID in ipairs(transition.completedQuests) do
            if IsQuestCompleted(questID) then
                foundCompletedQuest = true
                break
            end
        end

        if not foundCompletedQuest then
            return false
        end
    end

    if transition.storyFlag and not HasStoryFlag(transition.storyFlag) then
        return false
    end

    return true
end

local function FindTravelTransition(character, fromName, toName)
    for _, transition in ipairs(TRAVEL_TRANSITIONS) do
        if transition.from == fromName
            and transition.to == toName
            and MeetsTransitionRequirements(character, transition) then
            return transition
        end
    end

    return nil
end

local function PickWeightedCandidate(candidates, totalWeight)
    if #candidates == 0 or totalWeight <= 0 then
        return nil, nil
    end

    local roll = math.random(totalWeight)
    local cursor = 0

    for _, candidate in ipairs(candidates) do
        cursor = cursor + candidate.weight
        if roll <= cursor then
            return candidate.zone, candidate.context
        end
    end

    local fallback = candidates[#candidates]
    return fallback.zone, fallback.context
end

local function GetWeightedZone(character, previousZoneName, excludedZoneName)
    local level = UnitLevel("player")
    local previousZone = previousZoneName and zoneByName[previousZoneName] or nil
    local currentZoneName = GetRealZoneText and GetRealZoneText() or GetZoneText()
    local currentZone = currentZoneName and zoneByName[currentZoneName] or nil
    local raceStart = RACE_START_HINTS[character.race]
    local candidates = {}
    local totalWeight = 0

    for _, zone in ipairs(ZONES) do
        if zone.name ~= excludedZoneName
            and IsLevelAppropriate(zone, level)
            and not IsZoneUsedInJourney(character.activeJourney, zone.name) then
            local context
            local weight

            if previousZone then
                local travelTransition = FindTravelTransition(character, previousZone.name, zone.name)
                local rememberedVisit = character.visitedZones and character.visitedZones[zone.name]

                if travelTransition then
                    weight = travelTransition.weight or 25
                    context = {
                        kind = "travel",
                        from = previousZone.name,
                        text = travelTransition.text,
                    }
                elseif rememberedVisit then
                    weight = 60
                    context = {
                        kind = "memory",
                        from = previousZone.name,
                    }
                elseif IsDirectlyConnected(previousZone, zone) then
                    weight = 16
                    context = {
                        kind = "direct",
                        from = previousZone.name,
                    }
                end
            else
                weight = 10
                context = { kind = "beginning" }

                if currentZone and zone.name == currentZone.name then
                    weight = weight + 12
                    context = { kind = "current", from = currentZone.name }
                elseif currentZone and IsDirectlyConnected(currentZone, zone) then
                    weight = weight + 6
                    context = { kind = "direct", from = currentZone.name }
                elseif currentZone and SharesTheme(currentZone, zone) then
                    weight = weight + 3
                end
            end

            -- Later chapters require a real road or a curated travel bridge.
            if weight then
                weight = AddWeightForThemes(weight, zone, character.class)

                if previousZone and SharesTheme(previousZone, zone) then
                    weight = weight + 4
                end

                if raceStart and zone.name == raceStart and level <= 10 then
                    weight = weight + 8
                end

                if PathWouldRepeat(character, character.activeJourney, zone.name) then
                    weight = math.max(1, weight - 12)
                end

                weight = math.max(1, weight - (CountHistoricPair(character, previousZoneName, zone.name) * 5))

                if not previousZoneName then
                    weight = math.max(1, weight - (CountHistoricStart(character, zone.name) * 4))
                end

                table.insert(candidates, { zone = zone, weight = weight, context = context })
                totalWeight = totalWeight + weight
            end
        end
    end

    return PickWeightedCandidate(candidates, totalWeight)
end

local function GetChapterText(character, zone, context)
    context = context or { kind = "beginning" }

    if context.text then
        return context.text
    end

    local hook = ZONE_STORY_HOOKS[zone.name] or "unresolved trouble waits beyond the road"
    local transitionKey = context.from and (context.from .. ">" .. zone.name) or nil
    local writtenTransition = transitionKey and TRANSITION_STORIES[transitionKey] or nil

    if writtenTransition then
        return writtenTransition
    end

    if context.kind == "direct" and context.from then
        return string.format("The road from %s leads into %s, where %s.", context.from, zone.name, hook)
    end

    if context.kind == "memory" then
        return string.format("The next lead turns back toward %s, a place already written into this character's travels. You return because %s.", zone.name, hook)
    end

    if context.kind == "current" then
        return string.format("Your next chapter begins here in %s, where %s.", zone.name, hook)
    end

    local classIntro = CLASS_STORY_INTROS[character.class]
    if classIntro then
        return string.format("%s In %s, %s.", classIntro, zone.name, hook)
    end

    return string.format("Reports point toward %s, where %s.", zone.name, hook)
end

local function CreateChapter(character, previousZoneName, excludedZoneName)
    local zone, context = GetWeightedZone(character, previousZoneName, excludedZoneName)

    if not zone then
        return nil
    end

    local journey = character.activeJourney
    local recommendedMin, recommendedMax = GetRecommendedZoneRange(zone)

    return {
        number = journey and (#journey.chapters + 1) or 1,
        zone = zone.name,
        min = zone.min,
        max = zone.max,
        recommendedMin = recommendedMin,
        recommendedMax = recommendedMax,
        text = GetChapterText(character, zone, context),
        connection = context and context.kind or "beginning",
        previousZone = context and context.from or nil,
        generatedAtLevel = UnitLevel("player"),
        generatedAtLocation = GetRealZoneText and GetRealZoneText() or GetZoneText(),
    }
end

local function ArchiveActiveJourney(character, reason)
    if not character.activeJourney then
        return
    end

    character.activeJourney.endedAt = time()
    character.activeJourney.endReason = reason
    table.insert(character.history, 1, character.activeJourney)

    while #character.history > MAX_HISTORY do
        table.remove(character.history)
    end

    character.activeJourney = nil
end

local function GenerateJourney(character, reason)
    ArchiveActiveJourney(character, reason)

    local journey = {
        title = JOURNEY_TITLES[math.random(#JOURNEY_TITLES)],
        createdAt = time(),
        createdAtLevel = UnitLevel("player"),
        createdAtLocation = GetRealZoneText and GetRealZoneText() or GetZoneText(),
        class = character.class,
        race = character.race,
        faction = character.faction,
        chapters = {},
    }

    character.activeJourney = journey

    local chapter = CreateChapter(character, nil)
    if chapter then
        table.insert(journey.chapters, chapter)
    end

    return journey, chapter
end

local function GetCurrentChapter(character)
    local journey = character.activeJourney
    if not journey or not journey.chapters or #journey.chapters == 0 then
        return nil
    end

    return journey.chapters[#journey.chapters]
end

local function AddNextChapter(character)
    local journey = character.activeJourney
    if not journey then
        return nil, "You do not have a journey yet. Use /rcj generate."
    end

    local currentChapter = GetCurrentChapter(character)
    local chapter = CreateChapter(character, currentChapter and currentChapter.zone or nil)

    if not chapter then
        return nil, "I could not find a connected story chapter for your current level. Try again after gaining a level, or begin a new journey."
    end

    table.insert(journey.chapters, chapter)
    return chapter
end

local function RerollCurrentChapter(character)
    local journey = character.activeJourney
    if not journey or not journey.chapters or #journey.chapters == 0 then
        return nil, "There is no chapter to reroll yet. Use /rcj generate."
    end

    local removedChapter = table.remove(journey.chapters)
    local previousChapter = journey.chapters[#journey.chapters]
    local chapter = CreateChapter(character, previousChapter and previousChapter.zone or nil, removedChapter.zone)

    if not chapter then
        table.insert(journey.chapters, removedChapter)
        return nil, "I could not find a different suitable chapter for your current level, so the current chapter was kept."
    end

    table.insert(journey.chapters, chapter)
    return chapter
end

local function CreateFrameIfNeeded()
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", "RandomCharacterJourneyFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(430, 360)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("TOPLEFT", 14, -8)
    titleText:SetText("Random Character Journey")

    journeyScrollFrame = CreateFrame("ScrollFrame", "RandomCharacterJourneyScrollFrame", frame, "UIPanelScrollFrameTemplate")
    journeyScrollFrame:SetPoint("TOPLEFT", 18, -42)
    journeyScrollFrame:SetPoint("BOTTOMRIGHT", -34, 46)

    journeyScrollChild = CreateFrame("Frame", nil, journeyScrollFrame)
    journeyScrollChild:SetSize(370, 1)
    journeyScrollFrame:SetScrollChild(journeyScrollChild)

    bodyText = journeyScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bodyText:SetPoint("TOPLEFT", 0, 0)
    bodyText:SetWidth(370)
    bodyText:SetJustifyH("LEFT")
    bodyText:SetJustifyV("TOP")

    local nextButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    nextButton:SetSize(110, 24)
    nextButton:SetPoint("BOTTOMLEFT", 18, 16)
    nextButton:SetText("Next Chapter")
    nextButton:SetScript("OnClick", function()
        local character = GetCharacter()
        local chapter, errorMessage = AddNextChapter(character)
        if not chapter then
            Print(errorMessage)
            return
        end
        Print(chapter.text)
        RefreshJourneyFrame()
        frame:Show()
    end)

    local rerollChapterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    rerollChapterButton:SetSize(120, 24)
    rerollChapterButton:SetPoint("LEFT", nextButton, "RIGHT", 8, 0)
    rerollChapterButton:SetText("Reroll Chapter")
    rerollChapterButton:SetScript("OnClick", function()
        local character = GetCharacter()
        local chapter, errorMessage = RerollCurrentChapter(character)
        if not chapter then
            Print(errorMessage)
            return
        end
        Print(chapter.text)
        RefreshJourneyFrame()
        frame:Show()
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 24)
    closeButton:SetPoint("BOTTOMRIGHT", -18, 16)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame
end

local function FormatJourney(character)
    local journey = character.activeJourney
    if not journey then
        return "No journey yet.\n\nUse /rcj generate to begin."
    end

    local currentChapter = GetCurrentChapter(character)
    local lines = {
        journey.title,
        "",
        "Character: " .. tostring(character.name),
        "Level: " .. tostring(UnitLevel("player")),
        "Class: " .. tostring(character.class),
        "",
    }

    if currentChapter then
        local recommendedMin, recommendedMax = GetChapterRecommendedRange(currentChapter)
        table.insert(lines, "Current Chapter:")
        table.insert(lines, currentChapter.zone .. " (recommended " .. recommendedMin .. "-" .. recommendedMax .. ")")
        table.insert(lines, currentChapter.text)
        table.insert(lines, "")
    end

    table.insert(lines, "Journey So Far (newest first):")
    for index = #journey.chapters, 1, -1 do
        local chapter = journey.chapters[index]
        local suffix = index == #journey.chapters and "  | current" or ""
        table.insert(lines, chapter.number .. ". " .. chapter.zone .. suffix)
    end

    local dungeons = GetRecommendedDungeons(UnitLevel("player"))
    table.insert(lines, "")
    table.insert(lines, "Recommended Dungeon Detours:")
    if #dungeons == 0 then
        table.insert(lines, "None at your current level.")
    else
        for _, dungeon in ipairs(dungeons) do
            local note = dungeon.note and ("; " .. dungeon.note) or ""
            table.insert(lines, "- " .. dungeon.name .. " (" .. dungeon.min .. "-" .. dungeon.max .. ", " .. dungeon.location .. note .. ")")
        end
    end

    return table.concat(lines, "\n")
end

RefreshJourneyFrame = function()
    if bodyText then
        bodyText:SetText(FormatJourney(GetCharacter()))

        if journeyScrollChild then
            local textHeight = bodyText.GetStringHeight and bodyText:GetStringHeight() or 1
            local viewportHeight = journeyScrollFrame and journeyScrollFrame.GetHeight and journeyScrollFrame:GetHeight() or 1
            journeyScrollChild:SetHeight(math.max(tonumber(textHeight) or 1, tonumber(viewportHeight) or 1))
            journeyScrollFrame:SetVerticalScroll(0)
        end
    end
end

local function ShowJourney()
    local character = GetCharacter()
    CreateFrameIfNeeded()
    RefreshJourneyFrame()
    frame:Show()
end

local function PrintJourney()
    local character = GetCharacter()
    local journey = character.activeJourney

    if not journey then
        Print("No journey yet. Use /rcj generate to begin.")
        return
    end

    local currentChapter = GetCurrentChapter(character)
    Print(journey.title)

    if currentChapter then
        local recommendedMin, recommendedMax = GetChapterRecommendedRange(currentChapter)
        Print("Current chapter: " .. currentChapter.zone .. " (recommended " .. recommendedMin .. "-" .. recommendedMax .. ")")
        Print(currentChapter.text)
    end

    local dungeons = GetRecommendedDungeons(UnitLevel("player"))
    if #dungeons > 0 then
        Print("Recommended dungeon detours:")
        for _, dungeon in ipairs(dungeons) do
            Print(dungeon.name .. " (" .. dungeon.min .. "-" .. dungeon.max .. ", " .. dungeon.location .. ")")
        end
    end
end

local function PrintHistory()
    local character = GetCharacter()

    if not character.history or #character.history == 0 then
        Print("No previous journeys stored for this character.")
        return
    end

    Print("Previous journeys:")
    for index, journey in ipairs(character.history) do
        local zones = {}
        for _, chapter in ipairs(journey.chapters or {}) do
            table.insert(zones, chapter.zone)
        end
        Print(index .. ". " .. journey.title .. ": " .. table.concat(zones, " -> "))
    end
end

local function PrintHelp()
    Print("/rcj generate - abandon the active journey and create a new one")
    Print("/rcj next - add the next chapter")
    Print("/rcj reroll - replace the current chapter while keeping earlier chapters")
    Print("/rcj history - show previous journeys")
    Print("/rcj show - open the journey window")
end

local function HandleCommand(message)
    local command = string.lower(Trim(message))
    local character = GetCharacter()

    if command == "" or command == "show" then
        PrintJourney()
        ShowJourney()
        return
    end

    if command == "help" then
        PrintHelp()
        return
    end

    if command == "generate" then
        local _, chapter = GenerateJourney(character, "new")
        if chapter then
            Print(chapter.text)
        else
            Print("I could not find a suitable chapter for your current level.")
        end
        ShowJourney()
        return
    end

    if command == "next" then
        local chapter, errorMessage = AddNextChapter(character)
        if not chapter then
            Print(errorMessage)
            return
        end
        Print(chapter.text)
        ShowJourney()
        return
    end

    if command == "reroll" then
        local chapter, errorMessage = RerollCurrentChapter(character)
        if not chapter then
            Print(errorMessage)
            return
        end
        Print(chapter.text)
        ShowJourney()
        return
    end

    if command == "history" then
        PrintHistory()
        return
    end

    Print("Unknown command. Use /rcj help.")
end

SLASH_RANDOMCHARACTERJOURNEY1 = "/rcj"
SlashCmdList["RANDOMCHARACTERJOURNEY"] = HandleCommand

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == ADDON_NAME then
        InitializeDatabase()
        return
    end

    if event == "PLAYER_LOGIN" then
        InitializeDatabase()
        math.randomseed(time() + (UnitLevel("player") or 1))
        GetCharacter()
        Print("Loaded. Use /rcj generate to begin, or /rcj help for commands.")
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        InitializeDatabase()
        GetCharacter()
    end
end)
