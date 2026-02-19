--[[
    Horizon Suite - Focus - Daily/Weekly Provider
    C_QuestInfoSystem.GetQuestClassification + Enum.QuestFrequency. Zone-based daily/weekly detection.
]]

local addon = _G.HorizonSuite

--- Returns weeklies and dailies in zone (nearbySet). Each has questID and opts.forceCategory ("WEEKLY" or "DAILY").
-- Blacklist filtering is applied by the aggregator.
local function CollectDailiesWeeklies(ctx)
    local nearbySet = ctx.nearbySet or {}
    local out = {}
    if not nearbySet or not C_QuestInfoSystem or not C_QuestInfoSystem.GetQuestClassification then return out end

    local ids = {}
    for questID, _ in pairs(nearbySet) do
        if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
            -- Skip world quests; handled by CollectWorldQuests.
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
                ids[#ids + 1] = { questID = questID, opts = { isTracked = false, forceCategory = "WEEKLY" } }
            elseif isDaily then
                ids[#ids + 1] = { questID = questID, opts = { isTracked = false, forceCategory = "DAILY" } }
            end
        end
    end
    table.sort(ids, function(a, b) return a.questID < b.questID end)
    for _, e in ipairs(ids) do
        out[#out + 1] = e
    end
    return out
end

addon.CollectDailiesWeeklies = CollectDailiesWeeklies
