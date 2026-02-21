--[[
    Horizon Suite - Presence - Core
    Cinematic zone text and notification display. Frame, layers, animation engine,
    and public QueueOrPlay API. Ported from ModernZoneText.
    Step-by-step flow notes: notes/PresenceCore.md

    Design notes:
    - Colour is resolved at show time only (resolveColors, getDiscoveryColor); OnUpdate
      touches alpha and layout only, never colour or text.
    - Presence uses fixed cinematic timings (ENTRANCE_DUR 0.7s, EXIT_DUR 0.8s) and
      larger type sizes by design.
    - QueueOrPlay(typeName, title, subtitle, opts): title = heading, subtitle = second
      line; opts.questID is for colour/icon only, never displayed.
]]

local addon = _G.HorizonSuite
if not addon then return end

addon.Presence = addon.Presence or {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MAIN_SIZE    = 48
local SUB_SIZE     = 24
local FRAME_WIDTH  = 800
local FRAME_HEIGHT = 250
local FRAME_Y_DEF  = -180
local DIVIDER_W    = 400
local DIVIDER_H    = 2
local MAX_QUEUE    = 5

local ENTRANCE_DUR_DEF  = 0.7
local EXIT_DUR_DEF      = 0.8
local CROSSFADE_DUR = 0.4
local ELEMENT_DUR   = 0.4
local SUBTITLE_TRANSITION_DUR = 0.12

local DISCOVERY_SIZE  = 16
local QUEST_ICON_SIZE = 24  -- quest-type icon in toasts; larger than Focus (16) to match heading scale
local DELAY_TITLE     = 0.0
local DELAY_DIVIDER   = 0.15
local DELAY_SUBTITLE  = 0.30
local DELAY_DISCOVERY = 0.45

-- Category/subCategory align with Focus; colours resolved at play via addon.GetQuestColor (respects options).
-- BOSS_EMOTE uses addon.PRESENCE_BOSS_EMOTE_COLOR. QUEST_COMPLETE/QUEST_ACCEPT use opts.questID → base/category when present.
local TYPES = {
    LEVEL_UP       = { pri = 4, category = "COMPLETE",   subCategory = "DEFAULT", sz = 48, dur = 5.0 },
    BOSS_EMOTE     = { pri = 4, specialColor = true,     subCategory = "DEFAULT", sz = 48, dur = 5.0 },
    ACHIEVEMENT    = { pri = 3, category = "ACHIEVEMENT", subCategory = "DEFAULT", sz = 48, dur = 4.5 },
    QUEST_COMPLETE = { pri = 2, category = "DEFAULT",   subCategory = "DEFAULT", sz = 48, dur = 4.0 },  -- overridden by opts.questID → base
    WORLD_QUEST    = { pri = 2, category = "WORLD",     subCategory = "DEFAULT", sz = 48, dur = 4.0 },
    ZONE_CHANGE    = { pri = 2, category = "DEFAULT",   subCategory = "CAMPAIGN", sz = 48, dur = 4.0 },
    QUEST_ACCEPT       = { pri = 1, category = "DEFAULT",   subCategory = "DEFAULT", sz = 36, dur = 3.0 },  -- overridden by opts.questID
    WORLD_QUEST_ACCEPT = { pri = 1, category = "WORLD",     subCategory = "DEFAULT", sz = 36, dur = 3.0 },
    QUEST_UPDATE       = { pri = 1, category = "DEFAULT",   subCategory = "DEFAULT", sz = 20, dur = 2.5 },
    SUBZONE_CHANGE     = { pri = 1, category = "DEFAULT",   subCategory = "CAMPAIGN", sz = 36, dur = 3.0 },
    SCENARIO_START     = { pri = 2, category = "SCENARIO", subCategory = "DEFAULT", sz = 36, dur = 3.5 },  -- category overridden by opts.category (DELVES|DUNGEON|SCENARIO)
    SCENARIO_UPDATE     = { pri = 1, category = "SCENARIO", subCategory = "DEFAULT", sz = 36, dur = 2.5 },  -- category overridden by opts.category (DELVES|DUNGEON|SCENARIO); sz=36 matches SCENARIO_START
}

local function getFrameY()
    local v = addon.GetDB and tonumber(addon.GetDB("presenceFrameY", FRAME_Y_DEF)) or FRAME_Y_DEF
    return math.max(-300, math.min(0, v))
end

local function getFrameScale()
    local v = addon.GetDB and tonumber(addon.GetDB("presenceFrameScale", 1)) or 1
    return math.max(0.5, math.min(1.5, v))
end

local function getEntranceDur()
    if addon.GetDB and not addon.GetDB("presenceAnimations", true) then return 0 end
    local v = addon.GetDB and tonumber(addon.GetDB("presenceEntranceDur", ENTRANCE_DUR_DEF)) or ENTRANCE_DUR_DEF
    return math.max(0.2, math.min(1.5, v))
end

local function getExitDur()
    if addon.GetDB and not addon.GetDB("presenceAnimations", true) then return 0 end
    local v = addon.GetDB and tonumber(addon.GetDB("presenceExitDur", EXIT_DUR_DEF)) or EXIT_DUR_DEF
    return math.max(0.2, math.min(1.5, v))
end

local function getHoldScale()
    local v = addon.GetDB and tonumber(addon.GetDB("presenceHoldScale", 1)) or 1
    return math.max(0.5, math.min(2, v))
end

local function getPresenceFontPath()
    local raw = addon.GetDB and addon.GetDB("fontPath", addon.GetDefaultFontPath and addon.GetDefaultFontPath() or "Fonts\\FRIZQT__.TTF") or "Fonts\\FRIZQT__.TTF"
    return (addon.ResolveFontPath and addon.ResolveFontPath(raw)) or raw
end

local function getMainSize()
    local v = addon.GetDB and tonumber(addon.GetDB("presenceMainSize", MAIN_SIZE)) or MAIN_SIZE
    return math.max(24, math.min(72, v))
end

local function getSubSize()
    local v = addon.GetDB and tonumber(addon.GetDB("presenceSubSize", SUB_SIZE)) or SUB_SIZE
    return math.max(12, math.min(40, v))
end

local function getCategoryColor(cat, default)
    local c = (addon.GetQuestColor and addon.GetQuestColor(cat)) or (addon.QUEST_COLORS and addon.QUEST_COLORS[cat]) or (addon.QUEST_COLORS and addon.QUEST_COLORS.DEFAULT) or default
    return c
end

local function getDiscoveryColor()
    return (addon.GetPresenceDiscoveryColor and addon.GetPresenceDiscoveryColor()) or addon.PRESENCE_DISCOVERY_COLOR or getCategoryColor("COMPLETE", { 0.4, 1, 0.5 })
end

local function resolveColors(typeName, cfg, opts)
    opts = opts or {}
    if cfg.specialColor and typeName == "BOSS_EMOTE" then
        local c = (addon.GetPresenceBossEmoteColor and addon.GetPresenceBossEmoteColor()) or addon.PRESENCE_BOSS_EMOTE_COLOR or { 1, 0.2, 0.2 }
        local sc = getCategoryColor("DEFAULT", { 1, 1, 1 })
        return c, sc
    end
    local cat = cfg.category
    if opts.category and (typeName == "SCENARIO_START" or typeName == "SCENARIO_UPDATE" or typeName == "ZONE_CHANGE" or typeName == "SUBZONE_CHANGE") then
        cat = opts.category
    elseif opts.questID then
        if typeName == "QUEST_COMPLETE" and addon.GetQuestBaseCategory then
            local ok, res = pcall(addon.GetQuestBaseCategory, opts.questID)
            cat = (ok and res) or cat
        elseif (typeName == "QUEST_ACCEPT" or typeName == "QUEST_UPDATE") and addon.GetQuestCategory then
            local ok, res = pcall(addon.GetQuestCategory, opts.questID)
            cat = (ok and res) or cat
        end
    end
    local c = getCategoryColor(cat, { 0.9, 0.9, 0.9 })
    local subCat = cfg.subCategory or "DEFAULT"
    local sc = getCategoryColor(subCat, { 1, 1, 1 })
    return c, sc
end

-- ============================================================================
-- FRAME & LAYER CREATION
-- ============================================================================

local function CreateLayer(parent)
    local L = {}
    local shadowA = (addon.SHADOW_A ~= nil) and addon.SHADOW_A or 0.8
    -- Respect Typography shadow settings when available; fall back to addon globals
    local shadowX = (addon.GetDB and tonumber(addon.GetDB("shadowOffsetX", 2))) or addon.SHADOW_OX or 2
    local shadowY = (addon.GetDB and tonumber(addon.GetDB("shadowOffsetY", -2))) or addon.SHADOW_OY or -2

    L.titleShadow = parent:CreateFontString(nil, "BORDER")
    L.titleShadow:SetFont(getPresenceFontPath(), MAIN_SIZE, "OUTLINE")
    L.titleShadow:SetTextColor(0, 0, 0, shadowA)
    L.titleShadow:SetJustifyH("CENTER")

    L.titleText = parent:CreateFontString(nil, "OVERLAY")
    L.titleText:SetFont(getPresenceFontPath(), MAIN_SIZE, "OUTLINE")
    L.titleText:SetTextColor(1, 1, 1, 1)
    L.titleText:SetJustifyH("CENTER")
    L.titleText:SetPoint("TOP", 0, 0)
    L.titleShadow:SetPoint("CENTER", L.titleText, "CENTER", shadowX, shadowY)

    -- Quest-type icon (same atlas as Focus); larger size to match heading scale
    L.questTypeIcon = parent:CreateTexture(nil, "ARTWORK")
    L.questTypeIcon:SetSize(QUEST_ICON_SIZE, QUEST_ICON_SIZE)
    L.questTypeIcon:SetPoint("RIGHT", L.titleText, "LEFT", -6, 0)
    L.questTypeIcon:Hide()

    L.divider = parent:CreateTexture(nil, "ARTWORK")
    L.divider:SetSize(DIVIDER_W, DIVIDER_H)
    L.divider:SetPoint("TOP", 0, -65)
    L.divider:SetColorTexture(1, 1, 1, 1)
    L.divider:SetAlpha(0)

    L.subShadow = parent:CreateFontString(nil, "BORDER")
    L.subShadow:SetFont(getPresenceFontPath(), SUB_SIZE, "OUTLINE")
    L.subShadow:SetTextColor(0, 0, 0, shadowA)
    L.subShadow:SetJustifyH("CENTER")

    L.subText = parent:CreateFontString(nil, "OVERLAY")
    L.subText:SetFont(getPresenceFontPath(), SUB_SIZE, "OUTLINE")
    L.subText:SetTextColor(1, 1, 1, 1)  -- neutral; resolved at play via resolveColors
    L.subText:SetJustifyH("CENTER")
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -10)
    L.subShadow:SetPoint("CENTER", L.subText, "CENTER", shadowX, shadowY)

    L.discoveryShadow = parent:CreateFontString(nil, "BORDER")
    L.discoveryShadow:SetFont(getPresenceFontPath(), DISCOVERY_SIZE, "OUTLINE")
    L.discoveryShadow:SetTextColor(0, 0, 0, shadowA)
    L.discoveryShadow:SetJustifyH("CENTER")

    L.discoveryText = parent:CreateFontString(nil, "OVERLAY")
    L.discoveryText:SetFont(getPresenceFontPath(), DISCOVERY_SIZE, "OUTLINE")
    L.discoveryText:SetTextColor(1, 1, 1, 1)  -- neutral; resolved at show via getDiscoveryColor
    L.discoveryText:SetJustifyH("CENTER")
    L.discoveryText:SetPoint("TOP", L.subText, "BOTTOM", 0, -5)
    L.discoveryShadow:SetPoint("CENTER", L.discoveryText, "CENTER", shadowX, shadowY)
    L.discoveryText:SetAlpha(0)
    L.discoveryShadow:SetAlpha(0)

    return L
