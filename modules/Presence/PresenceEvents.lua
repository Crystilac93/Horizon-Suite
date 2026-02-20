--[[
    Horizon Suite - Presence - Event Dispatch
    Zone changes, level up, boss emotes, achievements, quest events.
    APIs: C_QuestLog, C_SuperTrack, C_Timer, GetZoneText, GetSubZoneText, GetAchievementInfo.
    Step-by-step flow notes: notes/PresenceEvents.md
]]

local addon = _G.HorizonSuite
if not addon or not addon.Presence then return end

-- Temporary diagnostics for debugging.
local PRESENCE_DEBUG_WQ = false
local function DbgWQ(...)
    if not PRESENCE_DEBUG_WQ or not addon.HSPrint then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    addon.HSPrint("[Presence WQ] " .. table.concat(parts, " "))
end

-- ============================================================================
-- FORMATTING & MARKUP
-- ============================================================================

local function StripPresenceMarkup(s)
    if not s or s == "" then return s or "" end
    s = s:gsub("|T.-|t", "")
    s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
    s = s:gsub("|r", "")
    return strtrim(s)
end

-- ============================================================================
-- Quest text detection (private)
-- ============================================================================

--- Returns true if the message looks like quest objective progress (e.g. "7/10", "slain", "Complete").
--- @param msg string|nil Message text to check
--- @return boolean
local function IsQuestText(msg)
    if not msg then return false end
    return msg:find("%d+/%d+")
        or msg:find("%%")
        or msg:find("slain")
        or msg:find("destroyed")
        or msg:find("Quest Accepted")
        or msg:find("Complete")
end

-- ============================================================================
-- Event frame and handlers
-- ============================================================================

local eventFrame = CreateFrame("Frame")
local eventsRegistered = false

local PRESENCE_EVENTS = {
    "ADDON_LOADED",
    "ZONE_CHANGED",
    "ZONE_CHANGED_INDOORS",
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_LEVEL_UP",
    "RAID_BOSS_EMOTE",
    "ACHIEVEMENT_EARNED",
    "QUEST_ACCEPTED",
    "QUEST_TURNED_IN",
    "QUEST_WATCH_UPDATE",
    "QUEST_LOG_UPDATE",
    "UI_INFO_MESSAGE",
    "PLAYER_ENTERING_WORLD",
    "SCENARIO_UPDATE",
    "SCENARIO_CRITERIA_UPDATE",
    "SCENARIO_COMPLETED",
}

local function OnAddonLoaded(addonName)
    if addonName == "Blizzard_WorldQuestComplete" and addon.Presence.KillWorldQuestBanner then
        C_Timer.After(0, function()
            addon.Presence.KillWorldQuestBanner()
        end)
        C_Timer.After(0.5, function()
            addon.Presence.KillWorldQuestBanner()
            eventFrame:UnregisterEvent("ADDON_LOADED")
        end)
    end
end

local function OnPlayerLevelUp(_, level)
    addon.Presence.QueueOrPlay("LEVEL_UP", "LEVEL UP", "You have reached level " .. (level or "??"))
end

local function OnRaidBossEmote(_, msg, unitName)
    local bossName = unitName or "Boss"
    local formatted = msg or ""
    formatted = formatted:gsub("|T.-|t", "")
    formatted = formatted:gsub("|c%x%x%x%x%x%x%x%x", "")
    formatted = formatted:gsub("|r", "")
    formatted = formatted:gsub("%%s", bossName)
    formatted = strtrim(formatted)
    addon.Presence.QueueOrPlay("BOSS_EMOTE", bossName, formatted)
end

local function OnAchievementEarned(_, achID)
    local _, name = GetAchievementInfo(achID)
    addon.Presence.QueueOrPlay("ACHIEVEMENT", "ACHIEVEMENT EARNED", StripPresenceMarkup(name or ""))
end

local function OnQuestAccepted(_, questID)
    local opts = (questID and { questID = questID }) or {}
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local questName = StripPresenceMarkup(C_QuestLog.GetTitleForQuestID(questID) or "New Quest")
        if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
            addon.Presence.QueueOrPlay("WORLD_QUEST_ACCEPT", "WORLD QUEST ACCEPTED", questName, opts)
        else
            addon.Presence.QueueOrPlay("QUEST_ACCEPT", "QUEST ACCEPTED", questName, opts)
        end
    else
        addon.Presence.QueueOrPlay("QUEST_ACCEPT", "QUEST ACCEPTED", "New Quest", opts)
    end
