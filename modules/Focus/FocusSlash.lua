--[[
    Horizon Suite - Focus - Slash Commands
    /horizon and subcommands.
]]

local addon = _G.HorizonSuite
if not addon then return end
local HSPrint = addon.HSPrint or function(msg) print("|cFF00CCFFHorizon Suite - Focus:|r " .. tostring(msg or "")) end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_MODERNQUESTTRACKER1 = "/horizon"
SlashCmdList["MODERNQUESTTRACKER"] = function(msg)
    local cmd = strtrim(msg or ""):lower()

    if cmd == "toggle" then
        if InCombatLockdown() then
            print("|cFFFF0000Horizon Suite:|r Cannot toggle during combat.")
            return
        end
        local currentlyEnabled = addon:IsModuleEnabled("focus")
        addon:SetModuleEnabled("focus", not currentlyEnabled)
        if addon:IsModuleEnabled("focus") then
            HSPrint("|cFF00FF00Focus enabled|r")
        else
            HSPrint("|cFFFF0000Focus disabled|r")
        end

    elseif cmd == "collapse" then
        addon.ToggleCollapse()
        if addon.focus.collapsed then
            print("|cFF00CCFFHorizon Suite - Focus:|r Panel collapsed.")
        else
            print("|cFF00CCFFHorizon Suite - Focus:|r Panel expanded.")
        end

    elseif cmd == "nearby" then
        local show = not addon.GetDB("showNearbyGroup", true)
        addon.SetDB("showNearbyGroup", show)
        if not InCombatLockdown() then
            if show then
                if addon.GetDB("animations", true) and addon.StartNearbyTurnOnTransition then
                    addon.StartNearbyTurnOnTransition()
                else
                    if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
                    if addon.FullLayout then addon.FullLayout() end
                end
            else
                if addon.GetDB("animations", true) and addon.StartGroupCollapseVisual then
                    addon.StartGroupCollapseVisual("NEARBY")
                else
                    if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
                    if addon.FullLayout then addon.FullLayout() end
                end
            end
        else
            if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
            if addon.FullLayout then addon.FullLayout() end
        end
        if show then
            print("|cFF00CCFFHorizon Suite - Focus:|r Nearby group shown.")
        else
            print("|cFF00CCFFHorizon Suite - Focus:|r Nearby group hidden.")
        end

    elseif cmd == "testsound" then
        if PlaySound then
            local ok, err = pcall(PlaySound, addon.RARE_ADDED_SOUND)
            if not ok and HSPrint then HSPrint("PlaySound rare failed: " .. tostring(err)) end
            HSPrint("Played rare-added sound.")
        else
            HSPrint("Could not play sound.")
        end

    elseif cmd == "mplusdebug" then
        addon.mplusDebugPreview = not addon.mplusDebugPreview
        if addon.FullLayout then addon.FullLayout() end
        HSPrint("M+ block debug preview: " .. (addon.mplusDebugPreview and "on" or "off"))

    elseif cmd == "test" then
        HSPrint("Showing test data (10 entries)...")

        local testQuests = {
            { questID = 90001, title = "The Fate of the Horde",
              color = addon.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              questTypeAtlas = "Quest-Campaign-Available",
              isComplete = false, isSuperTracked = true, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              itemLink = "item:12345:0:0:0:0:0:0:0", itemTexture = "Interface\\Icons\\INV_Misc_Rune_01",
              objectives = {
                  { text = "Speak with Thrall", finished = true },
                  { text = "Harbingers defeated: 2/5", finished = false },
              }},
            { questID = 90002, title = "Aiding the Accord",
              color = addon.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              objectives = {
                  { text = "Dragon Glyphs: 3/5", finished = false },
                  { text = "World Quests: 2/3", finished = false },
              }},
            { questID = 90007, title = "Scales of War",
              color = addon.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = true, isAccepted = true,
              zoneName = "Valdrakken",
              objectives = {
                  { text = "War Scales collected: 14/20", finished = false },
              }},
            { questID = 90006, title = "Threads of Fate",
              color = addon.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "The Waking Shores",
              objectives = {
                  { text = "Explore the Loom: 1/3", finished = false },
              }},
            { questID = 90008, title = "The Last Stitch",
              color = addon.QUEST_COLORS.CAMPAIGN, category = "CAMPAIGN",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Azure Span",
              itemLink = "item:67890:0:0:0:0:0:0:0", itemTexture = "Interface\\Icons\\INV_Fabric_Silk_02",
              objectives = {
                  { text = "Mend the Veil: 0/1", finished = false },
                  { text = "Gather Thread: 5/8", finished = false },
              }},
            { questID = 90003, title = "World Boss: Doomwalker",
              color = addon.QUEST_COLORS.WORLD, category = "WORLD",
              questTypeAtlas = "quest-recurring-available",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Thaldraszus",
              objectives = {
                  { text = "Slay Doomwalker", finished = false },
              }},
            { questID = 90009, title = "Elemental Fury",
              color = addon.QUEST_COLORS.WORLD, category = "CALLING",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "The Forbidden Reach",
              objectives = {
                  { text = "Elemental cores: 1/3", finished = false },
              }},
            { questID = 90004, title = "The Legendary Cloak",
              color = addon.QUEST_COLORS.LEGENDARY, category = "LEGENDARY",
              questTypeAtlas = "UI-QuestPoiLegendary-QuestBang",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Ohn'ahran Plains",
              objectives = {
                  { text = "Collect 50 Echoes: 37/50", finished = false },
              }},
            { questID = 90010, title = "Supply Run",
              color = addon.QUEST_COLORS.DEFAULT, category = "DEFAULT",
              isComplete = false, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Stormwind City",
              objectives = {
                  { text = "Deliver supplies: 0/1", finished = false },
              }},
            { questID = 90005, title = "Boar Pelts",
              color = addon.QUEST_COLORS.COMPLETE, category = "COMPLETE",
              questTypeAtlas = "QuestTurnin",
              isComplete = true, isAutoComplete = true, isSuperTracked = false, isNearby = false, isAccepted = true,
              zoneName = "Elwynn Forest",
              objectives = {
                  { text = "Boar Pelts: 10/10", finished = true },
              }},
        }

        -- Inject test data into the quest pipeline and use the normal layout engine.
        addon.testQuests = testQuests
        if addon.focus.collapsed then
            addon.focus.collapsed = false
            addon.chevron:SetText("-")
            addon.scrollFrame:Show()
            if HorizonDB then HorizonDB.collapsed = false end
        end
        addon.FullLayout()

    elseif cmd == "testitem" then
        HSPrint("Injected one debug quest with a quest item (real quests remain). Use /horizon reset to clear.")
        addon.testQuestItem = {
            entryKey       = 89999,
            questID        = 89999,
            title          = "Debug: Quest Item",
            objectives     = { { text = "Use the item button to test", finished = false } },
            color          = addon.QUEST_COLORS and addon.QUEST_COLORS.DEFAULT or "|cFFFFFFFF",
            category       = "DEFAULT",
            isComplete     = false,
            isSuperTracked = false,
            isNearby       = true,
            isAccepted     = true,
            zoneName       = "Debug",
            itemLink       = "item:12345:0:0:0:0:0:0:0",
            itemTexture    = "Interface\\Icons\\INV_Misc_Rune_01",
            questTypeAtlas = nil,
            isDungeonQuest = false,
            isTracked      = true,
            level          = nil,
        }
        if addon.focus.collapsed then
            addon.focus.collapsed = false
            addon.chevron:SetText("-")
            addon.scrollFrame:Show()
            if HorizonDB then HorizonDB.collapsed = false end
        end
        addon.FullLayout()

    elseif cmd == "reset" then
        -- Clear any injected test data and return to live quest data.
        addon.testQuests = nil
        addon.testQuestItem = nil
        addon.ScheduleRefresh()
        HSPrint("Reset tracker to live data.")

    elseif cmd == "resetpos" then
        addon.HS:ClearAllPoints()
        addon.HS:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", addon.PANEL_X, addon.PANEL_Y)
        if HorizonDB then
            HorizonDB.point    = nil
            HorizonDB.relPoint = nil
            HorizonDB.x        = nil
            HorizonDB.y        = nil
        end
        HSPrint("Position reset to default.")

    elseif cmd == "options" or cmd == "config" then
        if _G.HorizonSuite_ShowOptions then
            _G.HorizonSuite_ShowOptions()
        else
            HSPrint("Options not loaded.")
        end

    elseif cmd == "edit" then
        if _G.HorizonSuite_ShowEditPanel then
            _G.HorizonSuite_ShowEditPanel()
        else
            HSPrint("Edit panel not loaded.")
        end

    elseif cmd == "scendebug" then
        local v = not (addon.GetDB and addon.GetDB("scenarioDebug", false))
        if addon.SetDB then addon.SetDB("scenarioDebug", v) end
        HSPrint("Scenario debug logging: " .. (v and "on" or "off"))
        if addon.ScheduleRefresh then addon.ScheduleRefresh() end

    elseif cmd == "nearbydebug" or cmd == "zonedebug" then
        if addon.GetNearbyDebugInfo then
            HSPrint("|cFF00CCFF--- Nearby / Current Zone debug ---|r")
            for _, line in ipairs(addon.GetNearbyDebugInfo()) do
                HSPrint(line)
            end
        else
            HSPrint("GetNearbyDebugInfo not available.")
        end

    elseif cmd == "headercountdebug" then
        if addon.DebugHeaderCount then
            addon.DebugHeaderCount()
        else
            HSPrint("DebugHeaderCount not available.")
        end

    elseif cmd == "endeavordebug" then
        HSPrint("|cFF00CCFF--- Endeavor API debug ---|r")
        HSPrint("C_ContentTracking: " .. (C_ContentTracking and "yes" or "no"))
        if Enum and Enum.ContentTrackingType then
            local t = {}
            for k, v in pairs(Enum.ContentTrackingType) do
                if type(v) == "number" then t[#t + 1] = k .. "=" .. tostring(v) end
            end
            HSPrint("ContentTrackingType: " .. table.concat(t, ", "))
        end
        for _, typ in ipairs({ 0, 1, 2, 3, 4, 5 }) do
            if C_ContentTracking and C_ContentTracking.GetTrackedIDs then
                local ok, ids = pcall(C_ContentTracking.GetTrackedIDs, typ)
                if ok and ids and type(ids) == "table" and #ids > 0 then
                    HSPrint("  GetTrackedIDs(" .. typ .. "): " .. #ids .. " ids: " .. table.concat(ids, ", "))
                end
            end
        end
        HSPrint("C_Endeavors: " .. (C_Endeavors and "yes" or "no"))
        if C_Endeavors then
            for _, fn in ipairs({ "GetTrackedIDs", "GetEndeavorInfo", "GetInfo", "GetActiveEndeavorID" }) do
                if C_Endeavors[fn] then HSPrint("  C_Endeavors." .. fn .. ": yes") end
            end
        end
        HSPrint("C_PlayerHousing: " .. (C_PlayerHousing and "yes" or "no"))
        if C_PlayerHousing then
            for _, fn in ipairs({ "GetActiveEndeavorID", "GetActiveEndeavorInfo", "GetEndeavorInfo" }) do
                if C_PlayerHousing[fn] then HSPrint("  C_PlayerHousing." .. fn .. ": yes") end
            end
        end
        HSPrint("C_NeighborhoodInitiative: " .. (C_NeighborhoodInitiative and "yes" or "no"))
        if C_NeighborhoodInitiative then
            for _, fn in ipairs({ "GetTrackedInitiativeTasks", "GetInitiativeTaskInfo", "RemoveTrackedInitiativeTask", "GetInitiativeTaskChatLink" }) do
                if C_NeighborhoodInitiative[fn] then HSPrint("  C_NeighborhoodInitiative." .. fn .. ": yes") end
            end
        end
        HSPrint("HousingFramesUtil: " .. (HousingFramesUtil and "yes" or "no"))
        if HousingFramesUtil and HousingFramesUtil.OpenFrameToTaskID then
            HSPrint("  HousingFramesUtil.OpenFrameToTaskID: yes")
        end
        HSPrint("ReadTrackedEndeavors count: " .. (addon.ReadTrackedEndeavors and #addon.ReadTrackedEndeavors() or 0))
        HSPrint("ReadTrackedDecor count: " .. (addon.ReadTrackedDecor and #addon.ReadTrackedDecor() or 0))
        -- Dump GetInitiativeTaskInfo for each tracked endeavor (find housing XP / reward field names)
        if C_NeighborhoodInitiative and C_NeighborhoodInitiative.GetTrackedInitiativeTasks and C_NeighborhoodInitiative.GetInitiativeTaskInfo then
            local ok, result = pcall(C_NeighborhoodInitiative.GetTrackedInitiativeTasks)
            local ids = {}
            if ok and result then
                if result.trackedIDs and type(result.trackedIDs) == "table" then
                    ids = result.trackedIDs
                elseif type(result) == "table" and #result > 0 then
                    ids = result
                end
            end
            if #ids == 0 and addon.GetTrackedEndeavorIDs then
                ids = addon.GetTrackedEndeavorIDs() or {}
            end
            HSPrint("|cFF00CCFF--- GetInitiativeTaskInfo dump (" .. #ids .. " tracked) ---|r")
            for _, taskID in ipairs(ids) do
                local getOk, info = pcall(C_NeighborhoodInitiative.GetInitiativeTaskInfo, taskID)
                if getOk and info and type(info) == "table" then
                    HSPrint("  Endeavor " .. tostring(taskID) .. " (" .. tostring(info.taskName or "?") .. "):")
                    local keys = {}
                    for k in pairs(info) do keys[#keys + 1] = k end
                    table.sort(keys)
                    for _, k in ipairs(keys) do
                        local v = info[k]
                        if type(v) == "table" then
                            HSPrint("    " .. tostring(k) .. " = (table, #=" .. tostring(#v) .. ")")
                        else
                            HSPrint("    " .. tostring(k) .. " = " .. tostring(v))
                        end
                    end
                else
                    HSPrint("  Endeavor " .. tostring(taskID) .. ": GetInitiativeTaskInfo returned " .. (getOk and "nil" or ("error: " .. tostring(info))))
                end
            end
        end

    elseif cmd == "unaccepted" or cmd == "dwp" then
        if addon.ShowUnacceptedPopup then
            addon.ShowUnacceptedPopup()
            HSPrint("Opened unaccepted quests popup.")
        else
            HSPrint("ShowUnacceptedPopup not available.")
        end

    elseif cmd == "clicktodebug" then
        HSPrint("|cFF00CCFF--- Click-to-complete debug ---|r")
        if not C_QuestLog then
            HSPrint("C_QuestLog: not available")
        else
            HSPrint("ShowQuestComplete: " .. (ShowQuestComplete and "yes" or "no"))
            HSPrint("requireModifierForClickToComplete: " .. tostring(addon.GetDB("requireModifierForClickToComplete", false)))
            local n = C_QuestLog.GetNumQuestWatches and C_QuestLog.GetNumQuestWatches() or 0
            HSPrint("Tracked quests: " .. tostring(n))
            local eligible = 0
            for i = 1, n do
                local qid = C_QuestLog.GetQuestIDForQuestWatchIndex and C_QuestLog.GetQuestIDForQuestWatchIndex(i)
                if qid and qid > 0 then
                    local title = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(qid) or ("Quest " .. tostring(qid))
                    local logIdx = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(qid)
                    local isComplete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(qid)
                    local isAuto = false
                    if logIdx and C_QuestLog.GetInfo then
                        local ok, info = pcall(C_QuestLog.GetInfo, logIdx)
                        if ok and info then isAuto = info.isAutoComplete and true or false end
                    end
                    local status = (isAuto and isComplete) and "|cFF00FF00eligible|r" or "not eligible"
                    if isAuto and isComplete then eligible = eligible + 1 end
                    HSPrint("  [" .. tostring(qid) .. "] " .. tostring(title):sub(1, 40) .. " | complete=" .. tostring(isComplete) .. " | autoComplete=" .. tostring(isAuto) .. " | " .. status)
                end
            end
            HSPrint("Eligible for click-to-complete: " .. tostring(eligible))
        end

    elseif cmd == "delvedebug" then
        HSPrint("|cFF00CCFF--- Delve / Tier debug (run inside a Delve) ---|r")
        if C_PartyInfo and C_PartyInfo.IsDelveInProgress then
            local ok, v = pcall(C_PartyInfo.IsDelveInProgress)
            HSPrint("IsDelveInProgress: " .. tostring(ok and v or (ok and "false") or ("error: " .. tostring(v))))
        else
            HSPrint("IsDelveInProgress: not available")
        end
        if GetCVarNumberOrDefault then
            local ok, cvarTier = pcall(GetCVarNumberOrDefault, "lastSelectedDelvesTier")
            HSPrint("CVar lastSelectedDelvesTier: " .. (ok and tostring(cvarTier) or ("error: " .. tostring(cvarTier))))
        end
        if GetInstanceInfo then
            local ok, name, instType, diffID, diffName = pcall(GetInstanceInfo)
            if ok then
                HSPrint("GetInstanceInfo: name=" .. tostring(name) .. " type=" .. tostring(instType) .. " diffID=" .. tostring(diffID) .. " diffName=" .. tostring(diffName))
            end
        end

    else
        HSPrint("Commands:")
        HSPrint("  /horizon            - Show this help")
        HSPrint("  /horizon toggle     - Enable / disable")
        HSPrint("  /horizon collapse   - Collapse / expand panel")
        HSPrint("  /horizon nearby     - Toggle Nearby (Current Zone) group")
        HSPrint("  /horizon options    - Open options window")
        HSPrint("  /horizon edit       - Open edit screen")
        HSPrint("  /horizon testsound  - Play the rare-added notification sound")
        HSPrint("  /horizon test       - Show with test data")
        HSPrint("  /horizon testitem   - Inject one debug quest with item (real quests stay)")
        HSPrint("  /horizon reset      - Reset to live data")
        HSPrint("  /horizon resetpos   - Reset panel to default position")
        HSPrint("  /horizon scendebug  - Toggle scenario timer debug logging")
        HSPrint("  /horizon nearbydebug     - Print Current Zone / Nearby map and quest debug info")
        HSPrint("  /horizon headercountdebug - Print header count (in-log) breakdown for debugging")
        HSPrint("  /horizon delvedebug      - Dump Delve/tier APIs (run inside a Delve to find tier number)")
        HSPrint("  /horizon endeavordebug   - Dump Endeavor APIs + GetInitiativeTaskInfo fields (for tooltip/rewards)")
        HSPrint("  /horizon unaccepted      - Show popup of unaccepted quests in current zone with type labels (test)")
        HSPrint("  /horizon clicktodebug    - Debug: list tracked quests and which are eligible for click-to-complete")
        HSPrint("")
        HSPrint("  Click the header row to collapse / expand.")
        HSPrint("  Scroll with mouse wheel when content overflows.")
        HSPrint("  Drag the panel to reposition it (saved across sessions).")
        HSPrint("  Left-click a quest or rare to super-track; Left-click auto-complete quests to complete them.")
        HSPrint("  Shift+Left-click opens quest details; Right-click a quest to untrack, rare to clear super-track.")
    end
end