end

local F, layerA, layerB, curLayer, oldLayer
local anim
local active, activeTitle, activeTypeName
local queue, crossfadeStartAlpha
local subtitleTransition  -- { phase = "fadeOut"|"fadeIn", elapsed = 0, newText = string }
local PlayCinematic

local QUEST_UPDATE_DEDUPE_TIME = 1.5
local lastQuestUpdateNorm, lastQuestUpdateTime

-- ============================================================================
-- LIVE DEBUG LOG
-- ============================================================================

local DEBUG_LOG_MAX = 500
local debugLogBuffer = {}
local debugLogFrame

local function IsDebugLive()
    return addon.GetDB and addon.GetDB("presenceDebugLive", false)
end

local function PresenceDebugLog(msg)
    if not IsDebugLive() then return end
    local ts = ("%.1f"):format(GetTime() or 0)
    local line = "[" .. ts .. "] " .. tostring(msg or "")
    debugLogBuffer[#debugLogBuffer + 1] = line
    while #debugLogBuffer > DEBUG_LOG_MAX do
        table.remove(debugLogBuffer, 1)
    end

    if debugLogFrame and debugLogFrame.msg then
        debugLogFrame.msg:AddMessage(line, 0.7, 0.9, 1, 1)
    end
end

local function CreateDebugPanel()
    if debugLogFrame then return end

    local panel = CreateFrame("Frame", "HorizonSuitePresenceDebugFrame", UIParent)
    panel:SetSize(420, 320)
    panel:SetPoint("CENTER", 0, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:Hide()

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)

    local border = CreateFrame("Frame", nil, panel)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    if addon.CreateBorder then addon.CreateBorder(border, { 0.2, 0.2, 0.25, 1 }) end

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("Presence Live Debug")
    title:SetTextColor(0.7, 0.9, 1)

    local closeBtn = CreateFrame("Button", nil, panel)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function()
        if addon.Presence.SetDebugLive then addon.Presence.SetDebugLive(false) end
        panel:Hide()
    end)
    local closeTex = closeBtn:CreateTexture(nil, "OVERLAY")
    closeTex:SetAllPoints(closeBtn)
    closeTex:SetColorTexture(0.5, 0.2, 0.2, 0.8)

    local clearBtn = CreateFrame("Button", nil, panel)
    clearBtn:SetSize(60, 22)
    clearBtn:SetPoint("TOPRIGHT", -40, -10)
    clearBtn:SetScript("OnClick", function()
        debugLogBuffer = {}
        if debugLogFrame and debugLogFrame.msg then
            debugLogFrame.msg:SetMaxLines(DEBUG_LOG_MAX)
        end
    end)
    local clearTex = clearBtn:CreateTexture(nil, "BACKGROUND")
    clearTex:SetAllPoints(clearBtn)
    clearTex:SetColorTexture(0.2, 0.2, 0.25, 0.9)
    local clearLabel = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearLabel:SetPoint("CENTER", 0, 0)
    clearLabel:SetText("Clear")

    local msg = CreateFrame("ScrollingMessageFrame", nil, panel)
    msg:SetPoint("TOPLEFT", 8, -36)
    msg:SetPoint("BOTTOMRIGHT", -8, 8)
    msg:SetFontObject(GameFontNormalSmall)
    msg:SetFading(false)
    msg:SetMaxLines(DEBUG_LOG_MAX)
    msg:EnableMouseWheel(true)
    msg:SetScript("OnMouseWheel", function(_, delta)
        local scroll = msg:GetScrollOffset()
        msg:SetScrollOffset(scroll - delta)
    end)

    panel:SetScript("OnDragStart", function()
        if InCombatLockdown() then return end
        panel:StartMoving()
    end)
    panel:SetScript("OnDragStop", function()
        if InCombatLockdown() then return end
        panel:StopMovingOrSizing()
    end)

    debugLogFrame = panel
    debugLogFrame.msg = msg
