--[[
    Horizon Suite - Focus - World Quest Tracking
    Quests on map (GetNearbyQuestIDs), world/calling watch list, merge into tracker.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- WORLD QUEST AND QUESTS-ON-MAP LOGIC
-- ============================================================================

--- Build sets of quest IDs visible on the player's current map(s) and from task/WQ APIs.
-- @return table nearbySet Set of questID -> true for quests on player map or parent/children
-- @return table taskQuestOnlySet Set of questID -> true for quests coming only from task/WQ map APIs
local function GetNearbyQuestIDs()
    local nearbySet = {}
    local taskQuestOnlySet = {}

    -- Build mapIDsToCheck first so we can filter GetTasksTable by current map.
    -- This prevents stale WQs from the previous zone (e.g. after hearth) from staying in the tracker.
    local mapID = (C_Map and C_Map.GetBestMapForUnit) and C_Map.GetBestMapForUnit("player") or nil
    local mapIDsToCheck = nil
    if mapID and C_Map and C_Map.GetMapInfo then
        mapIDsToCheck = { mapID }
        local seen = { [mapID] = true }
        local myMapInfo = C_Map.GetMapInfo(mapID) or nil
        local myMapType = myMapInfo and myMapInfo.mapType
    if C_Map.GetMapInfo and myMapType ~= nil and myMapType >= 4 then
        local parentInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)) or nil
        local parentMapID = parentInfo and parentInfo.parentMapID and parentInfo.parentMapID ~= 0 and parentInfo.parentMapID or nil
        if parentMapID then
            local parentMapInfo = (C_Map.GetMapInfo and C_Map.GetMapInfo(parentMapID)) or nil
            local mapType = parentMapInfo and parentMapInfo.mapType
            if mapType == nil or mapType >= 3 then
                if not seen[parentMapID] then
                    seen[parentMapID] = true
                    mapIDsToCheck[#mapIDsToCheck + 1] = parentMapID
                end
            end
        end
    end
    -- Only add children when player's map is Micro (5) or Dungeon (4); never when in a Zone (city).
    if C_Map.GetMapChildrenInfo and myMapType ~= nil and myMapType >= 4 then
        local children = C_Map.GetMapChildrenInfo(mapID, nil, true)
        if children then
            for _, child in ipairs(children) do
                local childID = child and child.mapID
                if childID and not seen[childID] then
                    seen[childID] = true
                    mapIDsToCheck[#mapIDsToCheck + 1] = childID
                end
            end
        end
    end
    end

    -- GetTasksTable: filter by current map when mapIDsToCheck is available to prevent stale cross-zone WQs.
    if _G.GetTasksTable and type(_G.GetTasksTable) == "function" then
        local ok, tasks = pcall(_G.GetTasksTable)
        if ok and tasks and type(tasks) == "table" then
            for _, entry in pairs(tasks) do
                local questID = (type(entry) == "number" and entry) or (type(entry) == "table" and entry and entry.questID)
                if questID and type(questID) == "number" and questID > 0 then
                    local addIt = true
                    if mapIDsToCheck and C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
                        local info = C_TaskQuest.GetQuestInfoByQuestID(questID)
                        local questMapID = info and (info.mapID or info.uiMapID)
                        if not questMapID then
                            addIt = false
                        else
                            addIt = false
                            for _, checkID in ipairs(mapIDsToCheck) do
                                if questMapID == checkID then
                                    addIt = true
                                    break
                                end
                            end
                        end
                    end
                    if addIt then
                        nearbySet[questID] = true
                        taskQuestOnlySet[questID] = true
                    end
                end
            end
        end
    end

    if not C_Map or not C_Map.GetBestMapForUnit or not C_QuestLog.GetQuestsOnMap then return nearbySet, taskQuestOnlySet end
    if not mapIDsToCheck then return nearbySet, taskQuestOnlySet end

    for _, checkMapID in ipairs(mapIDsToCheck) do
        local onMap = C_QuestLog.GetQuestsOnMap(checkMapID)
        if onMap then
            for _, info in ipairs(onMap) do
                if info.questID then
                    nearbySet[info.questID] = true
                end
            end
        end
        if addon.GetTaskQuestsForMap then
            local taskPOIs = addon.GetTaskQuestsForMap(checkMapID, checkMapID) or addon.GetTaskQuestsForMap(checkMapID)
            if taskPOIs then
                addon.ParseTaskPOIs(taskPOIs, nearbySet)
                addon.ParseTaskPOIs(taskPOIs, taskQuestOnlySet)
            end
        end
    end

    -- Waypoint-based fallback: only when next waypoint is on the player's exact map (not parent), so we don't pull in quests from other zones that share a hub.
    if C_QuestLog.GetNextWaypoint then
        local questIDsToCheck = {}
        if C_QuestLog.GetNumQuestWatches and C_QuestLog.GetQuestIDForQuestWatchIndex then
            for i = 1, C_QuestLog.GetNumQuestWatches() do
                local qid = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
                if qid then questIDsToCheck[qid] = true end
            end
        end
        if C_QuestLog.GetNumWorldQuestWatches and C_QuestLog.GetQuestIDForWorldQuestWatchIndex then
            for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
                local qid = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
                if qid then questIDsToCheck[qid] = true end
            end
        end
        if C_QuestLog.GetNumQuestLogEntries then
            for i = 1, C_QuestLog.GetNumQuestLogEntries() do
                local info = C_QuestLog.GetInfo(i)
                if info and not info.isHeader and info.questID then
                    questIDsToCheck[info.questID] = true
                end
            end
        end
        for questID, _ in pairs(questIDsToCheck) do
            if not nearbySet[questID] then
                local waypointMapID = C_QuestLog.GetNextWaypoint(questID)
                if waypointMapID then
                    for _, checkID in ipairs(mapIDsToCheck) do
                        if waypointMapID == checkID then
                            nearbySet[questID] = true
                            break
                        end
                    end
                end
            end
        end
    end

    return nearbySet, taskQuestOnlySet
end

--- True if player is within threshold of the quest's map position (Blizzard-style quest area proximity).
-- Uses C_TaskQuest.GetQuestLocation and C_Map.GetPlayerMapPosition. Restricted in instances.
local QUEST_AREA_THRESHOLD = 0.12  -- normalized 0-1; ~12% of map = quest area size
local function IsPlayerNearQuestArea(questID, mapID)
    if not questID or not mapID or not C_TaskQuest or not C_TaskQuest.GetQuestLocation then return false end
    if not C_Map or not C_Map.GetPlayerMapPosition then return false end
    local qx, qy = C_TaskQuest.GetQuestLocation(questID, mapID)
    if not qx or not qy then
        -- Quest may be on parent map (e.g. micro zone); try parent
        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
        if info and info.parentMapID and info.parentMapID ~= 0 then
            qx, qy = C_TaskQuest.GetQuestLocation(questID, info.parentMapID)
            mapID = info.parentMapID
        end
    end
    if not qx or not qy then return false end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return false end
    local px, py = pos.x, pos.y
    if type(px) ~= "number" or type(py) ~= "number" then
        if pos.GetXY and type(pos.GetXY) == "function" then px, py = pos:GetXY() end
    end
    if not px or not py then return false end
    local dist = math.sqrt((qx - px) * (qx - px) + (qy - py) * (qy - py))
    return dist <= QUEST_AREA_THRESHOLD
end

-- World quest watch set for map-close diff.
local function GetCurrentWorldQuestWatchSet()
    local set = {}
    if C_QuestLog.GetNumWorldQuestWatches and C_QuestLog.GetQuestIDForWorldQuestWatchIndex then
        for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
            local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
            if questID then set[questID] = true end
        end
    end
    return set
end

-- True if questID is currently on the world quest watch list (avoids timing: map add can update list after we read it).
local function IsOnWorldQuestWatchList(questID)
    if not questID or not C_QuestLog.GetNumWorldQuestWatches or not C_QuestLog.GetQuestIDForWorldQuestWatchIndex then return false end
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        if C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i) == questID then return true end
    end
    return false
end

-- Returns watch-list WQs plus in-zone *active* world quests/callings so they appear in the objective list.
-- Filter out deprecated/expired WQs: only show if on watch list, or calling, or (world/task and currently active or in quest log).
local function GetWorldAndCallingQuestIDsToShow(nearbySet, taskQuestOnlySet)
    local playerMapID = (C_Map and C_Map.GetBestMapForUnit) and C_Map.GetBestMapForUnit("player") or nil
    local out = {}
    local seen = {}
    if C_QuestLog.GetNumWorldQuestWatches and C_QuestLog.GetQuestIDForWorldQuestWatchIndex then
        addon.lastWorldQuestWatchSet = addon.lastWorldQuestWatchSet or {}
        wipe(addon.lastWorldQuestWatchSet)
        local numWorldWatches = C_QuestLog.GetNumWorldQuestWatches()
        for i = 1, numWorldWatches do
            local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
            if questID and not seen[questID] then
                seen[questID] = true
                addon.lastWorldQuestWatchSet[questID] = true
                out[#out + 1] = { questID = questID, isTracked = true }
            end
        end
    end
    if addon.wqtTrackedQuests then
        for questID, _ in pairs(addon.wqtTrackedQuests) do
            if not seen[questID] then
                seen[questID] = true
                out[#out + 1] = { questID = questID, isTracked = true }
            end
        end
    end
    if nearbySet and (addon.IsQuestWorldQuest or C_QuestLog.IsWorldQuest) then
        local recentlyUntracked = addon.recentlyUntrackedWorldQuests
        local ids = {}
        for questID, _ in pairs(nearbySet) do
            if not seen[questID] and (not recentlyUntracked or not recentlyUntracked[questID]) then
                local isWorld = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) or (C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID))
                local isCalling = C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)
                local isActiveTask = C_TaskQuest and C_TaskQuest.IsActive and C_TaskQuest.IsActive(questID)
                local fromTaskQuestMap = taskQuestOnlySet and taskQuestOnlySet[questID]
                local inLog = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
                local qc = C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification and C_QuestInfoSystem.GetQuestClassification(questID)
                local isCampaign = (qc == Enum.QuestClassification.Campaign)
                local isRecurring = (qc == Enum.QuestClassification.Recurring)
                if isCampaign or isRecurring then
                    if isCalling then ids[#ids + 1] = questID end
                elseif isCalling then
                    ids[#ids + 1] = questID
                elseif isWorld and (inLog or isActiveTask) then
                    ids[#ids + 1] = questID
                end
            end
        end
        table.sort(ids)
        for _, questID in ipairs(ids) do
            seen[questID] = true
            if C_TaskQuest and C_TaskQuest.RequestPreloadRewardData then
                C_TaskQuest.RequestPreloadRewardData(questID)
            end
            local isWorld = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) or (C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID))
            local isCalling = C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)
            local fromTaskQuestMap = taskQuestOnlySet and taskQuestOnlySet[questID]
            local qc = C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification and C_QuestInfoSystem.GetQuestClassification(questID)
            local isCampaign = (qc == Enum.QuestClassification.Campaign)
            local isRecurring = (qc == Enum.QuestClassification.Recurring)
            -- Only force WORLD for task-map quests that are not already world/calling/campaign/recurring (should not happen now we only add WQ/Calling).
            local forceCategory = (fromTaskQuestMap and not isWorld and not isCalling and not isCampaign and not isRecurring) and "WORLD" or nil
            -- isInQuestArea: player within distance of quest (Blizzard-style). Zone-only WQs stay hidden when WQ off.
            local isInQuestArea = playerMapID and IsPlayerNearQuestArea(questID, playerMapID)
            -- Re-check watch list so WQs just added from map get isTracked = true (no **).
            local isTracked = IsOnWorldQuestWatchList(questID)
            out[#out + 1] = { questID = questID, isTracked = isTracked, isInQuestArea = isInQuestArea, forceCategory = forceCategory }
        end
    end
    return out
end

-- Returns weeklies and dailies that appear in the zone (nearbySet). Used to auto-add them to the tracker like world quests.
-- Each returned entry has questID and forceCategory ("WEEKLY" or "DAILY"). Quests not yet accepted are "available to collect".
local function GetWeekliesAndDailiesInZone(nearbySet)
    local out = {}
    if not nearbySet or not C_QuestInfoSystem or not C_QuestInfoSystem.GetQuestClassification then return out end
    local ids = {}
    for questID, _ in pairs(nearbySet) do
        if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
            -- Skip world quests; they are handled by GetWorldAndCallingQuestIDsToShow.
        elseif C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID) then
            -- Skip callings.
        else
            local qc = C_QuestInfoSystem.GetQuestClassification(questID)
            local isRecurring = (qc == Enum.QuestClassification.Recurring)
            local freq = addon.GetQuestFrequency and addon.GetQuestFrequency(questID)
            local isWeekly = isRecurring
                or (freq ~= nil and (freq == 2 or (LE_QUEST_FREQUENCY_WEEKLY and freq == LE_QUEST_FREQUENCY_WEEKLY)))
                or (freq ~= nil and Enum.QuestFrequency and Enum.QuestFrequency.Weekly and freq == Enum.QuestFrequency.Weekly)
            local isDaily = (freq ~= nil and (freq == 1 or (LE_QUEST_FREQUENCY_DAILY and freq == LE_QUEST_FREQUENCY_DAILY)))
                or (freq ~= nil and Enum.QuestFrequency and Enum.QuestFrequency.Daily and freq == Enum.QuestFrequency.Daily)
            if isWeekly then
                ids[#ids + 1] = { questID = questID, forceCategory = "WEEKLY" }
            elseif isDaily then
                ids[#ids + 1] = { questID = questID, forceCategory = "DAILY" }
            end
        end
    end
    table.sort(ids, function(a, b) return a.questID < b.questID end)
    for _, e in ipairs(ids) do
        out[#out + 1] = e
    end
    return out
end

local function RemoveWorldQuestWatch(questID)
    if not questID then return end
    if (addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID)) and C_QuestLog.RemoveWorldQuestWatch then
        C_QuestLog.RemoveWorldQuestWatch(questID)
    end
end

addon.GetNearbyQuestIDs = GetNearbyQuestIDs
addon.GetWorldAndCallingQuestIDsToShow = GetWorldAndCallingQuestIDsToShow
addon.GetWeekliesAndDailiesInZone = GetWeekliesAndDailiesInZone
addon.GetCurrentWorldQuestWatchSet = GetCurrentWorldQuestWatchSet
addon.RemoveWorldQuestWatch = RemoveWorldQuestWatch
