--[[
    Horizon Suite - Focus - Animation Engine
    HS OnUpdate: height lerp, entry fade/slide/collapse, objective flash, auto-hide.
    Uses C_Map.GetBestMapForUnit in RunMapCheck for zone change detection.
]]

local addon = _G.HorizonSuite

local HEIGHT_SNAP_THRESHOLD   = 0.5
local DRIFT_THRESHOLD        = 0.1
local FLASH_ALPHA_BY_INTENSITY = { subtle = 0.12, medium = 0.22, strong = 0.35 }
local GROUP_COLLAPSE_TIMEOUT = 2

local anim = addon.FOCUS_ANIM or { dur = 0.4, stagger = 0.05, slideInX = 20, slideOutX = 20, driftOutY = 10 }

-- ============================================================================
-- SHARED TRANSITION HELPERS (progress, easing, state init)
-- ============================================================================

--- Returns progress p in [0,1] from elapsed time, optional delay, and duration.
local function GetProgress(elapsed, delay, duration)
    local t = math.max(0, (elapsed or 0) - (delay or 0))
    return math.min(t / (duration or anim.dur), 1)
end

--- Sets entry to fadein state. staggerIndex is 0-based (0 = no delay).
function addon.SetEntryFadeIn(entry, staggerIndex)
    if not entry then return end
    entry.animState   = "fadein"
    entry.animTime    = 0
    entry.staggerDelay = (staggerIndex or 0) * anim.stagger
    entry:SetAlpha(0)
end

--- Sets entry to fadeout state.
function addon.SetEntryFadeOut(entry)
    if not entry then return end
    entry.animState   = "fadeout"
    entry.animTime    = 0
end

--- Sets entry to collapsing state. staggerIndex is 0-based.
function addon.SetEntryCollapsing(entry, staggerIndex)
    if not entry then return end
    entry.animState    = "collapsing"
    entry.animTime     = 0
    entry.collapseDelay = (staggerIndex or 0) * anim.stagger
end

--- Sets entry to slide-up state (Y moves from startY to finalY). Used when entries below
--- a collapsed category shift up to fill the gap.
function addon.SetEntrySlideUp(entry, startY)
    if not entry then return end
    entry.animState     = "slideup"
    entry.animTime      = 0
    entry.slideUpStartY = startY
end

-- ============================================================================
-- ANIMATION ENGINE
-- ============================================================================

local HS          = addon.HS
local pool         = addon.pool
local sectionPool  = addon.sectionPool
local scrollChild  = addon.scrollChild
local scrollFrame  = addon.scrollFrame

local function SetPanelHeight(h)
    if InCombatLockdown() then return end
    if addon.GetDB("growUp", false) then
        HS:SetHeight(h)
        return
    end
    local topBefore = HS:GetTop()
    if not topBefore then return end
    HS:SetHeight(h)
    local topAfter = HS:GetTop()
    if not topAfter then return end
    local drift = topAfter - topBefore
    if math.abs(drift) < DRIFT_THRESHOLD then return end
    local uiTop   = UIParent:GetTop()   or 0
    local uiRight = UIParent:GetRight() or 0
    local right   = HS:GetRight()      or 0
    HS:ClearAllPoints()
    HS:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", right - uiRight, topBefore - uiTop)
end

--- Detects player map changes and invalidates zone task quest cache.
--- Called on a timer; no params or return.
local function RunMapCheck()
    if not addon.focus.enabled or not C_Map or not C_Map.GetBestMapForUnit then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID and mapID ~= addon.focus.lastPlayerMapID then
        addon.focus.lastPlayerMapID = mapID
        if addon.zoneTaskQuestCache then wipe(addon.zoneTaskQuestCache) end
        if addon.ScheduleRefresh then addon.ScheduleRefresh() end
    elseif not addon.focus.lastPlayerMapID and mapID then
        addon.focus.lastPlayerMapID = mapID
    end