end

local function ShowDebugPanel()
    CreateDebugPanel()
    if debugLogFrame then
        debugLogFrame.msg:SetMaxLines(DEBUG_LOG_MAX)
        for _, line in ipairs(debugLogBuffer) do
            debugLogFrame.msg:AddMessage(line, 0.7, 0.9, 1, 1)
        end
        debugLogFrame:Show()
    end
end

local function HideDebugPanel()
    if debugLogFrame then debugLogFrame:Hide() end
end

local function SetDebugLive(v)
    if addon.SetDB then addon.SetDB("presenceDebugLive", v) end
    if v then
        ShowDebugPanel()
        PresenceDebugLog("Live debug enabled")
    else
        HideDebugPanel()
    end
end

local function ToggleDebugLive()
    local next = not IsDebugLive()
    SetDebugLive(next)
    return next
end

-- ============================================================================
-- EASING & ANIMATION HELPERS
-- ============================================================================

local function easeOut(t) return 1 - (1 - t) * (1 - t) end
local function easeIn(t)  return t * t end

local function entEase(elapsed, delay)
    if elapsed < delay then return 0 end
    return easeOut(math.min((elapsed - delay) / ELEMENT_DUR, 1))
end

local function resetLayer(L)
    L.titleText:SetAlpha(0)
    L.titleShadow:SetAlpha(0)
    L.divider:SetAlpha(0)
    L.subText:SetAlpha(0)
    L.subShadow:SetAlpha(0)
    L.discoveryText:SetAlpha(0)
    L.discoveryShadow:SetAlpha(0)
    L.discoveryText:SetText("")
    L.discoveryShadow:SetText("")
    if L.questTypeIcon then L.questTypeIcon:Hide() end
