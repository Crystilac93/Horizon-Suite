--[[
    Horizon Suite - Focus - Quest Data
    State, quest/rare/zone helpers, ReadTrackedQuests, SortAndGroupQuests.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- QUEST DATA
-- ============================================================================

addon.enabled            = false  -- Set by Focus module OnEnable
addon.collapsed          = false
addon.refreshPending     = false
addon.prevRareKeys       = {}
addon.rareTrackingInit   = false
addon.zoneJustChanged    = false
addon.collapseAnimating  = false  -- panel-wide collapse
addon.collapseAnimStart  = 0
addon.groupCollapses     = {}     -- per-group collapses: [groupKey] = startTime
addon.lastPlayerMapID    = nil
addon.combatFadeState   = nil   -- "out" = fading out for combat, "in" = fading in after combat
addon.combatFadeTime    = 0

-- Single source of truth: QuestUtils_IsQuestWorldQuest (Blizzard) or C_QuestLog.IsWorldQuest.
local function IsQuestWorldQuest(questID)
    if not questID or questID <= 0 then return false end
    if _G.QuestUtils_IsQuestWorldQuest and _G.QuestUtils_IsQuestWorldQuest(questID) then return true end
    if C_QuestLog and C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) then return true end
    return false
end

-- Frequency from quest log (Daily/Weekly). Returns nil if quest not in log or API unavailable.
local function GetQuestFrequency(questID)
    if not questID or not C_QuestLog or not C_QuestLog.GetLogIndexForQuestID then return nil end
    local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if not logIndex then return nil end
    if GetQuestLogTitle then
        local ok, _, _, _, _, _, frequency = pcall(GetQuestLogTitle, logIndex)
        if ok and frequency ~= nil then return frequency end
    end
    if C_QuestLog.GetInfo then
        local ok, info = pcall(C_QuestLog.GetInfo, logIndex)
        if ok and info and info.frequency ~= nil then return info.frequency end
    end
    return nil
end

-- Single source of truth: C_QuestInfoSystem.GetQuestClassification + frequency + IsQuestWorldQuest.
-- Order: COMPLETE (state) -> WORLD (WQ) -> Classification (Calling, Campaign, Recurring, Important, Legendary) -> Frequency (Weekly) -> DEFAULT.
-- Meta and Questline are ignored and fall through to frequency/DEFAULT.
local function GetQuestBaseCategory(questID)
    if not questID or questID <= 0 then return "DEFAULT" end
    if IsQuestWorldQuest(questID) then
        return "WORLD"
    end
    -- Classification (single source): Normal, Important, Legendary, Campaign, Calling, Meta, Recurring, Questline.
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        local qc = C_QuestInfoSystem.GetQuestClassification(questID)
        if qc == Enum.QuestClassification.Calling then return "CALLING" end
        if qc == Enum.QuestClassification.Campaign then return "CAMPAIGN" end
        if qc == Enum.QuestClassification.Recurring then return "WEEKLY" end
        if qc == Enum.QuestClassification.Important then return "IMPORTANT" end
        if qc == Enum.QuestClassification.Legendary then return "LEGENDARY" end
        -- Meta, Questline, Normal: fall through to frequency then DEFAULT
    end
    -- Frequency (when in log): Weekly -> WEEKLY; Daily -> DAILY.
    local freq = GetQuestFrequency(questID)
    if freq ~= nil then
        if Enum.QuestFrequency and Enum.QuestFrequency.Weekly and freq == Enum.QuestFrequency.Weekly then
            return "WEEKLY"
        end
        if freq == 2 or (LE_QUEST_FREQUENCY_WEEKLY and freq == LE_QUEST_FREQUENCY_WEEKLY) then
            return "WEEKLY"
        end
        if Enum.QuestFrequency and Enum.QuestFrequency.Daily and freq == Enum.QuestFrequency.Daily then
            return "DAILY"
        end
        if freq == 1 or (LE_QUEST_FREQUENCY_DAILY and freq == LE_QUEST_FREQUENCY_DAILY) then
            return "DAILY"
        end
    end
    return "DEFAULT"
end

local function GetQuestCategory(questID)
    if not questID or questID <= 0 then return "DEFAULT" end
    if C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) then
        return "COMPLETE"
    end
    return GetQuestBaseCategory(questID)
end

-- ---------------------------------------------------------------------------
-- Color matrix: defaults + per-category overrides for title/objective/zone/section
-- ---------------------------------------------------------------------------

