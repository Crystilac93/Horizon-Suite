--[[
    Horizon Suite - Focus - Aggregator
    Builds context, calls each content provider, normalizes entries, and returns merged quest list.
    APIs: C_QuestLog, C_SuperTrack, GetQuestLogSpecialItemInfo, GetQuestLogTitle.
]]

local addon = _G.HorizonSuite

local DEFAULT_SORT_MODE = "questType"
local CATEGORY_SORT_FALLBACK = 99
local DEFAULT_GROUP = "DEFAULT"
local UNKNOWN_TITLE_PLACEHOLDER = "..."

-- Entry sort mode: alpha, questType, zone, level (DB key entrySortMode, default questType)
local VALID_ENTRY_SORT = { alpha = true, questType = true, zone = true, level = true }

--- Current entry sort mode from DB (alpha, questType, zone, or level).
--- @return string Sort mode key
local function GetSortMode()
    local mode = addon.GetDB("entrySortMode", DEFAULT_SORT_MODE)
    if type(mode) == "string" and VALID_ENTRY_SORT[mode] then return mode end
    return DEFAULT_SORT_MODE
end

-- Category order for questType sort (lower = earlier)
local CATEGORY_SORT_ORDER = {
    COMPLETE = 1, CAMPAIGN = 2, IMPORTANT = 3, LEGENDARY = 4,
    DELVES = 5, SCENARIO = 5, ACHIEVEMENT = 5, DUNGEON = 5, WORLD = 6, WEEKLY = 7, DAILY = 8, CALLING = 9, RARE = 10, DEFAULT = 11,
}

local function CompareEntriesBySortMode(a, b)
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

    if mode == "alpha" then return ta < tb end
    if mode == "questType" then
        local ra, rb = CATEGORY_SORT_ORDER[a.category] or CATEGORY_SORT_FALLBACK, CATEGORY_SORT_ORDER[b.category] or CATEGORY_SORT_FALLBACK
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

