--[[
    Horizon Suite - Focus - Layout Engine
    PopulateEntry, FullLayout, ToggleCollapse, AcquireEntry, section headers, header button, keybind, floating item, M+ block.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- LAYOUT ENGINE
-- ============================================================================

local pool       = addon.pool
local activeMap  = addon.activeMap
local sectionPool = addon.sectionPool
local scrollChild = addon.scrollChild
local scrollFrame = addon.scrollFrame

--- Player's current zone name from map API. Used to suppress redundant zone labels for in-zone quests.
--- Schedule deferred refreshes when Endeavors or Decor have placeholder names (API data not yet loaded).
local function SchedulePlaceholderRefreshes(quests)
    if addon.focus.placeholderRefreshScheduled then return end
    for _, q in ipairs(quests) do
        local isEndeavorPlaceholder = q.isEndeavor and q.endeavorID and q.title == ("Endeavor " .. tostring(q.endeavorID))
        local isDecorPlaceholder = q.isDecor and q.decorID and q.title == ("Decor " .. tostring(q.decorID))
        if isEndeavorPlaceholder or isDecorPlaceholder then
            addon.focus.placeholderRefreshScheduled = true
            C_Timer.After(2, function()
                if addon.focus.enabled and addon.ScheduleRefresh then addon.ScheduleRefresh() end
            end)
            C_Timer.After(4, function()
                if addon.focus.enabled and addon.ScheduleRefresh then addon.ScheduleRefresh() end
            end)
            break
        end
    end
end

--- Player's current zone name. Uses Zone tier (whole zone, e.g. K'aresh), not continent or micro.
--- Dungeon/Delve: current map only. Overworld: GetZoneText() or walk up to Zone (mapType 3).
local function GetPlayerCurrentZoneName()
    if not C_Map or not C_Map.GetBestMapForUnit then return nil end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or not C_Map.GetMapInfo then return nil end

    -- Dungeon or Delve: use current map only (no walk-up).
    if (addon.IsDelveActive and addon.IsDelveActive()) or (addon.IsInPartyDungeon and addon.IsInPartyDungeon()) then
        local info = C_Map.GetMapInfo(mapID)
        return info and info.name or nil
    end

    -- Overworld: prefer GetZoneText() (fixes wrong-map e.g. Dornegol when in K'aresh).
    if GetZoneText and type(GetZoneText) == "function" then
        local zoneText = GetZoneText()
        if zoneText and zoneText:match("%S") then
            return zoneText:match("^%s*(.-)%s*$") or zoneText
        end
    end

    -- Fallback: walk up via parentMapID until Zone (mapType 3) or no parent.
    local UIMAPTYPE_ZONE = 3
    local current = mapID
    local info = C_Map.GetMapInfo(current)
    while info do
        if info.mapType == UIMAPTYPE_ZONE then
            return info.name
        end
        if not info.parentMapID or info.parentMapID == 0 then
            break
        end
        current = info.parentMapID
        info = C_Map.GetMapInfo(current)
    end
    info = C_Map.GetMapInfo(mapID)
    return info and info.name or nil
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

local headerBtn = CreateFrame("Button", nil, addon.HS)
headerBtn:SetPoint("TOPLEFT", addon.HS, "TOPLEFT", 0, 0)
headerBtn:SetPoint("TOPRIGHT", addon.HS, "TOPRIGHT", 0, 0)
headerBtn:SetHeight(addon.PADDING + addon.GetHeaderHeight())
headerBtn:RegisterForClicks("LeftButtonUp")
headerBtn:SetScript("OnClick", function()
    addon.ToggleCollapse()
end)
headerBtn:SetScript("OnEnter", function()
    if addon.GetDB("hideObjectivesHeader", false) then
        addon.chevron:SetAlpha(1)
        if not addon.GetDB("hideOptionsButton", false) then
            addon.optionsBtn:SetAlpha(1)
        end
    end
end)
headerBtn:SetScript("OnLeave", function()
    if addon.GetDB("hideObjectivesHeader", false) then
        if addon.optionsBtn:IsMouseOver() then return end
        addon.chevron:SetAlpha(0)
        if not addon.GetDB("hideOptionsButton", false) then
            addon.optionsBtn:SetAlpha(0)
        end
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
    addon.ToggleCollapse()
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
        if addon.GetDB("animations", true) and addon.StartNearbyTurnOnTransition then
            addon.StartNearbyTurnOnTransition()
        else
            if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
            if _G.HorizonSuite_FullLayout then _G.HorizonSuite_FullLayout() end
        end
    else
        if addon.GetDB("animations", true) and addon.StartGroupCollapseVisual then
            addon.StartGroupCollapseVisual("NEARBY")
        else
            if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
            if _G.HorizonSuite_FullLayout then _G.HorizonSuite_FullLayout() end
        end
    end
end)
nearbyToggleKeybindBtn:RegisterForClicks("AnyUp")

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
    if not addon.focus.enabled then return end
    if InCombatLockdown() then
        addon.focus.layoutPendingAfterCombat = true
        return
    end
    addon.focus.layoutPendingAfterCombat = false

    if not addon.ShouldShowInInstance() then
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
    local hideOptBtn = addon.GetDB("hideOptionsButton", false)
    if minimal then
        addon.headerText:Hide()
        addon.headerShadow:Hide()
        addon.countText:Hide()
        addon.countShadow:Hide()
        addon.divider:Hide()
        addon.optionsBtn:SetFrameLevel(headerBtn:GetFrameLevel() + 1)
        addon.optionsBtn:SetParent(addon.HS)
        headerBtn:SetHeight(addon.MINIMAL_HEADER_HEIGHT)
        addon.chevron:Show()
        if hideOptBtn then
            addon.optionsBtn:Hide()
        else
            addon.optionsLabel:SetText("Options")
            addon.optionsBtn:SetWidth(math.max(addon.optionsLabel:GetStringWidth() + 4, 44))
            addon.optionsBtn:Show()
            -- Visible on hover only: use alpha so frames stay in layout and remain clickable
            if not lastMinimal then
                addon.chevron:SetAlpha(headerBtn:IsMouseOver() and 1 or 0)
                addon.optionsBtn:SetAlpha(headerBtn:IsMouseOver() and 1 or 0)
            end
        end
    else
        addon.optionsBtn:SetFrameLevel(headerBtn:GetFrameLevel() + 1)
        addon.optionsBtn:SetParent(addon.HS)
        addon.chevron:SetAlpha(1)
        addon.headerText:Show()
        addon.headerShadow:Show()
        local headerStr = addon.ApplyTextCase("OBJECTIVES", "headerTextCase", "upper")
        addon.headerText:SetText(headerStr)
        addon.headerShadow:SetText(headerStr)
        if addon.GetDB("showQuestCount", true) then addon.countText:Show(); addon.countShadow:Show() else addon.countText:Hide(); addon.countShadow:Hide() end
        addon.chevron:Show()
        if hideOptBtn then
            addon.optionsBtn:Hide()
        else
            addon.optionsBtn:SetAlpha(1)
            addon.optionsBtn:Show()
            addon.optionsLabel:SetText("Options")
            addon.optionsBtn:SetWidth(math.max(addon.optionsLabel:GetStringWidth() + 4, 44))
        end
        addon.divider:SetShown(addon.GetDB("showHeaderDivider", true))
        headerBtn:SetHeight(addon.PADDING + addon.GetHeaderHeight())
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
        if addon.focus.rares.trackingInit and not addon.focus.zoneJustChanged then
            for key in pairs(currentRareKeys) do
                if not addon.focus.rares.prevKeys[key] and PlaySound and addon.GetDB("rareAddedSound", true) then
                    pcall(PlaySound, addon.RARE_ADDED_SOUND)
                    break
                end
            end
        end
        if addon.focus.zoneJustChanged then addon.focus.zoneJustChanged = false end
        addon.focus.rares.trackingInit = true
        addon.focus.rares.prevKeys = currentRareKeys
    else
        addon.focus.rares.prevKeys = {}
    end

    if addon.focus.collapsed then
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
        addon.UpdateHeaderQuestCount(#quests, addon.CountTrackedInLog(quests))

        -- During panel collapse animation, skip full collapsed layout so section headers
        -- stay visible; UpdateCollapseAnimations will call FullLayout when done.
        if addon.focus.collapse.animating then
            if #quests > 0 then
                if addon.focus.combat.fadeState == "in" then addon.HS:SetAlpha(0) end
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
                addon.HideAllSectionHeaders()
                addon.focus.layout.sectionIdx = 0
                local focusedGroupKey = addon.GetFocusedGroupKey(grouped)
                local yOff = 0
                for gi, grp in ipairs(grouped) do
                    if gi > 1 then
                        yOff = yOff - addon.GetSectionSpacing()
                    end
                    local sec = addon.AcquireSectionHeader(grp.key, focusedGroupKey)
                    if sec then
                        sec:ClearAllPoints()
                        sec:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", addon.GetContentLeftOffset(), yOff)
                        yOff = yOff - (addon.SECTION_SIZE + 4) - addon.GetSectionToEntryGap()
                    end
                end
                local totalContentH = math.max(-yOff, 1)
                scrollChild:SetHeight(totalContentH)
                scrollFrame:SetVerticalScroll(0)
                addon.focus.layout.scrollOffset = 0
                local headerArea = addon.PADDING + addon.GetHeaderHeight() + addon.DIVIDER_HEIGHT + addon.GetHeaderToContentGap()
                local visibleH = math.min(totalContentH, addon.GetMaxContentHeight())
                addon.focus.layout.targetHeight = math.max(addon.MIN_HEIGHT, headerArea + visibleH + addon.PADDING)
            else
                scrollFrame:Hide()
                addon.focus.layout.targetHeight = addon.GetCollapsedHeight()
            end
        else
            scrollFrame:Hide()
            addon.focus.layout.targetHeight = addon.GetCollapsedHeight()
        end

        if #quests > 0 then
            if addon.focus.combat.fadeState == "in" then addon.HS:SetAlpha(0) end
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
    if addon.focus.collapse.groups and next(addon.focus.collapse.groups) then
        addon.UpdateHeaderQuestCount(#quests, addon.CountTrackedInLog(quests))
        if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
        return
    end

    local currentIDs = {}
    for _, q in ipairs(quests) do
        currentIDs[q.entryKey or q.questID] = true
    end

    local onlyDelveShown = (#grouped == 1 and grouped[1] and grouped[1].key == "DELVES")
        and (addon.IsDelveActive and addon.IsDelveActive())
    for key, entry in pairs(activeMap) do
        if not currentIDs[key] then
            if onlyDelveShown and addon.ClearEntry then
                addon.ClearEntry(entry)
            elseif entry.animState ~= "completing" and entry.animState ~= "fadeout" then
                entry.animState = "fadeout"
                entry.animTime  = 0
            end
            activeMap[key] = nil
        end
    end
    if onlyDelveShown and addon.ClearEntry then
        for i = 1, addon.POOL_SIZE do
            local e = pool[i]
            if e and (e.questID or e.entryKey) then
                local key = e.questID or e.entryKey
                if not currentIDs[key] then
                    addon.ClearEntry(e)
                end
            end
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
                addon.PopulateEntry(entry, qData, grp.key)
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
        addon.focus.promotion.prevWorld  = addon.focus.promotion.prevWorld  or {}
        addon.focus.promotion.prevWeekly = addon.focus.promotion.prevWeekly or {}
        addon.focus.promotion.prevDaily  = addon.focus.promotion.prevDaily  or {}
        local promotedKeys = {}
        for _, grp in ipairs(grouped) do
            if grp.key == "WORLD" or grp.key == "WEEKLY" or grp.key == "DAILY" then
                local cur = (grp.key == "WORLD" and curPriority.WORLD) or (grp.key == "WEEKLY" and curPriority.WEEKLY) or (grp.key == "DAILY" and curPriority.DAILY) or {}
                local prev = (grp.key == "WORLD" and addon.focus.promotion.prevWorld) or (grp.key == "WEEKLY" and addon.focus.promotion.prevWeekly) or (grp.key == "DAILY" and addon.focus.promotion.prevDaily) or {}
                if next(prev) then
                    for k in pairs(cur) do
                        if not prev[k] then promotedKeys[k] = true end
                    end
                end
            end
        end
        local promotionFadeOutCount = 0
        if next(promotedKeys) then
            addon.focus.promotion.prevWorld  = curPriority.WORLD  or {}
            addon.focus.promotion.prevWeekly = curPriority.WEEKLY or {}
            addon.focus.promotion.prevDaily  = curPriority.DAILY  or {}
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
                addon.UpdateHeaderQuestCount(#quests, addon.CountTrackedInLog(quests))
                if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
                return
            end
        end
    end

    -- Update prev priority for next comparison (when not doing promotion transition).
    addon.focus.promotion.prevWorld  = curPriority.WORLD  or {}
    addon.focus.promotion.prevWeekly = curPriority.WEEKLY or {}
    addon.focus.promotion.prevDaily  = curPriority.DAILY  or {}

    addon.HideAllSectionHeaders()
    addon.focus.layout.sectionIdx = 0

    local yOff = 0
    local entryIndex = 0

    local showSections = #grouped > 1 and addon.GetDB("showSectionHeaders", true)
    local focusedGroupKey = addon.GetFocusedGroupKey(grouped)

    for gi, grp in ipairs(grouped) do
        local isCollapsed = showSections and addon.IsCategoryCollapsed(grp.key)

        if showSections then
            if gi > 1 then
                yOff = yOff - addon.GetSectionSpacing()
            end
            local sec = addon.AcquireSectionHeader(grp.key, focusedGroupKey)
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

    addon.UpdateHeaderQuestCount(#quests, addon.CountTrackedInLog(quests))

    local totalContentH = math.max(-yOff, 1)
    local prevScroll = addon.focus.layout.scrollOffset
    scrollChild:SetHeight(totalContentH)

    local frameH = scrollFrame:GetHeight() or 0
    local maxScr = math.max(totalContentH - frameH, 0)
    addon.focus.layout.scrollOffset = math.min(prevScroll, maxScr)
    scrollFrame:SetVerticalScroll(addon.focus.layout.scrollOffset)

    local headerArea    = addon.PADDING + addon.GetHeaderHeight() + addon.DIVIDER_HEIGHT + addon.GetHeaderToContentGap()
    local visibleH      = math.min(totalContentH, addon.GetMaxContentHeight())
    addon.focus.layout.targetHeight  = math.max(addon.MIN_HEIGHT, headerArea + visibleH + addon.PADDING)

    if #quests > 0 then
        if addon.focus.combat.fadeState == "in" then addon.HS:SetAlpha(0) end
        addon.HS:Show()
    end

    if addon.EnsureFocusUpdateRunning then addon.EnsureFocusUpdateRunning() end
end

addon.GetPlayerCurrentZoneName = GetPlayerCurrentZoneName
addon.AcquireEntry        = AcquireEntry
addon.FullLayout          = FullLayout
