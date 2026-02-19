--[[
    Horizon Suite - Focus - Delve Provider
    C_PartyInfo.IsDelveInProgress, CVar lastSelectedDelvesTier. Delve quest collection.
]]

local addon = _G.HorizonSuite

--- True when the player is in an active Delve (guarded API).
local function IsDelveActive()
    if C_PartyInfo and C_PartyInfo.IsDelveInProgress then
        local ok, inDelve = pcall(C_PartyInfo.IsDelveInProgress)
        if ok and inDelve then return true end
    end
    return false
end

--- Current Delve tier (1-11) or nil if unknown/not in delve. Guarded API.
local function GetActiveDelveTier()
    if not IsDelveActive() then return nil end
    if GetCVarNumberOrDefault then
        local ok, cvarTier = pcall(GetCVarNumberOrDefault, "lastSelectedDelvesTier")
        if ok and type(cvarTier) == "number" and cvarTier >= 1 and cvarTier <= 11 then
            return cvarTier
        end
    end
    return nil
end

--- Returns nearby quests on the delve map when in a Delve. Only adds quests whose map matches player map.
local function CollectDelveQuests(ctx)
    if not IsDelveActive() then return {} end
    local playerMapID = (C_Map and C_Map.GetBestMapForUnit) and C_Map.GetBestMapForUnit("player") or nil
    local mapInfo = (playerMapID and C_Map and C_Map.GetMapInfo) and C_Map.GetMapInfo(playerMapID) or nil
    local mapType = mapInfo and mapInfo.mapType
    local isInstanceMap = (mapType == 4 or mapType == 5)  -- 4 = Dungeon, 5 = Micro (Delve)
    if not playerMapID or not isInstanceMap then return {} end

    local out = {}
    local nearbySet = ctx.nearbySet or {}
    local seen = ctx.seen or {}
    for questID, _ in pairs(nearbySet) do
        if not seen[questID] and not addon.IsQuestWorldQuest(questID) then
            if not (C_QuestLog.IsQuestCalling and C_QuestLog.IsQuestCalling(questID)) then
                -- Only show quests the player actually has in their log
                local logIdx = C_QuestLog.GetLogIndexForQuestID(questID)
                if logIdx then
                    local info = C_QuestLog.GetInfo and C_QuestLog.GetInfo(logIdx)
                    if info and not info.isHidden then
                        out[#out + 1] = { questID = questID, opts = { isTracked = false, forceCategory = "DELVES" } }
                    end
                end
            end
        end
    end
    return out
end

addon.IsDelveActive        = IsDelveActive
addon.GetActiveDelveTier   = GetActiveDelveTier
addon.CollectDelveQuests   = CollectDelveQuests