local function EnsureColorMatrix()
    if not HorizonDB then return end
    if HorizonDB.colorMatrix and type(HorizonDB.colorMatrix) == "table" then return end

    local cm = { categories = {}, overrides = {} }

    -- Migrate legacy quest title colors into per-category title.
    local qc = HorizonDB.questColors
    if qc and type(qc) == "table" then
        for k, v in pairs(qc) do
            if type(v) == "table" and v[1] and v[2] and v[3] then
                if not cm.categories[k] then cm.categories[k] = {} end
                cm.categories[k].title = { v[1], v[2], v[3] }
            end
        end
    end

    -- Migrate legacy section header colors into per-category section.
    local sc = HorizonDB.sectionColors
    if sc and type(sc) == "table" then
        for k, v in pairs(sc) do
            if type(v) == "table" and v[1] and v[2] and v[3] then
                if not cm.categories[k] then cm.categories[k] = {} end
                cm.categories[k].section = { v[1], v[2], v[3] }
            end
        end
    end

    HorizonDB.colorMatrix = cm
end

local function GetColorMatrix()
    if not HorizonDB then return nil end
    EnsureColorMatrix()
    return HorizonDB.colorMatrix
end

-- When override toggles are on, Completed and Current Zone sections use their row colours for all elements.
-- When off, COMPLETE/NEARBY use baseCategory (the underlying quest type) for colours.
local function GetEffectiveColorCategory(category, groupKey, baseCategory)
    if not category then return groupKey or "DEFAULT" end
    local cm = GetColorMatrix()
    local ov = cm and cm.overrides and type(cm.overrides) == "table" and cm.overrides or {}
    if groupKey == "COMPLETE" and (ov.useCompletedOverride == nil or ov.useCompletedOverride) then
        return "COMPLETE"  -- Default true when not explicitly set to false
    end
    if groupKey == "COMPLETE" and baseCategory then
        return baseCategory  -- Use underlying category when override is off
    end
    if groupKey == "NEARBY" and ov.useCurrentZoneOverride then
        return "NEARBY"
    end
    return category
end

-- Matrix rows use group keys (e.g. RARES); quest category can be RARE. Use same row for RARE.
local function MatrixKey(category)
    if category == "RARE" then return "RARES" end
    if category == "ACHIEVEMENT" then return "ACHIEVEMENTS" end
    if category == "ENDEAVOR" then return "ENDEAVORS" end
    if category == "DECOR" then return "DECOR" end
    return category
end

local function GetTitleColor(category)
    if not category then
        return addon.QUEST_COLORS.DEFAULT
    end

    local cm = GetColorMatrix()
    local key = MatrixKey(category)
    if cm and cm.categories and cm.categories[key] and cm.categories[key].title then
        return cm.categories[key].title
    end

    -- Legacy per-category questColors support (for safety if migration didn't run yet).
    local db = HorizonDB and HorizonDB.questColors
    if db then
        if db[category] then return db[category] end
        if category == "CALLING" and db.WORLD then return db.WORLD end
    end

    return addon.QUEST_COLORS[category] or addon.QUEST_COLORS.DEFAULT
end

local function GetObjectiveColor(category)
    local cm = GetColorMatrix()
    local key = category and MatrixKey(category) or nil
    if cm and cm.categories and key and cm.categories[key] and cm.categories[key].objective then
        return cm.categories[key].objective
    end
    return addon.QUEST_COLORS[category] or addon.QUEST_COLORS.DEFAULT
end

local function GetZoneColor(category)
    local cm = GetColorMatrix()
    local key = category and MatrixKey(category) or nil
    if cm and cm.categories and key and cm.categories[key] and cm.categories[key].zone then
        return cm.categories[key].zone
    end
    return addon.ZONE_COLOR
end

local function GetQuestColor(category)
    -- Backwards-compatible wrapper for title color.
    return GetTitleColor(category)
end

local function GetSectionColor(groupKey)
    local cm = GetColorMatrix()
    if cm and cm.categories and groupKey and cm.categories[groupKey] and cm.categories[groupKey].section then
        return cm.categories[groupKey].section
    end
    return addon.SECTION_COLORS[groupKey] or addon.SECTION_COLORS.DEFAULT
end

local function GetQuestTypeAtlas(questID, category)
    if not questID or questID <= 0 then return nil end
    if C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questID) then
        return "QuestTurnin"
    end
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        local qc = C_QuestInfoSystem.GetQuestClassification(questID)
        if qc then
            local atlas = (qc == Enum.QuestClassification.Important and "importantavailablequesticon")
                or (qc == Enum.QuestClassification.Campaign and "Quest-Campaign-Available")
                or (qc == Enum.QuestClassification.Legendary and "UI-QuestPoiLegendary-QuestBang")
                or (qc == Enum.QuestClassification.Calling and "Quest-DailyCampaign-Available")
                or (qc == Enum.QuestClassification.Recurring and "quest-recurring-available")
                or (qc == Enum.QuestClassification.Meta and "quest-wrapper-available")
            if atlas then return atlas end
        end
    end
    if category == "COMPLETE" then return "QuestTurnin" end
    if category == "IMPORTANT" then return "importantavailablequesticon" end
    if category == "CAMPAIGN" then return "Quest-Campaign-Available" end
    if category == "LEGENDARY" then return "UI-QuestPoiLegendary-QuestBang" end
    if category == "CALLING" then return "Quest-DailyCampaign-Available" end
    if category == "WORLD" then return "quest-recurring-available" end
    if category == "WEEKLY" then return "quest-recurring-available" end
    if category == "DAILY" then return "quest-recurring-available" end
    if category == "DUNGEON" then return "questlog-questtypeicon-dungeon" end
    if C_QuestLog.GetQuestTagInfo then
        local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
        if tagInfo and tagInfo.tagID then
            local tagAtlas = (tagInfo.tagID == 41 and "questlog-questtypeicon-pvp")
                or (tagInfo.tagID == 81 and "questlog-questtypeicon-dungeon")
                or (tagInfo.tagID == 62 and "questlog-questtypeicon-raid")
                or (tagInfo.tagID == 1 and "questlog-questtypeicon-group")
            if tagAtlas then return tagAtlas end
        end
    end
    return "QuestNormal"