end

local function UpdatePanelHeight(dt)
    local targetHeight  = addon.focus.layout.targetHeight
    local currentHeight = addon.focus.layout.currentHeight
    if math.abs(currentHeight - targetHeight) > HEIGHT_SNAP_THRESHOLD then
        addon.focus.layout.currentHeight = currentHeight + (targetHeight - currentHeight) * math.min(addon.HEIGHT_SPEED * dt, 1)
        SetPanelHeight(addon.focus.layout.currentHeight)
    elseif currentHeight ~= targetHeight then
        addon.focus.layout.currentHeight = targetHeight
        SetPanelHeight(addon.focus.layout.currentHeight)
    end
end

local function UpdateCombatFade(dt, useAnim)
    local combatState = addon.focus.combat.fadeState
    if not combatState then return end
    local dur = anim.dur
    addon.focus.combat.fadeTime = addon.focus.combat.fadeTime + dt
    local floatingBtn = _G.HSFloatingQuestItem

    if combatState == "out" then
        if not useAnim then
            if not InCombatLockdown() then
                HS:Hide()
                if floatingBtn then floatingBtn:Hide() end
                if addon.UpdateFloatingQuestItem then addon.UpdateFloatingQuestItem(nil) end
                if addon.UpdateMplusBlock then addon.UpdateMplusBlock() end
            else
                addon.focus.pendingHideAfterCombat = true
            end
            addon.focus.combat.fadeState = nil
            addon.focus.combat.fadeTime = 0
        else
            local p = GetProgress(addon.focus.combat.fadeTime, 0, dur)
            local ep = addon.easeIn(p)
            HS:SetAlpha(1 - ep)
            if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(1 - ep) end
            if p >= 1 then
                if not InCombatLockdown() then
                    HS:Hide()
                    if floatingBtn then floatingBtn:Hide() end
                    if addon.UpdateFloatingQuestItem then addon.UpdateFloatingQuestItem(nil) end
                    if addon.UpdateMplusBlock then addon.UpdateMplusBlock() end
                else
                    addon.focus.pendingHideAfterCombat = true
                end
                addon.focus.combat.fadeState = nil
                addon.focus.combat.fadeTime = 0
            end
        end
    elseif combatState == "in" then
        if not useAnim then
            HS:SetAlpha(1)
            if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(1) end
            addon.focus.combat.fadeState = nil
            addon.focus.combat.fadeTime = 0
        else
            local p = GetProgress(addon.focus.combat.fadeTime, 0, dur)
            local ep = addon.easeOut(p)
            if HS:IsShown() then HS:SetAlpha(ep) end
            if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(ep) end
            if p >= 1 then
                HS:SetAlpha(1)
                if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(1) end
                addon.focus.combat.fadeState = nil
                addon.focus.combat.fadeTime = 0
            end
        end
    end
end