end

local function OnQuestTurnedIn(_, questID)
    local opts = (questID and { questID = questID }) or {}
    local questName = "Objective"
    if C_QuestLog then
        if C_QuestLog.GetTitleForQuestID then
            questName = StripPresenceMarkup(C_QuestLog.GetTitleForQuestID(questID) or questName)
        end
        if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
            addon.Presence.QueueOrPlay("WORLD_QUEST", "WORLD QUEST", questName, opts)
            return
        end
    end
    addon.Presence.QueueOrPlay("QUEST_COMPLETE", "QUEST COMPLETE", questName, opts)
end

-- ============================================================================
-- QUEST UPDATE LOGIC (DEBOUNCED)
-- ============================================================================

local lastQuestObjectivesCache = {}  -- questID -> serialized objectives
local bufferedUpdates = {}           -- questID -> timerObject
local UPDATE_BUFFER_TIME = 0.35      -- Time to wait for data to settle (fix for 55/100 vs 71/100)

-- Process debounced quest objective update; shows QUEST_UPDATE or skips if unchanged/blind.
local function ExecuteQuestUpdate(questID, isBlindUpdate)
    bufferedUpdates[questID] = nil -- Clear the timer ref

    if not questID or questID <= 0 then return end
    
    -- Note: We removed the IsComplete check here so 8/8 progress can show before the quest turn-in event takes over.
    
    -- 1. Fetch current objectives
    local objectives = (C_QuestLog and C_QuestLog.GetQuestObjectives) and (C_QuestLog.GetQuestObjectives(questID) or {}) or {}
    
    -- If no objectives (quest vanished/completed fully), abort.
    if #objectives == 0 then return end

    -- 2. Build state string
    local parts = {}
    for i = 1, #objectives do
        local o = objectives[i]
        parts[i] = (o and o.text or "") .. "|" .. (o and o.finished and "1" or "0")
    end
    local objKey = table.concat(parts, ";")

    -- 3. Compare with cache
    if lastQuestObjectivesCache[questID] == objKey then
        DbgWQ("ExecuteQuestUpdate: Unchanged", questID)
        return 
    end

    -- 4. Check for Blind Update Suppression (Fix for unrelated quests)
    -- If this is a blind update (guessed ID) AND we have no history of this quest, assume it's just initialization.
    local isNew = (lastQuestObjectivesCache[questID] == nil)
    lastQuestObjectivesCache[questID] = objKey -- Update cache now

    if isBlindUpdate and isNew then
        DbgWQ("ExecuteQuestUpdate: Suppressed blind new entry", questID)
        return
    end

    -- 5. Find the text to display
    local msg = nil
    for i = 1, #objectives do
        local o = objectives[i]
        -- Prioritize the first unfinished objective with text
        if o and o.text and o.text ~= "" and not o.finished then
            msg = o.text
            break
        end
    end
    -- Fallback: Use any text if everything is finished (e.g. 8/8)
    if not msg and #objectives > 0 then
        local o = objectives[1]
        if o and o.text and o.text ~= "" then msg = o.text end
    end
    
    if not msg or msg == "" then msg = "Objective updated" end

    -- 6. Trigger notification
    addon.Presence.QueueOrPlay("QUEST_UPDATE", "QUEST UPDATE", StripPresenceMarkup(msg), { questID = questID })
    DbgWQ("ExecuteQuestUpdate: Shown", questID, msg)
end

-- Entry point for requesting an update. Resets the timer to ensure we only process the *final* state.
local function RequestQuestUpdate(questID, isBlindUpdate)
    if not questID then return end
    
    -- Cancel existing timer for this quest (debounce)
    if bufferedUpdates[questID] then
        bufferedUpdates[questID]:Cancel()
    end
    
    -- Schedule new timer
    bufferedUpdates[questID] = C_Timer.After(UPDATE_BUFFER_TIME, function()
        ExecuteQuestUpdate(questID, isBlindUpdate)
    end)
end


-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function OnQuestWatchUpdate(_, questID)
    -- Direct update from the game for a specific quest. Not blind.
    RequestQuestUpdate(questID, false)
end

