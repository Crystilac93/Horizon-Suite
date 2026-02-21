--[[
    Horizon Suite - Focus - Entry Renderer
    PopulateEntry, ApplyHighlightStyle, ApplyObjectives, ApplyScenarioOrWQTimerBar, ApplyShadowColors.
]]

local addon = _G.HorizonSuite

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
    -- Keep the pool's default left padding (1-space) and just apply topPadding.
    local x, y = entry.titleText:GetPoint(1)
    local xOff = (type(x) == "number") and x or 4
    entry.titleText:SetPoint("TOPLEFT", entry, "TOPLEFT", xOff, -topPadding)
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
    -- Indentation now comes from the entry's padded title anchor; keep objective indent consistent.

    -- Additional left padding for objectives only (not zone line), matching bar->icon gap when icons are enabled.
    local OBJ_EXTRA_LEFT_PAD = 14

    local objTextWidth = textWidth - objIndent
    if objTextWidth < 1 then objTextWidth = addon.GetPanelWidth() - addon.PADDING * 2 - objIndent - (addon.CONTENT_RIGHT_PADDING or 0) end

    local objSpacing = ((questData.category == "DELVES" or questData.category == "DUNGEON") and addon.DELVE_OBJ_SPACING) or addon.GetObjSpacing()

    local cat = (effectiveCat ~= nil and effectiveCat ~= "") and effectiveCat or questData.category
    local objColor = (addon.GetObjectiveColor and addon.GetObjectiveColor(cat)) or addon.OBJ_COLOR or c
    local doneColor = (addon.GetCompletedObjectiveColor and addon.GetCompletedObjectiveColor(cat))
        or (addon.GetObjectiveColor and addon.GetObjectiveColor(cat)) or addon.OBJ_DONE_COLOR
    if addon.GetDB("dimNonSuperTracked", false) and not questData.isSuperTracked then
        objColor = { objColor[1] * 0.60, objColor[2] * 0.60, objColor[3] * 0.60 }
        doneColor = { doneColor[1] * 0.60, doneColor[2] * 0.60, doneColor[3] * 0.60 }
    end
    local effectiveDoneColor = doneColor

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
            local nf, nr = oData.numFulfilled, oData.numRequired
            -- Skip appending (X/Y) to objectives when the title already shows it (single-criterion numeric achievement).
            local titleShowsNumeric = questData.numericQuantity ~= nil and questData.numericRequired and type(questData.numericRequired) == "number" and questData.numericRequired > 1
            local singleObjective = questData.objectives and #questData.objectives == 1
            if nf ~= nil and nr ~= nil and type(nf) == "number" and type(nr) == "number" and nr > 1 and not (titleShowsNumeric and singleObjective) then
                local pattern = tostring(nf) .. "/" .. tostring(nr)
                if not objText:find(pattern, 1, true) then
                    objText = objText .. (" (%d/%d)"):format(nf, nr)
                end
            end
            if addon.GetDB("showObjectiveNumbers", false) then
                objText = ("%d. %s"):format(j, objText)
            end
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
            obj._hsFinished = oData.finished and true or false
            obj._hsAlpha = alpha
            if oData.finished then
                if useTick then
                    obj.text:SetTextColor(objColor[1], objColor[2], objColor[3], alpha)
                else
                    obj.text:SetTextColor(effectiveDoneColor[1], effectiveDoneColor[2], effectiveDoneColor[3], alpha)
                end
            else
                obj.text:SetTextColor(objColor[1], objColor[2], objColor[3], alpha)
            end

            obj.text:ClearAllPoints()
            -- First objective gets inset from title; subsequent objectives align with it.
            local leftPad = (shownObjs == 0) and OBJ_EXTRA_LEFT_PAD or 0
            obj.text:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", leftPad, -objSpacing)
            obj.text:Show()
            obj.shadow:Show()

            local objH = obj.text:GetStringHeight()
            if not objH or objH < 1 then objH = addon.OBJ_SIZE + 2 end
            totalH = totalH + objSpacing + objH

            prevAnchor = obj.text
            shownObjs = shownObjs + 1
        else
            obj._hsFinished = nil
            obj._hsAlpha = nil
            obj.text:Hide()
            obj.shadow:Hide()
            if obj.tick then obj.tick:Hide() end
        end
    end

    if questData.isComplete and shownObjs == 0 then
        local obj = entry.objectives[1]
        local isAutoComplete = questData.isAutoComplete and true or false
        local firstLineText = isAutoComplete
            and (_G.QUEST_WATCH_QUEST_COMPLETE or "Quest Complete")
            or (addon.GetDB("showObjectiveNumbers", false) and "1. Ready to turn in" or "Ready to turn in")
        obj.text:SetText(firstLineText)
        obj.shadow:SetText(firstLineText)
        obj._hsFinished = true
        obj._hsAlpha = 1
        obj.text:SetTextColor(doneColor[1], doneColor[2], doneColor[3], 1)
        obj.text:ClearAllPoints()
        obj.text:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", OBJ_EXTRA_LEFT_PAD, -objSpacing)
        obj.text:Show()
        obj.shadow:Show()
        local objH = obj.text:GetStringHeight()
        if not objH or objH < 1 then objH = addon.OBJ_SIZE + 2 end
        totalH = totalH + objSpacing + objH
        prevAnchor = obj.text

        if isAutoComplete then
            local obj2 = entry.objectives[2]
            local clickText = _G.QUEST_WATCH_CLICK_TO_COMPLETE or "(click to complete)"
            obj2.text:SetText(clickText)
            obj2.shadow:SetText(clickText)
            obj2._hsFinished = true
            obj2._hsAlpha = 1
            obj2.text:SetTextColor(doneColor[1], doneColor[2], doneColor[3], 1)
            obj2.text:ClearAllPoints()
            obj2.text:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -objSpacing)
            obj2.text:Show()
            obj2.shadow:Show()
            local obj2H = obj2.text:GetStringHeight()
            if not obj2H or obj2H < 1 then obj2H = addon.OBJ_SIZE + 2 end
            totalH = totalH + objSpacing + obj2H
            prevAnchor = obj2.text
        end
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
        if entry.affixShadow then entry.affixShadow:SetTextColor(hc[1], hc[2], hc[3], glowAlpha) end
        for j = 1, addon.MAX_OBJECTIVES do
            entry.objectives[j].shadow:SetTextColor(hc[1], hc[2], hc[3], glowAlpha)
        end
    else
        entry.titleShadow:SetTextColor(0, 0, 0, shadowA)
        entry.zoneShadow:SetTextColor(0, 0, 0, shadowA)
        if entry.affixShadow then entry.affixShadow:SetTextColor(0, 0, 0, shadowA) end
        for j = 1, addon.MAX_OBJECTIVES do
            entry.objectives[j].shadow:SetTextColor(0, 0, 0, shadowA)
        end
    end