local function UpdateEntryAnimations(dt, useAnim)
    local anyAnimating = false
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]

        if e.animState == "fadein" then
            e.animTime = e.animTime + dt
            if not useAnim then
                e:SetAlpha(1)
                if not InCombatLockdown() then
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, e.finalY)
                end
                e.animState = "active"
            elseif e.animTime < (e.staggerDelay or 0) then
                e:SetAlpha(0)
            else
                local p = GetProgress(e.animTime, e.staggerDelay, anim.dur)
                local ep = addon.easeOut(p)
                e:SetAlpha(ep)
                if not InCombatLockdown() then
                    local slideX = (1 - ep) * anim.slideInX
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX + slideX, e.finalY)
                end
                if p >= 1 then
                    e:SetAlpha(1)
                    if not InCombatLockdown() then
                        e:ClearAllPoints()
                        e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, e.finalY)
                    end
                    e.animState = "active"
                end
            end
            anyAnimating = true

        elseif e.animState == "completing" then
            e.animTime = e.animTime + dt
            if e.animTime >= addon.COMPLETE_HOLD then
                e.animState = "fadeout"
                e.animTime  = 0
            end
            anyAnimating = true

        elseif e.animState == "fadeout" then
            e.animTime = e.animTime + dt
            if not useAnim then
                local wasPromotion = e.promotionFadeOut
                if wasPromotion then
                    addon.promotionFadeOutCount = (addon.promotionFadeOutCount or 0) - 1
                    e.promotionFadeOut = nil
                end
                addon.ClearEntry(e)
                if wasPromotion and addon.promotionFadeOutCount == 0 and addon.onPromotionFadeOutCompleteCallback then
                    addon.onPromotionFadeOutCompleteCallback()
                end
            else
                local p  = GetProgress(e.animTime, 0, anim.dur)
                local ep = addon.easeIn(p)
                e:SetAlpha(1 - ep)
                if not InCombatLockdown() then
                    local driftY = ep * anim.driftOutY
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, e.finalY + driftY)
                end
                if p >= 1 then
                    local wasPromotion = e.promotionFadeOut
                    if wasPromotion then
                        addon.promotionFadeOutCount = (addon.promotionFadeOutCount or 0) - 1
                        e.promotionFadeOut = nil
                    end
                    addon.ClearEntry(e)
                    if wasPromotion and addon.promotionFadeOutCount == 0 and addon.onPromotionFadeOutCompleteCallback then
                        addon.onPromotionFadeOutCompleteCallback()
                    end
                end
            end
            anyAnimating = true

        elseif e.animState == "slideout" then
            -- Horizontal slide out (same as collapse, no delay). Used for e.g. nearby turn-on transition.
            e.animTime = e.animTime + dt
            if not useAnim then
                addon.ClearEntry(e)
            else
                local p = GetProgress(e.animTime, 0, anim.dur)
                local ep = addon.easeIn(p)
                e:SetAlpha(1 - ep)
                if not InCombatLockdown() then
                    local slideX = ep * anim.slideOutX
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX + slideX, e.finalY)
                end
                if p >= 1 then
                    addon.ClearEntry(e)
                end
            end
            anyAnimating = true

        elseif e.animState == "collapsing" then
            e.animTime = e.animTime + dt
            local delay = e.collapseDelay or 0
            if not useAnim and e.animTime >= delay then
                addon.ClearEntry(e)
            elseif e.animTime >= delay then
                local p = GetProgress(e.animTime, delay, anim.dur)
                local ep = addon.easeIn(p)
                e:SetAlpha(1 - ep)
                if not InCombatLockdown() then
                    local slideX = ep * anim.slideOutX
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX + slideX, e.finalY)
                end
                if p >= 1 then
                    addon.ClearEntry(e)
                end
            end
            anyAnimating = true

        elseif e.animState == "slideup" then
            e.animTime = e.animTime + dt
            if not useAnim then
                if not InCombatLockdown() and e.finalX and e.finalY then
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, e.finalY)
                end
                e.animState = "active"
                e.slideUpStartY = nil
            else
                local startY = e.slideUpStartY
                if startY and e.finalY ~= nil and e.finalX ~= nil then
                    local p = GetProgress(e.animTime, 0, anim.dur)
                    local ep = addon.easeOut(p)
                    local y = startY + (e.finalY - startY) * ep
                    if not InCombatLockdown() then
                        e:ClearAllPoints()
                        e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, y)
                    end
                    if p >= 1 then
                        if not InCombatLockdown() then
                            e:ClearAllPoints()
                            e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, e.finalY)
                        end
                        e.animState = "active"
                        e.slideUpStartY = nil
                    end
                else
                    e.animState = "active"
                    e.slideUpStartY = nil
                end
            end
            anyAnimating = true
        end

        if e.flashTime > 0 then
            e.flashTime = e.flashTime - dt
            local fp = math.max(e.flashTime / addon.FLASH_DUR, 0)
            local intensity = addon.GetDB("objectiveProgressFlashIntensity", "subtle")
            local alphaMax = FLASH_ALPHA_BY_INTENSITY[intensity] or FLASH_ALPHA_BY_INTENSITY.subtle
            -- Punch-then-settle: phase 1 (0-15%) rapid ease-in to full, phase 2 (15-100%) smooth ease-out to 0
            local alpha
            if fp > 0.85 then
                local phase1Progress = (1 - fp) / 0.15
                alpha = addon.easeIn(phase1Progress) * alphaMax
            else
                local phase2Progress = (0.85 - fp) / 0.85
                alpha = (1 - addon.easeOut(phase2Progress)) * alphaMax
            end
            local fc = addon.GetDB("objectiveProgressFlashColor", nil)
            if not fc or #fc < 3 then fc = { 1, 1, 1 } end
            e.flash:SetColorTexture(fc[1], fc[2], fc[3], alpha)
            anyAnimating = true
        end
    end
    -- When all "slideout" entries have finished, run the completion callback (e.g. nearby turn-on phase 2).
    local stillSlideOut = 0
    for i = 1, addon.POOL_SIZE do
        if pool[i].animState == "slideout" then stillSlideOut = stillSlideOut + 1 end
    end
    if stillSlideOut == 0 and addon.onSlideOutCompleteCallback then
        local fn = addon.onSlideOutCompleteCallback
        addon.onSlideOutCompleteCallback = nil
        fn()
    end
    return anyAnimating