end

local function updateEntrance()
    local L  = curLayer
    local e  = anim.elapsed
    local te = entEase(e, DELAY_TITLE)
    local de = entEase(e, DELAY_DIVIDER)
    local se = entEase(e, DELAY_SUBTITLE)

    L.titleText:SetAlpha(te)
    L.titleShadow:SetAlpha(te * 0.8)
    if L.questTypeIcon and L.questTypeIcon:IsShown() then L.questTypeIcon:SetAlpha(te) end
    L.titleText:ClearAllPoints()
    L.titleText:SetPoint("TOP", 0, (1 - te) * 20)

    L.divider:SetAlpha(de * 0.5)
    L.divider:SetSize(math.max(DIVIDER_W * de, 0.01), DIVIDER_H)

    L.subText:SetAlpha(se)
    L.subShadow:SetAlpha(se * 0.8)
    L.subText:ClearAllPoints()
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -10 + (1 - se) * (-10))

    if (L.discoveryText:GetText() or "") ~= "" then
        local dse = entEase(e, DELAY_DISCOVERY)
        L.discoveryText:SetAlpha(dse)
        L.discoveryShadow:SetAlpha(dse * 0.8)
    end
end

local function updateCrossfade()
    local fadeT = math.min(anim.elapsed / CROSSFADE_DUR, 1)
    local fade  = crossfadeStartAlpha * (1 - easeIn(fadeT))
    oldLayer.titleText:SetAlpha(fade)
    oldLayer.titleShadow:SetAlpha(fade * 0.8)
    if oldLayer.questTypeIcon and oldLayer.questTypeIcon:IsShown() then oldLayer.questTypeIcon:SetAlpha(fade) end
    oldLayer.divider:SetAlpha(fade * 0.5)
    oldLayer.subText:SetAlpha(fade)
    oldLayer.subShadow:SetAlpha(fade * 0.8)
    if (oldLayer.discoveryText:GetText() or "") ~= "" then
        oldLayer.discoveryText:SetAlpha(fade)
        oldLayer.discoveryShadow:SetAlpha(fade * 0.8)
    end
    updateEntrance()
end