end

local function GetQuestZoneName(questID)
    local isWorldQuest = IsQuestWorldQuest(questID)
    -- For world quests: prefer task-quest APIs (uiMapID). C_TaskQuest.GetQuestInfoByQuestID can return nil
    -- when quest data isn't cached (e.g. tracked WQ from another zone).
    if isWorldQuest and C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
        local info = C_TaskQuest.GetQuestInfoByQuestID(questID)
        local mapID = info and (info.mapID or info.uiMapID)
        if mapID and C_Map and C_Map.GetMapInfo then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                return mapInfo.name
            end
        end
    end
    -- Waypoint: for world quests when C_TaskQuest fails, waypoint gives quest location. For regular quests,
    -- waypoint often returns player's current map, so we prefer quest log header first.
    if isWorldQuest and C_QuestLog.GetNextWaypoint then
        local mapID = C_QuestLog.GetNextWaypoint(questID)
        if mapID and C_Map and C_Map.GetMapInfo then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                return mapInfo.name
            end
        end
    end
    -- For non-world quests: prefer quest log header (waypoint often = current zone).
    if C_QuestLog.GetLogIndexForQuestID then
        local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        if logIndex then
            for i = logIndex - 1, 1, -1 do
                local info = C_QuestLog.GetInfo(i)
                if info and info.isHeader then
                    return info.title
                end
            end
        end
    end
    if C_QuestLog.GetNextWaypoint then
        local mapID = C_QuestLog.GetNextWaypoint(questID)
        if mapID and C_Map and C_Map.GetMapInfo then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                return mapInfo.name
            end
        end
    end
    return nil
end

--- True when the player is in any party dungeon (Normal, Heroic, Mythic, or Mythic+). Guarded.
local function IsInPartyDungeon()
    local ok, _, instanceType = pcall(GetInstanceInfo)
    return ok and instanceType == "party"
end

local function IsInMythicDungeon()
    local _, instanceType, difficultyID = GetInstanceInfo()
    return instanceType == "party" and (difficultyID == 8 or difficultyID == 23)
end

local function GetMythicDungeonName()
    local name = GetInstanceInfo()
    return name or nil
end

