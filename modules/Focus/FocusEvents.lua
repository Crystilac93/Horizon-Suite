--[[
    Horizon Suite - Focus - Event Dispatch
    Event frame, ScheduleRefresh, table-dispatch OnEvent, world-map watch-list sync,
    global API for Options.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- EVENT DISPATCH
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
eventFrame:RegisterEvent("QUEST_WATCH_UPDATE")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
eventFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
eventFrame:RegisterEvent("VIGNETTES_UPDATED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("SCENARIO_UPDATE")
eventFrame:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
eventFrame:RegisterEvent("SCENARIO_CRITERIA_SHOW_STATE_UPDATE")
eventFrame:RegisterEvent("SCENARIO_COMPLETED")
eventFrame:RegisterEvent("SCENARIO_SPELL_UPDATE")
eventFrame:RegisterEvent("CRITERIA_COMPLETE")
eventFrame:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE")
eventFrame:RegisterEvent("CRITERIA_UPDATE")
eventFrame:RegisterEvent("ACHIEVEMENT_EARNED")
eventFrame:RegisterEvent("CONTENT_TRACKING_UPDATE")
pcall(function() eventFrame:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE") end)
pcall(function() eventFrame:RegisterEvent("INITIATIVE_TASKS_TRACKED_UPDATED") end)
pcall(function() eventFrame:RegisterEvent("INITIATIVE_TASKS_TRACKED_LIST_CHANGED") end)
pcall(function() eventFrame:RegisterEvent("TRACKING_TARGET_INFO_UPDATE") end)
pcall(function() eventFrame:RegisterEvent("TRACKABLE_INFO_UPDATE") end)

local function ScheduleRefresh()
    if not addon.focus.enabled then return end
    if addon.focus.refreshPending then return end
    addon.focus.refreshPending = true
    C_Timer.After(0.05, function()
        addon.focus.refreshPending = false
        if not addon.focus.enabled then return end
        if InCombatLockdown() then
            addon.focus.layoutPendingAfterCombat = true
            if addon.RefreshContentInCombat then addon.RefreshContentInCombat() end
            return
        end
        addon.focus.layoutPendingAfterCombat = false
        if addon.FullLayout then addon.FullLayout() end
    end)
end

addon.ScheduleRefresh = ScheduleRefresh

_G.HorizonSuite_ApplyTypography  = addon.ApplyTypography
_G.HorizonSuite_ApplyDimensions  = addon.ApplyDimensions
_G.HorizonSuite_RequestRefresh   = ScheduleRefresh
_G.HorizonSuite_FullLayout       = addon.FullLayout

-- ============================================================================
-- EVENT HANDLERS (table dispatch)
-- ============================================================================

local function OnAddonLoaded(addonName)
    if addonName == "HorizonSuite" then
        addon:EnsureModulesDB()
        for key in pairs(addon.modules or {}) do
            local modDb = HorizonDB and HorizonDB.modules and HorizonDB.modules[key]
            if modDb and modDb.enabled ~= false then
                addon:EnableModule(key)
            end
        end
    elseif addonName == "Blizzard_WorldMap" then
        if addon.FocusModuleHooks and addon.FocusModuleHooks.WorldMap then
            addon.FocusModuleHooks.WorldMap()
        end
    elseif addonName == "Blizzard_ObjectiveTracker" then
        if addon:IsModuleEnabled("focus") then
            if addon.TrySuppressTracker then addon.TrySuppressTracker() end
            ScheduleRefresh()
        end
    end
end

local function OnPlayerRegenDisabled()
    if addon.GetDB("hideInCombat", false) and addon.focus.enabled then
        local useAnim = addon.GetDB("animations", true)
        if useAnim and addon.HS:IsShown() then
            addon.focus.combat.fadeState = "out"
            addon.focus.combat.fadeTime  = 0
            if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
        else
            -- Cannot call HS:Hide() here; we are entering combat (protected action blocked).
            addon.focus.combat.fadeState = "out"
            addon.focus.combat.fadeTime  = 0
            addon.focus.pendingHideAfterCombat = true
            if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
        end
    end
end

local function OnPlayerRegenEnabled()
    if addon.focus.layoutPendingAfterCombat then
        addon.focus.layoutPendingAfterCombat = nil
        if addon.GetDB("hideInCombat", false) and addon.focus.enabled then
            addon.focus.combat.fadeState = "in"
            addon.focus.combat.fadeTime  = 0
            if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
        end
        addon.FullLayout()
    elseif addon.GetDB("hideInCombat", false) and addon.focus.enabled then
        addon.focus.combat.fadeState = "in"
        addon.focus.combat.fadeTime  = 0
        if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
        ScheduleRefresh()
    end
end

-- When entering a Delve/dungeon, APIs can lag. Poll until instance state is true, then run FullLayout directly
-- (same as options toggle path) so "hide other categories in Delve/Dungeon" is applied even if ScheduleRefresh was no-op.
local function StartInstanceStatePoll()
    if not addon.focus.enabled or not (addon.IsDelveActive or addon.IsInPartyDungeon) then return end
    local attempts = 0
    local function poll()
        attempts = attempts + 1
        if not addon.focus.enabled then return end
        local inDelve = addon.IsDelveActive and addon.IsDelveActive()
        local inDungeon = addon.IsInPartyDungeon and addon.IsInPartyDungeon()
        if inDelve or inDungeon then
            if addon.FullLayout and not InCombatLockdown() then
                addon.FullLayout()
            end
            return
        end
        if attempts < 10 then
            C_Timer.After(0.5, poll)
        end
    end
    C_Timer.After(0.5, poll)
end

local function OnPlayerLoginOrEnteringWorld()
    if addon.focus.enabled then
        addon.focus.zoneJustChanged = true
        addon.TrySuppressTracker()
        ScheduleRefresh()
        C_Timer.After(0.4, function() if addon.focus.enabled then addon.FullLayout() end end)
        C_Timer.After(1.5, function() if addon.focus.enabled then ScheduleRefresh() end end)
        StartInstanceStatePoll()
        -- Prime endeavor cache so GetInitiativeTaskInfo returns objectives without user opening the panel (Blizz bug workaround)
        C_Timer.After(0.2, function()
            if addon.focus.enabled and addon.GetTrackedEndeavorIDs and addon.RequestEndeavorTaskInfo then
                local idList = addon.GetTrackedEndeavorIDs()
                if #idList > 0 and HousingFramesUtil and HousingFramesUtil.ToggleHousingDashboard then
                    pcall(HousingFramesUtil.ToggleHousingDashboard)
                    pcall(HousingFramesUtil.ToggleHousingDashboard)
                end
                for _, id in ipairs(idList) do
                    addon.RequestEndeavorTaskInfo(id)
                end
            end
        end)
    end
end

local function OnQuestTurnedIn(questID)
    if not addon.focus.enabled then ScheduleRefresh(); return end
    for i = 1, addon.POOL_SIZE do
        if addon.pool[i].questID == questID and addon.pool[i].animState ~= "fadeout" then
            local e = addon.pool[i]
            e.titleText:SetTextColor(addon.QUEST_COLORS.COMPLETE[1], addon.QUEST_COLORS.COMPLETE[2], addon.QUEST_COLORS.COMPLETE[3], 1)
            e.animState = "completing"
            e.animTime  = 0
            addon.activeMap[questID] = nil
        end
    end
    ScheduleRefresh()
end

local function OnQuestWatchUpdate(questID)
    if not addon.focus.enabled then ScheduleRefresh(); return end
    if questID and addon.GetDB("objectiveProgressFlash", true) then
        for i = 1, addon.POOL_SIZE do
            if addon.pool[i].questID == questID then
                addon.pool[i].flashTime = addon.FLASH_DUR
            end
        end
    end
    ScheduleRefresh()
end

local function OnQuestAccepted(questID)
    if not addon.focus.enabled then ScheduleRefresh(); return end
    if not questID or questID <= 0 then ScheduleRefresh(); return end
    
    if addon.GetDB("autoTrackOnAccept", true) then
        local isWQ = (addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID))
            or (C_QuestLog and C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID))
        if not isWQ and C_QuestLog and C_QuestLog.AddQuestWatch then
            C_QuestLog.AddQuestWatch(questID)
        end
    end
    ScheduleRefresh()
end

local function OnQuestWatchListChanged(questID, added)
    if not addon.focus.enabled then ScheduleRefresh(); return end
    if questID and addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(questID) then
        if not addon.focus.recentlyUntrackedWorldQuests then addon.focus.recentlyUntrackedWorldQuests = {} end
        if added then
            addon.focus.recentlyUntrackedWorldQuests[questID] = nil
        else
            addon.focus.recentlyUntrackedWorldQuests[questID] = true
            if addon.wqtTrackedQuests and addon.wqtTrackedQuests[questID] then
                addon.wqtTrackedQuests[questID] = nil
                if HorizonDB and HorizonDB.wqtTrackedQuests then
                    HorizonDB.wqtTrackedQuests[questID] = nil
                end
            end
        end
    end
    ScheduleRefresh()
end

local function OnZoneChanged(event)
    addon.focus.zoneJustChanged = true
    addon.focus.lastPlayerMapID = nil
    -- Only clear right-click suppression on major area change (return to main zone), not on subzone change—unless option is "suppress until reload".
    if event == "ZONE_CHANGED_NEW_AREA" then
        if not addon.GetDB("suppressUntrackedUntilReload", false) then
            if addon.focus.recentlyUntrackedWorldQuests then wipe(addon.focus.recentlyUntrackedWorldQuests) end
        end
        C_Timer.After(2.5, function() if addon.focus.enabled then ScheduleRefresh() end end)
    end
    if addon.zoneTaskQuestCache then wipe(addon.zoneTaskQuestCache) end
    ScheduleRefresh()
    C_Timer.After(0.4, function() if addon.focus.enabled then addon.FullLayout() end end)
    C_Timer.After(1.5, function() if addon.focus.enabled then ScheduleRefresh() end end)
    StartInstanceStatePoll()
end

local eventHandlers = {
    ADDON_LOADED             = function(_, addonName) OnAddonLoaded(addonName) end,
    PLAYER_REGEN_DISABLED    = function() OnPlayerRegenDisabled() end,
    PLAYER_REGEN_ENABLED     = function() OnPlayerRegenEnabled() end,
    PLAYER_LOGIN             = function() OnPlayerLoginOrEnteringWorld() end,
    PLAYER_ENTERING_WORLD    = function() OnPlayerLoginOrEnteringWorld() end,
    QUEST_TURNED_IN          = function(_, questID) OnQuestTurnedIn(questID) end,
    QUEST_ACCEPTED           = function(_, questID) OnQuestAccepted(questID) end,
    QUEST_WATCH_UPDATE       = function(_, questID) OnQuestWatchUpdate(questID) end,
    QUEST_WATCH_LIST_CHANGED = function(_, questID, added) OnQuestWatchListChanged(questID, added) end,
    VIGNETTE_MINIMAP_UPDATED = function() ScheduleRefresh() end,
    VIGNETTES_UPDATED        = function() ScheduleRefresh() end,
    ZONE_CHANGED             = function(evt) OnZoneChanged(evt) end,
    ZONE_CHANGED_NEW_AREA    = function(evt) OnZoneChanged(evt) end,
    SCENARIO_UPDATE          = function() ScheduleRefresh() end,
    SCENARIO_CRITERIA_UPDATE = function() ScheduleRefresh() end,
    SCENARIO_CRITERIA_SHOW_STATE_UPDATE = function() ScheduleRefresh() end,
    SCENARIO_COMPLETED       = function() ScheduleRefresh() end,
    SCENARIO_SPELL_UPDATE    = function() ScheduleRefresh() end,
    CRITERIA_COMPLETE        = function() ScheduleRefresh() end,
    TRACKED_ACHIEVEMENT_UPDATE = function() ScheduleRefresh() end,
    CRITERIA_UPDATE          = function() ScheduleRefresh() end,
    ACHIEVEMENT_EARNED       = function() ScheduleRefresh() end,
    CONTENT_TRACKING_UPDATE  = function(_, trackableType)
        local achType = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Achievement) or 2
        local decorType = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Decor) or 3
        if trackableType == achType or trackableType == decorType then
            ScheduleRefresh()
        end
    end,
    ACTIVE_DELVE_DATA_UPDATE = function() ScheduleRefresh() end,
    INITIATIVE_TASKS_TRACKED_UPDATED = function() ScheduleRefresh() end,
    INITIATIVE_TASKS_TRACKED_LIST_CHANGED = function() ScheduleRefresh() end,
    TRACKING_TARGET_INFO_UPDATE = function() ScheduleRefresh() end,
    TRACKABLE_INFO_UPDATE = function() ScheduleRefresh() end,
}

--- OnEvent: table-dispatch to eventHandlers[event]; falls back to ScheduleRefresh for unhandled events.
-- @param self table Event frame
-- @param event string WoW event name (e.g. QUEST_WATCH_LIST_CHANGED, ADDON_LOADED)
-- @param ... any Event payload (varargs)
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Process pending hide before addon.focus.enabled check (handles module disabled in combat).
    if event == "PLAYER_REGEN_ENABLED" and addon.focus.pendingHideAfterCombat and addon.HS then
        addon.focus.pendingHideAfterCombat = nil
        addon.HS:Hide()
        local floatingBtn = _G.HSFloatingQuestItem
        if floatingBtn then floatingBtn:Hide() end
        if addon.UpdateFloatingQuestItem then addon.UpdateFloatingQuestItem(nil) end
        if addon.UpdateMplusBlock then addon.UpdateMplusBlock() end
    end
    if event ~= "ADDON_LOADED" and not addon.focus.enabled then
        return
    end
    local fn = eventHandlers[event]
    if fn then
        fn(event, ...)
    else
        ScheduleRefresh()
    end
end)