end

local function UpdateSectionHeaderFadeOut(dt, useAnim)
    if not addon.focus.collapse.sectionHeadersFadingOut then return end
    if not useAnim then
        for i = 1, addon.SECTION_POOL_SIZE do
            if sectionPool[i].active then
                sectionPool[i]:SetAlpha(0)
                sectionPool[i]:Hide()
                sectionPool[i].active = false
            end
        end
        addon.focus.collapse.sectionHeadersFadingOut = false
        addon.focus.collapse.sectionHeaderFadeTime = 0
        return
    end
    addon.focus.collapse.sectionHeaderFadeTime = addon.focus.collapse.sectionHeaderFadeTime + dt
    local p = math.min(addon.focus.collapse.sectionHeaderFadeTime / anim.dur, 1)
    local ep = addon.easeIn(p)
    for i = 1, addon.SECTION_POOL_SIZE do
        local s = sectionPool[i]
        if s.active and not InCombatLockdown() and s.finalX ~= nil then
            s:SetAlpha(1 - ep)
            local slideX = ep * anim.slideOutX
            s:ClearAllPoints()
            s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX + slideX, s.finalY)
        elseif s.active then
            s:SetAlpha(1 - ep)
        end
    end
    if p >= 1 then
        for i = 1, addon.SECTION_POOL_SIZE do
            if sectionPool[i].active then
                sectionPool[i]:Hide()
                sectionPool[i].active = false
            end
        end
        addon.focus.collapse.sectionHeadersFadingOut = false
        addon.focus.collapse.sectionHeaderFadeTime = 0
    end
end

local function UpdateSectionHeaderSlideUp(dt, useAnim)
    if not useAnim then
        for i = 1, addon.SECTION_POOL_SIZE do
            local s = sectionPool[i]
            if s and s.active and s.slideUpStartY ~= nil then
                s.slideUpStartY = nil
                s.slideUpAnimTime = nil
                if not InCombatLockdown() and s.finalX ~= nil and s.finalY ~= nil then
                    s:ClearAllPoints()
                    s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX, s.finalY)
                end
            end
        end
        return
    end
    for i = 1, addon.SECTION_POOL_SIZE do
        local s = sectionPool[i]
        if s and s.active and s.slideUpStartY ~= nil and s.finalX ~= nil and s.finalY ~= nil then
            s.slideUpAnimTime = (s.slideUpAnimTime or 0) + dt
            local p = GetProgress(s.slideUpAnimTime, 0, anim.dur)
            local ep = addon.easeOut(p)
            local y = s.slideUpStartY + (s.finalY - s.slideUpStartY) * ep
            if not InCombatLockdown() then
                s:ClearAllPoints()
                s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX, y)
            end
            if p >= 1 then
                if not InCombatLockdown() then
                    s:ClearAllPoints()
                    s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX, s.finalY)
                end
                s.slideUpStartY = nil
                s.slideUpAnimTime = nil
            end
        end
    end