--- Build the full list of quests (and rares) to show: watch list, zone WQs/callings, weeklies/dailies, dungeon quests, super-tracked WQ.
-- Respects filterByZone and test data injection (addon.testQuests). Each entry has questID, title, objectives, color, category, etc.
-- @return table Array of quest/rare entry tables for the tracker
local function ReadTrackedQuests()
    -- Allow test data injection from Slash.lua for /horizon test.
    if addon.testQuests then
        return addon.testQuests
    end

    local quests = {}
    local seen = {}
    local scenarioRewardQuestIDs = {}
    if addon.ReadScenarioEntries then
        for _, se in ipairs(addon.ReadScenarioEntries()) do
            local rid = se.rewardQuestID
            if type(rid) == "number" and rid > 0 then
                scenarioRewardQuestIDs[rid] = true
            end
        end
    end

    local numWatches = C_QuestLog.GetNumQuestWatches()
    local superTracked = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID) and C_SuperTrack.GetSuperTrackedQuestID() or 0
    local nearbySet, taskQuestOnlySet = addon.GetNearbyQuestIDs()

    local function addQuest(questID, opts)
        opts = opts or {}
        if not questID or questID <= 0 or seen[questID] then return end
        if scenarioRewardQuestIDs[questID] then return end
        seen[questID] = true
        local category   = opts.forceCategory or GetQuestCategory(questID)
        local baseCategory = (category == "COMPLETE") and GetQuestBaseCategory(questID) or nil
        local title      = C_QuestLog.GetTitleForQuestID(questID) or "..."
        local objectives = C_QuestLog.GetQuestObjectives(questID) or {}
        local color      = GetQuestColor(category)
        local isComplete = C_QuestLog.IsComplete(questID)
        local isSuper    = (questID == superTracked)
        local isNearby   = nearbySet[questID] or false
        local zoneName   = GetQuestZoneName(questID)
        local isDungeonQuest = opts.isDungeonQuest or (IsInPartyDungeon() and isNearby)
        local isTracked  = opts.isTracked ~= false

        local itemLink, itemTexture
        local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        local isAccepted = (logIndex ~= nil)
        if logIndex and GetQuestLogSpecialItemInfo then
            local link, tex = GetQuestLogSpecialItemInfo(logIndex)
            if link and tex then
                itemLink    = link
                itemTexture = tex
            end
        end

        local questLevel
        if logIndex then
            if C_QuestLog.GetInfo then
                local ok, info = pcall(C_QuestLog.GetInfo, logIndex)
                if ok and info and info.level then questLevel = info.level end
            end
            if not questLevel and GetQuestLogTitle then
                local ok, _, level = pcall(GetQuestLogTitle, logIndex)
                if ok and level then questLevel = level end
            end
        end

        local questTypeAtlas = GetQuestTypeAtlas(questID, category)

        quests[#quests + 1] = {
            entryKey       = questID,
            questID        = questID,
            title          = title,
            objectives     = objectives,
            color          = color,
            category       = category,
            baseCategory   = baseCategory,
            isComplete     = isComplete,
            isSuperTracked = isSuper,
            isNearby       = isNearby,
            isAccepted     = isAccepted,
            zoneName       = zoneName,
            itemLink       = itemLink,
            itemTexture    = itemTexture,
            questTypeAtlas = questTypeAtlas,
            isDungeonQuest = isDungeonQuest,
            isTracked      = isTracked,
            level          = questLevel,
        }
    end

    local filterByZone = addon.GetDB("filterByZone", false)
    for i = 1, numWatches do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if questID then
            -- When \"Filter by current zone\" is enabled, we *still* want tracked WORLD quests
            -- to remain visible while you're in the broader zone (even if the child map
            -- changes and they momentarily fall out of nearbySet).
            local isWorld = IsQuestWorldQuest(questID)
            if (not filterByZone or nearbySet[questID] or isWorld) then
                if addon.GetDB("showWorldQuests", true) or not IsQuestWorldQuest(questID) then
                    addQuest(questID)
                end
            end
        end
    end

    -- Active zone world quests and callings are automatically included from GetNearbyQuestIDs/GetWorldAndCallingQuestIDsToShow.
    -- When showWorldQuests is off, still show WQs on the watch list or when you enter the quest area (GetTasksTable/task map).
    local permanentBlacklist = (HorizonDB and HorizonDB.permanentQuestBlacklist) or {}
    local usePermanent = addon.GetDB("permanentlySuppressUntracked", false)
    for _, entry in ipairs(addon.GetWorldAndCallingQuestIDsToShow(nearbySet, taskQuestOnlySet)) do
        local isBlacklisted = (usePermanent and permanentBlacklist[entry.questID]) or (not usePermanent and addon.recentlyUntrackedWorldQuests and addon.recentlyUntrackedWorldQuests[entry.questID])
        if not seen[entry.questID] and not isBlacklisted and (addon.GetDB("showWorldQuests", true) or entry.isTracked or entry.isInQuestArea) then
            addQuest(entry.questID, { isTracked = entry.isTracked, forceCategory = entry.forceCategory })
        end
    end

    -- Weeklies and dailies in zone (available to accept or already accepted).
    if addon.GetWeekliesAndDailiesInZone then
        local permanentBlacklist = (HorizonDB and HorizonDB.permanentQuestBlacklist) or {}
        local recentlyUntracked = addon.recentlyUntrackedWeekliesAndDailies
        local usePermanent = addon.GetDB("permanentlySuppressUntracked", false)
        for _, entry in ipairs(addon.GetWeekliesAndDailiesInZone(nearbySet)) do
            local isBlacklisted = (usePermanent and permanentBlacklist[entry.questID]) or (not usePermanent and recentlyUntracked and recentlyUntracked[entry.questID])
            if not seen[entry.questID] and not isBlacklisted then
                addQuest(entry.questID, { isTracked = false, forceCategory = entry.forceCategory })
            end
        end
    end

    if IsInPartyDungeon() then
        for questID, _ in pairs(nearbySet) do
            if not seen[questID] and not IsQuestWorldQuest(questID) then
                if not (C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)) then
                    addQuest(questID, { isDungeonQuest = true, isTracked = false, forceCategory = "DUNGEON" })
                end
            end
        end
    end

    -- In a Delve, include all nearby quests so both Delve objectives show (e.g. Kriegval's Rest).
    if addon.IsDelveActive and addon.IsDelveActive() then
        for questID, _ in pairs(nearbySet) do
            if not seen[questID] and not IsQuestWorldQuest(questID) then
                if not (C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)) then
                    addQuest(questID, { isTracked = false, forceCategory = "DELVES" })
                end
            end
        end
    end

    -- Always show super-tracked quest (user has explicitly focused it, including WQs).
    if superTracked and superTracked > 0 and not seen[superTracked] and not scenarioRewardQuestIDs[superTracked] then
        addQuest(superTracked, { isTracked = true })
    end

    -- Append scenario entries (main + bonus steps); prefer scenario over duplicate quest rows.
    if addon.ReadScenarioEntries then
        for _, se in ipairs(addon.ReadScenarioEntries()) do
            quests[#quests + 1] = se
        end
    end

    -- Optional single quest-with-item injection for /horizon testitem (leaves real quests visible).
    if addon.testQuestItem then
        table.insert(quests, 1, addon.testQuestItem)
    end

    return quests
end

-- Entry sort mode: alpha, questType, zone, level (DB key entrySortMode, default questType)
local VALID_ENTRY_SORT = { alpha = true, questType = true, zone = true, level = true }
local function GetSortMode()
    local mode = addon.GetDB("entrySortMode", "questType")
    if type(mode) == "string" and VALID_ENTRY_SORT[mode] then return mode end
    return "questType"
end

-- Category order for questType sort (lower = earlier)
local CATEGORY_SORT_ORDER = {
    COMPLETE = 1, CAMPAIGN = 2, IMPORTANT = 3, LEGENDARY = 4,
    DELVES = 5, SCENARIO = 5, ACHIEVEMENT = 5, DUNGEON = 5, WORLD = 6, WEEKLY = 7, DAILY = 8, CALLING = 9, RARE = 10, DEFAULT = 11,
}

local function CompareEntriesBySortMode(a, b)
    -- Within WORLD: tracked or in-log first. Within WEEKLY/DAILY: in-log first.
    if a.category == "WORLD" or a.category == "CALLING" then
        local pa = ((a.isTracked or a.isAccepted) and 1) or 0
        local pb = ((b.isTracked or b.isAccepted) and 1) or 0
        if pa ~= pb then return pa > pb end
    elseif a.category == "WEEKLY" or a.category == "DAILY" then
        local pa = (a.isAccepted and 1) or 0
        local pb = (b.isAccepted and 1) or 0
        if pa ~= pb then return pa > pb end
    end

    local mode = GetSortMode()
    local ta, tb = (a.title or ""):lower(), (b.title or ""):lower()

    if mode == "alpha" then
        return ta < tb
    end

    if mode == "questType" then
        local ra, rb = CATEGORY_SORT_ORDER[a.category] or 99, CATEGORY_SORT_ORDER[b.category] or 99
        if ra ~= rb then return ra < rb end
        return ta < tb
    end

    if mode == "zone" then
        local za, zb = (a.zoneName or ""):lower(), (b.zoneName or ""):lower()
        if za ~= zb then return za < zb end
        return ta < tb
    end

    if mode == "level" then
        local la, lb = a.level or 0, b.level or 0
        if la ~= lb then return la > lb end
        return ta < tb
    end

    return ta < tb
end

local function SortAndGroupQuests(quests)
    local groups = {}
    for _, key in ipairs(addon.GetGroupOrder()) do
        groups[key] = {}
    end
    for _, q in ipairs(quests) do
        if q.isRare or q.category == "RARE" then
            groups["RARES"][#groups["RARES"] + 1] = q
        elseif q.isDungeonQuest or q.category == "DUNGEON" then
            groups["DUNGEON"][#groups["DUNGEON"] + 1] = q
        elseif q.category == "DELVES" then
            groups["DELVES"][#groups["DELVES"] + 1] = q
        elseif q.category == "SCENARIO" then
            groups["SCENARIO"][#groups["SCENARIO"] + 1] = q
        elseif q.category == "ACHIEVEMENT" or q.isAchievement then
            groups["ACHIEVEMENTS"][#groups["ACHIEVEMENTS"] + 1] = q
        elseif q.category == "ENDEAVOR" or q.isEndeavor then
            groups["ENDEAVORS"][#groups["ENDEAVORS"] + 1] = q
        elseif q.category == "DECOR" or q.isDecor then
            groups["DECOR"][#groups["DECOR"] + 1] = q
        elseif q.category == "WORLD" or q.category == "CALLING" then
            groups["WORLD"][#groups["WORLD"] + 1] = q
        elseif q.isNearby and not q.isAccepted then
            groups["AVAILABLE"][#groups["AVAILABLE"] + 1] = q
        elseif q.isNearby and q.isAccepted then
            -- Accepted quests that are in the current zone. In Zone overtakes Ready to Turn in: complete quests in zone always go to NEARBY. When showNearbyGroup is off, other in-zone quests use their real category (e.g. daily → DAILY).
            if addon.GetDB("showNearbyGroup", true) or q.category == "COMPLETE" then
                groups["NEARBY"][#groups["NEARBY"] + 1] = q
            else
                local grp = addon.CATEGORY_TO_GROUP[q.category] or "DEFAULT"
                groups[grp][#groups[grp] + 1] = q
            end
        else
            local grp = addon.CATEGORY_TO_GROUP[q.category] or "DEFAULT"
            groups[grp][#groups[grp] + 1] = q
        end
    end

    for _, key in ipairs(addon.GetGroupOrder()) do
        if #groups[key] > 0 then
            table.sort(groups[key], CompareEntriesBySortMode)
        end
    end

    local result = {}
    for _, key in ipairs(addon.GetGroupOrder()) do
        if #groups[key] > 0 then
            result[#result + 1] = { key = key, quests = groups[key] }
        end
    end
    -- When in a Delve or party dungeon and setting is on, show only that section.
    if addon.GetDB("hideOtherCategoriesInDelve", false) then
        if addon.IsDelveActive and addon.IsDelveActive() then
            for _, grp in ipairs(result) do
                if grp.key == "DELVES" then return { grp } end
            end
            return {}
        end
        if addon.IsInPartyDungeon and addon.IsInPartyDungeon() then
            for _, grp in ipairs(result) do
                if grp.key == "DUNGEON" then return { grp } end
            end
            return {}
        end
    end
    return result
end

addon.IsQuestWorldQuest    = IsQuestWorldQuest
addon.GetQuestFrequency    = GetQuestFrequency
addon.GetQuestCategory     = GetQuestCategory
addon.GetQuestBaseCategory = GetQuestBaseCategory
addon.GetEffectiveColorCategory = GetEffectiveColorCategory
addon.GetTitleColor        = GetTitleColor
addon.GetObjectiveColor    = GetObjectiveColor
addon.GetZoneColor         = GetZoneColor
addon.GetQuestColor        = GetQuestColor
addon.GetSectionColor      = GetSectionColor
addon.GetQuestTypeAtlas    = GetQuestTypeAtlas
addon.GetQuestZoneName     = GetQuestZoneName
addon.IsInPartyDungeon     = IsInPartyDungeon
addon.IsInMythicDungeon    = IsInMythicDungeon
addon.GetMythicDungeonName = GetMythicDungeonName
addon.ReadTrackedQuests    = ReadTrackedQuests
addon.SortAndGroupQuests   = SortAndGroupQuests
addon.GetSortMode          = GetSortMode
