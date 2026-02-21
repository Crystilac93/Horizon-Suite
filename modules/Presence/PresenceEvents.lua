--[[
    Horizon Suite - Presence - Event Dispatch
    Zone changes, level up, boss emotes, achievements, quest events.
    APIs: C_QuestLog, C_ScenarioInfo, C_SuperTrack, C_Timer, GetZoneText, GetSubZoneText, GetAchievementInfo.
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

--- Normalize quest update text to "X/Y Objective" format.
--- @param s string Raw text (e.g. "Burn Deepsflayer Nests: 3/6", "Objective (3/5)")
--- @return string
local function NormalizeQuestUpdateText(s)
    if not s or s == "" then return s or "" end
    s = strtrim(s)
    -- Already "X/Y ..." at start
    if s:match("^%d+/%d+%s") then return s end
    -- "Text: X/Y" -> "X/Y Text"
    local text, x, y = s:match("^(.+):%s*(%d+)/(%d+)$")
    if text and x and y then return ("%s/%s %s"):format(x, y, strtrim(text)) end
    -- "Text (X/Y)" -> "X/Y Text"
    local text2, x2, y2 = s:match("^(.+)%s*%((%d+)/(%d+)%)$")
    if text2 and x2 and y2 then return ("%s/%s %s"):format(x2, y2, strtrim(text2)) end
    return s
end

-- ============================================================================
-- Quest text detection (private)
-- ============================================================================

--- Returns true if the quest title is a Blizzard DNT (Do Not Translate) internal quest.
--- @param questName string|nil Quest title from C_QuestLog.GetTitleForQuestID
--- @return boolean
local function IsDNTQuest(questName)
    return questName and questName:match("^%[DNT%]")
end

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

--- True when we should suppress non-essential Presence notifications in Mythic+ (zone, quest, scenario).
local function ShouldSuppressInMplus()
    return addon.GetDB and addon.GetDB("presenceSuppressZoneInMplus", true) and addon.IsInMythicDungeon and addon.IsInMythicDungeon()
end

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
    if addon.GetDB and not addon.GetDB("presenceLevelUp", true) then return end
    local L = addon.L or {}
    addon.Presence.QueueOrPlay("LEVEL_UP", L["LEVEL UP"], L["You have reached level %s"]:format(level or "??"))
end

local function OnRaidBossEmote(_, msg, unitName)
    if addon.GetDB and not addon.GetDB("presenceBossEmote", true) then return end
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
    if addon.GetDB and not addon.GetDB("presenceAchievement", true) then return end
    local _, name = GetAchievementInfo(achID)
    local L = addon.L or {}
    addon.Presence.QueueOrPlay("ACHIEVEMENT", L["ACHIEVEMENT EARNED"], StripPresenceMarkup(name or ""))
end

local function OnQuestAccepted(_, questID)
    if addon.GetDB and not addon.GetDB("presenceQuestEvents", true) then return end
    if ShouldSuppressInMplus() then return end
    local opts = (questID and { questID = questID }) or {}
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local questName = StripPresenceMarkup(C_QuestLog.GetTitleForQuestID(questID) or "New Quest")
        if IsDNTQuest(questName) then return end
        if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
            local L = addon.L or {}
            addon.Presence.QueueOrPlay("WORLD_QUEST_ACCEPT", L["WORLD QUEST ACCEPTED"], questName, opts)
        else
            local L = addon.L or {}
            addon.Presence.QueueOrPlay("QUEST_ACCEPT", L["QUEST ACCEPTED"], questName, opts)
        end
    else
        local L = addon.L or {}
        addon.Presence.QueueOrPlay("QUEST_ACCEPT", L["QUEST ACCEPTED"], L["New Quest"], opts)
    end
end

local function OnQuestTurnedIn(_, questID)
    if addon.GetDB and not addon.GetDB("presenceQuestEvents", true) then return end
    if ShouldSuppressInMplus() then return end
    local opts = (questID and { questID = questID }) or {}
    local questName = "Objective"
    if C_QuestLog then
        if C_QuestLog.GetTitleForQuestID then
            questName = StripPresenceMarkup(C_QuestLog.GetTitleForQuestID(questID) or questName)
        end
        if IsDNTQuest(questName) then return end
        if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
            local L = addon.L or {}
            addon.Presence.QueueOrPlay("WORLD_QUEST", L["WORLD QUEST"], questName, opts)
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
local ZERO_PROGRESS_RETRY_TIME = 0.45 -- Re-sample when we get 0/X (meta quests like "0/8 WQs" may lag; fix for stale 0/8 after completion)

-- Process debounced quest objective update; shows QUEST_UPDATE or skips if unchanged/blind.
--- @param questID number
--- @param isBlindUpdate boolean
--- @param source string|nil Event name for debug (e.g. QUEST_WATCH_UPDATE, QUEST_LOG_UPDATE, UI_INFO_MESSAGE)
--- @param isRetry boolean|nil True when this is a deferred re-sample after 0/X
local function ExecuteQuestUpdate(questID, isBlindUpdate, source, isRetry)
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

    -- 6. Normalize to "X/Y Objective"
    local stripped = StripPresenceMarkup(msg)
    local normalized = NormalizeQuestUpdateText(stripped)

    -- 7. Re-sample when we get 0/X from QUEST_WATCH_UPDATE (meta quests like "0/8 WQs completed"
    --    often lag; client may not have updated yet when we first sample after completion).
    if not isRetry and source == "QUEST_WATCH_UPDATE" and normalized and normalized:match("^0/%d+") then
        lastQuestObjectivesCache[questID] = nil -- Roll back cache so retry sees "changed"
        bufferedUpdates[questID] = C_Timer.After(ZERO_PROGRESS_RETRY_TIME, function()
            ExecuteQuestUpdate(questID, isBlindUpdate, source, true)
        end)
        DbgWQ("ExecuteQuestUpdate: Deferred 0/X retry", questID)
        return
    end

    -- 8. Trigger notification
    if addon.GetDB and not addon.GetDB("presenceQuestEvents", true) then return end
    if ShouldSuppressInMplus() then return end
    local L = addon.L or {}
    addon.Presence.QueueOrPlay("QUEST_UPDATE", L["QUEST UPDATE"], normalized, { questID = questID, source = source })
    DbgWQ("ExecuteQuestUpdate: Shown", questID, msg)
end

-- Entry point for requesting an update. Resets the timer to ensure we only process the *final* state.
--- @param questID number
--- @param isBlindUpdate boolean
--- @param source string|nil Event name for debug (e.g. QUEST_WATCH_UPDATE, QUEST_LOG_UPDATE, UI_INFO_MESSAGE)
local function RequestQuestUpdate(questID, isBlindUpdate, source)
    if not questID then return end

    -- Cancel existing timer for this quest (debounce)
    if bufferedUpdates[questID] then
        bufferedUpdates[questID]:Cancel()
    end

    -- Schedule new timer
    bufferedUpdates[questID] = C_Timer.After(UPDATE_BUFFER_TIME, function()
        ExecuteQuestUpdate(questID, isBlindUpdate, source)
    end)
end


-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function OnQuestWatchUpdate(_, questID)
    -- Direct update from the game for a specific quest. Not blind.
    RequestQuestUpdate(questID, false, "QUEST_WATCH_UPDATE")
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
        RequestQuestUpdate(questID, true, "QUEST_LOG_UPDATE")
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
            RequestQuestUpdate(questID, true, "UI_INFO_MESSAGE")
        else
            -- Fallback for non-mapped messages (standard throttle)
            -- Suppress when debounced path has pending update (prefer QUEST_WATCH_UPDATE)
            local hasPendingUpdate = false
            for _, t in pairs(bufferedUpdates) do
                if t then hasPendingUpdate = true break end
            end
            if hasPendingUpdate then return end
            if addon.GetDB and not addon.GetDB("presenceQuestEvents", true) then return end
            if ShouldSuppressInMplus() then return end

            local now = GetTime()
            if lastUIInfoMsg == msg and (now - lastUIInfoTime) < UI_MSG_THROTTLE then return end
            lastUIInfoMsg, lastUIInfoTime = msg, now

            local stripped = StripPresenceMarkup(msg or "")
            local normalized = NormalizeQuestUpdateText(stripped)
            local L = addon.L or {}
            addon.Presence.QueueOrPlay("QUEST_UPDATE", L["QUEST UPDATE"], normalized, { source = "UI_INFO_MESSAGE" })
        end
    end
end

-- ============================================================================
-- SCENARIO & ZONE LOGIC
-- ============================================================================

local wasInScenario = false
local scenarioCheckPending = false
local SCENARIO_DEBOUNCE = 0.4

-- Scenario criteria update (delve/scenario objective progress toasts)
local lastScenarioCriteriaCache = nil
local lastScenarioObjectives = nil
local scenarioCriteriaUpdateTimer = nil
local SCENARIO_UPDATE_BUFFER_TIME = 0.35

--- Fetch main-step criteria from C_ScenarioInfo; build state key and objectives list.
--- Per Blizzard ScenarioInfoDocumentation: description, completed, quantity, totalQuantity, quantityString, criteriaID.
--- @return string|nil stateKey, table objectives
local function GetMainStepCriteria()
    if not C_Scenario or not C_Scenario.GetStepInfo then return nil, {} end
    local t = { pcall(C_Scenario.GetStepInfo) }
    if not t[1] or not t[2] then return nil, {} end
    local numCriteria = t[4] or t[3] or t[5]
    local maxIdx = math.max((numCriteria or 0), 1) + 3
    local parts = {}
    local objectives = {}
    for criteriaIndex = 0, maxIdx do
        local cOk, criteriaInfo = false, nil
        if C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo then
            cOk, criteriaInfo = pcall(C_ScenarioInfo.GetCriteriaInfo, criteriaIndex)
        end
        if (not cOk or not criteriaInfo) and C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfoByStep then
            cOk, criteriaInfo = pcall(C_ScenarioInfo.GetCriteriaInfoByStep, 1, criteriaIndex)
        end
        if cOk and criteriaInfo then
            local text = (criteriaInfo.description and criteriaInfo.description ~= "") and criteriaInfo.description
                or (criteriaInfo.quantityString and criteriaInfo.quantityString ~= "") and criteriaInfo.quantityString or ""
            local finished = criteriaInfo.complete or criteriaInfo.completed or false
            local qty = criteriaInfo.quantity
            local total = criteriaInfo.totalQuantity
            local hasQty = qty ~= nil and total ~= nil and type(qty) == "number" and type(total) == "number" and total > 0
            local criteriaID = (criteriaInfo.criteriaID ~= nil) and criteriaInfo.criteriaID or criteriaIndex
            parts[#parts + 1] = (text or "") .. "|" .. (finished and "1" or "0") .. "|" .. (hasQty and qty or "") .. "|" .. (hasQty and total or "")
            objectives[#objectives + 1] = {
                criteriaID = criteriaID,
                text = text ~= "" and text or nil,
                quantityString = (criteriaInfo.quantityString and criteriaInfo.quantityString ~= "") and criteriaInfo.quantityString or nil,
                finished = finished,
                numFulfilled = hasQty and qty or nil,
                numRequired = hasQty and total or nil,
            }
        end
    end
    return table.concat(parts, ";"), objectives
end

--- Build display string for an objective. Prefers Blizzard quantityString when present (completed).
local function formatObjectiveMsg(o)
    if not o then return nil end
    if o.quantityString and o.quantityString ~= "" and o.quantityString ~= "0" then
        return o.quantityString
    end
    if o.text and o.text ~= "" and o.text ~= "0" then
        if o.numFulfilled ~= nil and o.numRequired ~= nil and o.numRequired > 0 then
            return ("%s (%d/%d)"):format(o.text, o.numFulfilled, o.numRequired)
        end
        return o.text
    end
    if o.numFulfilled ~= nil and o.numRequired ~= nil and o.numRequired > 0 then
        return ("%d/%d"):format(o.numFulfilled, o.numRequired)
    end
    return nil
end

--- Process debounced scenario criteria update; shows SCENARIO_UPDATE or skips if unchanged.
local function ExecuteScenarioCriteriaUpdate()
    scenarioCriteriaUpdateTimer = nil
    if not addon.IsScenarioActive or not addon.IsScenarioActive() then return end
    if ShouldSuppressInMplus() then return end
    if addon.GetDB and not addon.GetDB("showScenarioEvents", true) then return end
    if not addon.GetScenarioDisplayInfo then return end

    local stateKey, objectives = GetMainStepCriteria()
    if not stateKey or stateKey == "" then return end

    if lastScenarioCriteriaCache == stateKey then return end

    local oldObjectives = lastScenarioObjectives
    lastScenarioCriteriaCache = stateKey
    lastScenarioObjectives = objectives

    local msg = nil
    -- Match by criteriaID (per Blizzard API) so we correctly identify which objective completed when list order changes.
    if oldObjectives and #oldObjectives > 0 then
        local oldByID = {}
        local newByID = {}
        for _, o in ipairs(oldObjectives) do
            if o.criteriaID ~= nil then oldByID[o.criteriaID] = o end
        end
        for _, o in ipairs(objectives) do
            if o.criteriaID ~= nil then newByID[o.criteriaID] = o end
        end

        -- Completed: old not finished, new finished (same criteriaID)
        for id, newO in pairs(newByID) do
            local oldO = oldByID[id]
            if oldO and not oldO.finished and newO.finished then
                msg = formatObjectiveMsg(newO)
                break
            end
        end
        -- Progressed: numFulfilled changed
        if not msg then
            for id, newO in pairs(newByID) do
                local oldO = oldByID[id]
                if oldO and oldO.numFulfilled ~= newO.numFulfilled then
                    msg = formatObjectiveMsg(newO)
                    break
                end
            end
        end
        -- Removed as completed: old existed, not finished, no longer in new
        if not msg then
            for id, oldO in pairs(oldByID) do
                if not oldO.finished and not newByID[id] then
                    msg = formatObjectiveMsg(oldO)
                    break
                end
            end
        end
        -- New: added (no old with same ID)
        if not msg then
            for id, newO in pairs(newByID) do
                if not oldByID[id] then
                    msg = formatObjectiveMsg(newO)
                    break
                end
            end
        end
    end
    -- Fallback: index-based (when no oldObjectives or criteriaID matching found nothing)
    if not msg and oldObjectives then
        for i = 1, #objectives do
            local oldO = oldObjectives[i]
            local newO = objectives[i]
            if oldO and newO then
                local progressed = (oldO.numFulfilled ~= newO.numFulfilled)
                local finished = (not oldO.finished and newO.finished)
                local textChanged = (oldO.text ~= newO.text)
                if finished or progressed then
                    msg = formatObjectiveMsg(newO)
                    break
                elseif textChanged and not oldO.finished then
                    msg = formatObjectiveMsg(oldO) or formatObjectiveMsg(newO)
                    break
                end
            elseif not oldO and newO then
                msg = formatObjectiveMsg(newO)
                break
            end
        end
    end
    -- Fallback: first unfinished objective (first run, structure change, or no diff).
    if not msg then
        for i = 1, #objectives do
            local o = objectives[i]
            if o and not o.finished then
                msg = formatObjectiveMsg(o)
                if msg then break end
            end
        end
    end
    if not msg and #objectives > 0 then
        msg = formatObjectiveMsg(objectives[1])
    end
    if not msg or msg == "" or msg == "0" then msg = "Objective updated" end

    local title, _, category = addon.GetScenarioDisplayInfo()
    addon.Presence.QueueOrPlay("SCENARIO_UPDATE", StripPresenceMarkup(title or "Scenario"), StripPresenceMarkup(msg), { category = category or "SCENARIO", source = "SCENARIO_CRITERIA_UPDATE" })
end

--- Request a scenario criteria update; debounced.
local function RequestScenarioCriteriaUpdate()
    if scenarioCriteriaUpdateTimer then
        scenarioCriteriaUpdateTimer:Cancel()
    end
    scenarioCriteriaUpdateTimer = C_Timer.After(SCENARIO_UPDATE_BUFFER_TIME, ExecuteScenarioCriteriaUpdate)
end

local function TryShowScenarioStart()
    if scenarioCheckPending then return end
    if not addon.IsScenarioActive or not addon.IsScenarioActive() then return end
    if wasInScenario then return end
    -- Delve objective update feature disabled for now; zone entry already shows ZONE_CHANGE
    if addon.IsDelveActive and addon.IsDelveActive() then return end
    if ShouldSuppressInMplus() then return end
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
        -- Seed scenario criteria cache so first update has a baseline to diff against
        local seedKey, seedObjs = GetMainStepCriteria()
        if seedKey then
            lastScenarioCriteriaCache = seedKey
            lastScenarioObjectives = seedObjs
        end
        addon.Presence.QueueOrPlay("SCENARIO_START", StripPresenceMarkup(title), StripPresenceMarkup(subtitle or ""), { category = category, source = "SCENARIO_UPDATE" })
    end)
end

local function OnPlayerEnteringWorld()
    if not addon.Presence._scenarioInitDone then
        addon.Presence._scenarioInitDone = true
        -- Delve objective update disabled; don't treat delve as scenario for this flow
        local inScenario = addon.IsScenarioActive and addon.IsScenarioActive()
        if inScenario and addon.IsDelveActive and addon.IsDelveActive() then inScenario = false end
        wasInScenario = inScenario
    end
end

local function OnScenarioUpdate() TryShowScenarioStart() end

local function OnScenarioCriteriaUpdate()
    -- Delve objective update feature disabled; skip when in a delve
    if addon.IsDelveActive and addon.IsDelveActive() then return end
    TryShowScenarioStart()
    if wasInScenario then
        RequestScenarioCriteriaUpdate()
    end
end

local function OnScenarioCompleted()
    wasInScenario = false
    lastScenarioCriteriaCache = nil
    lastScenarioObjectives = nil
    if scenarioCriteriaUpdateTimer then
        scenarioCriteriaUpdateTimer:Cancel()
        scenarioCriteriaUpdateTimer = nil
    end
end

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
            local updateSub = sub
            if addon.IsDelveActive and addon.IsDelveActive() then
                local tier = addon.GetActiveDelveTier and addon.GetActiveDelveTier()
                if tier then updateSub = "Tier " .. tier end
            end
            addon.Presence.SoftUpdateSubtitle(updateSub)
            if addon.Presence.pendingDiscovery then
                addon.Presence.ShowDiscoveryLine()
                addon.Presence.pendingDiscovery = nil
            end
        else
            if addon.GetDB and not addon.GetDB("presenceZoneChange", true) then return end
            if ShouldSuppressInMplus() then return end
            local opts = {}
            local displaySub = sub
            if addon.IsDelveActive and addon.IsDelveActive() then
                opts.category = "DELVES"
                local tier = addon.GetActiveDelveTier and addon.GetActiveDelveTier()
                if tier then displaySub = "Tier " .. tier end
            elseif addon.IsInPartyDungeon and addon.IsInPartyDungeon() then
                opts.category = "DUNGEON"
            end
            opts.source = "ZONE_CHANGED_NEW_AREA"
            addon.Presence.QueueOrPlay("ZONE_CHANGE", StripPresenceMarkup(zone), StripPresenceMarkup(displaySub), opts)
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
                local updateSub = sub
                if addon.IsDelveActive and addon.IsDelveActive() then
                    local tier = addon.GetActiveDelveTier and addon.GetActiveDelveTier()
                    if tier then updateSub = "Tier " .. tier end
                end
                addon.Presence.SoftUpdateSubtitle(updateSub)
                if addon.Presence.pendingDiscovery then
                    addon.Presence.ShowDiscoveryLine()
                    addon.Presence.pendingDiscovery = nil
                end
            else
                -- In Delves, ZONE_CHANGE already showed delve+tier; suppress SUBZONE_CHANGE
                -- to avoid duplicate or inverted toast (parent/delve swap from GetZoneText/GetSubZoneText).
                if addon.IsDelveActive and addon.IsDelveActive() then return end
                if addon.GetDB and not addon.GetDB("presenceZoneChange", true) then return end
                if ShouldSuppressInMplus() then return end

                local opts = {}
                local displaySub = sub
                if addon.IsInPartyDungeon and addon.IsInPartyDungeon() then
                    opts.category = "DUNGEON"
                end
                opts.source = "ZONE_CHANGED"
                addon.Presence.QueueOrPlay("SUBZONE_CHANGE", StripPresenceMarkup(zone), StripPresenceMarkup(displaySub), opts)
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

addon.Presence.EnableEvents           = EnableEvents
addon.Presence.DisableEvents         = DisableEvents
addon.Presence.IsQuestText           = IsQuestText
addon.Presence.NormalizeQuestUpdateText = NormalizeQuestUpdateText
addon.Presence.eventFrame            = eventFrame
