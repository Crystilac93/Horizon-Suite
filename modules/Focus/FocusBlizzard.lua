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
    local ok1, err1 = pcall(function()
        frame:UnregisterAllEvents()
        frame:SetParent(hiddenParent)
        frame:Hide()
        frame:SetAlpha(0)
    end)
    if not ok1 and addon.HSPrint then addon.HSPrint("KillBlizzardFrame hide failed: " .. tostring(err1)) end
    local ok2, err2 = pcall(function()
        frame:SetScript("OnShow", function(self) self:Hide() end)
    end)
    if not ok2 and addon.HSPrint then addon.HSPrint("KillBlizzardFrame OnShow hook failed: " .. tostring(err2)) end
end

local trackerSuppressed = false
local suppressionTicker = nil
local wqtSuppressed = false

local function TrySuppressTracker()
    if trackerSuppressed then return end
    if ObjectiveTrackerFrame then
        KillBlizzardFrame(ObjectiveTrackerFrame)
        trackerSuppressed = true
        
        -- Start a recurring check to ensure tracker stays hidden
        if not suppressionTicker then
            suppressionTicker = C_Timer.NewTicker(0.5, function()
                if addon.enabled and ObjectiveTrackerFrame and ObjectiveTrackerFrame:IsShown() then
                    ObjectiveTrackerFrame:Hide()
                end
                -- Also suppress World Quest Tracker addon if detected
                if addon.enabled and not wqtSuppressed then
                    local wqtFrame = _G.WorldQuestTrackerScreenPanel or _G.WorldQuestTrackerFrame or _G.WQT_WorldQuestFrame or _G.WorldQuestsList
                    if wqtFrame then
                        KillBlizzardFrame(wqtFrame)
                        wqtSuppressed = true
                    end
                end
            end)
        end
    end
end

local function RestoreTracker()
    if not trackerSuppressed then return end
    
    -- Cancel the suppression ticker
    if suppressionTicker then
        suppressionTicker:Cancel()
        suppressionTicker = nil
    end
    
    if ObjectiveTrackerFrame then
        local ok, err = pcall(function()
            ObjectiveTrackerFrame:SetParent(UIParent)
            ObjectiveTrackerFrame:ClearAllPoints()
            ObjectiveTrackerFrame:SetPoint("TOPRIGHT", MinimapCluster or UIParent, "BOTTOMRIGHT", 0, 0)
            ObjectiveTrackerFrame:SetAlpha(1)
            ObjectiveTrackerFrame:Show()
            ObjectiveTrackerFrame:SetScript("OnShow", nil)
        end)
        if not ok and addon.HSPrint then addon.HSPrint("RestoreTracker failed: " .. tostring(err)) end
        trackerSuppressed = false
    end
    
    -- Restore WQT if it was suppressed
    if wqtSuppressed then
        local wqtFrame = _G.WorldQuestTrackerScreenPanel or _G.WorldQuestTrackerFrame or _G.WQT_WorldQuestFrame or _G.WorldQuestsList
        if wqtFrame then
            local ok, err = pcall(function()
                wqtFrame:SetParent(UIParent)
                wqtFrame:SetAlpha(1)
                wqtFrame:Show()
                wqtFrame:SetScript("OnShow", nil)
            end)
            if not ok and addon.HSPrint then addon.HSPrint("RestoreWQT failed: " .. tostring(err)) end
        end
        wqtSuppressed = false
    end
end

addon.TrySuppressTracker = TrySuppressTracker
addon.RestoreTracker    = RestoreTracker

-- ============================================================================
-- WORLD QUEST TRACKER INTEGRATION
-- ============================================================================