end

local function UpdateSectionHeaderFadeIn(dt, useAnim)
    if not addon.focus.collapse.sectionHeadersFadingIn then return end
    if not useAnim then
        for i = 1, addon.SECTION_POOL_SIZE do
            if sectionPool[i].active then
                sectionPool[i]:SetAlpha(1)
            end
        end
        addon.focus.collapse.sectionHeadersFadingIn = false
        addon.focus.collapse.sectionHeaderFadeTime = 0
        return
    end
    addon.focus.collapse.sectionHeaderFadeTime = addon.focus.collapse.sectionHeaderFadeTime + dt
    local allDone = true
    for i = 1, addon.SECTION_POOL_SIZE do
        local s = sectionPool[i]
        if s.active and s.staggerDelay ~= nil then
            if addon.focus.collapse.sectionHeaderFadeTime < s.staggerDelay then
                s:SetAlpha(0)
                if not InCombatLockdown() and s.finalX ~= nil then
                    local slideX = anim.slideInX
                    s:ClearAllPoints()
                    s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX + slideX, s.finalY)
                end
                allDone = false
            else
                local p = GetProgress(addon.focus.collapse.sectionHeaderFadeTime, s.staggerDelay, anim.dur)
                local ep = addon.easeOut(p)
                s:SetAlpha(ep)
                if not InCombatLockdown() and s.finalX ~= nil then
                    local slideX = (1 - ep) * anim.slideInX
                    s:ClearAllPoints()
                    s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX + slideX, s.finalY)
                end
                if p < 1 then allDone = false end
            end
        end
    end
    if allDone then
        for i = 1, addon.SECTION_POOL_SIZE do
            local s = sectionPool[i]
            if s.active then
                s:SetAlpha(1)
                if not InCombatLockdown() and s.finalX ~= nil then
                    s:ClearAllPoints()
                    s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX, s.finalY)
                end
            end
        end
        addon.focus.collapse.sectionHeadersFadingIn = false
        addon.focus.collapse.sectionHeaderFadeTime = 0
    end
end

local function UpdateCollapseAnimations(dt)
    if not addon.focus.collapse.animating then return end
    local useAnim = addon.GetDB("animations", true)
    UpdateSectionHeaderFadeOut(dt or 0, useAnim)
    local stillCollapsing = false
    for i = 1, addon.POOL_SIZE do
        if pool[i].animState == "collapsing" then
            stillCollapsing = true
            break
        end
    end
    local stillSectionHeadersFadingOut = addon.focus.collapse.sectionHeadersFadingOut
    if not stillCollapsing and not stillSectionHeadersFadingOut then
        addon.focus.collapse.animating = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].animState == "idle" and (pool[i].questID or pool[i].entryKey) then
                addon.ClearEntry(pool[i], false)
            end
        end
        wipe(addon.activeMap)
        if addon.GetDB("animations", true) then
            addon.focus.collapse.sectionHeadersFadingIn  = true
            addon.focus.collapse.sectionHeaderFadeTime    = 0
        end
        if addon.FullLayout then addon.FullLayout() end
    end
end

