--[[
    Horizon Suite - Focus - Interactions
    Mouse scripts on pool entries (click, tooltip, scroll).
]]

local addon = _G.HorizonSuite

-- INTERACTIONS
-- ============================================================================

local pool = addon.pool

--- Try to complete an auto-complete quest via ShowQuestComplete (Blizzard behavior).
--- Returns true if completion was triggered; false otherwise.
--- @param questID number
--- @return boolean
local function TryCompleteQuestFromClick(questID)
    if not questID or questID <= 0 then return false end
    -- Test-mode bypass: when /horizon test is active, simulate click-to-complete for fake auto-complete quests.
    if addon.testQuests and questID >= 90001 and questID <= 90010 then
        for _, q in ipairs(addon.testQuests) do
            if q.questID == questID and q.isComplete and q.isAutoComplete then
                local printFn = addon.HSPrint or print
                printFn("|cFF00FF00[DEBUG]|r Click-to-complete hit (test quest " .. tostring(questID) .. ") - would call ShowQuestComplete in live.")
                if addon.ScheduleRefresh then addon.ScheduleRefresh() end
                return true
            end
        end
    end
    if not C_QuestLog or not C_QuestLog.GetLogIndexForQuestID or not C_QuestLog.IsComplete then return false end
    local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if not logIndex then return false end
    if not C_QuestLog.GetInfo then return false end
    -- pcall: GetInfo can throw on invalid logIndex.
    local ok, info = pcall(C_QuestLog.GetInfo, logIndex)
    if not ok or not info or not info.isAutoComplete then return false end
    if not C_QuestLog.IsComplete(questID) then return false end
    if ShowQuestComplete and type(ShowQuestComplete) == "function" then
        pcall(ShowQuestComplete, questID)
        if addon.ScheduleRefresh then addon.ScheduleRefresh() end
        return true
    end
    return false
end