local function updateExit()
    local L   = curLayer
    -- Linear fade for smoother exit; easeIn (t^2) was abrupt in the final 20%
    local exitDur = getExitDur()
    local e   = (exitDur > 0) and math.min(anim.elapsed / exitDur, 1) or 1
    local inv = 1 - e

    L.titleText:SetAlpha(inv)
    L.titleShadow:SetAlpha(inv * 0.8)
    if L.questTypeIcon and L.questTypeIcon:IsShown() then L.questTypeIcon:SetAlpha(inv) end
    L.titleText:ClearAllPoints()
    L.titleText:SetPoint("TOP", 0, e * 15)

    L.divider:SetAlpha(0.5 * inv)
    L.divider:SetSize(math.max(DIVIDER_W * inv, 0.01), DIVIDER_H)

    L.subText:SetAlpha(inv)
    L.subShadow:SetAlpha(inv * 0.8)
    L.subText:ClearAllPoints()
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -10 + e * (-10))

    if (L.discoveryText:GetText() or "") ~= "" then
        L.discoveryText:SetAlpha(inv)
        L.discoveryShadow:SetAlpha(inv * 0.8)
    end
end

local function updateSubtitleTransition(dt)
    if not subtitleTransition or not curLayer then return end
    local st = subtitleTransition
    st.elapsed = st.elapsed + dt
    local L = curLayer
    if st.phase == "fadeOut" then
        local t = math.min(st.elapsed / SUBTITLE_TRANSITION_DUR, 1)
        local alpha = 1 - t
        L.subText:SetAlpha(alpha)
        L.subShadow:SetAlpha(alpha * 0.8)
        if st.elapsed >= SUBTITLE_TRANSITION_DUR then
            L.subText:SetText(st.newText or "")
            L.subShadow:SetText(st.newText or "")
            st.phase = "fadeIn"
            st.elapsed = 0
        end
    else
        local t = math.min(st.elapsed / SUBTITLE_TRANSITION_DUR, 1)
        local alpha = t
        L.subText:SetAlpha(alpha)
        L.subShadow:SetAlpha(alpha * 0.8)
        if st.elapsed >= SUBTITLE_TRANSITION_DUR then
            L.subText:SetAlpha(1)
            L.subShadow:SetAlpha(0.8)
            subtitleTransition = nil
        end
    end
end

local function finalizeEntrance()
    local L = curLayer
    L.titleText:SetAlpha(1)
    L.titleShadow:SetAlpha(0.8)
    if L.questTypeIcon and L.questTypeIcon:IsShown() then L.questTypeIcon:SetAlpha(1) end
    L.titleText:ClearAllPoints()
    L.titleText:SetPoint("TOP", 0, 0)
    L.divider:SetAlpha(0.5)
    L.divider:SetSize(DIVIDER_W, DIVIDER_H)
    L.subText:SetAlpha(1)
    L.subShadow:SetAlpha(0.8)
    L.subText:ClearAllPoints()
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -10)
    if (L.discoveryText:GetText() or "") ~= "" then
        L.discoveryText:SetAlpha(1)
        L.discoveryShadow:SetAlpha(0.8)
    end
end

local onComplete
-- OnUpdate: drives entrance/hold/exit phases; adjusts alpha and layout only (no colour or text).
local function PresenceOnUpdate(_, dt)
    if anim.phase == "idle" then return end
    anim.elapsed = anim.elapsed + dt

    if subtitleTransition then
        updateSubtitleTransition(dt)
    end

    if anim.phase == "entrance" then
        local entDur = getEntranceDur()
        if entDur > 0 then
            updateEntrance()
        else
            finalizeEntrance()
        end
        if anim.elapsed >= entDur then
            finalizeEntrance()
            anim.phase   = "hold"
            anim.elapsed = 0
        end
    elseif anim.phase == "crossfade" then
        updateCrossfade()
        local entDur = getEntranceDur()
        if anim.elapsed >= entDur then
            finalizeEntrance()
            resetLayer(oldLayer)
            anim.phase   = "hold"
            anim.elapsed = 0
        end
    elseif anim.phase == "hold" then
        if anim.elapsed >= anim.holdDur then
            anim.phase   = "exit"
            anim.elapsed = 0
        end
    elseif anim.phase == "exit" then
        updateExit()
        local exitDur = getExitDur()
        if anim.elapsed >= exitDur then
            onComplete()
        end
    end
end