-- Group collapse completion: when no entries in a group are collapsing anymore,
-- mark that group as collapsed and trigger a layout refresh.
local function UpdateGroupCollapseCompletion()
    if not addon.focus.collapse.groups then return end
    for groupKey, startTime in pairs(addon.focus.collapse.groups) do
            local stillCollapsing = false
            for i = 1, addon.POOL_SIZE do
                local e = pool[i]
                if e.groupKey == groupKey and e.animState == "collapsing" then
                    stillCollapsing = true
                    break
                end
            end

            -- Safety timeout in case something goes wrong with anim state.
            local timedOut = (GetTime() - startTime) > GROUP_COLLAPSE_TIMEOUT

            if not stillCollapsing or timedOut then
                addon.focus.collapse.groups[groupKey] = nil

                -- Capture Y positions of entries and section headers in other groups before layout reflow.
                local slideUpStarts = {}
                local slideUpStartsSec = {}
                local useAnim = addon.GetDB("animations", true)
                if useAnim then
                    for i = 1, addon.POOL_SIZE do
                        local e = pool[i]
                        if e and (e.questID or e.entryKey)
                           and e.groupKey ~= groupKey
                           and e.animState == "active"
                           and e.finalY ~= nil then
                            local key = e.questID or e.entryKey
                            slideUpStarts[key] = e.finalY
                        end
                    end
                    for i = 1, addon.SECTION_POOL_SIZE do
                        local s = sectionPool[i]
                        if s and s.active and s.groupKey and s.groupKey ~= groupKey and s.finalY ~= nil then
                            slideUpStartsSec[s.groupKey] = s.finalY
                        end
                    end
                end

                -- Clean up any lingering collapsing entries for this group.
                for i = 1, addon.POOL_SIZE do
                    local e = pool[i]
                    if e.groupKey == groupKey and e.animState == "collapsing" then
                        addon.ClearEntry(e)
                    end
                end

                -- Re-run layout so remaining groups close up the gap.
                if addon.FullLayout then
                    addon.FullLayout()
                end

                -- Apply slide-up animation to entries that moved up (exclude fadein to avoid interrupting).
                if useAnim and next(slideUpStarts) then
                    for i = 1, addon.POOL_SIZE do
                        local e = pool[i]
                        if e and (e.questID or e.entryKey) and e.animState == "active" and e.finalY ~= nil then
                            local key = e.questID or e.entryKey
                            local startY = slideUpStarts[key]
                            if startY and startY ~= e.finalY then
                                addon.SetEntrySlideUp(e, startY)
                                if not InCombatLockdown() then
                                    e:ClearAllPoints()
                                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, startY)
                                end
                            end
                        end
                    end
                end

                -- Apply slide-up animation to section headers that moved up.
                if useAnim and next(slideUpStartsSec) then
                    for i = 1, addon.SECTION_POOL_SIZE do
                        local s = sectionPool[i]
                        if s and s.active and s.groupKey and s.finalY ~= nil then
                            local startY = slideUpStartsSec[s.groupKey]
                            if startY and startY ~= s.finalY then
                                s.slideUpStartY = startY
                                s.slideUpAnimTime = 0
                                if not InCombatLockdown() then
                                    s:ClearAllPoints()
                                    s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX, startY)
                                end
                            end
                        end
                    end
                end

                -- Only handle one group per frame; others will be processed next tick.
                break
            end
        end
end

local function NeedsFocusUpdate()
    if addon.focus.layout.targetHeight ~= addon.focus.layout.currentHeight then return true end
    if addon.focus.combat.fadeState then return true end
    if addon.focus.collapse.groups and next(addon.focus.collapse.groups) then return true end
    if addon.focus.collapse.sectionHeadersFadingIn then return true end
    for i = 1, addon.SECTION_POOL_SIZE do
        if sectionPool[i].active and sectionPool[i].slideUpStartY ~= nil then return true end
    end
    for i = 1, addon.POOL_SIZE do
        local s = pool[i].animState
        if s ~= "idle" and s ~= "active" then return true end
        if pool[i].flashTime > 0 then return true end
    end
    if addon.focus.collapse.animating then return true end
    return false
end

