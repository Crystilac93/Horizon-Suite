--[[
    Horizon Suite - Focus - Animation Engine
    HS OnUpdate: height lerp, entry fade/slide/collapse, objective flash, auto-hide.
    Uses C_Map.GetBestMapForUnit in RunMapCheck for zone change detection.
]]

local addon = _G.HorizonSuite

local HEIGHT_SNAP_THRESHOLD   = 0.5
local DRIFT_THRESHOLD        = 0.1
local FLASH_ALPHA_MAX        = 0.12
local GROUP_COLLAPSE_TIMEOUT = 2

-- ============================================================================
-- ANIMATION ENGINE
-- ============================================================================

local HS          = addon.HS
local pool         = addon.pool
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
    local dur = addon.COMBAT_FADE_DUR or 0.4
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
            local p = math.min(addon.focus.combat.fadeTime / dur, 1)
            HS:SetAlpha(1 - p)
            if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(1 - p) end
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
            local p = math.min(addon.focus.combat.fadeTime / dur, 1)
            if HS:IsShown() then HS:SetAlpha(p) end
            if floatingBtn and floatingBtn:IsShown() then floatingBtn:SetAlpha(p) end
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
            elseif e.animTime < e.staggerDelay then
                e:SetAlpha(0)
            else
                local t = e.animTime - e.staggerDelay
                local p = math.min(t / addon.FADE_IN_DUR, 1)
                local ep = addon.easeOut(p)
                e:SetAlpha(ep)
                if not InCombatLockdown() then
                    local slideX = (1 - ep) * addon.SLIDE_IN_X
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
                local p  = math.min(e.animTime / addon.FADE_OUT_DUR, 1)
                local ep = addon.easeIn(p)
                e:SetAlpha(1 - ep)
                if not InCombatLockdown() then
                    local driftY = ep * addon.DRIFT_OUT_Y
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
                local p = math.min(e.animTime / addon.COLLAPSE_DUR, 1)
                local ep = addon.easeIn(p)
                e:SetAlpha(1 - ep)
                if not InCombatLockdown() then
                    local slideX = ep * addon.SLIDE_OUT_X
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
                local t = e.animTime - delay
                local p = math.min(t / addon.COLLAPSE_DUR, 1)
                local ep = addon.easeIn(p)
                e:SetAlpha(1 - ep)
                if not InCombatLockdown() then
                    local slideX = ep * addon.SLIDE_OUT_X
                    e:ClearAllPoints()
                    e:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", e.finalX + slideX, e.finalY)
                end
                if p >= 1 then
                    addon.ClearEntry(e)
                end
            end
            anyAnimating = true
        end

        if e.flashTime > 0 then
            e.flashTime = e.flashTime - dt
            local fp = math.max(e.flashTime / addon.FLASH_DUR, 0)
            e.flash:SetColorTexture(1, 1, 1, fp * FLASH_ALPHA_MAX)
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

local function UpdateCollapseAnimations()
    if not addon.focus.collapse.animating then return end
    local stillCollapsing = false
    for i = 1, addon.POOL_SIZE do
        if pool[i].animState == "collapsing" then
            stillCollapsing = true
            break
        end
    end
    if not stillCollapsing then
        addon.focus.collapse.animating = false
        for i = 1, addon.POOL_SIZE do
            if pool[i].animState == "idle" and (pool[i].questID or pool[i].entryKey) then
                addon.ClearEntry(pool[i], false)
            end
        end
        wipe(addon.activeMap)
        if addon.GetDB("showSectionHeadersWhenCollapsed", false) then
            if addon.FullLayout then addon.FullLayout() end
        else
            if not InCombatLockdown() then
                scrollFrame:Hide()
            else
                addon.focus.layoutPendingAfterCombat = true
            end
            addon.focus.layout.targetHeight = addon.GetCollapsedHeight()
        end
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

                -- Only handle one group per frame; others will be processed next tick.
                break
            end
        end
end

local function NeedsFocusUpdate()
    if addon.focus.layout.targetHeight ~= addon.focus.layout.currentHeight then return true end
    if addon.focus.combat.fadeState then return true end
    if addon.focus.collapse.groups and next(addon.focus.collapse.groups) then return true end
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
    UpdateCollapseAnimations()
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

addon.RunMapCheck              = RunMapCheck
addon.EnsureFocusUpdateRunning = EnsureFocusUpdateRunning