end

local function PopulateEntry(entry, questData, groupKey)
    local hasItem = (questData.itemTexture and questData.itemLink) and true or false
    local showItemBtn = hasItem and addon.GetDB("showQuestItemButtons", false)
    local showQuestIcons = addon.GetDB("showQuestTypeIcons", false)
    local showAchievementIcons = addon.GetDB("showAchievementIcons", true)
    local showDecorIcons = addon.GetDB("showDecorIcons", true)
    local hasIcon = ((questData.questTypeAtlas ~= nil) and showQuestIcons) or (questData.isAchievement and questData.achievementIcon and showQuestIcons and showAchievementIcons) or (questData.isDecor and questData.decorIcon and showQuestIcons and showDecorIcons)
    local isOffMapWorld = (questData.category == "WORLD") and questData.isTracked and not questData.isNearby

    local leftOffset = addon.GetContentLeftOffset and addon.GetContentLeftOffset() or (addon.PADDING + addon.ICON_COLUMN_WIDTH)
    local textWidth = addon.GetPanelWidth() - addon.PADDING - leftOffset - (addon.CONTENT_RIGHT_PADDING or 0)
    local titleLeftOffset = 0

    -- Extra spacing between icon column and title when icons are enabled.
    -- Keep icons-off layout exactly as-is.
    -- NOTE: ApplyHighlightStyle() resets title anchors, so we apply the final title X *after* highlight styling.
    local function ApplyIconModeTitleOffset()
        local basePad = entry.__baseTitlePadPx or 0
        local extraTitlePad = 0
        if showQuestIcons then
            local highlightStyle = addon.NormalizeHighlightStyle(addon.GetDB("activeQuestHighlight", "bar-left")) or "bar-left"
            local iconW = addon.QUEST_TYPE_ICON_SIZE or 14
            local iconTitleGap = 6
            if highlightStyle == "bar-left" or highlightStyle == "pill-left" then
                local barLeft = addon.BAR_LEFT_OFFSET or 12
                local barW = math.max(2, math.min(6, tonumber(addon.GetDB("highlightBarWidth", 2)) or 2))
                local padAfterBar = 6
                local iconLeft = -barLeft + barW + padAfterBar
                extraTitlePad = math.max(0, iconLeft + iconW + iconTitleGap)
            else
                extraTitlePad = iconW + iconTitleGap
            end
        end

        -- Preserve any vertical padding already applied (e.g. bar-top highlight style)
        local _, _, _, curX, curY = entry.titleText:GetPoint(1)
        curY = (type(curY) == "number") and curY or 0
        entry.titleText:ClearAllPoints()
        entry.titleText:SetPoint("TOPLEFT", entry, "TOPLEFT", basePad + extraTitlePad, curY)
        entry.titleShadow:ClearAllPoints()
        entry.titleShadow:SetPoint("CENTER", entry.titleText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)
        return extraTitlePad
    end

    -- Apply an initial offset (will be re-applied after highlight style too).
    ApplyIconModeTitleOffset()

    -- Quest type icon visibility is fully controlled by the toggle;
    -- positioning is handled in FocusLayout.
    if not showQuestIcons then
        entry.questTypeIcon:Hide()
    elseif questData.category == "DELVES" then
        entry.questTypeIcon:SetAtlas(addon.DELVE_TIER_ATLAS)
        entry.questTypeIcon:Show()
    elseif questData.isAchievement and questData.achievementIcon and showAchievementIcons then
        entry.questTypeIcon:SetTexture(questData.achievementIcon)
        entry.questTypeIcon:Show()
    elseif questData.isDecor and questData.decorIcon and showDecorIcons then
        entry.questTypeIcon:SetTexture(questData.decorIcon)
        entry.questTypeIcon:Show()
    elseif questData.questTypeAtlas then
        entry.questTypeIcon:SetAtlas(questData.questTypeAtlas)
        entry.questTypeIcon:Show()
    else
        -- Toggle on but no icon data: hide.
        entry.questTypeIcon:Hide()
    end

    if entry.trackedFromOtherZoneIcon then
        entry.trackedFromOtherZoneIcon:Hide()
    end

    entry.titleText:SetWidth(textWidth)
    entry.titleShadow:SetWidth(textWidth)

    local displayTitle = questData.title
    if (addon.GetDB("showCompletedCount", false) or questData.isAchievement or questData.isEndeavor) then
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
            displayTitle = ("%s (%d/%d)"):format(displayTitle, done, total)
        end
    end

    -- Entry numbering (per category): apply when option is on.
    if addon.GetDB("showCategoryEntryNumbers", true) and questData.categoryIndex and type(questData.categoryIndex) == "number" then
        displayTitle = ("%d. %s"):format(questData.categoryIndex, displayTitle)
    end

    if addon.GetDB("showQuestLevel", false) and questData.level then
        displayTitle = ("%s [L%d]"):format(displayTitle, questData.level)
    end
    -- Tier in title
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
    displayTitle = addon.ApplyTextCase(displayTitle, "questTitleCase", "proper")
    entry.titleText:SetText(displayTitle)
    entry.titleShadow:SetText(displayTitle)
    local effectiveCat = (addon.GetEffectiveColorCategory and addon.GetEffectiveColorCategory(questData.category, groupKey, questData.baseCategory)) or questData.category
    local c = (addon.GetTitleColor and addon.GetTitleColor(effectiveCat)) or questData.color
    if not c or type(c) ~= "table" or not c[1] or not c[2] or not c[3] then
        c = addon.QUEST_COLORS and addon.QUEST_COLORS.DEFAULT or { 0.9, 0.9, 0.9 }
    end
    if questData.isDungeonQuest and not questData.isTracked then
        c = { c[1] * 0.65, c[2] * 0.65, c[3] * 0.65 }
    elseif addon.GetDB("dimNonSuperTracked", false) and not questData.isSuperTracked then
        c = { c[1] * 0.60, c[2] * 0.60, c[3] * 0.60 }
    end
    entry.titleText:SetTextColor(c[1], c[2], c[3], 1)
    entry._savedColor = nil

    local highlightStyle, hc, ha, barW, topPadding, bottomPadding = ApplyHighlightStyle(entry, questData)

    -- Re-apply icon-mode title offset because ApplyHighlightStyle resets the anchor.
    ApplyIconModeTitleOffset()

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
    -- Cache the font-scaled "two spaces" width (measured from the title font) once per entry render.
    local twoSpacesPx = addon.focus and addon.focus.layout and addon.focus.layout.twoSpacesPx
    local titleIndentPx = addon.focus and addon.focus.layout and addon.focus.layout.titleIndentPx
    local titleToContentSpacing = ((questData.category == "DELVES" or questData.category == "DUNGEON") and addon.DELVE_OBJ_SPACING) or addon.GetObjSpacing()
    local showZoneLabels = addon.GetDB("showZoneLabels", true)
    local playerZone = addon.GetPlayerCurrentZoneName and addon.GetPlayerCurrentZoneName() or nil
    local inCurrentZone = questData.isNearby or (questData.zoneName and playerZone and questData.zoneName:lower() == playerZone:lower())
    local shouldShowZone = showZoneLabels and questData.zoneName and not inCurrentZone
    if shouldShowZone then
        local zoneLabel = questData.zoneName
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
        entry.zoneText:SetPoint("TOPLEFT", entry.titleText, "BOTTOMLEFT", 0, -titleToContentSpacing)
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

    -- Delve affixes: show on first Delve entry or scenario main.
    local showAffixesInEntry = questData.category == "DELVES"
        and (questData.categoryIndex == 1 or questData.isScenarioMain)
        and addon.GetDB("showDelveAffixes", true)
        and addon.GetDelvesAffixes
    local affixStr = ""
    if showAffixesInEntry and addon.GetDelvesAffixes then
        local affixes, tierSpellID = addon.GetDelvesAffixes()
        entry.tierSpellID = tierSpellID
        if affixes and #affixes > 0 then
            local parts = {}
            for _, a in ipairs(affixes) do
                if a.name and a.name ~= "" then parts[#parts + 1] = a.name end
            end
            if #parts > 0 then
                affixStr = table.concat(parts, "  ·  ")
                entry.affixData = affixes
            end
        end
    end
    if affixStr ~= "" and entry.affixText then
        local rawFont = addon.GetDB("fontPath", (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF")
        local fontPath = (addon.ResolveFontPath and addon.ResolveFontPath(rawFont)) or rawFont
        local fontOutline = addon.GetDB("fontOutline", "OUTLINE")
        local affixSize = math.max(10, math.min(16, tonumber(addon.GetDB("mplusAffixSize", 12)) or 12))
        entry.affixText:SetWidth(textWidth)
        entry.affixText:SetFont(fontPath, affixSize, fontOutline)
        entry.affixText:SetText(affixStr)
        entry.affixText:SetTextColor(0.78, 0.85, 0.88, 1)
        entry.affixText:ClearAllPoints()
        entry.affixText:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -titleToContentSpacing)
        entry.affixText:Show()
        if entry.affixShadow then
            entry.affixShadow:SetWidth(textWidth)
            entry.affixShadow:Show()
        end
        local affixH = entry.affixText:GetStringHeight()
        if not affixH or affixH < 1 then affixH = addon.ZONE_SIZE + 2 end
        totalH = totalH + titleToContentSpacing + affixH
        prevAnchor = entry.affixText
    else
        entry.affixText:Hide()
        entry.affixShadow:Hide()
        entry.affixData = nil
    end

    totalH, prevAnchor = ApplyObjectives(entry, questData, textWidth, prevAnchor, totalH, c, effectiveCat)
    totalH = ApplyScenarioOrWQTimerBar(entry, questData, textWidth, prevAnchor or entry.titleText, totalH)

    entry.entryHeight = totalH + topPadding + bottomPadding
    entry:SetHeight(totalH + topPadding + bottomPadding)

    ApplyShadowColors(entry, questData, highlightStyle, hc, ha)

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

    entry.baseCategory = questData.baseCategory
    entry.isComplete = questData.isComplete and true or false
    entry.isSuperTracked = questData.isSuperTracked and true or false
    entry.isDungeonQuest = questData.isDungeonQuest and true or false

    if questData.isRare then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.category   = questData.category
        entry.creatureID = questData.creatureID
        entry.achievementID = nil
        entry.endeavorID = nil
        entry.decorID    = nil
        entry.itemLink   = nil
        entry.isTracked  = nil
    elseif questData.isAchievement or questData.category == "ACHIEVEMENT" then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.category   = questData.category
        entry.creatureID = nil
        entry.achievementID = questData.achievementID
        entry.endeavorID = nil
        entry.isTracked  = true
    elseif questData.isEndeavor or questData.category == "ENDEAVOR" then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.category   = questData.category
        entry.creatureID = nil
        entry.achievementID = nil
        entry.endeavorID = questData.endeavorID
        entry.decorID    = nil
        entry.isTracked  = true
    elseif questData.isDecor or questData.category == "DECOR" then
        entry.questID    = nil
        entry.entryKey   = questData.entryKey
        entry.category   = questData.category
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

addon.PopulateEntry = PopulateEntry
