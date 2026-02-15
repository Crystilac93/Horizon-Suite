--[[
    Horizon Suite - Focus - Layout Engine
    PopulateEntry, FullLayout, ToggleCollapse, AcquireEntry, section headers, header button, keybind, floating item, M+ block.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- LAYOUT ENGINE
-- ============================================================================

addon.targetHeight  = addon.MIN_HEIGHT
addon.currentHeight = addon.MIN_HEIGHT

local pool       = addon.pool
local activeMap  = addon.activeMap
local sectionPool = addon.sectionPool
local scrollChild = addon.scrollChild
local scrollFrame = addon.scrollFrame

--- Player's current zone name from map API. Used to suppress redundant zone labels for in-zone quests.
--- Schedule deferred refreshes when Endeavors or Decor have placeholder names (API data not yet loaded).
local function SchedulePlaceholderRefreshes(quests)
    if addon.placeholderRefreshScheduled then return end
    for _, q in ipairs(quests) do
        local isEndeavorPlaceholder = q.isEndeavor and q.endeavorID and q.title == ("Endeavor " .. tostring(q.endeavorID))
        local isDecorPlaceholder = q.isDecor and q.decorID and q.title == ("Decor " .. tostring(q.decorID))
        if isEndeavorPlaceholder or isDecorPlaceholder then
            addon.placeholderRefreshScheduled = true
            C_Timer.After(2, function()
                if addon.enabled and addon.ScheduleRefresh then addon.ScheduleRefresh() end
            end)
            C_Timer.After(4, function()
                if addon.enabled and addon.ScheduleRefresh then addon.ScheduleRefresh() end
            end)
            break
        end
    end
end

local function GetPlayerCurrentZoneName()
    if not C_Map or not C_Map.GetBestMapForUnit then return nil end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or not C_Map.GetMapInfo then return nil end
    local info = C_Map.GetMapInfo(mapID)
    return info and info.name or nil
end

local function hideAllHighlight(entry)
    entry.trackBar:Hide()
    entry.highlightBg:Hide()
    if entry.highlightTop then entry.highlightTop:Hide() end
    entry.highlightBorderT:Hide()
    entry.highlightBorderB:Hide()
    entry.highlightBorderL:Hide()
    entry.highlightBorderR:Hide()
end

local function ApplyHighlightStyle(entry, questData)
    local highlightStyle = addon.NormalizeHighlightStyle(addon.GetDB("activeQuestHighlight", "bar-left")) or "bar-left"
    local hc = addon.GetDB("highlightColor", nil)
    if not hc or #hc < 3 then hc = { 0.40, 0.70, 1.00 } end
    local ha = tonumber(addon.GetDB("highlightAlpha", 0.25)) or 0.25
    local barW = math.max(2, math.min(6, tonumber(addon.GetDB("highlightBarWidth", 2)) or 2))
    local topPadding = (questData.isSuperTracked and highlightStyle == "bar-top") and barW or 0
    local bottomPadding = (questData.isSuperTracked and highlightStyle == "bar-bottom") and barW or 0

    entry.titleText:ClearAllPoints()
    entry.titleText:SetPoint("TOPLEFT", entry, "TOPLEFT", 0, -topPadding)
    entry.titleShadow:ClearAllPoints()
    entry.titleShadow:SetPoint("CENTER", entry.titleText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

    hideAllHighlight(entry)
    if questData.isSuperTracked then
        local borderAlpha = math.min(1, (ha + 0.35))
        if highlightStyle == "bar-left" or highlightStyle == "bar-right" or highlightStyle == "pill-left" then
            entry.trackBar:SetColorTexture(hc[1], hc[2], hc[3], 0.70)
            entry.trackBar:Show()
        elseif highlightStyle == "bar-top" then
            entry.highlightTop:SetColorTexture(hc[1], hc[2], hc[3], 0.70)
            entry.highlightTop:SetHeight(barW)
            entry.highlightTop:Show()
        elseif highlightStyle == "bar-bottom" then
            entry.highlightBorderB:SetColorTexture(hc[1], hc[2], hc[3], 0.70)
            entry.highlightBorderB:SetHeight(barW)
            entry.highlightBorderB:Show()
        elseif highlightStyle == "outline" then
            entry.highlightBorderB:SetHeight(1)
            entry.highlightBorderL:SetWidth(1)
            entry.highlightBorderR:SetWidth(1)
            for _, tex in ipairs({ entry.highlightBorderT, entry.highlightBorderB, entry.highlightBorderL, entry.highlightBorderR }) do
                tex:SetColorTexture(hc[1], hc[2], hc[3], borderAlpha)
                tex:Show()
            end
        elseif highlightStyle == "bar-both" then
            entry.highlightBorderL:SetColorTexture(hc[1], hc[2], hc[3], 0.70)
            entry.highlightBorderL:SetWidth(2)
            entry.highlightBorderL:Show()
            entry.highlightBorderR:SetColorTexture(hc[1], hc[2], hc[3], 0.70)
            entry.highlightBorderR:SetWidth(2)
            entry.highlightBorderR:Show()
        else
            entry.highlightBg:SetColorTexture(hc[1], hc[2], hc[3], ha)
            entry.highlightBg:Show()
            entry.highlightTop:SetHeight(2)
            entry.highlightTop:SetColorTexture(hc[1], hc[2], hc[3], math.min(1, ha + 0.2))
            entry.highlightTop:Show()
            for _, tex in ipairs({ entry.highlightBorderT, entry.highlightBorderB, entry.highlightBorderL, entry.highlightBorderR }) do
                tex:SetColorTexture(hc[1], hc[2], hc[3], borderAlpha)
                tex:Show()
            end
        end
    end
    return highlightStyle, hc, ha, barW, topPadding, bottomPadding
end

local function ApplyObjectives(entry, questData, textWidth, prevAnchor, totalH, c, effectiveCat)
    local objIndent = addon.GetObjIndent()
    local objTextWidth = textWidth - objIndent
    if objTextWidth < 1 then objTextWidth = addon.GetPanelWidth() - addon.PADDING * 2 - objIndent - (addon.CONTENT_RIGHT_PADDING or 0) end

    local objSpacing = ((questData.category == "DELVES" or questData.category == "DUNGEON") and addon.DELVE_OBJ_SPACING) or addon.GetObjSpacing()

    local cat = (effectiveCat ~= nil and effectiveCat ~= "") and effectiveCat or questData.category
    local objColor = (addon.GetObjectiveColor and addon.GetObjectiveColor(cat)) or addon.OBJ_COLOR or c
    -- Completed objectives use effective category colour (respects override toggle)
    local doneColor = (addon.GetObjectiveColor and addon.GetObjectiveColor(cat)) or addon.OBJ_DONE_COLOR
    if addon.GetDB("dimNonSuperTracked", false) and not questData.isSuperTracked then
        objColor = { objColor[1] * 0.60, objColor[2] * 0.60, objColor[3] * 0.60 }
        doneColor = { doneColor[1] * 0.60, doneColor[2] * 0.60, doneColor[3] * 0.60 }
    end
    -- Achievements: completed criteria use quest-log green instead of category bronze
    local effectiveDoneColor = (questData.isAchievement and addon.OBJ_DONE_COLOR) or doneColor
    if questData.isAchievement and addon.GetDB("dimNonSuperTracked", false) and not questData.isSuperTracked then
        effectiveDoneColor = { effectiveDoneColor[1] * 0.60, effectiveDoneColor[2] * 0.60, effectiveDoneColor[3] * 0.60 }
    end

    local showEllipsis = (questData.isAchievement or questData.isEndeavor) and questData.objectives and #questData.objectives > 4
    local shownObjs = 0
    for j = 1, addon.MAX_OBJECTIVES do
        local obj = entry.objectives[j]
        local oData = questData.objectives[j]
        if showEllipsis then
            if j == 5 then
                oData = { text = "...", finished = false }
            elseif j > 4 then
                oData = nil
            end
        end

        obj.text:SetWidth(objTextWidth)
        obj.shadow:SetWidth(objTextWidth)

        if oData then
            local objText = oData.text or ""
            if addon.GetDB("showObjectiveNumbers", false) then
                objText = ("%d. %s"):format(j, objText)
            end
            obj.text:SetText(objText)
            obj.shadow:SetText(objText)

            if oData.finished then
                obj.text:SetTextColor(effectiveDoneColor[1], effectiveDoneColor[2], effectiveDoneColor[3], 1)
            else
                obj.text:SetTextColor(objColor[1], objColor[2], objColor[3], 1)
            end

            obj.text:ClearAllPoints()
            local indent = (shownObjs == 0 and prevAnchor == entry.titleText) and objIndent or 0
            obj.text:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", indent, -objSpacing)
            obj.text:Show()
            obj.shadow:Show()

            local objH = obj.text:GetStringHeight()
            if not objH or objH < 1 then objH = addon.OBJ_SIZE + 2 end
            totalH = totalH + objSpacing + objH

            prevAnchor = obj.text
            shownObjs = shownObjs + 1
        else
            obj.text:Hide()
            obj.shadow:Hide()
        end
    end

    if questData.isComplete and shownObjs == 0 then
        local obj = entry.objectives[1]
        local turnInText = addon.GetDB("showObjectiveNumbers", false) and "1. Ready to turn in" or "Ready to turn in"
        obj.text:SetText(turnInText)
        obj.shadow:SetText(turnInText)
        obj.text:SetTextColor(doneColor[1], doneColor[2], doneColor[3], 1)
        obj.text:ClearAllPoints()
        local turnInIndent = (prevAnchor == entry.titleText) and objIndent or 0
        obj.text:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", turnInIndent, -objSpacing)
        obj.text:Show()
        obj.shadow:Show()
        local objH = obj.text:GetStringHeight()
        if not objH or objH < 1 then objH = addon.OBJ_SIZE + 2 end
        totalH = totalH + objSpacing + objH
        prevAnchor = obj.text
    end

    return totalH, prevAnchor
end

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

local function ApplyScenarioOrWQTimerBar(entry, questData, textWidth, prevAnchor, totalH)
    -- Delves: no timer or progress bar; show only delve name and objectives.
    if questData.category == "DELVES" then
        entry.wqTimerText:Hide()
        entry.wqProgressBg:Hide()
        entry.wqProgressFill:Hide()
        entry.wqProgressText:Hide()
        if entry.scenarioTimerBars then
            for _, bar in ipairs(entry.scenarioTimerBars) do bar:Hide() end
        end
        return totalH
    end
    local isWorld = questData.category == "WORLD" or questData.category == "CALLING"
    local isScenario = questData.category == "SCENARIO"
    if (not isWorld and not isScenario) or questData.isRare then
        entry.wqTimerText:Hide()
        entry.wqProgressBg:Hide()
        entry.wqProgressFill:Hide()
        entry.wqProgressText:Hide()
        if entry.scenarioTimerBars then
            for _, bar in ipairs(entry.scenarioTimerBars) do bar:Hide() end
        end
        return totalH
    end

    local objIndent = addon.GetObjIndent()
    local barW = textWidth - objIndent
    if barW < 40 then barW = addon.GetPanelWidth() - addon.PADDING * 2 - objIndent - (addon.CONTENT_RIGHT_PADDING or 0) end
    local barH = addon.WQ_TIMER_BAR_HEIGHT or 6
    local spacing = addon.GetObjSpacing()
    local scenarioBarTopMargin = isScenario and 4 or 0
    local scenarioFirstElementPlaced = false

    local showBar
    -- Scenario per-criteria timer bars (KT-aligned): one bar per objective/criterion with timer.
    if isScenario and entry.scenarioTimerBars and addon.GetDB("cinematicScenarioBar", true) then
        local timerSources = {}
        for _, o in ipairs(questData.objectives or {}) do
            if o.timerDuration and o.timerStartTime then
                timerSources[#timerSources + 1] = { duration = o.timerDuration, startTime = o.timerStartTime }
            end
        end
        if #timerSources == 0 and questData.timerDuration and questData.timerStartTime then
            timerSources[#timerSources + 1] = { duration = questData.timerDuration, startTime = questData.timerStartTime }
        end
        local barHeight = math.max(4, math.min(8, tonumber(addon.GetDB("scenarioBarHeight", 6)) or 6))
        for i, src in ipairs(timerSources) do
            local bar = entry.scenarioTimerBars[i]
            if bar then
                local barSpacing = (i == 1) and (spacing + scenarioBarTopMargin) or spacing
                bar.duration = src.duration
                bar.startTime = src.startTime
                bar:SetWidth(barW)
                bar:SetHeight(barHeight)
                bar:ClearAllPoints()
                bar:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", objIndent, -barSpacing)
                bar:Show()
                totalH = totalH + barSpacing + barHeight
                prevAnchor = bar
                scenarioFirstElementPlaced = true
            end
        end
        for i = #timerSources + 1, #(entry.scenarioTimerBars or {}) do
            local bar = entry.scenarioTimerBars[i]
            if bar then bar.duration = nil; bar.startTime = nil; bar:Hide() end
        end
        entry.wqTimerText:Hide()
        showBar = addon.GetDB("cinematicScenarioBar", true)
    else
        if entry.scenarioTimerBars then
            for _, bar in ipairs(entry.scenarioTimerBars) do
                bar.duration = nil
                bar.startTime = nil
                bar:Hide()
            end
        end

        local timerStr
        if questData.timeLeftSeconds and questData.timeLeftSeconds > 0 then
            timerStr = FormatTimeLeftSeconds(questData.timeLeftSeconds)
        elseif questData.timeLeft and questData.timeLeft > 0 then
            timerStr = FormatTimeLeftMinutes(questData.timeLeft)
        end

        local showTimer
        if isScenario then
            showTimer = (timerStr ~= nil)
            showBar = addon.GetDB("cinematicScenarioBar", true)
        else
            showTimer = addon.GetDB("showWorldQuestTimer", true) and (timerStr ~= nil)
            showBar = addon.GetDB("showWorldQuestProgressBar", true)
        end

        if showTimer and timerStr then
            local timerSpacing = isScenario and (spacing + scenarioBarTopMargin) or spacing
            entry.wqTimerText:SetText(timerStr)
            entry.wqTimerText:SetWidth(barW)
            entry.wqTimerText:ClearAllPoints()
            entry.wqTimerText:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", objIndent, -timerSpacing)
            if isScenario then
                local sc = addon.GetQuestColor and addon.GetQuestColor(questData.category) or (addon.QUEST_COLORS and addon.QUEST_COLORS[questData.category]) or { 0.38, 0.52, 0.88 }
                entry.wqTimerText:SetTextColor(sc[1], sc[2], sc[3], 1)
            else
                entry.wqTimerText:SetTextColor(1, 1, 1, 1)
            end
            entry.wqTimerText:Show()
            local th = entry.wqTimerText:GetStringHeight()
            if not th or th < 1 then th = addon.OBJ_SIZE + 2 end
            totalH = totalH + timerSpacing + th
            prevAnchor = entry.wqTimerText
            if isScenario then scenarioFirstElementPlaced = true end
        else
            entry.wqTimerText:Hide()
        end
    end

    local firstPercent
    for _, o in ipairs(questData.objectives or {}) do
        if o.percent ~= nil and not o.finished then
            firstPercent = o.percent
            break
        end
    end
    if showBar and firstPercent ~= nil then
        local barHeight = barH
        if isScenario then
            barHeight = math.max(4, math.min(8, tonumber(addon.GetDB("scenarioBarHeight", 6)) or 6))
        end
        local percentBarSpacing = spacing + (isScenario and not scenarioFirstElementPlaced and scenarioBarTopMargin or 0)
        entry.wqProgressBg:SetHeight(barHeight)
        entry.wqProgressBg:SetWidth(barW)
        entry.wqProgressBg:ClearAllPoints()
        entry.wqProgressBg:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", objIndent, -percentBarSpacing)
        if isScenario then
            local opacity = tonumber(addon.GetDB("scenarioBarOpacity", 0.85)) or 0.85
            entry.wqProgressBg:SetColorTexture(0.08, 0.06, 0.12, math.max(0.35, opacity * 0.45))
        else
            entry.wqProgressBg:SetColorTexture(0.2, 0.2, 0.25, 0.8)
        end
        entry.wqProgressBg:Show()
        local pct = firstPercent and math.min(100, math.max(0, firstPercent)) or 0
        entry.wqProgressFill:SetHeight(barHeight)
        entry.wqProgressFill:SetWidth(math.max(2, barW * pct / 100))
        entry.wqProgressFill:ClearAllPoints()
        entry.wqProgressFill:SetPoint("TOPLEFT", entry.wqProgressBg, "TOPLEFT", 0, 0)
        if isScenario then
            local sc = addon.GetQuestColor and addon.GetQuestColor(questData.category) or (addon.QUEST_COLORS and addon.QUEST_COLORS[questData.category]) or { 0.38, 0.52, 0.88 }
            local fillOpacity = tonumber(addon.GetDB("scenarioBarOpacity", 0.85)) or 0.85
            local r, g, b = sc[1] * 0.9, sc[2] * 0.9, sc[3] * 1.0
            entry.wqProgressFill:SetColorTexture(r, g, b, math.min(0.92, fillOpacity))
        else
            entry.wqProgressFill:SetColorTexture(0.45, 0.35, 0.65, 0.9)
        end
        entry.wqProgressFill:Show()
        entry.wqProgressText:SetText(firstPercent ~= nil and (tostring(firstPercent) .. "%") or "")
        entry.wqProgressText:ClearAllPoints()
        entry.wqProgressText:SetPoint("CENTER", entry.wqProgressBg, "CENTER", 0, 0)
        if isScenario then
            entry.wqProgressText:SetTextColor(1, 1, 1, 0.92)
        else
            entry.wqProgressText:SetTextColor(0.9, 0.9, 0.9, 1)
        end
        entry.wqProgressText:SetShown(firstPercent ~= nil)
        totalH = totalH + percentBarSpacing + barHeight
    else
        entry.wqProgressBg:Hide()
        entry.wqProgressFill:Hide()
        entry.wqProgressText:Hide()
    end

    return totalH
end

local function ApplyShadowColors(entry, questData, highlightStyle, hc, ha)
    local shadowA = addon.GetDB("showTextShadow", true) and (tonumber(addon.GetDB("shadowAlpha", 0.8)) or 0.8) or 0
    local glowAlpha = math.min(1, ha + 0.4)
    if questData.isSuperTracked and highlightStyle == "glow" then
        entry.titleShadow:SetTextColor(hc[1], hc[2], hc[3], glowAlpha)
        entry.zoneShadow:SetTextColor(hc[1], hc[2], hc[3], glowAlpha)
        for j = 1, addon.MAX_OBJECTIVES do
            entry.objectives[j].shadow:SetTextColor(hc[1], hc[2], hc[3], glowAlpha)
        end
    else
        entry.titleShadow:SetTextColor(0, 0, 0, shadowA)
        entry.zoneShadow:SetTextColor(0, 0, 0, shadowA)
        for j = 1, addon.MAX_OBJECTIVES do
            entry.objectives[j].shadow:SetTextColor(0, 0, 0, shadowA)
        end
    end
end

--- Populate a single quest/rare entry frame with title, zone, objectives, highlight, and track bar.
-- @param entry table Pool entry frame (from addon.pool)
-- @param questData table Quest or rare data (title, objectives, color, isSuperTracked, etc.)
-- @param groupKey string Group this entry is in (e.g. COMPLETE, NEARBY); used for override colour resolution.
-- @return number Total height of the entry in pixels
local function PopulateEntry(entry, questData, groupKey)
    local hasItem = (questData.itemTexture and questData.itemLink) and true or false
    local showItemBtn = hasItem and addon.GetDB("showQuestItemButtons", false)
    local showQuestIcons = addon.GetDB("showQuestTypeIcons", false)
    local showAchievementIcons = addon.GetDB("showAchievementIcons", true)
    local showDecorIcons = addon.GetDB("showDecorIcons", true)
    local hasIcon = (questData.questTypeAtlas and showQuestIcons) or (questData.isAchievement and questData.achievementIcon and showQuestIcons and showAchievementIcons) or (questData.isDecor and questData.decorIcon and showQuestIcons and showDecorIcons)
    -- Off-map WORLD quest that is tracked (only world quests, not normal quests).
    local isOffMapWorld = (questData.category == "WORLD") and questData.isTracked and not questData.isNearby

    local leftOffset = addon.GetContentLeftOffset and addon.GetContentLeftOffset() or (addon.PADDING + addon.ICON_COLUMN_WIDTH)
    local textWidth = addon.GetPanelWidth() - addon.PADDING - leftOffset - (addon.CONTENT_RIGHT_PADDING or 0)

    -- All titles share the same X offset; we are no longer indenting off-map quests.
    local titleLeftOffset = 0

    if questData.category == "DELVES" then
        entry.questTypeIcon:SetAtlas(addon.DELVE_TIER_ATLAS)
        entry.questTypeIcon:Show()
    elseif questData.isAchievement and questData.achievementIcon and showQuestIcons and showAchievementIcons then
        entry.questTypeIcon:SetTexture(questData.achievementIcon)
        entry.questTypeIcon:Show()
    elseif questData.isDecor and questData.decorIcon and showQuestIcons and showDecorIcons then
        entry.questTypeIcon:SetTexture(questData.decorIcon)
        entry.questTypeIcon:Show()
    elseif hasIcon then
        entry.questTypeIcon:SetAtlas(questData.questTypeAtlas)
        entry.questTypeIcon:Show()
    else
        entry.questTypeIcon:Hide()
    end
    -- Ensure any legacy off-map icon (if present on the frame) is hidden; we now rely on color/text only.
    if entry.trackedFromOtherZoneIcon then
        entry.trackedFromOtherZoneIcon:Hide()
    end

    entry.titleText:SetWidth(textWidth)
    entry.titleShadow:SetWidth(textWidth)

    local displayTitle = questData.title
    if (addon.GetDB("showCompletedCount", false) or questData.isAchievement or questData.isEndeavor) then
        local done, total
        if questData.criteriaDone and questData.criteriaTotal and type(questData.criteriaDone) == "number" and type(questData.criteriaTotal) == "number" and questData.criteriaTotal > 0 then
            done, total = questData.criteriaDone, questData.criteriaTotal
        elseif questData.objectives and #questData.objectives > 0 then
            done, total = 0, #questData.objectives
            for _, o in ipairs(questData.objectives) do if o.finished then done = done + 1 end end
        end
        if done and total then
            displayTitle = ("%s (%d/%d)"):format(questData.title, done, total)
        end
    end
    if addon.GetDB("showQuestLevel", false) and questData.level then
        displayTitle = ("%s [L%d]"):format(displayTitle, questData.level)
    end
    if questData.category == "DELVES" and type(questData.delveTier) == "number" then
        displayTitle = displayTitle .. (" (Tier %d)"):format(questData.delveTier)
    end
    -- ** = not in quest log. WORLD: also require not on WQ watch list (tracked). WEEKLY/DAILY: only "not in log".
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
    displayTitle = addon.ApplyTextCase(displayTitle, "questTitleCase", "proper")
    entry.titleText:SetText(displayTitle)
    entry.titleShadow:SetText(displayTitle)
    local effectiveCat = (addon.GetEffectiveColorCategory and addon.GetEffectiveColorCategory(questData.category, groupKey, questData.baseCategory)) or questData.category
    local c = (addon.GetTitleColor and addon.GetTitleColor(effectiveCat)) or questData.color
    if questData.isDungeonQuest and not questData.isTracked then
        c = { c[1] * 0.65, c[2] * 0.65, c[3] * 0.65 }
    elseif addon.GetDB("dimNonSuperTracked", false) and not questData.isSuperTracked then
        c = { c[1] * 0.60, c[2] * 0.60, c[3] * 0.60 }
    end
    entry.titleText:SetTextColor(c[1], c[2], c[3], 1)
    entry._savedColor = nil

    local highlightStyle, hc, ha, barW, topPadding, bottomPadding = ApplyHighlightStyle(entry, questData)

    -- For tracked WORLD quests that are not on the current map (off-map world quests),
    -- add a subtle tinted background so they stand out, without affecting normal quests.
    -- No special highlight for off-map quests; only the active (super-tracked) quest uses the highlight styles above.

    if showItemBtn then
        entry.itemLink = questData.itemLink
        entry.itemBtn.icon:SetTexture(questData.itemTexture)
        if not InCombatLockdown() then
            entry.itemBtn:SetAttribute("type", "item")
            entry.itemBtn:SetAttribute("item", questData.itemLink)
        end
        entry.itemBtn:Show()
        addon.ApplyItemCooldown(entry.itemBtn.cooldown, questData.itemLink)
        local leftExtend = (addon.BAR_LEFT_OFFSET or 12) + 2 + addon.QUEST_TYPE_ICON_SIZE + 10 + addon.ITEM_BTN_SIZE
        entry:SetHitRectInsets(-leftExtend, 0, 0, 0)
    else
        entry.itemLink = nil
        entry.itemBtn:Hide()
        if not InCombatLockdown() then
            entry.itemBtn:SetAttribute("item", nil)
        end
        entry:SetHitRectInsets(0, 0, 0, 0)
    end

    local titleH = entry.titleText:GetStringHeight()
    if not titleH or titleH < 1 then titleH = addon.TITLE_SIZE + 4 end
    local totalH = titleH

    local prevAnchor = entry.titleText
    local titleToContentSpacing = ((questData.category == "DELVES" or questData.category == "DUNGEON") and addon.DELVE_OBJ_SPACING) or addon.GetObjSpacing()
    local showZoneLabels = addon.GetDB("showZoneLabels", true)
    local playerZone = GetPlayerCurrentZoneName()
    local inCurrentZone = questData.isNearby or (questData.zoneName and playerZone and questData.zoneName:lower() == playerZone:lower())
    local shouldShowZone = showZoneLabels and questData.zoneName and not inCurrentZone
    if shouldShowZone then
        local zoneLabel = questData.zoneName
        -- For off-map WORLD quests, prefix the zone with a clear marker so they are easy to spot.
        if isOffMapWorld then
            zoneLabel = ("[Off-map] %s"):format(zoneLabel)
        end
        entry.zoneText:SetText(zoneLabel)
        entry.zoneShadow:SetText(zoneLabel)
        local zoneColor = (addon.GetZoneColor and addon.GetZoneColor(effectiveCat)) or addon.ZONE_COLOR
        if addon.GetDB("dimNonSuperTracked", false) and not questData.isSuperTracked then
            zoneColor = { zoneColor[1] * 0.60, zoneColor[2] * 0.60, zoneColor[3] * 0.60 }
        end
        entry.zoneText:SetTextColor(zoneColor[1], zoneColor[2], zoneColor[3], 1)
        entry.zoneText:ClearAllPoints()
        entry.zoneText:SetPoint("TOPLEFT", entry.titleText, "BOTTOMLEFT", addon.GetObjIndent(), -titleToContentSpacing)
        entry.zoneText:Show()
        entry.zoneShadow:Show()
        local zoneH = entry.zoneText:GetStringHeight()
        if not zoneH or zoneH < 1 then zoneH = addon.ZONE_SIZE + 2 end
        totalH = totalH + titleToContentSpacing + zoneH
        prevAnchor = entry.zoneText
    else
        entry.zoneText:Hide()
        entry.zoneShadow:Hide()
    end

    totalH, prevAnchor = ApplyObjectives(entry, questData, textWidth, prevAnchor, totalH, c, effectiveCat)
    totalH = ApplyScenarioOrWQTimerBar(entry, questData, textWidth, prevAnchor or entry.titleText, totalH)

    entry.entryHeight = totalH + topPadding + bottomPadding
    entry:SetHeight(totalH + topPadding + bottomPadding)

    ApplyShadowColors(entry, questData, highlightStyle, hc, ha)

    -- Active-quest bar: position after entry has final height (left, right, or pill-left)
    local trackBarW = (highlightStyle == "pill-left") and barW or 2
    if (highlightStyle == "bar-left" or highlightStyle == "bar-right" or highlightStyle == "pill-left") and entry.trackBar:IsShown() then
        entry.trackBar:ClearAllPoints()
        if highlightStyle == "bar-left" or highlightStyle == "pill-left" then
            local barLeft = addon.BAR_LEFT_OFFSET or 12
            entry.trackBar:SetPoint("TOPLEFT", entry, "TOPLEFT", -barLeft, 0)
            entry.trackBar:SetPoint("BOTTOMRIGHT", entry, "BOTTOMLEFT", -barLeft + trackBarW, 0)
        else
            local barInsetRight = addon.ICON_COLUMN_WIDTH - addon.PADDING + 4
            entry.trackBar:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -barInsetRight, 0)
            entry.trackBar:SetPoint("BOTTOMLEFT", entry, "BOTTOMRIGHT", -barInsetRight - trackBarW, 0)
        end
    end

    if questData.isRare then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.category   = nil
        entry.creatureID = questData.creatureID
        entry.achievementID = nil
        entry.endeavorID = nil
        entry.decorID    = nil
        entry.itemLink   = nil
        entry.isTracked  = nil
    elseif questData.isAchievement or questData.category == "ACHIEVEMENT" then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.category   = nil
        entry.creatureID = nil
        entry.achievementID = questData.achievementID
        entry.endeavorID = nil
        entry.isTracked  = true
    elseif questData.isEndeavor or questData.category == "ENDEAVOR" then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.category   = nil
        entry.creatureID = nil
        entry.achievementID = nil
        entry.endeavorID = questData.endeavorID
        entry.decorID    = nil
        entry.isTracked  = true
    elseif questData.isDecor or questData.category == "DECOR" then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.category   = nil
        entry.creatureID = nil
        entry.achievementID = nil
        entry.endeavorID = nil
        entry.decorID    = questData.decorID
        entry.isTracked  = true
        elseif questData.isScenarioMain or questData.isScenarioBonus then
        entry.questID    = questData.questID
        entry.entryKey   = questData.entryKey
        entry.category   = questData.category
        entry.creatureID = nil
        entry.achievementID = nil
        entry.endeavorID = nil
        entry.decorID    = nil
        entry.isTracked  = questData.isTracked
    else
        entry.questID    = questData.questID
        entry.entryKey   = nil
        entry.category   = questData.category
        entry.creatureID = nil
        entry.achievementID = nil
        entry.endeavorID = nil
        entry.decorID    = nil
        entry.isTracked  = questData.isTracked
    end
    return totalH
end

local function AcquireEntry()
    for i = 1, addon.POOL_SIZE do
        if pool[i].animState == "idle" and not pool[i].questID and not pool[i].entryKey then
            return pool[i]
        end
    end
    for i = 1, addon.POOL_SIZE do
        if pool[i].animState == "fadeout" then
            addon.ClearEntry(pool[i])
            return pool[i]
        end
    end
    return nil
end

local function HideAllSectionHeaders()
    for i = 1, addon.SECTION_POOL_SIZE do
        sectionPool[i].active = false
        sectionPool[i]:Hide()
        sectionPool[i]:SetAlpha(0)
    end
end

local function GetFocusedGroupKey(grouped)
    if not grouped then return nil end
    for _, grp in ipairs(grouped) do
        for _, qData in ipairs(grp.quests) do
            if qData.isSuperTracked then
                return grp.key
            end
        end
    end
    return nil
end

addon.sectionIdx = 0
local function AcquireSectionHeader(groupKey, focusedGroupKey)
    addon.sectionIdx = addon.sectionIdx + 1
    if addon.sectionIdx > addon.SECTION_POOL_SIZE then return nil end
    local s = sectionPool[addon.sectionIdx]
    s.groupKey = groupKey

    local label = addon.SECTION_LABELS[groupKey] or groupKey
    label = addon.ApplyTextCase(label, "sectionHeaderTextCase", "upper")
    local color = addon.GetSectionColor(groupKey)
    if addon.GetDB("dimNonSuperTracked", false) and focusedGroupKey and groupKey ~= focusedGroupKey then
        color = { color[1] * 0.60, color[2] * 0.60, color[3] * 0.60 }
    end
    s.text:SetText(label)
    s.shadow:SetText(label)
    s.text:SetTextColor(color[1], color[2], color[3], addon.SECTION_COLOR_A)

    -- Update chevron to reflect current collapsed state.
    -- When panel is collapsed with headers visible, all show "+".
    if s.chevron then
        if addon.collapsed and addon.GetDB("showSectionHeadersWhenCollapsed", false) then
            s.chevron:SetText("+")
        elseif addon.IsCategoryCollapsed(groupKey) then
            s.chevron:SetText("+")
        else
            s.chevron:SetText("−")
        end
    end

    -- Clicking the section header toggles collapsed state for this category,
    -- using animated collapse when hiding a group.
    s:SetScript("OnClick", function(self)
        local key = self.groupKey
        if not key then return end

        if addon.IsCategoryCollapsed(key) then
            -- EXPAND: flip state immediately, then reflow; new entries will fade in.
            addon.SetCategoryCollapsed(key, false)
            if self.chevron then
                self.chevron:SetText("−")
            end
            if addon.collapsed then
                addon.collapsed = false
                addon.EnsureDB()
                if HorizonDB then HorizonDB.collapsed = false end
                addon.chevron:SetText("-")
                scrollFrame:Show()
            end
            addon.FullLayout()
        else
            -- COLLAPSE: start animated collapse, do not call FullLayout yet.
            if self.chevron then
                self.chevron:SetText("+")
            end
            if addon.StartGroupCollapse then
                addon.StartGroupCollapse(key)
            end
        end
    end)

    s.active = true
    s:SetAlpha(1)
    s:Show()
    return s
end

local function ToggleCollapse()
    if addon.collapseAnimating then
        if (GetTime() - addon.collapseAnimStart) < 2 then return end
        addon.collapseAnimating = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].animState == "collapsing" then
                addon.ClearEntry(pool[i])
            end
        end
        wipe(activeMap)
        scrollFrame:Hide()
        addon.targetHeight = addon.GetCollapsedHeight()
    end

    addon.collapsed = not addon.collapsed
    if addon.collapsed then
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
            e.animState     = "collapsing"
            e.animTime      = 0
            e.collapseDelay = 0
        end

        local showHeadersWhenCollapsed = addon.GetDB("showSectionHeadersWhenCollapsed", false)
        if not showHeadersWhenCollapsed then
            for i = 1, addon.SECTION_POOL_SIZE do
                if sectionPool[i].active then
                    sectionPool[i]:SetAlpha(0)
                    sectionPool[i]:Hide()
                    sectionPool[i].active = false
                end
            end
        end

        addon.collapseAnimating = #visibleEntries > 0
        addon.collapseAnimStart = GetTime()
        if addon.collapseAnimating and addon.EnsureFocusUpdateRunning then
            addon.EnsureFocusUpdateRunning()
        end
        if not addon.collapseAnimating then
            if showHeadersWhenCollapsed then
                addon.FullLayout()
            else
                scrollFrame:Hide()
                addon.targetHeight = addon.GetCollapsedHeight()
            end
        end
    else
        addon.chevron:SetText("-")
        scrollFrame:Show()
        addon.FullLayout()
    end
    addon.EnsureDB()
    HorizonDB.collapsed = addon.collapsed
end

-- Start an animated collapse for a single category group.
function addon.StartGroupCollapse(groupKey)
    if not groupKey then return end

    -- Collect visible entries belonging to this group.
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
        -- Nothing visible to collapse; just persist state and reflow.
        addon.SetCategoryCollapsed(groupKey, true)
        addon.FullLayout()
        return
    end

    -- Sort by Y position so we get a clean stagger from top to bottom.
    table.sort(entries, function(a, b)
        return a.finalY > b.finalY
    end)

    -- Set collapsing state with staggered delays.
    for i, e in ipairs(entries) do
        e.animState     = "collapsing"
        e.animTime      = 0
        e.collapseDelay = (i - 1) * addon.ENTRY_STAGGER
    end

    -- Mark this group as collapsing so Animation.lua can detect completion.
    addon.groupCollapses[groupKey] = GetTime()
    if addon.EnsureFocusUpdateRunning then
        addon.EnsureFocusUpdateRunning()
    end

    -- Immediately mark the category as logically collapsed so layout
    -- treats it as hidden; animation is just the visual transition.
    if addon.SetCategoryCollapsed then
        addon.SetCategoryCollapsed(groupKey, true)
    end
end

-- Visual-only collapse: same staggered slide-out animation, but do not persist
-- category collapsed state. Used when toggling the Nearby group off so that
-- when the user turns it back on the section is not collapsed.
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
        e.animState     = "collapsing"
        e.animTime      = 0
        e.collapseDelay = (i - 1) * addon.ENTRY_STAGGER
    end

    addon.groupCollapses[groupKey] = GetTime()
end

-- Trigger fade-in for entries currently in the NEARBY group (used when turning Nearby group on with animations).
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
        e.animState     = "fadein"
        e.animTime      = 0
        e.staggerDelay  = (i - 1) * addon.ENTRY_STAGGER
        e:SetAlpha(0)
    end
end

-- Two-phase "turn Nearby on": fade out entries from their current category, then reflow and fade them in under NEARBY.
-- Call with showNearbyGroup already set to true.
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

local headerBtn = CreateFrame("Button", nil, addon.HS)
headerBtn:SetPoint("TOPLEFT", addon.HS, "TOPLEFT", 0, 0)
headerBtn:SetPoint("TOPRIGHT", addon.HS, "TOPRIGHT", 0, 0)
headerBtn:SetHeight(addon.PADDING + addon.HEADER_HEIGHT)
headerBtn:RegisterForClicks("LeftButtonUp")
headerBtn:SetScript("OnClick", function()
    ToggleCollapse()
end)
headerBtn:SetScript("OnEnter", function()
    if addon.GetDB("hideObjectivesHeader", false) then
        addon.chevron:SetAlpha(1)
        addon.optionsBtn:SetAlpha(1)
    end
end)
headerBtn:SetScript("OnLeave", function()
    if addon.GetDB("hideObjectivesHeader", false) then
        -- Don't hide when moving to options button (it's on top of header, so we get OnLeave when hovering it)
        if addon.optionsBtn:IsMouseOver() then return end
        addon.chevron:SetAlpha(0)
        addon.optionsBtn:SetAlpha(0)
    end
end)
headerBtn:RegisterForDrag("LeftButton")
headerBtn:SetScript("OnDragStart", function()
    if HorizonDB and HorizonDB.lockPosition then return end
    if InCombatLockdown() then return end
    addon.HS:StartMoving()
end)
headerBtn:SetScript("OnDragStop", function()
    if HorizonDB and HorizonDB.lockPosition then return end
    addon.HS:StopMovingOrSizing()
    addon.HS:SetUserPlaced(false)
    if InCombatLockdown() then return end
    addon.SavePanelPosition()
end)

local collapseKeybindBtn = CreateFrame("Button", "HSCollapseButton", nil)
collapseKeybindBtn:SetScript("OnClick", function()
    ToggleCollapse()
end)
collapseKeybindBtn:RegisterForClicks("AnyUp")

local nearbyToggleKeybindBtn = CreateFrame("Button", "HSNearbyToggleButton", nil)
nearbyToggleKeybindBtn:SetScript("OnClick", function()
    local newShow = not addon.GetDB("showNearbyGroup", true)
    addon.SetDB("showNearbyGroup", newShow)
    if InCombatLockdown() then
        if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
        if _G.HorizonSuite_FullLayout then _G.HorizonSuite_FullLayout() end
        return
    end
    if newShow then
        -- Turning Nearby group on: with animations, fade out from current category then fade in under NEARBY; else reflow once.
        if addon.GetDB("animations", true) and addon.StartNearbyTurnOnTransition then
            addon.StartNearbyTurnOnTransition()
        else
            if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
            if _G.HorizonSuite_FullLayout then _G.HorizonSuite_FullLayout() end
        end
    else
        -- Turning Nearby group off: animate NEARBY entries collapsing out, then FullLayout runs on completion.
        if addon.GetDB("animations", true) and addon.StartGroupCollapseVisual then
            addon.StartGroupCollapseVisual("NEARBY")
        else
            if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
            if _G.HorizonSuite_FullLayout then _G.HorizonSuite_FullLayout() end
        end
    end
end)
nearbyToggleKeybindBtn:RegisterForClicks("AnyUp")

local function ShouldShowInInstance()
    local inType = select(2, GetInstanceInfo())
    if inType == "none" then return true end
    if inType == "party"  then return addon.GetDB("showInDungeon", false) end
    if inType == "raid"   then return addon.GetDB("showInRaid", false) end
    if inType == "pvp"    then return addon.GetDB("showInBattleground", false) end
    if inType == "arena"  then return addon.GetDB("showInArena", false) end
    return true
end

-- Count displayed tracker entries that are in the quest log and not world quests (for header "tracked/in log" mode).
-- Excludes rares and achievements.
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

--- Content-only refresh during combat. Updates text and colors on visible entries.
-- Only SetText and SetTextColor; no Show/Hide, SetPoint, or SetAttribute.
local function RefreshContentInCombat()
    if not addon.enabled then return end
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
        local doneColor = (addon.GetObjectiveColor and addon.GetObjectiveColor(effectiveCat)) or addon.OBJ_DONE_COLOR or { 0.5, 0.8, 0.5 }
        if shouldDim then
            objColor = { objColor[1] * 0.60, objColor[2] * 0.60, objColor[3] * 0.60 }
            doneColor = { doneColor[1] * 0.60, doneColor[2] * 0.60, doneColor[3] * 0.60 }
        end
        -- Achievements: completed criteria use quest-log green instead of category bronze
        local effectiveDoneColor = (questData.isAchievement and addon.OBJ_DONE_COLOR) or doneColor
        if questData.isAchievement and shouldDim then
            effectiveDoneColor = { effectiveDoneColor[1] * 0.60, effectiveDoneColor[2] * 0.60, effectiveDoneColor[3] * 0.60 }
        end

        -- Title
        local displayTitle = questData.title or ""
        if (addon.GetDB("showCompletedCount", false) or questData.isAchievement or questData.isEndeavor) then
            local done, total
            if questData.criteriaDone and questData.criteriaTotal and type(questData.criteriaDone) == "number" and type(questData.criteriaTotal) == "number" and questData.criteriaTotal > 0 then
                done, total = questData.criteriaDone, questData.criteriaTotal
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

        -- Zone label
        local showZoneLabels = addon.GetDB("showZoneLabels", true)
        local playerZone = GetPlayerCurrentZoneName()
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

        -- Objectives (SetText, SetTextColor only)
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
                if showObjectiveNumbers then objText = ("%d. %s"):format(j, objText) end
                obj.text:SetText(objText)
                obj.shadow:SetText(objText)
                if oData.finished then
                    obj.text:SetTextColor(effectiveDoneColor[1], effectiveDoneColor[2], effectiveDoneColor[3], 1)
                else
                    obj.text:SetTextColor(objColor[1], objColor[2], objColor[3], 1)
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
            end
        end

        -- WQ/Scenario timer and progress text
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

addon.RefreshContentInCombat = RefreshContentInCombat

--- Full layout of the objectives panel.
-- @brief Computes and applies the complete tracker layout: visibility, quest list, section headers, entry positions, scroll height.
-- Algorithm: (1) Bail if disabled or in combat. (2) Hide panel if instance visibility
-- forbids. (3) Apply grow-up anchor and header visibility from DB. (4) When collapsed,
-- update floating item and header count then return. (5) Read and sort/group quests,
-- mark entries no longer in list for fadeout. (6) For each grouped quest, acquire or
-- reuse pool entry and PopulateEntry. (7) Place section headers and entries by group,
-- respecting collapsed categories. (8) Set scroll child height, clamp scroll offset,
-- compute target panel height and show frame.
local lastMinimal = false
local function FullLayout()
    if not addon.enabled then return end
    if InCombatLockdown() then
        addon.layoutPendingAfterCombat = true
        return
    end
    addon.layoutPendingAfterCombat = false

    if not ShouldShowInInstance() then
        addon.HS:Hide()
        addon.UpdateFloatingQuestItem(nil)
        addon.UpdateMplusBlock()
        return
    end

    if addon.ShouldHideInCombat() then
        addon.HS:Hide()
        addon.UpdateFloatingQuestItem(nil)
        addon.UpdateMplusBlock()
        return
    end

    if addon.GetDB("growUp", false) then
        addon.ApplyGrowUpAnchor()
    end

    local minimal = addon.GetDB("hideObjectivesHeader", false)
    if minimal then
        addon.headerText:Hide()
        addon.headerShadow:Hide()
        addon.countText:Hide()
        addon.countShadow:Hide()
        addon.divider:Hide()
        addon.optionsLabel:SetText("Options")
        addon.optionsBtn:SetWidth(math.max(addon.optionsLabel:GetStringWidth() + 4, 44))
        addon.optionsBtn:SetFrameLevel(headerBtn:GetFrameLevel() + 1)
        addon.optionsBtn:SetParent(addon.HS)
        headerBtn:SetHeight(addon.MINIMAL_HEADER_HEIGHT)
        addon.chevron:Show()
        addon.optionsBtn:Show()
        -- Visible on hover only: use alpha so frames stay in layout and remain clickable
        if not lastMinimal then
            addon.chevron:SetAlpha(headerBtn:IsMouseOver() and 1 or 0)
            addon.optionsBtn:SetAlpha(headerBtn:IsMouseOver() and 1 or 0)
        end
    else
        addon.optionsBtn:SetFrameLevel(headerBtn:GetFrameLevel() + 1)
        addon.optionsBtn:SetParent(addon.HS)
        addon.chevron:SetAlpha(1)
        addon.optionsBtn:SetAlpha(1)
        addon.headerText:Show()
        addon.headerShadow:Show()
        local headerStr = addon.ApplyTextCase("OBJECTIVES", "headerTextCase", "upper")
        addon.headerText:SetText(headerStr)
        addon.headerShadow:SetText(headerStr)
        if addon.GetDB("showQuestCount", true) then addon.countText:Show(); addon.countShadow:Show() else addon.countText:Hide(); addon.countShadow:Hide() end
        addon.chevron:Show()
        addon.optionsBtn:Show()
        addon.optionsLabel:SetText("Options")
        addon.optionsBtn:SetWidth(math.max(addon.optionsLabel:GetStringWidth() + 4, 44))
        addon.divider:SetShown(addon.GetDB("showHeaderDivider", true))
        headerBtn:SetHeight(addon.PADDING + addon.HEADER_HEIGHT)
    end
    lastMinimal = minimal

    local contentTop = addon.GetContentTop()

    -- Update the Mythic+ banner first so we can anchor the scrollFrame around it.
    if addon.UpdateMplusBlock then
        addon.UpdateMplusBlock()
    end

    scrollFrame:ClearAllPoints()
    local mplus = addon.mplusBlock
    local hasMplus = mplus and mplus:IsShown()
    local mplusPos = addon.GetDB("mplusBlockPosition", "top") or "top"
    local gap = 4

    if hasMplus and mplusPos == "top" then
        -- Banner sits directly under header; list starts just below the banner.
        scrollFrame:SetPoint("TOPLEFT", mplus, "BOTTOMLEFT", 0, -gap)
        scrollFrame:SetPoint("BOTTOMRIGHT", addon.HS, "BOTTOMRIGHT", 0, addon.PADDING)
    elseif hasMplus and mplusPos == "bottom" then
        -- List runs from header down to just above the banner.
        scrollFrame:SetPoint("TOPLEFT", addon.HS, "TOPLEFT", 0, contentTop)
        scrollFrame:SetPoint("BOTTOMRIGHT", mplus, "TOPRIGHT", 0, gap)
    else
        -- No Mythic+ banner: use the full content area.
        scrollFrame:SetPoint("TOPLEFT", addon.HS, "TOPLEFT", 0, contentTop)
        scrollFrame:SetPoint("BOTTOMRIGHT", addon.HS, "BOTTOMRIGHT", 0, addon.PADDING)
    end

    local rares = addon.GetDB("showRareBosses", true) and addon.GetRaresOnMap() or {}
    if #rares > 0 then
        local currentRareKeys = {}
        for _, r in ipairs(rares) do currentRareKeys[r.entryKey or r.questID] = true end
        if addon.rareTrackingInit and not addon.zoneJustChanged then
            for key in pairs(currentRareKeys) do
                if not addon.prevRareKeys[key] and PlaySound and addon.GetDB("rareAddedSound", true) then
                    pcall(PlaySound, addon.RARE_ADDED_SOUND)
                    break
                end
            end
        end
        if addon.zoneJustChanged then addon.zoneJustChanged = false end
        addon.rareTrackingInit = true
        addon.prevRareKeys = currentRareKeys
    else
        addon.prevRareKeys = {}
    end

    if addon.collapsed then
        local quests = addon.ReadTrackedQuests()
        for _, r in ipairs(rares) do quests[#quests + 1] = r end
        if addon.GetDB("showAchievements", true) and addon.ReadTrackedAchievements then
            for _, a in ipairs(addon.ReadTrackedAchievements()) do quests[#quests + 1] = a end
        end
        if addon.ReadTrackedEndeavors then
            for _, e in ipairs(addon.ReadTrackedEndeavors()) do quests[#quests + 1] = e end
        end
        if addon.ReadTrackedDecor then
            for _, d in ipairs(addon.ReadTrackedDecor()) do quests[#quests + 1] = d end
        end
        SchedulePlaceholderRefreshes(quests)
        addon.UpdateFloatingQuestItem(quests)
        addon.UpdateHeaderQuestCount(#quests, CountTrackedInLog(quests))

        -- During panel collapse animation, skip full collapsed layout so section headers
        -- stay visible; UpdateCollapseAnimations will call FullLayout when done.
        if addon.collapseAnimating then
            if #quests > 0 then
                if addon.combatFadeState == "in" then addon.HS:SetAlpha(0) end
                addon.HS:Show()
            end
            return
        end

        if addon.GetDB("showSectionHeadersWhenCollapsed", false) then
            -- Collapsed-with-headers: show section headers only, no entries.
            local grouped = addon.SortAndGroupQuests(quests)
            local showSections = #grouped >= 1 and addon.GetDB("showSectionHeaders", true)

            if showSections and #grouped > 0 then
                scrollFrame:Show()
                HideAllSectionHeaders()
                addon.sectionIdx = 0
                local focusedGroupKey = GetFocusedGroupKey(grouped)
                local yOff = 0
                for gi, grp in ipairs(grouped) do
                    if gi > 1 then
                        yOff = yOff - addon.GetSectionSpacing()
                    end
                    local sec = AcquireSectionHeader(grp.key, focusedGroupKey)
                    if sec then
                        sec:ClearAllPoints()
                        sec:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", addon.GetContentLeftOffset(), yOff)
                        yOff = yOff - (addon.SECTION_SIZE + 4) - addon.GetSectionToEntryGap()
                    end
                end
                local totalContentH = math.max(-yOff, 1)
                scrollChild:SetHeight(totalContentH)
                scrollFrame:SetVerticalScroll(0)
                addon.scrollOffset = 0
                local headerArea = addon.PADDING + addon.HEADER_HEIGHT + addon.DIVIDER_HEIGHT + addon.GetHeaderToContentGap()
                local visibleH = math.min(totalContentH, addon.GetMaxContentHeight())
                addon.targetHeight = math.max(addon.MIN_HEIGHT, headerArea + visibleH + addon.PADDING)
            else
                scrollFrame:Hide()
                addon.targetHeight = addon.GetCollapsedHeight()
            end
        else
            scrollFrame:Hide()
            addon.targetHeight = addon.GetCollapsedHeight()
        end

        if #quests > 0 then
            if addon.combatFadeState == "in" then addon.HS:SetAlpha(0) end
            addon.HS:Show()
        end
        return
    end

    scrollFrame:Show()

    local quests  = addon.ReadTrackedQuests()
    for _, r in ipairs(rares) do quests[#quests + 1] = r end
    if addon.GetDB("showAchievements", true) and addon.ReadTrackedAchievements then
        for _, a in ipairs(addon.ReadTrackedAchievements()) do quests[#quests + 1] = a end
    end
    if addon.ReadTrackedEndeavors then
        for _, e in ipairs(addon.ReadTrackedEndeavors()) do quests[#quests + 1] = e end
    end
    if addon.ReadTrackedDecor then
        for _, d in ipairs(addon.ReadTrackedDecor()) do quests[#quests + 1] = d end
    end
    SchedulePlaceholderRefreshes(quests)
    addon.UpdateFloatingQuestItem(quests)
    local grouped = addon.SortAndGroupQuests(quests)

    -- When a category is collapsing, skip full layout to avoid section header flicker.
    if addon.groupCollapses and next(addon.groupCollapses) then
        addon.UpdateHeaderQuestCount(#quests, CountTrackedInLog(quests))
        if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
        return
    end

    local currentIDs = {}
    for _, q in ipairs(quests) do
        currentIDs[q.entryKey or q.questID] = true
    end

    for key, entry in pairs(activeMap) do
        if not currentIDs[key] then
            if entry.animState ~= "completing" and entry.animState ~= "fadeout" then
                entry.animState = "fadeout"
                entry.animTime  = 0
            end
            activeMap[key] = nil
        end
    end

    for _, grp in ipairs(grouped) do
        for _, qData in ipairs(grp.quests) do
            local key = qData.entryKey or qData.questID
            local entry = activeMap[key]
            if not entry then
                entry = AcquireEntry()
                if entry then
                    entry.animState = "fadein"
                    entry.animTime  = 0
                    activeMap[key] = entry
                end
            elseif entry.animState == "idle" and not entry.questID and not entry.entryKey then
                -- Zombie entry left over from a group collapse: reset it for fadein.
                entry.animState = "fadein"
                entry.animTime  = 0
                entry:SetAlpha(0)
            end
            if entry then
                entry.groupKey = grp.key
                PopulateEntry(entry, qData, grp.key)
            end
        end
    end

    -- Build current "priority" sets (tracked/in-log) for WORLD, WEEKLY, DAILY to detect promotion.
    local function isPriorityWorld(q) return (q.isTracked or q.isAccepted) and true or false end
    local function isPriorityWeeklyDaily(q) return q.isAccepted and true or false end
    local curPriority = {}
    for _, grp in ipairs(grouped) do
        if grp.key == "WORLD" or grp.key == "WEEKLY" or grp.key == "DAILY" then
            curPriority[grp.key] = {}
            for _, qData in ipairs(grp.quests) do
                local key = qData.entryKey or qData.questID
                if key and ((grp.key == "WORLD" and isPriorityWorld(qData)) or ((grp.key == "WEEKLY" or grp.key == "DAILY") and isPriorityWeeklyDaily(qData))) then
                    curPriority[grp.key][key] = true
                end
            end
        end
    end

    -- Promotion animation: if priority set grew (tracked/in-log added), fade out only the promoted quest(s) then reflow and fade them in at top.
    if addon.GetDB("animations", true) then
        addon.prevPriorityWorld  = addon.prevPriorityWorld  or {}
        addon.prevPriorityWeekly = addon.prevPriorityWeekly or {}
        addon.prevPriorityDaily  = addon.prevPriorityDaily  or {}
        local promotedKeys = {}
        for _, grp in ipairs(grouped) do
            if grp.key == "WORLD" or grp.key == "WEEKLY" or grp.key == "DAILY" then
                local cur = (grp.key == "WORLD" and curPriority.WORLD) or (grp.key == "WEEKLY" and curPriority.WEEKLY) or (grp.key == "DAILY" and curPriority.DAILY) or {}
                local prev = (grp.key == "WORLD" and addon.prevPriorityWorld) or (grp.key == "WEEKLY" and addon.prevPriorityWeekly) or (grp.key == "DAILY" and addon.prevPriorityDaily) or {}
                if next(prev) then
                    for k in pairs(cur) do
                        if not prev[k] then promotedKeys[k] = true end
                    end
                end
            end
        end
        local promotionFadeOutCount = 0
        if next(promotedKeys) then
            addon.prevPriorityWorld  = curPriority.WORLD  or {}
            addon.prevPriorityWeekly = curPriority.WEEKLY or {}
            addon.prevPriorityDaily  = curPriority.DAILY  or {}
            for key in pairs(promotedKeys) do
                local entry = activeMap[key]
                if entry and (entry.animState == "active" or entry.animState == "fadein") and entry.finalX and entry.finalY then
                    entry.animState = "fadeout"
                    entry.animTime  = 0
                    entry.promotionFadeOut = true
                    promotionFadeOutCount = promotionFadeOutCount + 1
                end
            end
            if promotionFadeOutCount > 0 then
                addon.promotionFadeOutCount = promotionFadeOutCount
                addon.onPromotionFadeOutCompleteCallback = function()
                    addon.onPromotionFadeOutCompleteCallback = nil
                    addon.promotionFadeOutCount = nil
                    if addon.FullLayout then addon.FullLayout() end
                end
                addon.UpdateHeaderQuestCount(#quests, CountTrackedInLog(quests))
                if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
                return
            end
        end
    end

    -- Update prev priority for next comparison (when not doing promotion transition).
    addon.prevPriorityWorld  = curPriority.WORLD  or {}
    addon.prevPriorityWeekly = curPriority.WEEKLY or {}
    addon.prevPriorityDaily  = curPriority.DAILY  or {}

    HideAllSectionHeaders()
    addon.sectionIdx = 0

    local yOff = 0
    local entryIndex = 0

    local showSections = #grouped > 1 and addon.GetDB("showSectionHeaders", true)
    local focusedGroupKey = GetFocusedGroupKey(grouped)

    for gi, grp in ipairs(grouped) do
        local isCollapsed = showSections and addon.IsCategoryCollapsed(grp.key)

        if showSections then
            if gi > 1 then
                yOff = yOff - addon.GetSectionSpacing()
            end
            local sec = AcquireSectionHeader(grp.key, focusedGroupKey)
            if sec then
                sec:ClearAllPoints()
                sec:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", addon.GetContentLeftOffset(), yOff)
                yOff = yOff - (addon.SECTION_SIZE + 4) - addon.GetSectionToEntryGap()
            end
        end

        if isCollapsed then
            -- Do not position entries for collapsed groups; hide any that are not
            -- currently animating a collapse.
            for _, qData in ipairs(grp.quests) do
                local key = qData.entryKey or qData.questID
                local entry = activeMap[key]
                if entry and entry.animState ~= "collapsing" then
                    entry:Hide()
                end
            end
        else
            local entrySpacing = ((grp.key == "DELVES" or grp.key == "DUNGEON") and addon.DELVE_ENTRY_SPACING) or addon.GetTitleSpacing()
            for _, qData in ipairs(grp.quests) do
                local key = qData.entryKey or qData.questID
                local entry = activeMap[key]
                if entry then
                    entry.groupKey = grp.key
                    entry.finalX = addon.GetContentLeftOffset()
                    entry.finalY = yOff
                    entry.staggerDelay = entryIndex * addon.ENTRY_STAGGER
                    entryIndex = entryIndex + 1

                    entry:ClearAllPoints()
                    entry:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", addon.GetContentLeftOffset(), yOff)
                    entry:Show()
                    yOff = yOff - entry.entryHeight - entrySpacing
                end
            end
        end
    end

    addon.UpdateHeaderQuestCount(#quests, CountTrackedInLog(quests))

    local totalContentH = math.max(-yOff, 1)
    local prevScroll = addon.scrollOffset
    scrollChild:SetHeight(totalContentH)

    local frameH = scrollFrame:GetHeight() or 0
    local maxScr = math.max(totalContentH - frameH, 0)
    addon.scrollOffset = math.min(prevScroll, maxScr)
    scrollFrame:SetVerticalScroll(addon.scrollOffset)

    local headerArea    = addon.PADDING + addon.HEADER_HEIGHT + addon.DIVIDER_HEIGHT + addon.GetHeaderToContentGap()
    local visibleH      = math.min(totalContentH, addon.GetMaxContentHeight())
    addon.targetHeight  = math.max(addon.MIN_HEIGHT, headerArea + visibleH + addon.PADDING)

    if #quests > 0 then
        if addon.combatFadeState == "in" then addon.HS:SetAlpha(0) end
        addon.HS:Show()
    end

    if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
end

addon.PopulateEntry       = PopulateEntry
addon.AcquireEntry       = AcquireEntry
addon.HideAllSectionHeaders = HideAllSectionHeaders
addon.AcquireSectionHeader = AcquireSectionHeader
addon.ToggleCollapse      = ToggleCollapse
addon.FullLayout         = FullLayout