-- Guess active WQ ID for blind QUEST_LOG_UPDATE/UI_INFO_MESSAGE (super-tracked or nearby).
local function GetWorldQuestIDForObjectiveUpdate()
    local super = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID) and C_SuperTrack.GetSuperTrackedQuestID() or 0
    if super and super > 0 and addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(super) then
        if not (C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(super)) then
            return super
        end
    end
    -- 2. Nearby Tracked
    if addon.ReadTrackedQuests then
        local candidates = {}
        for _, q in ipairs(addon.ReadTrackedQuests()) do
            if q.questID and (q.category == "WORLD" or q.category == "CALLING") and not q.isComplete and q.isNearby then
                candidates[#candidates + 1] = q.questID
            end
        end
        if #candidates > 0 then return candidates[1] end
    end
    return nil
end

local function OnQuestLogUpdate()
    if addon.Presence._suppressQuestUpdateOnReload then return end
    
    -- Blind scan: we don't know exactly which quest changed, so we guess the active WQ.
    local questID = GetWorldQuestIDForObjectiveUpdate()
    if questID then
        -- Pass true for isBlindUpdate to suppress popup if we've never seen this quest before
        RequestQuestUpdate(questID, true)
    end
end

local lastUIInfoMsg, lastUIInfoTime = nil, 0
local UI_MSG_THROTTLE = 1.0

local function OnUIInfoMessage(_, msgType, msg)
    if IsQuestText(msg) and not (msg and (msg:find("Quest Accepted") or msg:find("Accepted"))) then
        -- Try to map this message to the active WQ
        local questID = GetWorldQuestIDForObjectiveUpdate()
        
        if questID then
            -- If we have an ID, use the standard update path (it handles debounce/cache)
            RequestQuestUpdate(questID, true)
        else
            -- Fallback for non-mapped messages (standard throttle)
            local now = GetTime()
            if lastUIInfoMsg == msg and (now - lastUIInfoTime) < UI_MSG_THROTTLE then return end
            lastUIInfoMsg, lastUIInfoTime = msg, now
            addon.Presence.QueueOrPlay("QUEST_UPDATE", "QUEST UPDATE", StripPresenceMarkup(msg or ""), {})
        end
    end
end

-- ============================================================================
-- SCENARIO & ZONE LOGIC
-- ============================================================================

local wasInScenario = false
local scenarioCheckPending = false
local SCENARIO_DEBOUNCE = 0.4

local function TryShowScenarioStart()
    if scenarioCheckPending then return end
    if not addon.IsScenarioActive or not addon.IsScenarioActive() then return end
    if wasInScenario then return end
    if addon.GetDB and not addon.GetDB("showScenarioEvents", true) then return end
    if not addon.GetScenarioDisplayInfo then return end

    scenarioCheckPending = true
    C_Timer.After(SCENARIO_DEBOUNCE, function()
        scenarioCheckPending = false
        if not addon:IsModuleEnabled("presence") then return end
        if not addon.IsScenarioActive or not addon.IsScenarioActive() then return end
        if wasInScenario then return end
        if addon.GetDB and not addon.GetDB("showScenarioEvents", true) then return end

        local title, subtitle, category = addon.GetScenarioDisplayInfo()
        if not title or title == "" then return end

        wasInScenario = true
        addon.Presence.QueueOrPlay("SCENARIO_START", StripPresenceMarkup(title), StripPresenceMarkup(subtitle or ""), { category = category })
    end)
end

local function OnPlayerEnteringWorld()
    if not addon.Presence._scenarioInitDone then
        addon.Presence._scenarioInitDone = true
        wasInScenario = addon.IsScenarioActive and addon.IsScenarioActive()
    end
end

local function OnScenarioUpdate() TryShowScenarioStart() end
local function OnScenarioCriteriaUpdate() TryShowScenarioStart() end
local function OnScenarioCompleted() wasInScenario = false end

local function OnZoneChangedNewArea()
    local zone = GetZoneText() or "Unknown Zone"
    local sub  = GetSubZoneText() or ""
    local wait = addon.Presence.DISCOVERY_WAIT or 0.15
    C_Timer.After(wait, function()
        if not addon:IsModuleEnabled("presence") then return end
        local active = addon.Presence.active and addon.Presence.active()
        local activeTitle = addon.Presence.activeTitle and addon.Presence.activeTitle()
        local phase = addon.Presence.animPhase and addon.Presence.animPhase()
        if active and activeTitle == zone and (phase == "hold" or phase == "entrance") then
            addon.Presence.SoftUpdateSubtitle(sub)
            if addon.Presence.pendingDiscovery then
                addon.Presence.ShowDiscoveryLine()
                addon.Presence.pendingDiscovery = nil
            end
        else
            addon.Presence.QueueOrPlay("ZONE_CHANGE", StripPresenceMarkup(zone), StripPresenceMarkup(sub))
        end
    end)
end

local function OnZoneChanged()
    local sub = GetSubZoneText()
    if sub and sub ~= "" then
        local zone = GetZoneText() or ""
        local wait = addon.Presence.DISCOVERY_WAIT or 0.15
        C_Timer.After(wait, function()
            if not addon:IsModuleEnabled("presence") then return end
            local active = addon.Presence.active and addon.Presence.active()
            local activeTitle = addon.Presence.activeTitle and addon.Presence.activeTitle()
            local phase = addon.Presence.animPhase and addon.Presence.animPhase()
            if active and activeTitle == zone and (phase == "hold" or phase == "entrance") then
                addon.Presence.SoftUpdateSubtitle(sub)
                if addon.Presence.pendingDiscovery then
                    addon.Presence.ShowDiscoveryLine()
                    addon.Presence.pendingDiscovery = nil
                end
            else
                addon.Presence.QueueOrPlay("SUBZONE_CHANGE", StripPresenceMarkup(zone), StripPresenceMarkup(sub))
            end
        end)
    end
end

local eventHandlers = {
    ADDON_LOADED             = function(_, addonName) OnAddonLoaded(addonName) end,
    PLAYER_LEVEL_UP          = function(_, level) OnPlayerLevelUp(_, level) end,
    RAID_BOSS_EMOTE          = function(_, msg, unitName) OnRaidBossEmote(_, msg, unitName) end,
    ACHIEVEMENT_EARNED       = function(_, achID) OnAchievementEarned(_, achID) end,
    QUEST_ACCEPTED           = function(_, questID) OnQuestAccepted(_, questID) end,
    QUEST_TURNED_IN          = function(_, questID) OnQuestTurnedIn(_, questID) end,
    QUEST_WATCH_UPDATE       = function(_, questID) OnQuestWatchUpdate(_, questID) end,
    QUEST_LOG_UPDATE         = function() OnQuestLogUpdate() end,
    UI_INFO_MESSAGE          = function(_, msgType, msg) OnUIInfoMessage(_, msgType, msg) end,
    PLAYER_ENTERING_WORLD   = function() OnPlayerEnteringWorld() end,
    SCENARIO_UPDATE          = function() OnScenarioUpdate() end,
    SCENARIO_CRITERIA_UPDATE = function() OnScenarioCriteriaUpdate() end,
    SCENARIO_COMPLETED       = function() OnScenarioCompleted() end,
    ZONE_CHANGED_NEW_AREA    = function() OnZoneChangedNewArea() end,
    ZONE_CHANGED             = function() OnZoneChanged() end,
    ZONE_CHANGED_INDOORS     = function() OnZoneChanged() end,
}

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if not addon:IsModuleEnabled("presence") then return end
    local fn = eventHandlers[event]
    if fn then fn(event, ...) end
end)

--- Register all Presence events. Idempotent.
--- @return nil
local function EnableEvents()
    if eventsRegistered then return end
    for _, evt in ipairs(PRESENCE_EVENTS) do
        eventFrame:RegisterEvent(evt)
    end
    eventsRegistered = true
    addon.Presence._suppressQuestUpdateOnReload = true
    C_Timer.After(2, function()
        addon.Presence._suppressQuestUpdateOnReload = nil
    end)
end

--- Unregister all Presence events.
--- @return nil
local function DisableEvents()
    if not eventsRegistered then return end
    for _, evt in ipairs(PRESENCE_EVENTS) do
        eventFrame:UnregisterEvent(evt)
    end
    eventsRegistered = false
end

-- ============================================================================
-- Exports
-- ============================================================================

addon.Presence.EnableEvents  = EnableEvents
addon.Presence.DisableEvents = DisableEvents
addon.Presence.IsQuestText   = IsQuestText
addon.Presence.eventFrame    = eventFrame