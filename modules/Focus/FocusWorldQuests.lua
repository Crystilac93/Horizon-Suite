--[[
    Horizon Suite - Focus - World Quest Tracking
    Quests on map (GetNearbyQuestIDs), world/calling watch list, merge into tracker.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- WORLD QUEST AND QUESTS-ON-MAP LOGIC
-- ============================================================================

--- True when a task/world quest is genuinely active on the server right now.
-- Checks C_TaskQuest.IsActive, time remaining, and completed flag.
-- @param questID number
-- @return boolean
local function IsTaskQuestCurrentlyActive(questID)
    if not questID or questID <= 0 then return false end
    -- Must not have been completed already.
    if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questID) then
        return false
    end
    -- C_TaskQuest.IsActive: definitive server-side check.
    if C_TaskQuest and C_TaskQuest.IsActive then
        if not C_TaskQuest.IsActive(questID) then return false end
    end
    -- Time-left guard: if the quest has a timer and it has expired, reject it.
    if C_TaskQuest and C_TaskQuest.GetQuestTimeLeftSeconds then
        local timeLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questID)
        -- timeLeft is nil when no timer exists (some callings, bonus objectives); that is fine.
        if timeLeft and timeLeft <= 0 then return false end
    end
    return true
end

--- True when a task/world quest belongs to one of the maps we are checking.
-- Uses C_TaskQuest.GetQuestZoneID and walks up the parent chain so sub-zone
-- quests on the player's zone are correctly included.
-- @param questID number
-- @param mapIDSet table  Set of mapID -> true
-- @return boolean
local function IsTaskQuestOnPlayerMaps(questID, mapIDSet)
    if not questID or not mapIDSet then return false end
    if not (C_TaskQuest and C_TaskQuest.GetQuestZoneID) then return true end  -- no API, assume match
    local ok, zoneMapID = pcall(C_TaskQuest.GetQuestZoneID, questID)
    if not ok or not zoneMapID then return false end
    -- Walk up the map hierarchy: sub-zone → zone → continent, stop at 5 levels to avoid infinite loops.
    local checkID = zoneMapID
    for _ = 1, 5 do
        if not checkID or checkID == 0 then break end
        if mapIDSet[checkID] then return true end
        if not (C_Map and C_Map.GetMapInfo) then break end
        local info = C_Map.GetMapInfo(checkID)
        if not info or not info.parentMapID or info.parentMapID == 0 then break end
        checkID = info.parentMapID
    end
    return false
end