-- Hook WQT's quest tracking to automatically add tracked WQs to HorizonSuite
local wqtHooked = false
local function HookWQTTracking()
    if wqtHooked then return end
    if not addon.enabled then return end
    
    local WQT = _G.WorldQuestTrackerAddon
    if not WQT then
        if addon.HSPrint then addon.HSPrint("[WQT] WorldQuestTrackerAddon not found") end
        return
    end
    
    if addon.HSPrint then addon.HSPrint("[WQT] Found WorldQuestTrackerAddon, attempting hook") end
    
    -- Hook the main tracking function: WorldQuestTracker.AddQuestToTracker
    -- Signature: function WorldQuestTracker.AddQuestToTracker(self, questID, mapID)
    -- Note: WQT extracts questID as: self.questID or questID
    if WQT.AddQuestToTracker then
        hooksecurefunc(WQT, "AddQuestToTracker", function(self, questID, mapID)
            if not addon.enabled then return end
            -- Match WQT's extraction logic
            local qid = self and self.questID or questID
            if not qid then return end
            
            if addon.HSPrint then
                addon.HSPrint("[WQT] AddQuestToTracker called: questID=" .. tostring(qid) .. " (self.questID=" .. tostring(self and self.questID or "nil") .. ", param=" .. tostring(questID) .. ")")
            end
            
            -- Check if it's a world quest
            local isWorldQuest = false
            if C_QuestLog and C_QuestLog.IsWorldQuest then
                isWorldQuest = C_QuestLog.IsWorldQuest(qid)
            elseif addon.IsQuestWorldQuest then
                isWorldQuest = addon.IsQuestWorldQuest(qid)
            end
            
            if addon.HSPrint then
                addon.HSPrint("[WQT] Is world quest: " .. tostring(isWorldQuest))
            end
            
            -- For world quests: store in our tracking table
            if isWorldQuest then
                if not addon.wqtTrackedQuests then
                    addon.wqtTrackedQuests = {}
                end
                addon.wqtTrackedQuests[qid] = true
                if addon.HSPrint then
                    local count = 0
                    for _ in pairs(addon.wqtTrackedQuests) do count = count + 1 end
                    addon.HSPrint("[WQT] Added " .. tostring(qid) .. " to tracking table. Total tracked: " .. count)
                end
            else
                -- Regular quest: use normal watch API
                if C_QuestLog and C_QuestLog.AddQuestWatch then
                    local success = C_QuestLog.AddQuestWatch(qid)
                    if addon.HSPrint then
                        addon.HSPrint("[WQT] AddQuestWatch result: " .. tostring(success))
                    end
                end
            end
            
            -- Refresh HorizonSuite to pick up the newly watched quest
            C_Timer.After(0.1, function()
                if addon.ScheduleRefresh then addon.ScheduleRefresh() end
            end)
            C_Timer.After(0.3, function()
                if addon.FullLayout then addon.FullLayout() end
            end)
        end)
        wqtHooked = true
        if addon.HSPrint then addon.HSPrint("[WQT] AddQuestToTracker hook successful") end
    else
        if addon.HSPrint then addon.HSPrint("[WQT] AddQuestToTracker function not found") end
    end
    
    -- Hook the remove function: WorldQuestTracker.RemoveQuestFromTracker
    -- Signature: function WorldQuestTracker.RemoveQuestFromTracker(questID, noUpdate)
    if WQT.RemoveQuestFromTracker then
        hooksecurefunc(WQT, "RemoveQuestFromTracker", function(questID, noUpdate)
            if not addon.enabled then return end
            if not questID then return end
            
            if addon.HSPrint then
                addon.HSPrint("[WQT] RemoveQuestFromTracker called: questID=" .. tostring(questID) .. ", noUpdate=" .. tostring(noUpdate))
            end
            
            -- Remove from our tracking table
            if addon.wqtTrackedQuests and addon.wqtTrackedQuests[questID] then
                addon.wqtTrackedQuests[questID] = nil
                if addon.HSPrint then
                    local count = 0
                    for _ in pairs(addon.wqtTrackedQuests) do count = count + 1 end
                    addon.HSPrint("[WQT] Removed " .. tostring(questID) .. " from tracking table. Total tracked: " .. count)
                end
                
                -- Refresh to update the list
                C_Timer.After(0.1, function()
                    if addon.ScheduleRefresh then addon.ScheduleRefresh() end
                end)
            end
        end)
        if addon.HSPrint then addon.HSPrint("[WQT] RemoveQuestFromTracker hook successful") end
    else
        if addon.HSPrint then addon.HSPrint("[WQT] RemoveQuestFromTracker function not found") end
    end
end

-- Listen for WQT addon load
local wqtFrame = CreateFrame("Frame")
wqtFrame:RegisterEvent("ADDON_LOADED")
wqtFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "WorldQuestTracker" then
        C_Timer.After(0.5, HookWQTTracking)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Also try immediate hook if WQT already loaded
if C_AddOns and C_AddOns.IsAddOnLoaded("WorldQuestTracker") then
    C_Timer.After(1, HookWQTTracking)
end

addon.HookWQTTracking = HookWQTTracking