onComplete = function()
    local doneTitle = activeTitle
    local doneType = activeTypeName
    local doneSub = (curLayer and curLayer.subText and curLayer.subText:GetText()) or ""

    subtitleTransition = nil
    F:SetScript("OnUpdate", nil)
    anim.phase      = "idle"
    active          = nil
    activeTitle     = nil
    activeTypeName  = nil
    resetLayer(curLayer)
    resetLayer(oldLayer)
    F:Hide()

    PresenceDebugLog(("Complete %s \"%s\" | \"%s\"; queue=%d"):format(tostring(doneType or "?"), tostring(doneTitle or ""):gsub('"', "'"), tostring(doneSub):gsub('"', "'"), #queue))

    if #queue > 0 then
        local best = 1
        for i = 2, #queue do
            if TYPES[queue[i][1]].pri > TYPES[queue[best][1]].pri then
                best = i
            end
        end
        local nxt = table.remove(queue, best)
        -- Defer to next frame to avoid visible flicker when advancing queue (Hide then Show in same frame)
        C_Timer.After(0, function() PlayCinematic(nxt[1], nxt[2], nxt[3], nxt[4]) end)
    end
end

-- ============================================================================
-- Public functions
-- ============================================================================

--- One-time setup: create frame, layers, animation state. Idempotent.
--- @return nil
local function Init()
    if F then return end

    F = CreateFrame("Frame", "HorizonSuitePresenceFrame", UIParent)
    F:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    F:SetPoint("TOP", 0, getFrameY())
    F:SetScale(getFrameScale())
    F:Hide()

    layerA   = CreateLayer(F)
    layerB   = CreateLayer(F)
    curLayer = layerA
    oldLayer = layerB

    anim = { phase = "idle", elapsed = 0, holdDur = 4 }
    active = nil
    activeTitle = nil
    activeTypeName = nil
    queue = {}
    crossfadeStartAlpha = 1
    subtitleTransition = nil
    addon.Presence.pendingDiscovery = nil

    addon.Presence.frame = F
    addon.Presence.anim = anim
    addon.Presence.active = function() return active end
    addon.Presence.activeTitle = function() return activeTitle end
    addon.Presence.animPhase = function() return anim.phase end
end

PlayCinematic = function(typeName, title, subtitle, opts)
    local cfg = TYPES[typeName]
    if not cfg then return end

    opts = opts or {}

    if typeName == "QUEST_UPDATE" and subtitle and addon.Presence.NormalizeQuestUpdateText then
        lastQuestUpdateNorm = addon.Presence.NormalizeQuestUpdateText(subtitle)
        lastQuestUpdateTime = GetTime()
    end
    local L = curLayer
    local c, sc = resolveColors(typeName, cfg, opts)
    local mainSz = math.max(12, math.min(72, math.floor(cfg.sz * (getMainSize() / MAIN_SIZE))))
    local subSz  = math.max(12, math.min(40, math.floor(((cfg.sz >= SUB_SIZE) and SUB_SIZE or cfg.sz) * (getSubSize() / SUB_SIZE))))

    L.titleText:SetFont(getPresenceFontPath(), mainSz, "OUTLINE")
    L.titleShadow:SetFont(getPresenceFontPath(), mainSz, "OUTLINE")
    L.subText:SetFont(getPresenceFontPath(), subSz, "OUTLINE")
    L.subShadow:SetFont(getPresenceFontPath(), subSz, "OUTLINE")

    L.titleText:SetTextColor(c[1], c[2], c[3], 1)
    L.subText:SetTextColor(sc[1], sc[2], sc[3], 1)
    L.divider:SetVertexColor(c[1], c[2], c[3])

    L.titleText:SetText(title or "")
    L.titleShadow:SetText(title or "")
    L.subText:SetText(subtitle or "")
    L.subShadow:SetText(subtitle or "")

    resetLayer(L)
    L.divider:SetSize(0.01, DIVIDER_H)

    -- Quest-type icon (same as Focus): show when quest-related, opts.questID set, and user has icons enabled (set after resetLayer)
    if L.questTypeIcon then
        local showIcon = false
        local atlas
        local questRelated = (typeName == "QUEST_ACCEPT" or typeName == "QUEST_COMPLETE" or typeName == "QUEST_UPDATE" or typeName == "WORLD_QUEST" or typeName == "WORLD_QUEST_ACCEPT")
        local presenceVal = addon.GetDB and addon.GetDB("showPresenceQuestTypeIcons", nil)
        local showIcons = (presenceVal ~= nil) and presenceVal or (addon.GetDB and addon.GetDB("showQuestTypeIcons", false))
        if questRelated and opts.questID and addon.GetQuestTypeAtlas and addon.GetDB and showIcons then
            local catForAtlas = "DEFAULT"
            if typeName == "QUEST_COMPLETE" then
                catForAtlas = "COMPLETE"  -- turn-in icon
            elseif (typeName == "QUEST_ACCEPT" or typeName == "QUEST_UPDATE") and addon.GetQuestCategory then
                catForAtlas = addon.GetQuestCategory(opts.questID) or catForAtlas
            elseif typeName == "WORLD_QUEST" or typeName == "WORLD_QUEST_ACCEPT" then
                catForAtlas = "WORLD"
            end
            atlas = addon.GetQuestTypeAtlas(opts.questID, catForAtlas)
            if atlas then showIcon = true end
        end
        if showIcon and atlas then
            L.questTypeIcon:SetAtlas(atlas)
            -- Scale icon to match title size so it aligns visually (QUEST_UPDATE uses sz=20)
            local iconMax = (addon.GetDB and addon.GetDB("presenceIconSize", 24)) or QUEST_ICON_SIZE
            local iconSz = (mainSz < iconMax) and mainSz or iconMax
            L.questTypeIcon:SetSize(iconSz, iconSz)
            L.questTypeIcon:ClearAllPoints()
            L.questTypeIcon:SetPoint("RIGHT", L.titleText, "LEFT", -6, 0)
            L.questTypeIcon:Show()
        else
            L.questTypeIcon:Hide()
        end
    end

    L.titleText:ClearAllPoints()
    L.titleText:SetPoint("TOP", 0, 20)
    L.subText:ClearAllPoints()
    L.subText:SetPoint("TOP", L.divider, "BOTTOM", 0, -20)

    if addon.Presence.pendingDiscovery and (typeName == "ZONE_CHANGE" or typeName == "SUBZONE_CHANGE") and (not addon.GetDB or addon.GetDB("showPresenceDiscovery", true)) then
        L.discoveryText:SetText(addon.L["Discovered"])
        L.discoveryShadow:SetText(addon.L["Discovered"])
        local dc = getDiscoveryColor()
        L.discoveryText:SetTextColor(dc[1], dc[2], dc[3], 1)
        L.discoveryShadow:SetTextColor(0, 0, 0, (addon.SHADOW_A ~= nil) and addon.SHADOW_A or 0.8)
        addon.Presence.pendingDiscovery = nil
    end

    active        = cfg
    activeTitle   = title
    activeTypeName = typeName
    anim.elapsed = 0
    anim.holdDur = cfg.dur * getHoldScale()

    if oldLayer.titleText:GetAlpha() > 0 then
        anim.phase = "crossfade"
    else
        anim.phase = "entrance"
    end

    local src = (opts.source and (" via %s"):format(opts.source)) or ""
    PresenceDebugLog(("Play %s \"%s\" | \"%s\" phase=%s%s"):format(typeName, tostring(title or ""):gsub('"', "'"), tostring(subtitle or ""):gsub('"', "'"), anim.phase, src))

    F:SetScript("OnUpdate", PresenceOnUpdate)
    F:SetAlpha(1)
    F:Show()
end

--- Update the subtitle text of the currently displayed cinematic (e.g. subzone soft-update).
--- Uses a quick fade-out/fade-in transition instead of instant swap.
--- @param newSub string New subtitle text
--- @return nil
local function SoftUpdateSubtitle(newSub)
    if not curLayer then return end
    local txt = newSub or ""
    if (curLayer.subText:GetText() or "") == txt then return end
    if subtitleTransition then
        subtitleTransition.newText = txt
    else
        subtitleTransition = { phase = "fadeOut", elapsed = 0, newText = txt }
    end
    if anim.phase == "hold" then
        anim.elapsed = 0
    end
end

--- Show the "Discovered" line on the current layer (zone/subzone discovery).
--- @return nil
local function ShowDiscoveryLine()
    if not curLayer then return end
    if addon.GetDB and not addon.GetDB("showPresenceDiscovery", true) then return end
    curLayer.discoveryText:SetText(addon.L["Discovered"])
    curLayer.discoveryShadow:SetText(addon.L["Discovered"])
    local dc = getDiscoveryColor()
    curLayer.discoveryText:SetTextColor(dc[1], dc[2], dc[3], 1)
    curLayer.discoveryShadow:SetTextColor(0, 0, 0, (addon.SHADOW_A ~= nil) and addon.SHADOW_A or 0.8)
    if anim.phase == "hold" then
        curLayer.discoveryText:SetAlpha(1)
        curLayer.discoveryShadow:SetAlpha(0.8)
    end
end

--- Set flag so next zone/subzone change shows "Discovered" line.
--- @return nil
local function SetPendingDiscovery()
    addon.Presence.pendingDiscovery = true
end

local function interruptCurrent()
    crossfadeStartAlpha = curLayer.titleText:GetAlpha()
    oldLayer, curLayer = curLayer, oldLayer
    active         = nil
    activeTitle    = nil
    activeTypeName = nil
end

--- Queue or immediately play a cinematic notification.
--- @param typeName string LEVEL_UP, BOSS_EMOTE, ACHIEVEMENT, QUEST_COMPLETE, etc.
--- @param title string Heading text (first line)
--- @param subtitle string Second line text
--- @param opts table|nil Optional; opts.questID for colour/icon, opts.category for SCENARIO_START, opts.source for debug (event name)
--- @return nil
local function QueueOrPlay(typeName, title, subtitle, opts)
    if not F then Init() end
    local cfg = TYPES[typeName]
    if not cfg then return end

    opts = opts or {}

    -- Dedupe: skip QUEST_UPDATE if same normalized text shown recently
    if typeName == "QUEST_UPDATE" and subtitle and addon.Presence.NormalizeQuestUpdateText then
        local norm = addon.Presence.NormalizeQuestUpdateText(subtitle)
        if norm and norm ~= "" and lastQuestUpdateNorm == norm and (GetTime() - (lastQuestUpdateTime or 0)) < QUEST_UPDATE_DEDUPE_TIME then
            return
        end
    end

    if active then
        -- Always queue when something is showing; no interrupting. Subzone-only changes
        -- bypass QueueOrPlay and use SoftUpdateSubtitle (PresenceEvents).
        if #queue < MAX_QUEUE then
            -- Dedup: skip if same type and title already showing (e.g. duplicate zone change)
            if not (activeTitle == title and activeTypeName == typeName) then
                queue[#queue + 1] = { typeName, title, subtitle, opts }
                local src = (opts.source and (" via %s"):format(opts.source)) or ""
                PresenceDebugLog(("Queued %s | \"%s\" | \"%s\" (q=%d)%s"):format(typeName, tostring(title):gsub('"', "'"), tostring(subtitle or ""):gsub('"', "'"), #queue, src))
            end
        end
    else
        local src = (opts.source and (" via %s"):format(opts.source)) or ""
        PresenceDebugLog(("QueueOrPlay: play %s | \"%s\" | \"%s\"%s"):format(typeName, tostring(title or ""):gsub('"', "'"), tostring(subtitle or ""):gsub('"', "'"), src))
        PlayCinematic(typeName, title, subtitle, opts)
    end
end

--- Hide frame, clear queue, reset animation state.
--- @return nil
local function HideAndClear()
    if not F then return end
    F:SetScript("OnUpdate", nil)
    anim.phase      = "idle"
    active          = nil
    activeTitle     = nil
    activeTypeName  = nil
    queue = {}
    subtitleTransition = nil
    addon.Presence.pendingDiscovery = nil
    resetLayer(curLayer)
    resetLayer(oldLayer)
    F:Hide()
end

--- Dump Presence internal state to chat for debugging.
--- @return nil
local function DumpDebug()
    if not F then Init() end
    local p = addon.HSPrint or function(msg) print("|cFF00CCFFHorizon Suite:|r " .. tostring(msg or "")) end

    p("|cFF00CCFF--- Presence debug ---|r")
    p("Frame: created, visible=" .. tostring(F and F:IsVisible()))
    p("Module enabled: " .. tostring(addon.IsModuleEnabled and addon:IsModuleEnabled("presence") or "?"))

    if InCombatLockdown then
        p("In combat: " .. tostring(InCombatLockdown()))
    end

    if anim then
        p("Anim phase: " .. tostring(anim.phase) .. ", elapsed: " .. tostring(anim.elapsed) .. ", holdDur: " .. tostring(anim.holdDur))
    end

    if active then
        local sub = (curLayer and curLayer.subText and curLayer.subText:GetText()) or ""
        p("Active: typeName=\"" .. tostring(activeTypeName) .. "\" title=\"" .. tostring(activeTitle) .. "\" subtitle=\"" .. tostring(sub):gsub('"', '\\"') .. "\" pri=" .. tostring(active.pri))
    else
        p("Active: (none)")
    end

    p("Pending discovery: " .. tostring(addon.Presence.pendingDiscovery or false))
    p("Queue: " .. tostring(#queue) .. " entries")
    for i, e in ipairs(queue) do
        p("  [" .. tostring(i) .. "] " .. tostring(e[1]) .. " | \"" .. tostring(e[2]):gsub('"', '\\"') .. "\" | \"" .. tostring(e[3]):gsub('"', '\\"') .. "\"")
    end

    if addon.GetDB then
        p("Options: showPresenceDiscovery=" .. tostring(addon.GetDB("showPresenceDiscovery", true)) .. ", showPresenceQuestTypeIcons=" .. tostring(addon.GetDB("showPresenceQuestTypeIcons", false)) .. ", presenceIconSize=" .. tostring(addon.GetDB("presenceIconSize", 24)))
    end

    if GetZoneText then
        p("Current zone: " .. tostring(GetZoneText()) .. " / " .. tostring(GetSubZoneText()))
    end

    p("|cFF00CCFF--- End Presence debug ---|r")
end

-- ============================================================================
-- Exports
-- ============================================================================

--- Re-apply frame position and scale from DB. Call when presence options change.
--- @return nil
local function ApplyPresenceOptions()
    if not F then return end
    F:ClearAllPoints()
    F:SetPoint("TOP", 0, getFrameY())
    F:SetScale(getFrameScale())
end

addon.Presence.Init               = Init
addon.Presence.ApplyPresenceOptions = ApplyPresenceOptions
addon.Presence.QueueOrPlay        = QueueOrPlay
addon.Presence.SoftUpdateSubtitle = SoftUpdateSubtitle
addon.Presence.ShowDiscoveryLine  = ShowDiscoveryLine
addon.Presence.SetPendingDiscovery = SetPendingDiscovery
addon.Presence.HideAndClear       = HideAndClear
addon.Presence.DumpDebug          = DumpDebug
addon.Presence.IsDebugLive        = IsDebugLive
addon.Presence.SetDebugLive       = SetDebugLive
addon.Presence.ToggleDebugLive    = ToggleDebugLive
addon.Presence.ShowDebugPanel     = ShowDebugPanel
addon.Presence.HideDebugPanel     = HideDebugPanel
addon.Presence.DISCOVERY_WAIT     = 0.15