--- Buckets entries by group key, sorts each group, and returns ordered { key, quests } array.
--- @param quests table Array of normalized entry tables
--- @return table Array of { key = string, quests = table }
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
            if addon.GetDB("showNearbyGroup", true) or q.category == "COMPLETE" then
                groups["NEARBY"][#groups["NEARBY"] + 1] = q
            else
                local grp = addon.CATEGORY_TO_GROUP[q.category] or DEFAULT_GROUP
                groups[grp][#groups[grp] + 1] = q
            end
        else
            local grp = addon.CATEGORY_TO_GROUP[q.category] or DEFAULT_GROUP
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

--- Build the full list of quests by calling each provider and normalizing.
--- Respects filterByZone and test data. Merges Collect* providers and ReadScenarioEntries.
--- @return table Array of normalized entry tables (see entry shape in FocusState.lua)
local function ReadTrackedQuests()
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

    local superTracked = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID) and C_SuperTrack.GetSuperTrackedQuestID() or 0
    local nearbySet, taskQuestOnlySet = addon.GetNearbyQuestIDs()
    local playerZone = (addon.GetPlayerCurrentZoneName and addon.GetPlayerCurrentZoneName()) or nil
    local filterByZone = addon.GetDB("filterByZone", false)

    local function zoneMatchesPlayer(questID)
        local zn = addon.GetQuestZoneName and addon.GetQuestZoneName(questID)
        return not zn or not playerZone or zn:lower() == playerZone:lower()
    end

    local function addQuest(questID, opts)
        opts = opts or {}
        if not questID or questID <= 0 or seen[questID] then return end
        if scenarioRewardQuestIDs[questID] then return end
        seen[questID] = true

        local category = opts.forceCategory or addon.GetQuestCategory(questID)
        local baseCategory = (category == "COMPLETE") and addon.GetQuestBaseCategory(questID) or nil
        local title = C_QuestLog.GetTitleForQuestID(questID) or UNKNOWN_TITLE_PLACEHOLDER
        local objectives = C_QuestLog.GetQuestObjectives(questID) or {}
        local objectivesDoneCount, objectivesTotalCount
        local completedObjDisplay = addon.GetDB("questCompletedObjectiveDisplay", "off")
        if completedObjDisplay == "hide" and #objectives > 0 then
            objectivesDoneCount, objectivesTotalCount = 0, #objectives
            for _, o in ipairs(objectives) do
                if o.finished then objectivesDoneCount = objectivesDoneCount + 1 end
            end
            local filtered = {}
            for _, o in ipairs(objectives) do
                if not o.finished then filtered[#filtered + 1] = o end
            end
            objectives = filtered
        end
        local color = addon.GetQuestColor(category)
        local isComplete = C_QuestLog.IsComplete(questID)
        local isSuper = (questID == superTracked)
        local zoneName = addon.GetQuestZoneName(questID)
        local isNearby = (nearbySet[questID] or false)
            and (not zoneName or not playerZone or zoneName:lower() == playerZone:lower())
        local isDungeonQuest = opts.isDungeonQuest or (addon.IsInPartyDungeon and addon.IsInPartyDungeon() and isNearby)
        local isTracked = opts.isTracked ~= false

        local itemLink, itemTexture
        local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        local isAccepted = (logIndex ~= nil)
        if logIndex and GetQuestLogSpecialItemInfo then
            local link, tex = GetQuestLogSpecialItemInfo(logIndex)
            if link and tex then itemLink, itemTexture = link, tex end
        end

        local questLevel
        if logIndex then
            -- pcall: C_QuestLog.GetInfo can throw on invalid logIndex.
            if C_QuestLog.GetInfo then
                local ok, info = pcall(C_QuestLog.GetInfo, logIndex)
                if ok and info and info.level then questLevel = info.level end
            end
            if not questLevel and GetQuestLogTitle then
                -- pcall: GetQuestLogTitle can throw on invalid logIndex.
                local ok, _, level = pcall(GetQuestLogTitle, logIndex)
                if ok and level then questLevel = level end
            end
        end

        local questTypeAtlas = addon.GetQuestTypeAtlas(questID, category)

        local entry = {
            entryKey = questID, questID = questID, title = title, objectives = objectives,
            color = color, category = category, baseCategory = baseCategory,
            isComplete = isComplete, isSuperTracked = isSuper, isNearby = isNearby,
            isAccepted = isAccepted, zoneName = zoneName, itemLink = itemLink, itemTexture = itemTexture,
            questTypeAtlas = questTypeAtlas, isDungeonQuest = isDungeonQuest, isTracked = isTracked, level = questLevel,
        }
        if objectivesDoneCount and objectivesTotalCount then
            entry.objectivesDoneCount = objectivesDoneCount
            entry.objectivesTotalCount = objectivesTotalCount
        end
        quests[#quests + 1] = entry
    end

    local ctx = {
        nearbySet = nearbySet,
        taskQuestOnlySet = taskQuestOnlySet,
        playerZone = playerZone,
        filterByZone = filterByZone,
        seen = seen,
        superTracked = superTracked,
        scenarioRewardQuestIDs = scenarioRewardQuestIDs,
    }

    -- 1. Tracked quests (watch list)
    for _, e in ipairs(addon.CollectTrackedQuests(ctx)) do
        if not seen[e.questID] then addQuest(e.questID, e.opts or {}) end
    end

    -- 2. World quests and callings (with blacklist)
    local permanentBlacklist = (HorizonDB and HorizonDB.permanentQuestBlacklist) or {}
    local usePermanent = addon.GetDB("permanentlySuppressUntracked", false)
    local recentlyUntrackedWQ = addon.focus.recentlyUntrackedWorldQuests
    for _, e in ipairs(addon.CollectWorldQuests(ctx)) do
        local opts = e.opts or {}
        local isBlacklisted = (usePermanent and permanentBlacklist[e.questID]) or (not usePermanent and recentlyUntrackedWQ and recentlyUntrackedWQ[e.questID])
        if not seen[e.questID] and not isBlacklisted and (addon.GetDB("showWorldQuests", true) or opts.isTracked or opts.isInQuestArea) then
            if not filterByZone or zoneMatchesPlayer(e.questID) then
                addQuest(e.questID, opts)
            end
        end
    end

    -- 3. Dailies and weeklies (with blacklist)
    local recentlyUntrackedDW = addon.focus.recentlyUntrackedWeekliesAndDailies
    for _, e in ipairs(addon.CollectDailiesWeeklies(ctx)) do
        local opts = e.opts or {}
        local isBlacklisted = (usePermanent and permanentBlacklist[e.questID]) or (not usePermanent and recentlyUntrackedDW and recentlyUntrackedDW[e.questID])
        if not seen[e.questID] and not isBlacklisted then
            if not filterByZone or zoneMatchesPlayer(e.questID) then
                addQuest(e.questID, opts)
            end
        end
    end

    -- 4. Dungeon quests
    for _, e in ipairs(addon.CollectDungeonQuests(ctx)) do
        if not seen[e.questID] then addQuest(e.questID, e.opts or {}) end
    end

    -- 5. Delve quests
    for _, e in ipairs(addon.CollectDelveQuests(ctx)) do
        if not seen[e.questID] then addQuest(e.questID, e.opts or {}) end
    end

    -- 6. Super-tracked catch-all
    if superTracked and superTracked > 0 and not seen[superTracked] and not scenarioRewardQuestIDs[superTracked] then
        addQuest(superTracked, { isTracked = true })
    end

    -- 7. Scenario entries (already normalized)
    if addon.ReadScenarioEntries then
        for _, se in ipairs(addon.ReadScenarioEntries()) do
            quests[#quests + 1] = se
        end
    end

    if addon.testQuestItem then
        table.insert(quests, 1, addon.testQuestItem)
    end

    return quests
end

addon.ReadTrackedQuests   = ReadTrackedQuests
addon.SortAndGroupQuests  = SortAndGroupQuests
addon.GetSortMode         = GetSortMode
