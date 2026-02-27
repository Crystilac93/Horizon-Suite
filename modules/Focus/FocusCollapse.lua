--[[
    Horizon Suite - Focus - Collapse and Combat
    ToggleCollapse, StartGroupCollapse, ShouldShowInInstance, CountTrackedInLog, RefreshContentInCombat.
]]

local addon = _G.HorizonSuite

local pool       = addon.pool
local activeMap  = addon.activeMap
local sectionPool = addon.sectionPool
local scrollFrame = addon.scrollFrame
local scrollChild = addon.scrollChild

local COLLAPSE_CANCEL_DEBOUNCE_SEC  = 2
local COMPLETED_OBJECTIVE_FADE_ALPHA = 0.4
local MIN_TICK_SIZE                  = 10

--- Toggles full-panel collapsed/expanded state. Starts collapse animation or cancels in-progress collapse.
local function ToggleCollapse()
    if addon.focus.collapse.animating then
        if (GetTime() - addon.focus.collapse.animStart) < COLLAPSE_CANCEL_DEBOUNCE_SEC then return end
        addon.focus.collapse.animating = false
        addon.focus.collapse.sectionHeadersFadingOut = false
        addon.focus.collapse.sectionHeadersFadingOutKeys = nil
        addon.focus.collapse.sectionHeadersFadingIn = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].animState == "collapsing" then
                addon.ClearEntry(pool[i])
            end
        end
        for i = 1, addon.SECTION_POOL_SIZE do
            if sectionPool[i].active then
                sectionPool[i]:SetAlpha(0)
                sectionPool[i]:Hide()
                sectionPool[i].active = false
            end
        end
        wipe(activeMap)
        if not InCombatLockdown() then
            scrollFrame:Hide()
        else
            addon.focus.layoutPendingAfterCombat = true
        end
        addon.focus.layout.targetHeight = addon.GetCollapsedHeight()
    end

    addon.focus.collapsed = not addon.focus.collapsed
    if addon.focus.collapsed then
        addon.chevron:SetText("+")

        local visibleEntries = {}
        for i = 1, addon.POOL_SIZE do
            local e = pool[i]
            if (e.questID or e.entryKey) and (e.animState == "active" or e.animState == "fadein") then
                visibleEntries[#visibleEntries + 1] = e
            end
        end

        table.sort(visibleEntries, function(a, b) return a.finalY < b.finalY end)

        for idx, e in ipairs(visibleEntries) do
            addon.SetEntryCollapsing(e, 0)
        end

        local showHeadersWhenCollapsed = addon.GetDB("showSectionHeadersWhenCollapsed", false)
        local useAnim = addon.GetDB("animations", true)
        if useAnim then
            addon.focus.collapse.sectionHeadersFadingOut = true
            addon.focus.collapse.sectionHeaderFadeTime   = 0
        else
            for i = 1, addon.SECTION_POOL_SIZE do
                if sectionPool[i].active then
                    sectionPool[i]:SetAlpha(0)
                    sectionPool[i]:Hide()
                    sectionPool[i].active = false
                end
            end
        end

        addon.focus.collapse.animating = #visibleEntries > 0 or addon.focus.collapse.sectionHeadersFadingOut
        addon.focus.collapse.animStart = GetTime()
        if addon.focus.collapse.animating and addon.EnsureFocusUpdateRunning then
            addon.EnsureFocusUpdateRunning()
        end
        if not addon.focus.collapse.animating then
            if showHeadersWhenCollapsed then
                addon.FullLayout()
            else
                if not InCombatLockdown() then
                    scrollFrame:Hide()
                else
                    addon.focus.layoutPendingAfterCombat = true
                end
                addon.focus.layout.targetHeight = addon.GetCollapsedHeight()
            end
        end
    else
        addon.chevron:SetText("-")
        if not InCombatLockdown() then
            scrollFrame:Show()
        else
            addon.focus.layoutPendingAfterCombat = true
        end
        if addon.GetDB("animations", true) then
            addon.focus.collapse.sectionHeadersFadingIn  = true
            addon.focus.collapse.sectionHeaderFadeTime    = 0
        end
        addon.FullLayout()
    end
    addon.EnsureDB()
    addon.SetDB("collapsed", addon.focus.collapsed)
end

--- Initiates category collapse for a group. Animates entries collapsing, then runs FullLayout.
--- @param groupKey string Category key (e.g. "NEARBY", "WEEKLY")
local function StartGroupCollapse(groupKey)
    if not groupKey then return end

    local entries = {}
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        if e.groupKey == groupKey
           and (e.questID or e.entryKey)
           and (e.animState == "active" or e.animState == "fadein") then
            entries[#entries + 1] = e
        end
    end

    if #entries == 0 then
        addon.SetCategoryCollapsed(groupKey, true)
        addon.FullLayout()
        return
    end

    table.sort(entries, function(a, b)
        return a.finalY > b.finalY
    end)

    for i, e in ipairs(entries) do
        addon.SetEntryCollapsing(e, i - 1)
    end

    addon.focus.collapse.groups[groupKey] = GetTime()
    if addon.EnsureFocusUpdateRunning then
        addon.EnsureFocusUpdateRunning()
    end

    if addon.SetCategoryCollapsed then
        addon.SetCategoryCollapsed(groupKey, true)
    end
end

--- Same as StartGroupCollapse but visual-only: no FullLayout or SetCategoryCollapsed.
--- @param groupKey string Category key
local function StartGroupCollapseVisual(groupKey)
    if not groupKey then return end

    local entries = {}
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        if e.groupKey == groupKey
           and (e.questID or e.entryKey)
           and (e.animState == "active" or e.animState == "fadein") then
            entries[#entries + 1] = e
        end
    end

    if #entries == 0 then
        if addon.FullLayout then addon.FullLayout() end
        return
    end

    table.sort(entries, function(a, b)
        return a.finalY > b.finalY
    end)

    for i, e in ipairs(entries) do
        addon.SetEntryCollapsing(e, i - 1)
    end

    addon.focus.collapse.groups[groupKey] = GetTime()
end

--- Triggers fade-in for NEARBY entries. Sorts by finalY descending and staggers fade-in.
local function TriggerNearbyEntriesFadeIn()
    local entries = {}
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        if e.groupKey == "NEARBY" and (e.questID or e.entryKey) and (e.animState == "active" or e.animState == "fadein") then
            entries[#entries + 1] = e
        end
    end
    table.sort(entries, function(a, b)
        return (a.finalY or 0) > (b.finalY or 0)
    end)
    for i, e in ipairs(entries) do
        addon.SetEntryFadeIn(e, i - 1)
    end
end

--- Slides out non-NEARBY entries, then runs FullLayout and TriggerNearbyEntriesFadeIn when slide-out completes.
local function StartNearbyTurnOnTransition()
    local quests = addon.ReadTrackedQuests()
    local grouped = addon.SortAndGroupQuests(quests)
    local nearbyKeys = {}
    for _, grp in ipairs(grouped) do
        if grp.key == "NEARBY" then
            for _, q in ipairs(grp.quests) do
                nearbyKeys[q.entryKey or q.questID] = true
            end
            break
        end
    end

    local slideOutCount = 0
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        local key = e.questID or e.entryKey
        if key and nearbyKeys[key] and e.groupKey ~= "NEARBY" and (e.animState == "active" or e.animState == "fadein") then
            e.animState = "slideout"
            e.animTime  = 0
            slideOutCount = slideOutCount + 1
        end
    end

    if slideOutCount > 0 then
        addon.focus.callbacks.onSlideOutComplete = function()
            addon.focus.callbacks.onSlideOutComplete = nil
            if addon.FullLayout then addon.FullLayout() end
            if addon.TriggerNearbyEntriesFadeIn then addon.TriggerNearbyEntriesFadeIn() end
        end
    else
        if addon.FullLayout then addon.FullLayout() end
        if addon.TriggerNearbyEntriesFadeIn then addon.TriggerNearbyEntriesFadeIn() end
    end
end

--- Whether to show the tracker in the current instance type (dungeon, raid, bg, arena).
--- Per-difficulty granularity for dungeon and raid; falls back to legacy toggle if granular keys are nil.
--- @return boolean
local function ShouldShowInInstance()
    local _, inType, difficultyID = GetInstanceInfo()
    if inType == "none" then return true end
    if inType == "party" then
        -- Per-difficulty dungeon toggles; fall back to legacy showInDungeon
        if difficultyID == 1 then  -- Normal
            local v = addon.GetDB("showInDungeonNormal", nil)
            if v ~= nil then return v end
        elseif difficultyID == 2 then  -- Heroic
            local v = addon.GetDB("showInDungeonHeroic", nil)
            if v ~= nil then return v end
        elseif difficultyID == 23 then  -- Mythic
            local v = addon.GetDB("showInDungeonMythic", nil)
            if v ~= nil then return v end
        elseif difficultyID == 8 then  -- Mythic Keystone (M+)
            local v = addon.GetDB("showInDungeonMythicPlus", nil)
            if v ~= nil then return v end
        end
        return addon.GetDB("showInDungeon", false)
    end
    if inType == "raid" then
        -- Per-difficulty raid toggles; fall back to legacy showInRaid
        if difficultyID == 17 then  -- LFR
            local v = addon.GetDB("showInRaidLFR", nil)
            if v ~= nil then return v end
        elseif difficultyID == 14 then  -- Normal
            local v = addon.GetDB("showInRaidNormal", nil)
            if v ~= nil then return v end
        elseif difficultyID == 15 then  -- Heroic
            local v = addon.GetDB("showInRaidHeroic", nil)
            if v ~= nil then return v end
        elseif difficultyID == 16 then  -- Mythic
            local v = addon.GetDB("showInRaidMythic", nil)
            if v ~= nil then return v end
        end
        return addon.GetDB("showInRaid", false)
    end
    if inType == "pvp"    then return addon.GetDB("showInBattleground", false) end
    if inType == "arena"  then return addon.GetDB("showInArena", false) end
    return true
end

--- Counts non-rare/achievement/endeavor/decor entries that are in the quest log.
--- @param quests table Array of normalized entry tables
--- @return number
local function CountTrackedInLog(quests)
    if not quests then return 0 end
    local n = 0
    local getLogIdx = C_QuestLog and C_QuestLog.GetLogIndexForQuestID
    local isWQ = addon.IsQuestWorldQuest
    for _, entry in ipairs(quests) do
        if not (entry.isRare or entry.category == "RARE" or entry.isAchievement or entry.category == "ACHIEVEMENT" or entry.isEndeavor or entry.category == "ENDEAVOR" or entry.isDecor or entry.category == "DECOR") then
            local qid = entry.questID
            if qid and getLogIdx and getLogIdx(qid) and (not isWQ or not isWQ(qid)) then
                n = n + 1
            end
        end
    end
    return n
end

--- Refreshes entry text and colors in combat (objectives, titles, timers, zone labels).
--- Called when combat events fire and ShouldHideInCombat is false.
local function RefreshContentInCombat()
    if not addon.focus.enabled then return end
    if addon.ShouldHideInCombat and addon.ShouldHideInCombat() then return end

    local quests = addon.ReadTrackedQuests and addon.ReadTrackedQuests() or {}
    if not quests or #quests == 0 then return end

    local grouped = addon.SortAndGroupQuests and addon.SortAndGroupQuests(quests) or {}
    local dataMap = {}
    for _, grp in ipairs(grouped) do
        for _, qData in ipairs(grp.quests) do
            local key = qData.questID or qData.entryKey
            if key then
                dataMap[key] = { questData = qData, groupKey = grp.key }
            end
        end
    end

    local objectivePrefixStyle = addon.GetDB("objectivePrefixStyle", "none")
    local playerZone = addon.GetPlayerCurrentZoneName and addon.GetPlayerCurrentZoneName() or nil

    for i = 1, addon.POOL_SIZE do
        local entry = pool[i]
        if not entry then break end

        local key = entry.questID or entry.entryKey
        if key and entry.animState ~= "fadeout" and entry.animState ~= "collapsing" then
            local rec = dataMap[key]
            if rec then
                local questData = rec.questData
                local groupKey = rec.groupKey
                local effectiveCat = (addon.GetEffectiveColorCategory and addon.GetEffectiveColorCategory(questData.category, groupKey, questData.baseCategory)) or questData.category
                local shouldDim = addon.GetDB("dimNonSuperTracked", false) and not questData.isSuperTracked
                local objColor = (addon.GetObjectiveColor and addon.GetObjectiveColor(effectiveCat)) or addon.OBJ_COLOR or { 0.9, 0.9, 0.9 }
                local doneColor = (addon.GetCompletedObjectiveColor and addon.GetCompletedObjectiveColor(effectiveCat))
                    or (addon.GetObjectiveColor and addon.GetObjectiveColor(effectiveCat)) or addon.OBJ_DONE_COLOR or { 0.5, 0.8, 0.5 }
                if shouldDim then
                    objColor = addon.ApplyDimColor(objColor)
                    doneColor = addon.ApplyDimColor(doneColor)
                end
                local effectiveDoneColor = doneColor

                local displayTitle = questData.title or ""
                -- Determine if progress bar is active (suppress title X/Y to avoid duplication)
                local progressBarActiveForTitle = false
                if addon.GetDB("showObjectiveProgressBar", false) and questData.objectives then
                    local ac = 0
                    for _, o in ipairs(questData.objectives) do
                        if o.numFulfilled ~= nil and o.numRequired ~= nil and type(o.numFulfilled) == "number" and type(o.numRequired) == "number" and o.numRequired > 1 then
                            ac = ac + 1
                        end
                    end
                    if ac == 1 then progressBarActiveForTitle = true end
                end
                if not progressBarActiveForTitle and (addon.GetDB("showCompletedCount", false) or questData.isAchievement or questData.isEndeavor) then
                    local done, total
                    if questData.numericQuantity ~= nil and questData.numericRequired and type(questData.numericRequired) == "number" and questData.numericRequired > 1 then
                        done, total = questData.numericQuantity, questData.numericRequired
                    elseif questData.criteriaDone and questData.criteriaTotal and type(questData.criteriaDone) == "number" and type(questData.criteriaTotal) == "number" and questData.criteriaTotal > 0 then
                        done, total = questData.criteriaDone, questData.criteriaTotal
                    elseif questData.objectivesDoneCount and questData.objectivesTotalCount then
                        done, total = questData.objectivesDoneCount, questData.objectivesTotalCount
                    elseif questData.objectives and #questData.objectives > 0 then
                        done, total = 0, #questData.objectives
                        for _, o in ipairs(questData.objectives) do if o.finished then done = done + 1 end end
                    end
                    if done and total then
                        displayTitle = ("%s (%d/%d)"):format(questData.title or "", done, total)
                    end
                end
                if addon.GetDB("showQuestLevel", false) and questData.level then
                    displayTitle = ("%s [L%d]"):format(displayTitle, questData.level)
                end
                if questData.category == "DELVES" and type(questData.delveTier) == "number" then
                    displayTitle = displayTitle .. (" (Tier %d)"):format(questData.delveTier)
                end
                local showInZoneSuffix = addon.GetDB("showInZoneSuffix", true)
                if showInZoneSuffix then
                    local needSuffix = false
                    if questData.category == "WORLD" then
                        needSuffix = (questData.isAutoAdded == true) and (questData.isSuperTracked ~= true)
                    elseif questData.category == "WEEKLY" or questData.category == "DAILY" then
                        needSuffix = (questData.isAccepted == false)
                    end
                    if needSuffix then
                        local iconKey = addon.GetDB("autoTrackIcon", "radar1")
                        local iconPath = addon.GetRadarIconPath and addon.GetRadarIconPath(iconKey) or ("Interface\\AddOns\\HorizonSuite\\media\\" .. iconKey .. ".blp")
                        displayTitle = displayTitle .. " |T" .. iconPath .. ":0|t"
                    end
                end
                displayTitle = addon.ApplyTextCase and addon.ApplyTextCase(displayTitle, "questTitleCase", "proper") or displayTitle
                if addon.GetDB("showCategoryEntryNumbers", true) and questData.categoryIndex and type(questData.categoryIndex) == "number" then
                    displayTitle = ("%d. %s"):format(questData.categoryIndex, displayTitle)
                end
                entry.titleText:SetText(displayTitle)
                entry.titleShadow:SetText(displayTitle)
                local titleColor = (addon.GetTitleColor and addon.GetTitleColor(effectiveCat)) or questData.color
                if not titleColor or type(titleColor) ~= "table" or not titleColor[1] or not titleColor[2] or not titleColor[3] then
                    titleColor = addon.QUEST_COLORS and addon.QUEST_COLORS.DEFAULT or { 0.9, 0.9, 0.9 }
                end
                if questData.isDungeonQuest and not questData.isTracked then
                    local df = addon.DUNGEON_UNTRACKED_DIM or 0.65
                    titleColor = { titleColor[1] * df, titleColor[2] * df, titleColor[3] * df }
                elseif shouldDim then
                    titleColor = addon.ApplyDimColor(titleColor)
                end
                local dimAlpha = shouldDim and addon.GetDimAlpha() or 1
                entry.titleText:SetTextColor(titleColor[1], titleColor[2], titleColor[3], dimAlpha)

                local showZoneLabels = addon.GetDB("showZoneLabels", true)
                local inCurrentZone = questData.isNearby or (questData.zoneName and playerZone and questData.zoneName:lower() == playerZone:lower())
                local shouldShowZone = showZoneLabels and questData.zoneName and not inCurrentZone
                if shouldShowZone then
                    local zoneLabel = questData.zoneName
                    local isOffMapWorld = (questData.category == "WORLD") and questData.isTracked and not questData.isNearby
                    if isOffMapWorld then zoneLabel = ("[Off-map] %s"):format(zoneLabel) end
                    entry.zoneText:SetText(zoneLabel)
                    entry.zoneShadow:SetText(zoneLabel)
                    local zoneColor = (addon.GetZoneColor and addon.GetZoneColor(effectiveCat)) or addon.ZONE_COLOR or { 0.8, 0.8, 0.8 }
                    if shouldDim then
                        zoneColor = addon.ApplyDimColor(zoneColor)
                    end
                    entry.zoneText:SetTextColor(zoneColor[1], zoneColor[2], zoneColor[3], dimAlpha)
                end

                local objectives = questData.objectives or {}
                local maxObjs = addon.MAX_OBJECTIVES
                local showEllipsis = (questData.isAchievement or questData.isEndeavor) and #objectives > maxObjs

                -- Progress bar: determine if the entry has exactly 1 arithmetic objective with numRequired > 1
                local showProgressBarOpt = addon.GetDB("showObjectiveProgressBar", false)
                local progressBarObjIdx = nil
                if showProgressBarOpt and #objectives > 0 then
                    local arithmeticCount = 0
                    local arithmeticIdx = nil
                    for idx, o in ipairs(objectives) do
                        if o.numFulfilled ~= nil and o.numRequired ~= nil and type(o.numFulfilled) == "number" and type(o.numRequired) == "number" and o.numRequired > 1 then
                            arithmeticCount = arithmeticCount + 1
                            arithmeticIdx = idx
                        end
                    end
                    if arithmeticCount == 1 then
                        progressBarObjIdx = arithmeticIdx
                    end
                end

                for j = 1, addon.MAX_OBJECTIVES do
                    local obj = entry.objectives[j]
                    if not obj then break end

                    local oData = objectives[j]
                    if showEllipsis then
                        if j == maxObjs then oData = { text = "...", finished = false }
                        elseif j > maxObjs then oData = nil
                        end
                    end

                    if oData and oData.text then
                        local objText = oData.text or ""
                        local nf, nr = oData.numFulfilled, oData.numRequired
                        local thisObjHasBar = (progressBarObjIdx == j)
                        -- Skip appending (X/Y) when the title already shows it (single-criterion numeric achievement).
                        -- Also skip when a progress bar is shown for this objective.
                        local titleShowsNumeric = questData.numericQuantity ~= nil and questData.numericRequired and type(questData.numericRequired) == "number" and questData.numericRequired > 1
                        local singleObjective = #objectives == 1
                        if not thisObjHasBar and nf ~= nil and nr ~= nil and type(nf) == "number" and type(nr) == "number" and nr > 1 and not (titleShowsNumeric and singleObjective) then
                            local pattern = tostring(nf) .. "/" .. tostring(nr)
                            if not objText:find(pattern, 1, true) then
                                objText = objText .. (" (%d/%d)"):format(nf, nr)
                            end
                        end
                        if objectivePrefixStyle == "numbers" then
                            objText = ("%d. %s"):format(j, objText)
                        elseif objectivePrefixStyle == "hyphens" then
                            objText = "- " .. objText
                        end
                        local useTick = oData.finished and addon.GetDB("useTickForCompletedObjectives", false) and not questData.isComplete
                        obj.text:SetText(objText)
                        obj.shadow:SetText(objText)
                        local tickSize = math.max(MIN_TICK_SIZE, tonumber(addon.GetDB("objectiveFontSize", 11)) or 11)
                        if useTick and obj.tick then
                            obj.tick:SetSize(tickSize, tickSize)
                            obj.tick:ClearAllPoints()
                            obj.tick:SetPoint("RIGHT", obj.text, "LEFT", -4, 0)
                            obj.tick:Show()
                        elseif obj.tick then
                            obj.tick:Hide()
                        end
                        local alpha = 1
                        if oData.finished and (not questData.isAchievement and not questData.isEndeavor) and addon.GetDB("questCompletedObjectiveDisplay", "off") == "fade" then
                            alpha = COMPLETED_OBJECTIVE_FADE_ALPHA
                        end
                        if oData.finished then
                            if useTick then
                                obj.text:SetTextColor(objColor[1], objColor[2], objColor[3], alpha)
                            else
                                obj.text:SetTextColor(effectiveDoneColor[1], effectiveDoneColor[2], effectiveDoneColor[3], alpha)
                            end
                        else
                            obj.text:SetTextColor(objColor[1], objColor[2], objColor[3], alpha)
                        end

                        -- Update progress bar fill and label during combat refresh
                        if thisObjHasBar and nf and nr and type(nf) == "number" and type(nr) == "number" and nr > 0 and obj.progressBarFill then
                            local fraction = math.min(nf / nr, 1)
                            local barW = obj.progressBarBg and obj.progressBarBg:GetWidth() or 100
                            obj.progressBarFill:SetWidth(math.max(1, barW * fraction))
                            if obj.progressBarLabel then
                                local pct = math.floor(100 * fraction)
                                obj.progressBarLabel:SetText(("%d/%d (%d%%)"):format(nf, nr, pct))
                            end
                            local barFillColor
                            if addon.GetDB("progressBarUseCategoryColor", true) then
                                barFillColor = titleColor
                            else
                                barFillColor = addon.GetDB("progressBarFillColor", nil)
                                if not barFillColor or type(barFillColor) ~= "table" then barFillColor = { 0.40, 0.65, 0.90 } end
                            end
                            if barFillColor and barFillColor[1] and barFillColor[2] and barFillColor[3] then
                                obj.progressBarFill:SetColorTexture(barFillColor[1], barFillColor[2], barFillColor[3], barFillColor[4] or 0.85)
                            end
                        end
                    end
                end

                if questData.isComplete and (not objectives or #objectives == 0) then
                    local obj = entry.objectives[1]
                    if obj then
                        local turnInText = objectivePrefixStyle == "numbers" and "1. Ready to turn in"
                            or objectivePrefixStyle == "hyphens" and "- Ready to turn in"
                            or "Ready to turn in"
                        obj.text:SetText(turnInText)
                        obj.shadow:SetText(turnInText)
                        obj.text:SetTextColor(doneColor[1], doneColor[2], doneColor[3], 1)
                        if obj.tick then obj.tick:Hide() end
                    end
                end

                local isWorld = questData.category == "WORLD" or questData.category == "CALLING"
                local isScenario = questData.category == "SCENARIO"
                local hasEntryTimer = (questData.timerDuration and questData.timerStartTime) and true or false
                local isGenericTimed = (not isScenario) and hasEntryTimer and not questData.isRare
                local showTimerBarsToggle = addon.GetDB("showTimerBars", false)
                if showTimerBarsToggle and (((isWorld or isScenario) and not questData.isRare) or isGenericTimed) then
                    local timerStr
                    local remainingSec, durationSec
                    if questData.timerDuration and questData.timerStartTime then
                        remainingSec = questData.timerDuration - (GetTime() - questData.timerStartTime)
                        if remainingSec > 0 then
                            timerStr = addon.FormatTimeRemaining(remainingSec)
                            durationSec = questData.timerDuration
                        end
                    end
                    if not timerStr and questData.objectives then
                        for _, o in ipairs(questData.objectives) do
                            if o.timerDuration and o.timerStartTime then
                                remainingSec = o.timerDuration - (GetTime() - o.timerStartTime)
                                if remainingSec > 0 then
                                    timerStr = addon.FormatTimeRemaining(remainingSec)
                                    durationSec = o.timerDuration
                                    break
                                end
                            end
                        end
                    end
                    if not timerStr and questData.timeLeftSeconds and questData.timeLeftSeconds > 0 then
                        timerStr = addon.FormatTimeRemaining(questData.timeLeftSeconds)
                        remainingSec = questData.timeLeftSeconds
                        durationSec = questData.timeLeftSeconds
                    elseif not timerStr and questData.timeLeft and questData.timeLeft > 0 then
                        remainingSec = questData.timeLeft * 60
                        timerStr = addon.FormatTimeRemainingFromMinutes(questData.timeLeft)
                        durationSec = remainingSec
                    end
                    if timerStr then
                        local showTimer = isScenario or isGenericTimed or addon.GetDB("showWorldQuestTimer", true)
                        if showTimer then
                            local timerDisplayMode = addon.GetDB("timerDisplayMode", "inline")
                            if timerDisplayMode == "inline" and entry.inlineTimerText then
                                entry.inlineTimerText:SetText(" (" .. timerStr .. ")")
                                if addon.GetDB("timerColorByRemaining", false) and durationSec and remainingSec then
                                    local r, g, b = addon.GetTimerColorByRemaining(math.max(0, remainingSec), durationSec)
                                    local dimAlpha = (addon.GetDB("dimNonSuperTracked", false) and not questData.isSuperTracked) and addon.GetDimAlpha() or 1
                                    entry.inlineTimerText:SetTextColor(r, g, b, dimAlpha)
                                end
                            else
                                entry.wqTimerText:SetText(timerStr)
                                if addon.GetDB("timerColorByRemaining", false) and durationSec and remainingSec then
                                    local r, g, b = addon.GetTimerColorByRemaining(math.max(0, remainingSec), durationSec)
                                    entry.wqTimerText:SetTextColor(r, g, b, 1)
                                end
                            end
                        end
                    end

                    local firstPercent
                    for _, o in ipairs(objectives) do
                        if o.percent ~= nil and not o.finished then
                            local nr = o.numRequired
                            if nr ~= nil and type(nr) == "number" and nr > 1 then
                                firstPercent = o.percent
                                break
                            end
                        end
                    end
                    if firstPercent ~= nil then
                        entry.wqProgressText:SetText(tostring(firstPercent) .. "%")
                    end
                end
            end
        end
    end
end

addon.ToggleCollapse             = ToggleCollapse
addon.StartGroupCollapse         = StartGroupCollapse
addon.StartGroupCollapseVisual   = StartGroupCollapseVisual
addon.TriggerNearbyEntriesFadeIn = TriggerNearbyEntriesFadeIn
addon.StartNearbyTurnOnTransition = StartNearbyTurnOnTransition
addon.ShouldShowInInstance       = ShouldShowInInstance
addon.CountTrackedInLog          = CountTrackedInLog
addon.RefreshContentInCombat     = RefreshContentInCombat