--- Build sets of quest IDs visible on the player's current map(s) and from task/WQ APIs.
-- @return table nearbySet Set of questID -> true for quests on player map or parent/children
-- @return table taskQuestOnlySet Set of questID -> true for quests coming only from task/WQ map APIs
local function GetNearbyQuestIDs()
    local nearbySet = {}
    local taskQuestOnlySet = {}

    -- Build mapIDsToCheck first so we can filter by current map.
    -- This prevents stale WQs from the previous zone (e.g. after hearth) from staying in the tracker.
    local mapID = (C_Map and C_Map.GetBestMapForUnit) and C_Map.GetBestMapForUnit("player") or nil
    local mapIDsToCheck = nil
    local mapIDSet = {}  -- fast lookup set for the same IDs
    if mapID and C_Map and C_Map.GetMapInfo then
        mapIDsToCheck = { mapID }
        mapIDSet[mapID] = true
        local seen = { [mapID] = true }
        local myMapInfo = C_Map.GetMapInfo(mapID) or nil
        local myMapType = myMapInfo and myMapInfo.mapType
    -- In a Delve, only use the current map; do not add parent or children (avoids pulling in zone quests).
    if not (addon.IsDelveActive and addon.IsDelveActive()) then
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
                        mapIDSet[parentMapID] = true
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
                        mapIDSet[childID] = true
                    end
                end
            end
        end
    end
    end

    -- GetTasksTable: global list of all task quests. Skip world quests entirely
    -- (GetTaskQuestsForMap below is authoritative). For non-WQ tasks (bonus objectives),
    -- require map match + IsActive.
    if _G.GetTasksTable and type(_G.GetTasksTable) == "function" then
        local ok, tasks = pcall(_G.GetTasksTable)
        if ok and tasks and type(tasks) == "table" then
            for _, entry in pairs(tasks) do
                local questID = (type(entry) == "number" and entry) or (type(entry) == "table" and entry and entry.questID)
                if questID and type(questID) == "number" and questID > 0 then
                    -- Skip world quests: GetTasksTable can hold stale WQ entries.
                    local isWQ = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID)
                    if not isWQ and IsTaskQuestCurrentlyActive(questID) then
                        local onMap = not mapIDsToCheck or IsTaskQuestOnPlayerMaps(questID, mapIDSet)
                        if onMap then
                            nearbySet[questID] = true
                            taskQuestOnlySet[questID] = true
                        end
                    end
                end
            end
        end
    end

    if not C_Map or not C_Map.GetBestMapForUnit or not C_QuestLog.GetQuestsOnMap then return nearbySet, taskQuestOnlySet end
    if not mapIDsToCheck then return nearbySet, taskQuestOnlySet end

    for _, checkMapID in ipairs(mapIDsToCheck) do
        -- C_QuestLog.GetQuestsOnMap: regular quest map pins (accepted quests with POI locations).
        -- Skip any world/task quests; they come from C_TaskQuest APIs below.
        -- Use POI mapID to verify the quest is genuinely on one of our maps.
        local onMap = C_QuestLog.GetQuestsOnMap(checkMapID)
        if onMap then
            for _, info in ipairs(onMap) do
                if info.questID then
                    -- Identify world/bonus/task quests by multiple methods and skip them.
                    local isWQ = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(info.questID)
                    if not isWQ and C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
                        local qc = C_QuestInfoSystem.GetQuestClassification(info.questID)
                        if qc == Enum.QuestClassification.WorldQuest or qc == Enum.QuestClassification.BonusObjective then
                            isWQ = true
                        end
                    end
                    local isTask = not isWQ and C_TaskQuest and C_TaskQuest.IsActive and C_TaskQuest.IsActive(info.questID)
                    if not isWQ and not isTask then
                        nearbySet[info.questID] = true
                    end
                end
            end
        end

        -- C_TaskQuest.GetQuestsOnMap: authoritative source for active task/world quests.
        -- We already requested quests for checkMapID, so results belong to this map
        -- or its sub-areas. Only gate: IsTaskQuestCurrentlyActive (IsActive + time-left + not completed).
        if addon.GetTaskQuestsForMap then
            local taskPOIs = addon.GetTaskQuestsForMap(checkMapID, checkMapID) or addon.GetTaskQuestsForMap(checkMapID)
            if taskPOIs then
                for _, poi in ipairs(taskPOIs) do
                    local questID = (type(poi) == "table" and (poi.questID or poi.questId)) or (type(poi) == "number" and poi)
                    if questID and type(questID) == "number" and questID > 0 then
                        if IsTaskQuestCurrentlyActive(questID) then
                            nearbySet[questID] = true
                            taskQuestOnlySet[questID] = true
                        end
                    end
                end
            end
        end
    end

    -- Waypoint-based fallback: only when next waypoint is on the player's exact map (not parent),
    -- so we don't pull in quests from other zones that share a hub.
    -- Skip world/task quests here; they are handled by the C_TaskQuest path above.
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
                -- World quests in the waypoint path must also pass active validation.
                local isWQ = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID)
                if isWQ and not IsTaskQuestCurrentlyActive(questID) then
                    -- stale WQ; skip
                else
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
        addon.focus.lastWorldQuestWatchSet = addon.focus.lastWorldQuestWatchSet or {}
        wipe(addon.focus.lastWorldQuestWatchSet)
        local numWorldWatches = C_QuestLog.GetNumWorldQuestWatches()
        for i = 1, numWorldWatches do
            local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
            if questID and not seen[questID] and IsTaskQuestCurrentlyActive(questID) then
                seen[questID] = true
                addon.focus.lastWorldQuestWatchSet[questID] = true
                out[#out + 1] = { questID = questID, isTracked = true }
            end
        end
    end
    if addon.wqtTrackedQuests then
        for questID, _ in pairs(addon.wqtTrackedQuests) do
            if not seen[questID] and IsTaskQuestCurrentlyActive(questID) then
                seen[questID] = true
                out[#out + 1] = { questID = questID, isTracked = true }
            end
        end
    end
    if nearbySet and (addon.IsQuestWorldQuest or C_QuestLog.IsWorldQuest) then
        local recentlyUntracked = addon.focus.recentlyUntrackedWorldQuests
        local ids = {}
        for questID, _ in pairs(nearbySet) do
            if not seen[questID] and (not recentlyUntracked or not recentlyUntracked[questID]) then
                local isWorld = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) or (C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID))
                local isCalling = C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)
                local qc = C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification and C_QuestInfoSystem.GetQuestClassification(questID)
                local isCampaign = (qc == Enum.QuestClassification.Campaign)
                local isRecurring = (qc == Enum.QuestClassification.Recurring)
                if isCampaign or isRecurring then
                    if isCalling then ids[#ids + 1] = questID end
                elseif isCalling then
                    ids[#ids + 1] = questID
                elseif isWorld then
                    -- Use the unified active check: IsActive + time-left + not completed.
                    if IsTaskQuestCurrentlyActive(questID) then
                        ids[#ids + 1] = questID
                    end
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

--- Provider: returns world quests and callings from GetWorldAndCallingQuestIDsToShow in aggregator format.
-- Blacklist and zone filtering are applied by the aggregator.
local function CollectWorldQuests(ctx)
    local nearbySet = ctx.nearbySet or {}
    local taskQuestOnlySet = ctx.taskQuestOnlySet or {}
    local raw = GetWorldAndCallingQuestIDsToShow(nearbySet, taskQuestOnlySet)
    local out = {}
    for _, entry in ipairs(raw) do
        out[#out + 1] = {
            questID = entry.questID,
            opts = { isTracked = entry.isTracked, isInQuestArea = entry.isInQuestArea, forceCategory = entry.forceCategory }
        }
    end
    return out
end

local function RemoveWorldQuestWatch(questID)
    if not questID then return end
    if (addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID)) and C_QuestLog.RemoveWorldQuestWatch then
        C_QuestLog.RemoveWorldQuestWatch(questID)
    end
end

local function GetNearbyDebugInfo()
    local lines = {}
    if not C_Map or not C_Map.GetBestMapForUnit then
        lines[#lines + 1] = "C_Map.GetBestMapForUnit not available."
        return lines
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(mapID)
        lines[#lines + 1] = ("GetBestMapForUnit mapID: %s, name: %s"):format(tostring(mapID), info and (info.name or "nil") or "nil")
        if info then
            lines[#lines + 1] = ("  mapType: %s, parentMapID: %s"):format(tostring(info.mapType), tostring(info.parentMapID or "nil"))
        end
    else
        lines[#lines + 1] = "GetBestMapForUnit returned nil or GetMapInfo not available."
    end
    if GetZoneText then
        lines[#lines + 1] = ("GetZoneText: %s"):format(tostring(GetZoneText()))
    end
    if GetSubZoneText then
        lines[#lines + 1] = ("GetSubZoneText: %s"):format(tostring(GetSubZoneText()))
    end
    if GetMinimapZoneText then
        lines[#lines + 1] = ("GetMinimapZoneText: %s"):format(tostring(GetMinimapZoneText()))
    end
    lines[#lines + 1] = ("IsDelveActive: %s"):format((addon.IsDelveActive and addon.IsDelveActive()) and "true" or "false")
    lines[#lines + 1] = ("IsInPartyDungeon: %s"):format((addon.IsInPartyDungeon and addon.IsInPartyDungeon()) and "true" or "false")
    if addon.GetPlayerCurrentZoneName then
        local currentZone = addon.GetPlayerCurrentZoneName()
        lines[#lines + 1] = ("GetPlayerCurrentZoneName (resolved): %s"):format(tostring(currentZone or "nil"))
    end
    return lines
end

addon.GetNearbyQuestIDs          = GetNearbyQuestIDs
addon.GetNearbyDebugInfo         = GetNearbyDebugInfo
addon.GetWorldAndCallingQuestIDsToShow = GetWorldAndCallingQuestIDsToShow
addon.CollectWorldQuests         = CollectWorldQuests
addon.GetCurrentWorldQuestWatchSet = GetCurrentWorldQuestWatchSet
addon.RemoveWorldQuestWatch      = RemoveWorldQuestWatch
