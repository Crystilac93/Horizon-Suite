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

local function FormatTimeLeftSeconds(seconds)
    if not seconds or seconds < 0 then return nil end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return ("%02d:%02d"):format(m, s)
end

local function FormatTimeLeftMinutes(minutes)
    if not minutes or minutes < 0 then return nil end
    local m = math.floor(minutes)
    local s = math.floor((minutes - m) * 60)
    return ("%02d:%02d"):format(m, s)
end

local function ToggleCollapse()
    if addon.focus.collapse.animating then
        if (GetTime() - addon.focus.collapse.animStart) < 2 then return end
        addon.focus.collapse.animating = false
        addon.focus.collapse.sectionHeadersFadingOut = false
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
        scrollFrame:Hide()
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
                scrollFrame:Hide()
                addon.focus.layout.targetHeight = addon.GetCollapsedHeight()
            end
        end
    else
        addon.chevron:SetText("-")
        scrollFrame:Show()
        if addon.GetDB("animations", true) then
            addon.focus.collapse.sectionHeadersFadingIn  = true
            addon.focus.collapse.sectionHeaderFadeTime    = 0
        end
        addon.FullLayout()
    end
    addon.EnsureDB()
    HorizonDB.collapsed = addon.focus.collapsed
end

function addon.StartGroupCollapse(groupKey)
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

function addon.StartGroupCollapseVisual(groupKey)
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

function addon.TriggerNearbyEntriesFadeIn()
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

function addon.StartNearbyTurnOnTransition()
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
        addon.onSlideOutCompleteCallback = function()
            addon.onSlideOutCompleteCallback = nil
            if addon.FullLayout then addon.FullLayout() end
            if addon.TriggerNearbyEntriesFadeIn then addon.TriggerNearbyEntriesFadeIn() end
        end
    else
        if addon.FullLayout then addon.FullLayout() end
        if addon.TriggerNearbyEntriesFadeIn then addon.TriggerNearbyEntriesFadeIn() end
    end
end

local function ShouldShowInInstance()
    local inType = select(2, GetInstanceInfo())
    if inType == "none" then return true end
    if inType == "party"  then return addon.GetDB("showInDungeon", false) end
    if inType == "raid"   then return addon.GetDB("showInRaid", false) end
    if inType == "pvp"    then return addon.GetDB("showInBattleground", false) end
    if inType == "arena"  then return addon.GetDB("showInArena", false) end
    return true
end

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

    local showObjectiveNumbers = addon.GetDB("showObjectiveNumbers", false)
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
                    objColor = { objColor[1] * 0.60, objColor[2] * 0.60, objColor[3] * 0.60 }
                    doneColor = { doneColor[1] * 0.60, doneColor[2] * 0.60, doneColor[3] * 0.60 }
                end
                local effectiveDoneColor = doneColor

                local displayTitle = questData.title or ""
                if (addon.GetDB("showCompletedCount", false) or questData.isAchievement or questData.isEndeavor) then
                    local done, total
                    if questData.criteriaDone and questData.criteriaTotal and type(questData.criteriaDone) == "number" and type(questData.criteriaTotal) == "number" and questData.criteriaTotal > 0 then
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
                        needSuffix = (questData.isAccepted == false and questData.isTracked == false)
                    elseif questData.category == "WEEKLY" or questData.category == "DAILY" then
                        needSuffix = (questData.isAccepted == false)
                    end
                    if needSuffix then displayTitle = displayTitle .. " **" end
                end
                displayTitle = addon.ApplyTextCase and addon.ApplyTextCase(displayTitle, "questTitleCase", "proper") or displayTitle
                entry.titleText:SetText(displayTitle)
                entry.titleShadow:SetText(displayTitle)
                local titleColor = (addon.GetTitleColor and addon.GetTitleColor(effectiveCat)) or questData.color
                if questData.isDungeonQuest and not questData.isTracked then
                    titleColor = { titleColor[1] * 0.65, titleColor[2] * 0.65, titleColor[3] * 0.65 }
                elseif shouldDim then
                    titleColor = { titleColor[1] * 0.60, titleColor[2] * 0.60, titleColor[3] * 0.60 }
                end
                entry.titleText:SetTextColor(titleColor[1], titleColor[2], titleColor[3], 1)

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
                        zoneColor = { zoneColor[1] * 0.60, zoneColor[2] * 0.60, zoneColor[3] * 0.60 }
                    end
                    entry.zoneText:SetTextColor(zoneColor[1], zoneColor[2], zoneColor[3], 1)
                end

                local objectives = questData.objectives or {}
                local showEllipsis = (questData.isAchievement or questData.isEndeavor) and #objectives > 4
                for j = 1, addon.MAX_OBJECTIVES do
                    local obj = entry.objectives[j]
                    if not obj then break end

                    local oData = objectives[j]
                    if showEllipsis then
                        if j == 5 then oData = { text = "...", finished = false }
                        elseif j > 4 then oData = nil
                        end
                    end

                    if oData and oData.text then
                        local objText = oData.text or ""
                        local nf, nr = oData.numFulfilled, oData.numRequired
                        if nf ~= nil and nr ~= nil and type(nf) == "number" and type(nr) == "number" and nr > 1 then
                            local pattern = tostring(nf) .. "/" .. tostring(nr)
                            if not objText:find(pattern, 1, true) then
                                objText = objText .. (" (%d/%d)"):format(nf, nr)
                            end
                        end
                        if showObjectiveNumbers then objText = ("%d. %s"):format(j, objText) end
                        local useTick = oData.finished and addon.GetDB("useTickForCompletedObjectives", false) and not questData.isComplete
                        obj.text:SetText(objText)
                        obj.shadow:SetText(objText)
                        local tickSize = math.max(10, tonumber(addon.GetDB("objectiveFontSize", 11)) or 11)
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
                            alpha = 0.4
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
                    end
                end

                if questData.isComplete and (not objectives or #objectives == 0) then
                    local obj = entry.objectives[1]
                    if obj then
                        local turnInText = showObjectiveNumbers and "1. Ready to turn in" or "Ready to turn in"
                        obj.text:SetText(turnInText)
                        obj.shadow:SetText(turnInText)
                        obj.text:SetTextColor(doneColor[1], doneColor[2], doneColor[3], 1)
                        if obj.tick then obj.tick:Hide() end
                    end
                end

                local isWorld = questData.category == "WORLD" or questData.category == "CALLING"
                local isScenario = questData.category == "SCENARIO"
                if (isWorld or isScenario) and not questData.isRare then
                    local timerStr
                    if questData.timeLeftSeconds and questData.timeLeftSeconds > 0 then
                        timerStr = FormatTimeLeftSeconds(questData.timeLeftSeconds)
                    elseif questData.timeLeft and questData.timeLeft > 0 then
                        timerStr = FormatTimeLeftMinutes(questData.timeLeft)
                    end
                    if timerStr then
                        local showTimer = isScenario or addon.GetDB("showWorldQuestTimer", true)
                        if showTimer then
                            entry.wqTimerText:SetText(timerStr)
                        end
                    end

                    local firstPercent
                    for _, o in ipairs(objectives) do
                        if o.percent ~= nil and not o.finished then firstPercent = o.percent; break end
                    end
                    if firstPercent ~= nil then
                        entry.wqProgressText:SetText(tostring(firstPercent) .. "%")
                    end
                end
            end
        end
    end
end

addon.ToggleCollapse        = ToggleCollapse
addon.ShouldShowInInstance  = ShouldShowInInstance
addon.CountTrackedInLog     = CountTrackedInLog
addon.RefreshContentInCombat = RefreshContentInCombat