local function FocusOnUpdate(_, dt)
    if not addon.focus.enabled then return end
    local useAnim = addon.GetDB("animations", true)
    UpdatePanelHeight(dt)
    UpdateCombatFade(dt, useAnim)
    local anyAnimating = UpdateEntryAnimations(dt, useAnim)
    UpdateSectionHeaderSlideUp(dt, useAnim)
    UpdateSectionHeaderFadeIn(dt, useAnim)
    UpdateCollapseAnimations(dt)
    UpdateGroupCollapseCompletion()

    if not anyAnimating then
        local hasActive = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].questID or pool[i].entryKey then hasActive = true; break end
        end
        if not hasActive and not addon.focus.collapsed then
            if not InCombatLockdown() then
                HS:Hide()
            else
                addon.focus.pendingHideAfterCombat = true
            end
        end
    end

    if not NeedsFocusUpdate() then
        HS:SetScript("OnUpdate", nil)
    end
end

--- Ensures the Focus OnUpdate script is running when animations are needed.
--- Called by layout/events; no params or return.
local function EnsureFocusUpdateRunning()
    if not addon.focus.enabled then return end
    if HS:GetScript("OnUpdate") ~= FocusOnUpdate then
        HS:SetScript("OnUpdate", FocusOnUpdate)
    end
end

--- Captures Y positions before a category expand so entries/sections below can slide down.
--- Call before SetCategoryCollapsed(key, false) and FullLayout.
function addon.PrepareGroupExpandSlideDown(expandingKey)
    if not addon.GetDB("animations", true) then return end
    local starts = {}
    local startsSec = {}
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        if e and (e.questID or e.entryKey)
           and e.groupKey ~= expandingKey
           and e.animState == "active"
           and e.finalY ~= nil then
            starts[e.questID or e.entryKey] = e.finalY
        end
    end
    for i = 1, addon.SECTION_POOL_SIZE do
        local s = sectionPool[i]
        if s and s.active and s.groupKey and s.groupKey ~= expandingKey and s.finalY ~= nil then
            startsSec[s.groupKey] = s.finalY
        end
    end
    addon.focus.collapse.expandSlideDownStarts = next(starts) and starts or nil
    addon.focus.collapse.expandSlideDownStartsSec = next(startsSec) and startsSec or nil
end

--- Applies slide-down animation after FullLayout when a category was expanded.
--- Call after FullLayout in the expand path.
function addon.ApplyGroupExpandSlideDown()
    local starts = addon.focus.collapse.expandSlideDownStarts
    local startsSec = addon.focus.collapse.expandSlideDownStartsSec
    addon.focus.collapse.expandSlideDownStarts = nil
    addon.focus.collapse.expandSlideDownStartsSec = nil
    if not addon.GetDB("animations", true) then return end
    if starts then
        for i = 1, addon.POOL_SIZE do
            local e = pool[i]
            if e and (e.questID or e.entryKey) and e.animState == "active" and e.finalY ~= nil then
                local key = e.questID or e.entryKey
                local startY = starts[key]
                if startY and startY ~= e.finalY then
                    addon.SetEntrySlideUp(e, startY)
                    if not InCombatLockdown() then
                        e:ClearAllPoints()
                        e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX, startY)
                    end
                end
            end
        end
    end
    if startsSec then
        for i = 1, addon.SECTION_POOL_SIZE do
            local s = sectionPool[i]
            if s and s.active and s.groupKey and s.finalY ~= nil then
                local startY = startsSec[s.groupKey]
                if startY and startY ~= s.finalY then
                    s.slideUpStartY = startY
                    s.slideUpAnimTime = 0
                    if not InCombatLockdown() then
                        s:ClearAllPoints()
                        s:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", s.finalX, startY)
                    end
                end
            end
        end
    end
end

addon.RunMapCheck              = RunMapCheck
addon.EnsureFocusUpdateRunning = EnsureFocusUpdateRunning
