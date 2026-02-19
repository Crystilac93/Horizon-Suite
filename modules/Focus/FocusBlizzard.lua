--[[
    Horizon Suite - Focus - Blizzard Suppression
    Hide default objective tracker when Horizon Suite is enabled.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- BLIZZARD SUPPRESSION
-- ============================================================================

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local function KillBlizzardFrame(frame)
    if not frame then return end
    pcall(function()
        frame:UnregisterAllEvents()
        frame:SetParent(hiddenParent)
        frame:Hide()
        frame:SetAlpha(0)
        frame:SetScript("OnShow", function(self) self:Hide() end)
    end)
end

local trackerSuppressed = false
local wqtSuppressed = false
local wqtSuppressionTicker = nil

local function TrySuppressTracker()
    if trackerSuppressed then return end
    if ObjectiveTrackerFrame then
        KillBlizzardFrame(ObjectiveTrackerFrame)
        trackerSuppressed = true
    end
    if not wqtSuppressed then
        local wqtFrame = _G.WorldQuestTrackerScreenPanel
        if wqtFrame then
            KillBlizzardFrame(wqtFrame)
            wqtSuppressed = true
        end
    end
    if not wqtSuppressionTicker and addon.focus.enabled then
        wqtSuppressionTicker = C_Timer.NewTicker(0.1, function()
            if not addon.focus.enabled then
                if wqtSuppressionTicker then
                    wqtSuppressionTicker:Cancel()
                    wqtSuppressionTicker = nil
                end
                return
            end
            local wqtFrame = _G.WorldQuestTrackerScreenPanel
            if wqtFrame and wqtFrame:IsShown() then
                wqtFrame:Hide()
            end
        end)
    end
end

local function RestoreTracker()
    if wqtSuppressionTicker then
        wqtSuppressionTicker:Cancel()
        wqtSuppressionTicker = nil
    end
    if not trackerSuppressed then return end
    if ObjectiveTrackerFrame then
        pcall(function()
            ObjectiveTrackerFrame:SetParent(UIParent)
            ObjectiveTrackerFrame:ClearAllPoints()
            ObjectiveTrackerFrame:SetPoint("TOPRIGHT", MinimapCluster or UIParent, "BOTTOMRIGHT", 0, 0)
            ObjectiveTrackerFrame:SetAlpha(1)
            ObjectiveTrackerFrame:Show()
            ObjectiveTrackerFrame:SetScript("OnShow", nil)
        end)
        trackerSuppressed = false
    end
    if wqtSuppressed then
        local wqtFrame = _G.WorldQuestTrackerScreenPanel
        if wqtFrame then
            pcall(function()
                wqtFrame:SetParent(UIParent)
                wqtFrame:SetAlpha(1)
                wqtFrame:Show()
                wqtFrame:SetScript("OnShow", nil)
            end)
            wqtSuppressed = false
        end
    end
end

addon.TrySuppressTracker = TrySuppressTracker
addon.RestoreTracker    = RestoreTracker

-- ============================================================================
-- WORLD QUEST TRACKER INTEGRATION
-- ============================================================================

-- Sync WQT-tracked world quests with HorizonSuite
local wqtHooked = false
local function HookWQTTracking()
    if wqtHooked then return end
    if not addon.focus.enabled then return end
    local WQT = _G.WorldQuestTrackerAddon
    if not WQT then return end
    
    if WQT.RefreshTrackerAnchor then
        hooksecurefunc(WQT, "RefreshTrackerAnchor", function()
            if not addon.focus.enabled then return end
            local wqtPanel = _G.WorldQuestTrackerScreenPanel
            if wqtPanel and wqtPanel:IsShown() then
                wqtPanel:Hide()
            end
        end)
    end
    
    if WQT.AddQuestToTracker then
        hooksecurefunc(WQT, "AddQuestToTracker", function(self, questID, mapID)
            if not addon.focus.enabled then return end
            local qid = self and self.questID or questID
            if not qid then return end
            local isWorldQuest = (C_QuestLog and C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(qid))
                or (addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(qid))
            if isWorldQuest then
                addon.wqtTrackedQuests = addon.wqtTrackedQuests or {}
                addon.wqtTrackedQuests[qid] = true
                if HorizonDB then
                    HorizonDB.wqtTrackedQuests = HorizonDB.wqtTrackedQuests or {}
                    HorizonDB.wqtTrackedQuests[qid] = true
                end
            elseif C_QuestLog and C_QuestLog.AddQuestWatch then
                C_QuestLog.AddQuestWatch(qid)
            end
            local wqtPanel = _G.WorldQuestTrackerScreenPanel
            if wqtPanel and wqtPanel:IsShown() then
                wqtPanel:Hide()
            end
            C_Timer.After(0.1, function()
                if addon.ScheduleRefresh then addon.ScheduleRefresh() end
                if addon.FullLayout then C_Timer.After(0.2, addon.FullLayout) end
            end)
        end)
        wqtHooked = true
    end
    
    if WQT.RemoveQuestFromTracker then
        hooksecurefunc(WQT, "RemoveQuestFromTracker", function(questID, noUpdate)
            if not addon.focus.enabled or not questID then return end
            if addon.wqtTrackedQuests and addon.wqtTrackedQuests[questID] then
                addon.wqtTrackedQuests[questID] = nil
                if HorizonDB and HorizonDB.wqtTrackedQuests then
                    HorizonDB.wqtTrackedQuests[questID] = nil
                end
                local wqtPanel = _G.WorldQuestTrackerScreenPanel
                if wqtPanel and wqtPanel:IsShown() then
                    wqtPanel:Hide()
                end
                C_Timer.After(0.1, function()
                    if addon.ScheduleRefresh then addon.ScheduleRefresh() end
                end)
            end
        end)
    end
end

local wqtFrame = CreateFrame("Frame")
wqtFrame:RegisterEvent("ADDON_LOADED")
wqtFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "WorldQuestTracker" then
        C_Timer.After(0.5, HookWQTTracking)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
if C_AddOns and C_AddOns.IsAddOnLoaded("WorldQuestTracker") then
    C_Timer.After(1, HookWQTTracking)
end

addon.HookWQTTracking = HookWQTTracking