StaticPopupDialogs["HORIZONSUITE_ABANDON_QUEST"] = StaticPopupDialogs["HORIZONSUITE_ABANDON_QUEST"] or {
    text = "Abandon %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local data = self.data
        if data and data.questID and C_QuestLog and C_QuestLog.AbandonQuest then
            if C_QuestLog.SetSelectedQuest then
                C_QuestLog.SetSelectedQuest(data.questID)
            end
            if C_QuestLog.SetAbandonQuest then
                C_QuestLog.SetAbandonQuest()
            elseif SetAbandonQuest then
                SetAbandonQuest()
            end
            C_QuestLog.AbandonQuest()
            addon.ScheduleRefresh()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

for i = 1, addon.POOL_SIZE do
    local e = pool[i]
    e:EnableMouse(true)

    e:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if self.entryKey then
                local achID = self.entryKey:match("^ach:(%d+)$")
                if achID and self.achievementID then
                    local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                    if requireCtrl and not IsControlKeyDown() then return end
                    if addon.OpenAchievementToAchievement then
                        addon.OpenAchievementToAchievement(self.achievementID)
                    end
                    return
                end
                local endID = self.entryKey:match("^endeavor:(%d+)$")
                if endID and self.endeavorID then
                    local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                    if requireCtrl and not IsControlKeyDown() then return end
                    if HousingFramesUtil and HousingFramesUtil.OpenFrameToTaskID then
                        pcall(HousingFramesUtil.OpenFrameToTaskID, self.endeavorID)
                    elseif ToggleHousingDashboard then
                        ToggleHousingDashboard()
                    elseif HousingFrame and HousingFrame.Show then
                        if HousingFrame:IsShown() then HousingFrame:Hide() else HousingFrame:Show() end
                    end
                    return
                end
                local decorID = self.entryKey:match("^decor:(%d+)$")
                if decorID and self.decorID then
                    local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                    if requireCtrl and not IsControlKeyDown() then return end
                    if IsShiftKeyDown() then
                        local trackTypeDecor = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Decor) or 3
                        if ContentTrackingUtil and ContentTrackingUtil.OpenMapToTrackable then
                            pcall(ContentTrackingUtil.OpenMapToTrackable, trackTypeDecor, self.decorID)
                        end
                    elseif IsAltKeyDown() then
                        if HousingFramesUtil and HousingFramesUtil.PreviewHousingDecorID then
                            pcall(HousingFramesUtil.PreviewHousingDecorID, self.decorID)
                        elseif ToggleHousingDashboard then
                            ToggleHousingDashboard()
                        elseif HousingFrame and HousingFrame.Show then
                            if HousingFrame:IsShown() then HousingFrame:Hide() else HousingFrame:Show() end
                        end
                    else
                        if not HousingDashboardFrame and C_AddOns and C_AddOns.LoadAddOn then
                            pcall(C_AddOns.LoadAddOn, "Blizzard_HousingDashboard")
                        end
                        local entryType = (Enum and Enum.HousingCatalogEntryType and Enum.HousingCatalogEntryType.Decor) or 1
                        local ok, info = pcall(function()
                            if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID then
                                return C_HousingCatalog.GetCatalogEntryInfoByRecordID(entryType, self.decorID, true)
                            end
                        end)
                        if ok and info and HousingDashboardFrame and HousingDashboardFrame.SetTab and HousingDashboardFrame.catalogTab then
                            ShowUIPanel(HousingDashboardFrame)
                            HousingDashboardFrame:SetTab(HousingDashboardFrame.catalogTab)
                            if C_Timer and C_Timer.After then
                                C_Timer.After(0.5, function()
                                    if HousingDashboardFrame and HousingDashboardFrame.CatalogContent and HousingDashboardFrame.CatalogContent.PreviewFrame then
                                        local pf = HousingDashboardFrame.CatalogContent.PreviewFrame
                                        if pf.PreviewCatalogEntryInfo then
                                            pcall(pf.PreviewCatalogEntryInfo, pf, info)
                                        end
                                        if pf.Show then pf:Show() end
                                    end
                                end)
                            end
                        elseif ToggleHousingDashboard then
                            ToggleHousingDashboard()
                        elseif HousingFrame and HousingFrame.Show then
                            if HousingFrame:IsShown() then HousingFrame:Hide() else HousingFrame:Show() end
                        end
                    end
                    return
                end
                local vignetteGUID = self.entryKey:match("^vignette:(.+)$")
                if vignetteGUID and C_SuperTrack and C_SuperTrack.SetSuperTrackedVignette then
                    C_SuperTrack.SetSuperTrackedVignette(vignetteGUID)
                    local wqtPanel = _G.WorldQuestTrackerScreenPanel
                    if wqtPanel and wqtPanel:IsShown() then
                        wqtPanel:Hide()
                    end
                end
                if WorldMapFrame and not WorldMapFrame:IsShown() and ToggleWorldMap then
                    ToggleWorldMap()
                end
                return
            end
            if not self.questID then return end

            local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
            local isWorldQuest = addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(self.questID)

            -- Plain Left (no Shift): try click-to-complete for auto-complete quests (Blizzard behavior).
            if not IsShiftKeyDown() then
                local needMod = addon.GetDB("requireModifierForClickToComplete", false)
                if (not needMod or IsControlKeyDown()) and TryCompleteQuestFromClick(self.questID) then
                    return
                end
            end

            -- Shift+Left: always open quest log & map (safe, read-only). For world quests, optionally add to watch list.
            if IsShiftKeyDown() then
                if isWorldQuest and C_QuestLog.AddWorldQuestWatch then
                    -- With safety enabled, adding to watch for world quests requires Ctrl+Shift+Left.
                    if not requireCtrl or IsControlKeyDown() then
                        C_QuestLog.AddWorldQuestWatch(self.questID)
                        addon.ScheduleRefresh()
                    end
                end
                if addon.OpenQuestDetails then
                    addon.OpenQuestDetails(self.questID)
                end
                return
            end

            -- Non-world quests that are not yet tracked or not yet accepted: handle appropriately.
            if not isWorldQuest and self.isTracked == false then
                if requireCtrl and not IsControlKeyDown() then
                    -- Safety: ignore plain Left-click when Ctrl is required.
                    return
                end
                -- Check if quest is accepted
                local isAccepted = (C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(self.questID)) or false
                if isAccepted then
                    -- Quest is accepted but not tracked: add to tracker
                    if C_QuestLog.AddQuestWatch then
                        C_QuestLog.AddQuestWatch(self.questID)
                    end
                else
                    -- Quest not yet accepted: set waypoint to quest giver/start location
                    if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                        C_SuperTrack.SetSuperTrackedQuestID(self.questID)
                        local wqtPanel = _G.WorldQuestTrackerScreenPanel
                        if wqtPanel and wqtPanel:IsShown() then
                            wqtPanel:Hide()
                        end
                    end
                end
                addon.ScheduleRefresh()
                return
            end

            -- Left (no modifier): focus (set as super-tracked quest).
            if requireCtrl and not IsControlKeyDown() then
                -- Safety: ignore plain Left-click on quests when Ctrl is required.
                return
            end
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                C_SuperTrack.SetSuperTrackedQuestID(self.questID)
                local wqtPanel = _G.WorldQuestTrackerScreenPanel
                if wqtPanel and wqtPanel:IsShown() then
                    wqtPanel:Hide()
                end
            end
            if addon.FullLayout and not InCombatLockdown() then
                addon.FullLayout()
            end
        elseif button == "RightButton" then
            if self.entryKey then
                local achID = self.entryKey:match("^ach:(%d+)$")
                if achID and self.achievementID then
                    local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                    if requireCtrl and not IsControlKeyDown() then return end
                    local trackType = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Achievement) or 2
                    local stopType = (Enum and Enum.ContentTrackingStopType and Enum.ContentTrackingStopType.Manual) or 0
                    if C_ContentTracking and C_ContentTracking.StopTracking then
                        C_ContentTracking.StopTracking(trackType, self.achievementID, stopType)
                    elseif RemoveTrackedAchievement then
                        RemoveTrackedAchievement(self.achievementID)
                    end
                    addon.ScheduleRefresh()
                    return
                end
                local endID = self.entryKey:match("^endeavor:(%d+)$")
                if endID and self.endeavorID then
                    local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                    if requireCtrl and not IsControlKeyDown() then return end
                    if C_NeighborhoodInitiative and C_NeighborhoodInitiative.RemoveTrackedInitiativeTask then
                        pcall(C_NeighborhoodInitiative.RemoveTrackedInitiativeTask, self.endeavorID)
                    elseif C_Endeavors and C_Endeavors.StopTracking then
                        pcall(C_Endeavors.StopTracking, self.endeavorID)
                    end
                    addon.ScheduleRefresh()
                    return
                end
                local decorID = self.entryKey:match("^decor:(%d+)$")
                if decorID and self.decorID then
                    local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                    if requireCtrl and not IsControlKeyDown() then return end
                    local trackTypeDecor = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Decor) or 3
                    local stopType = (Enum and Enum.ContentTrackingStopType and Enum.ContentTrackingStopType.Manual) or 0
                    if C_ContentTracking and C_ContentTracking.StopTracking then
                        pcall(C_ContentTracking.StopTracking, trackTypeDecor, self.decorID, stopType)
                    end
                    addon.ScheduleRefresh()
                    return
                end
                local vignetteGUID = self.entryKey:match("^vignette:(.+)$")
                if vignetteGUID and C_SuperTrack and C_SuperTrack.GetSuperTrackedVignette then
                    if C_SuperTrack.GetSuperTrackedVignette() == vignetteGUID then
                        C_SuperTrack.SetSuperTrackedVignette(nil)
                        local wqtPanel = _G.WorldQuestTrackerScreenPanel
                        if wqtPanel and wqtPanel:IsShown() then
                            wqtPanel:Hide()
                        end
                    end
                end
                return
            end
            if self.questID then
                -- Shift+Right: abandon quest with confirmation (non-world quests only). For world quests, untrack instead.
                if IsShiftKeyDown() then
                    if not (addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(self.questID)) then
                        local questName = C_QuestLog.GetTitleForQuestID(self.questID) or "this quest"
                        StaticPopup_Show("HORIZONSUITE_ABANDON_QUEST", questName, nil, { questID = self.questID })
                        return
                    end
                end

                local requireCtrl = addon.GetDB("requireCtrlForQuestClicks", false)
                if requireCtrl and not IsControlKeyDown() then
                    -- Safety: ignore plain Right-click on quests when Ctrl is required.
                    return
                end

                -- Right (no modifier): if this quest is focused, unfocus only; otherwise untrack.
                if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.SetSuperTrackedQuestID then
                    local focusedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
                    if focusedQuestID and focusedQuestID == self.questID then
                        C_SuperTrack.SetSuperTrackedQuestID(0)
                        local wqtPanel = _G.WorldQuestTrackerScreenPanel
                        if wqtPanel and wqtPanel:IsShown() then
                            wqtPanel:Hide()
                        end
                        if addon.FullLayout and not InCombatLockdown() then
                            addon.FullLayout()
                        end
                        return
                    end
                end

                local usePermanent = addon.GetDB("permanentlySuppressUntracked", false)
                
                if addon.IsQuestWorldQuest and addon.IsQuestWorldQuest(self.questID) and addon.RemoveWorldQuestWatch then
                    addon.RemoveWorldQuestWatch(self.questID)
                    -- Add to suppression: permanent or temporary
                    if usePermanent then
                        if not HorizonDB.permanentQuestBlacklist then HorizonDB.permanentQuestBlacklist = {} end
                        HorizonDB.permanentQuestBlacklist[self.questID] = true
                        -- Trigger blacklist grid refresh
                        if addon.RefreshBlacklistGrid then addon.RefreshBlacklistGrid() end
                    else
                        if not addon.focus.recentlyUntrackedWorldQuests then addon.focus.recentlyUntrackedWorldQuests = {} end
                        addon.focus.recentlyUntrackedWorldQuests[self.questID] = true
                    end
                elseif C_QuestLog.RemoveQuestWatch then
                    C_QuestLog.RemoveQuestWatch(self.questID)
                end
                addon.ScheduleRefresh()
            end
        end
    end)

    e:SetScript("OnEnter", function(self)
        if not self.questID and not self.entryKey then return end
        local r, g, b = self.titleText:GetTextColor()
        self._savedColor = { r, g, b }
        self.titleText:SetTextColor(
            math.min(r * 1.25, 1),
            math.min(g * 1.25, 1),
            math.min(b * 1.25, 1), 1)
        if self.creatureID then
            local link = ("unit:Creature-0-0-0-0-%d-0000000000"):format(self.creatureID)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetHyperlink, GameTooltip, link)
            local att = _G.AllTheThings
            if att and att.Modules and att.Modules.Tooltip then
                local attach = att.Modules.Tooltip.AttachTooltipSearchResults
                local searchFn = att.SearchForObject or att.SearchForField
                if attach and searchFn then
                    pcall(attach, GameTooltip, searchFn, "npcID", self.creatureID)
                end
            end
            GameTooltip:Show()
        elseif self.endeavorID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            local endeavorColor = (addon.GetQuestColor and addon.GetQuestColor("ENDEAVOR")) or (addon.QUEST_COLORS and addon.QUEST_COLORS.ENDEAVOR) or { 0.45, 0.95, 0.75 }
            local ecR, ecG, ecB = endeavorColor[1], endeavorColor[2], endeavorColor[3]
            local greyR, greyG, greyB = 0.7, 0.7, 0.7
            local whiteR, whiteG, whiteB = 0.9, 0.9, 0.9
            local doneR, doneG, doneB = 0.5, 0.8, 0.5

            local ok, info = pcall(function()
                return C_NeighborhoodInitiative and C_NeighborhoodInitiative.GetInitiativeTaskInfo and C_NeighborhoodInitiative.GetInitiativeTaskInfo(self.endeavorID)
            end)
            if ok and info and type(info) == "table" then
                local title = info.taskName or self.titleText:GetText() or ("Endeavor #" .. tostring(self.endeavorID))
                local isRepeatable = (Enum and Enum.NeighborhoodInitiativeTaskType and info.taskType == Enum.NeighborhoodInitiativeTaskType.RepeatableInfinite)
                if isRepeatable and info.timesCompleted and info.timesCompleted > 0 and _G.HOUSING_DASHBOARD_REPEATABLE_TASK_TITLE_TOOLTIP_FORMAT then
                    title = _G.HOUSING_DASHBOARD_REPEATABLE_TASK_TITLE_TOOLTIP_FORMAT:format(info.taskName or title, info.timesCompleted)
                end
                GameTooltip:AddLine(title, ecR, ecG, ecB)
                if isRepeatable and _G.HOUSING_ENDEAVOR_REPEATABLE_TASK then
                    GameTooltip:AddLine(_G.HOUSING_ENDEAVOR_REPEATABLE_TASK, greyR, greyG, greyB)
                end
                GameTooltip:AddLine(" ")
                if info.description and type(info.description) == "string" and info.description ~= "" then
                    GameTooltip:AddLine(info.description, 1, 1, 1, true)
                    GameTooltip:AddLine(" ")
                end
                local reqHeader = _G.REQUIREMENTS or "Requirements:"
                GameTooltip:AddLine(reqHeader, greyR, greyG, greyB)
                if info.requirementsList and type(info.requirementsList) == "table" then
                    for _, req in ipairs(info.requirementsList) do
                        local text = (type(req) == "table" and req.requirementText) or tostring(req)
                        if text and text ~= "" then
                            text = text:gsub(" / ", "/")
                            local r, g, b = whiteR, whiteG, whiteB
                            if type(req) == "table" and req.completed then r, g, b = doneR, doneG, doneB end
                            GameTooltip:AddLine("  " .. text, r, g, b)
                        end
                    end
                end
                -- Resolve contribution/XP amount (GetInitiativeTaskInfo uses progressContributionAmount for housing/neighborhood favor).
                local contributionAmount = (info.progressContributionAmount and type(info.progressContributionAmount) == "number") and info.progressContributionAmount
                    or (info.thresholdContributionAmount and type(info.thresholdContributionAmount) == "number") and info.thresholdContributionAmount
                    or (info.contributionAmount and type(info.contributionAmount) == "number") and info.contributionAmount
                    or nil
                if not (contributionAmount and contributionAmount > 0) then
                    for k, v in pairs(info) do
                        if type(k) == "string" and type(v) == "number" and v > 0 then
                            local lower = k:lower()
                            if lower:find("contribution") or lower:find("favor") or lower:find("reward") and lower:find("amount") or lower:find("threshold") or lower:find("xp") or (lower:find("amount") and not lower:find("completed")) then
                                contributionAmount = v
                                break
                            end
                        end
                    end
                end
                local hasContribution = contributionAmount and contributionAmount > 0
                local hasQuestReward = info.rewardQuestID and addon.AddQuestRewardsToTooltip
                if hasContribution or hasQuestReward then
                    GameTooltip:AddLine(" ")
                    local rewardsHeader = _G.REWARDS or "Rewards:"
                    GameTooltip:AddLine(rewardsHeader, greyR, greyG, greyB)
                    if hasContribution then
                        local amountStr = (type(FormatLargeNumber) == "function" and FormatLargeNumber(contributionAmount)) or tostring(contributionAmount)
                        local favorLabel = _G.HOUSING_ENDEAVOR_REWARD_HOUSING_XP or _G.NEIGHBORHOOD_FAVOR_PROGRESS or "Housing XP"
                        -- Use the chevron XP icon and identical line format to currency rewards.
                        local xpTex = _G.HOUSING_XP_CURRENCY_ICON or _G.HOUSING_XP_ICON_FILE_ID or 894556
                        local iconStr = "|T" .. tostring(xpTex) .. ":0|t "
                        GameTooltip:AddLine(iconStr .. amountStr .. " " .. favorLabel, 1, 1, 1)
                    end
                    if hasQuestReward then
                        addon.AddQuestRewardsToTooltip(GameTooltip, info.rewardQuestID)
                    end
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(("Endeavor #%s"):format(tostring(self.endeavorID)), greyR, greyG, greyB)
            else
                local title = self.titleText:GetText() or ("Endeavor #" .. tostring(self.endeavorID))
                GameTooltip:AddLine(title, ecR, ecG, ecB)
                GameTooltip:AddLine(("Endeavor #%s"):format(tostring(self.endeavorID)), greyR, greyG, greyB)
                if addon.GetEndeavorDisplayInfo then
                    local getOk, name, _, objectives = pcall(addon.GetEndeavorDisplayInfo, self.endeavorID)
                    if getOk and objectives and type(objectives) == "table" and #objectives > 0 then
                        GameTooltip:AddLine(" ")
                        for _, obj in ipairs(objectives) do
                            local text = (type(obj) == "table" and obj.text) or tostring(obj)
                            if text and text ~= "" then
                                local r, g, b = whiteR, whiteG, whiteB
                                if type(obj) == "table" and obj.finished then r, g, b = doneR, doneG, doneB end
                                GameTooltip:AddLine("  " .. text, r, g, b)
                            end
                        end
                    end
                end
            end
            if not GameTooltip:NumLines() or GameTooltip:NumLines() == 0 then
                GameTooltip:SetText(self.titleText:GetText() or ("Endeavor #" .. tostring(self.endeavorID)))
            end
            GameTooltip:Show()
        elseif self.decorID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.titleText:GetText() or "")
            GameTooltip:AddLine(("Decor #%d"):format(self.decorID), 0.7, 0.7, 0.7)
            GameTooltip:Show()
        elseif self.achievementID and GetAchievementLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local link = GetAchievementLink(self.achievementID)
            if link then
                pcall(GameTooltip.SetHyperlink, GameTooltip, link)
            else
                GameTooltip:SetText(self.titleText:GetText() or "")
            end
            GameTooltip:Show()
        elseif self.questID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetHyperlink, GameTooltip, "quest:" .. self.questID)
            addon.AddQuestRewardsToTooltip(GameTooltip, self.questID)
            addon.AddQuestPartyProgressToTooltip(GameTooltip, self.questID)
            GameTooltip:Show()
        elseif self.entryKey then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.titleText:GetText() or "")
            GameTooltip:Show()
        end
    end)

    e:SetScript("OnLeave", function(self)
        if self._savedColor then
            local sc = self._savedColor
            self.titleText:SetTextColor(sc[1], sc[2], sc[3], 1)
            self._savedColor = nil
        end
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)

    e:EnableMouseWheel(true)
    e:SetScript("OnMouseWheel", function(_, delta) addon.HandleScroll(delta) end)
end
