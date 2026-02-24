--[[
    Horizon Suite - Horizon Insight (Insight)
    Cinematic tooltips with class colors, spec/role, faction icons.
    Blizzard APIs: GameTooltip, TooltipDataProcessor, C_ClassColor, Inspect.
    Settings via addon.GetDB/SetDB (profile-backed).
]]

local addon = _G.HorizonSuite
if not addon then return end

addon.Insight = addon.Insight or {}
local Insight = addon.Insight

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local FONT_PATH       = "Fonts\\FRIZQT__.TTF"
local HEADER_SIZE     = 14
local BODY_SIZE       = 12
local SMALL_SIZE      = 10

local PANEL_BG        = { 0, 0, 0, 0.75 }
local PANEL_BORDER    = { 0.25, 0.25, 0.25, 0.30 }

local FADE_IN_DUR     = 0.15

local DEFAULT_ANCHOR  = "cursor"
local FIXED_POINT     = "BOTTOMRIGHT"
local FIXED_X         = -40
local FIXED_Y         = 120

local INSPECT_THROTTLE = 1.5
local CACHE_TTL        = 300
local CACHE_MAX        = 100

local FACTION_ICONS = {
    Horde    = "|TInterface\\FriendsFrame\\PlusManz-Horde:14:14:0:0|t ",
    Alliance = "|TInterface\\FriendsFrame\\PlusManz-Alliance:14:14:0:0|t ",
}

local SPEC_COLOR   = { 0.65, 0.75, 0.85 }
local MOUNT_COLOR  = { 0.80, 0.65, 1.00 }   -- soft purple for mount name
local MOUNT_SRC_COLOR = { 0.55, 0.55, 0.55 } -- grey for source text
local ILVL_COLOR   = { 0.60, 0.85, 1.00 }   -- ice blue for item level
local TITLE_COLOR  = { 1.00, 0.82, 0.00 }   -- gold for PvP title

local CINEMATIC_BACKDROP = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- ============================================================================
-- HELPERS
-- ============================================================================

local function easeOut(t) return 1 - (1 - t) * (1 - t) end

local function IsEnabled()
    return addon:IsModuleEnabled("insight")
end

local function GetAnchorMode()    return addon.GetDB("insightAnchorMode",    DEFAULT_ANCHOR) end
local function GetFixedPoint()    return addon.GetDB("insightFixedPoint",   FIXED_POINT)    end
local function GetFixedX()        return tonumber(addon.GetDB("insightFixedX", FIXED_X)) or FIXED_X end
local function GetFixedY()        return tonumber(addon.GetDB("insightFixedY", FIXED_Y)) or FIXED_Y end

local function ShowMount()        return addon.GetDB("insightShowMount",       true)  end
local function ShowIlvl()         return addon.GetDB("insightShowIlvl",        true)  end
local function ShowPvPTitle()     return addon.GetDB("insightShowPvPTitle",    true)  end
local function ShowStatusBadges() return addon.GetDB("insightShowStatusBadges",true)  end

-- ============================================================================
-- BACKBONE TOOLTIP STYLING
-- ============================================================================

local tooltipsToStyle = {}
local hookedShow      = {}

local function StripNineSlice(tooltip)
    if tooltip and tooltip.NineSlice then
        tooltip.NineSlice:SetAlpha(0)
    end
end

local function RestoreNineSlice(tooltip)
    if tooltip and tooltip.NineSlice then
        tooltip.NineSlice:SetAlpha(1)
    end
end

local function ApplyBackdrop(tooltip)
    if not tooltip then return end
    if not tooltip.SetBackdrop then
        Mixin(tooltip, BackdropTemplateMixin)
    end
    tooltip:SetBackdrop(CINEMATIC_BACKDROP)
    tooltip:SetBackdropColor(PANEL_BG[1], PANEL_BG[2], PANEL_BG[3], PANEL_BG[4])
    tooltip:SetBackdropBorderColor(PANEL_BORDER[1], PANEL_BORDER[2], PANEL_BORDER[3], PANEL_BORDER[4])
end

local function StyleFonts(tooltip)
    if not tooltip then return end
    local name = tooltip:GetName()
    if not name then return end
    local S = function(v) return (addon.ScaledForModule or addon.Scaled or function(x) return x end)(v, "insight") end
    local numLines = tooltip:NumLines()
    for i = 1, numLines do
        local left  = _G[name .. "TextLeft" .. i]
        local right = _G[name .. "TextRight" .. i]
        if left then
            local sz = (i == 1) and S(HEADER_SIZE) or S(BODY_SIZE)
            left:SetFont(FONT_PATH, sz, "OUTLINE")
        end
        if right then
            right:SetFont(FONT_PATH, S(BODY_SIZE), "OUTLINE")
        end
    end
end

local function StyleTooltipFull(tooltip)
    StripNineSlice(tooltip)
    ApplyBackdrop(tooltip)
end

local function HookTooltipOnShow(tooltip)
    tooltip:HookScript("OnShow", function(self)
        if not IsEnabled() then return end
        StripNineSlice(self)
        ApplyBackdrop(self)
    end)
end

local function HookTooltipShowMethod(tooltip)
    if hookedShow[tooltip] then return end
    hookedShow[tooltip] = true
    hooksecurefunc(tooltip, "Show", function(self)
        if not IsEnabled() then return end
        StyleFonts(self)
    end)
end

-- ============================================================================
-- ANIMATION ENGINE
-- ============================================================================

local fadeState   = "idle"
local fadeElapsed = 0
local fadeTarget  = nil

local animFrame = CreateFrame("Frame")
animFrame:Hide()

animFrame:SetScript("OnUpdate", function(self, elapsed)
    if fadeState == "fadein" and fadeTarget then
        fadeElapsed = fadeElapsed + elapsed
        local progress = math.min(fadeElapsed / FADE_IN_DUR, 1)
        fadeTarget:SetAlpha(easeOut(progress))
        if progress >= 1 then
            fadeState = "visible"
            self:Hide()
        end
    else
        self:Hide()
    end
end)

local function StartFadeIn(tooltip)
    fadeTarget  = tooltip
    fadeElapsed = 0
    fadeState   = "fadein"
    tooltip:SetAlpha(0)
    animFrame:Show()
end

local function HookGameTooltipAnimation()
    GameTooltip:HookScript("OnShow", function(self)
        if not IsEnabled() then return end
        StartFadeIn(self)
    end)
    GameTooltip:HookScript("OnHide", function(self)
        fadeState = "idle"
        animFrame:Hide()
        self:SetAlpha(1)
    end)
end

-- ============================================================================
-- MOUNT SCANNER
-- ============================================================================

local function GetPlayerMountInfo(unit)
    if not C_MountJournal or not C_UnitAuras then return nil end
    local i = 1
    while true do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not auraData then break end
        local spellID = auraData.spellId
        if spellID then
            local mountID = C_MountJournal.GetMountFromSpell(spellID)
            if mountID then
                local mName, _, mIcon, _, _, sourceType, _, _, _, _, isCollected =
                    C_MountJournal.GetMountInfoByID(mountID)
                local _, description, source = C_MountJournal.GetMountInfoExtraByID(mountID)
                return {
                    name        = mName,
                    icon        = mIcon,
                    source      = source,
                    sourceType  = sourceType,
                    isCollected = isCollected,
                    description = description,
                }
            end
        end
        i = i + 1
    end
    return nil
end

-- ============================================================================
-- UNIT TOOLTIP ENHANCEMENTS
-- ============================================================================

local inspectCache = {}
local lastInspect  = 0

local function PruneCache()
    local now   = GetTime()
    local count = 0
    local oldest, oldestKey
    for guid, entry in pairs(inspectCache) do
        if now - entry.time > CACHE_TTL then
            inspectCache[guid] = nil
        else
            count = count + 1
            if not oldest or entry.time < oldest then
                oldest    = entry.time
                oldestKey = guid
            end
        end
    end
    if count > CACHE_MAX and oldestKey then
        inspectCache[oldestKey] = nil
    end
end

local function CacheInspect(guid, unit)
    local specID = GetInspectSpecialization(unit)
    if not specID or specID <= 0 then return end
    local _, specName, _, specIcon, role = GetSpecializationInfoByID(specID)
    if not specName then return end

    local ilvl
    if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
        local equipped = C_PaperDollInfo.GetInspectItemLevel(unit)
        if equipped and equipped > 0 then
            ilvl = equipped
        end
    end

    inspectCache[guid] = {
        specName = specName,
        specIcon = specIcon,
        role     = role,
        ilvl     = ilvl,
        time     = GetTime(),
    }
end

local function RequestInspect(unit)
    if not UnitIsPlayer(unit) then return end
    if not CanInspect(unit) then return end
    local now = GetTime()
    if now - lastInspect < INSPECT_THROTTLE then return end
    lastInspect = now
    NotifyInspect(unit)
end

local function HideHealthBar()
    local bar = GameTooltip.StatusBar
    if bar then
        bar:Hide()
        bar:HookScript("OnShow", function(self) self:Hide() end)
    end
end

local function ProcessUnitTooltip()
    if not IsEnabled() then return end
    if not GameTooltip or not GameTooltip:IsShown() then return end
    if not UnitExists("mouseover") then return end

    local unit     = "mouseover"
    local isPlayer = UnitIsPlayer(unit)
    local guid     = UnitGUID(unit)

    if not isPlayer then
        GameTooltip:SetBackdropBorderColor(PANEL_BORDER[1], PANEL_BORDER[2], PANEL_BORDER[3], PANEL_BORDER[4])
        StyleFonts(GameTooltip)
        return
    end

    local className, classFile = UnitClass(unit)
    local classColor = classFile and C_ClassColor and C_ClassColor.GetClassColor(classFile)
    local cached     = guid and inspectCache[guid]

    -- 1. Name line: faction icon + class colour
    local nameLeft = _G["GameTooltipTextLeft1"]
    if nameLeft then
        local faction = UnitFactionGroup(unit)
        local icon    = FACTION_ICONS[faction] or ""
        local name    = GetUnitName(unit, true) or nameLeft:GetText() or ""
        nameLeft:SetText(icon .. name)
        if classColor then
            nameLeft:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    end

    -- 2. Border tint
    if classColor then
        GameTooltip:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.60)
    end

    -- 3. Clean up Blizzard lines: strip "(Player)", remove faction text, style class line
    local numLines = GameTooltip:NumLines()
    for j = 2, numLines do
        local lineLeft = _G["GameTooltipTextLeft" .. j]
        if lineLeft then
            local text = lineLeft:GetText() or ""

            -- Strip "(Player)" suffix
            if text:find(" %(Player%)") then
                text = text:gsub(" %(Player%)", "")
                lineLeft:SetText(text)
            end

            -- Blank the redundant faction line (already shown as icon on name)
            if text == "Horde" or text == "Alliance" then
                lineLeft:SetText("")

            -- Style the class line: class colour + spec icon prefix (when cached)
            elseif className and text ~= "" and text:find(className, 1, true) then
                if classColor then
                    lineLeft:SetTextColor(classColor.r, classColor.g, classColor.b)
                end
                if cached and cached.specIcon then
                    lineLeft:SetText("|T" .. cached.specIcon .. ":14:14:0:0|t " .. text)
                end
            end
        end
    end

    -- 4. PvP title
    if ShowPvPTitle() then
        local pvpFullName = UnitPVPName(unit)
        local baseName    = UnitName(unit)
        if pvpFullName and baseName and pvpFullName ~= baseName then
            GameTooltip:AddLine(pvpFullName, TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
        end
    end

    -- 5. Status badges
    if ShowStatusBadges() then
        local badges = {}
        if UnitAffectingCombat(unit) then badges[#badges + 1] = "|cffff4444[Combat]|r" end
        if UnitIsAFK(unit)           then badges[#badges + 1] = "|cffffff55[AFK]|r"    end
        if UnitIsDND(unit)           then badges[#badges + 1] = "|cffaaaaaa[DND]|r"    end
        if #badges > 0 then
            GameTooltip:AddLine(table.concat(badges, "  "), 1, 1, 1)
        end
    end

    -- 6. Item level (only once inspect cache is available)
    if cached then
        if ShowIlvl() and cached.ilvl then
            GameTooltip:AddLine("Item Level: " .. cached.ilvl, ILVL_COLOR[1], ILVL_COLOR[2], ILVL_COLOR[3])
        end
        GameTooltip:Show()
    else
        RequestInspect(unit)
    end

    -- 7. Mount block
    if ShowMount() then
        local mount = GetPlayerMountInfo(unit)
        if mount and mount.name then
            local iconStr = mount.icon and ("|T" .. mount.icon .. ":14:14:0:0|t ") or ""
            GameTooltip:AddLine(iconStr .. mount.name, MOUNT_COLOR[1], MOUNT_COLOR[2], MOUNT_COLOR[3])
            if mount.source and mount.source ~= "" then
                GameTooltip:AddLine(mount.source, MOUNT_SRC_COLOR[1], MOUNT_SRC_COLOR[2], MOUNT_SRC_COLOR[3])
            end
            if mount.isCollected == true then
                GameTooltip:AddLine("|cff55ff55You own this mount|r", 1, 1, 1)
            elseif mount.isCollected == false then
                GameTooltip:AddLine("|cffff5555You don't own this mount|r", 1, 1, 1)
            end
            GameTooltip:Show()
        end
    end

    StyleFonts(GameTooltip)
end

local pendingUnit = false

local function OnUnitTooltip(tooltip, data)
    if tooltip ~= GameTooltip or not IsEnabled() then return end
    if not pendingUnit then
        pendingUnit = true
        C_Timer.After(0, function()
            pendingUnit = false
            ProcessUnitTooltip()
        end)
    end
end

-- ============================================================================
-- POSITIONING SYSTEM
-- ============================================================================

local function HookPositioning()
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not IsEnabled() then return end
        local mode = GetAnchorMode()
        if mode == "fixed" then
            tooltip:ClearAllPoints()
            tooltip:SetPoint(GetFixedPoint(), UIParent, GetFixedPoint(), GetFixedX(), GetFixedY())
        else
            tooltip:SetOwner(parent, "ANCHOR_CURSOR")
        end
    end)
end

-- Draggable anchor frame
local anchorFrame = CreateFrame("Frame", "HorizonSuiteInsightAnchor", UIParent, "BackdropTemplate")
anchorFrame:SetSize(160, 40)
anchorFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", FIXED_X, FIXED_Y)
anchorFrame:SetBackdrop(CINEMATIC_BACKDROP)
anchorFrame:SetBackdropColor(0, 0, 0, 0.85)
anchorFrame:SetBackdropBorderColor(0.50, 0.70, 1.0, 0.60)
anchorFrame:SetMovable(true)
anchorFrame:EnableMouse(true)
anchorFrame:RegisterForDrag("LeftButton")
anchorFrame:SetClampedToScreen(true)
anchorFrame:SetFrameStrata("DIALOG")
anchorFrame:Hide()

local anchorLabel = anchorFrame:CreateFontString(nil, "OVERLAY")
anchorLabel:SetFont(FONT_PATH, (addon.ScaledForModule or addon.Scaled or function(v) return v end)(BODY_SIZE, "insight"), "OUTLINE")
anchorLabel:SetPoint("CENTER")
anchorLabel:SetTextColor(0.50, 0.70, 1.0, 1)
anchorLabel:SetText("TOOLTIP ANCHOR")

local anchorHint = anchorFrame:CreateFontString(nil, "OVERLAY")
anchorHint:SetFont(FONT_PATH, (addon.ScaledForModule or addon.Scaled or function(v) return v end)(SMALL_SIZE, "insight"), "OUTLINE")
anchorHint:SetPoint("TOP", anchorFrame, "BOTTOM", 0, -4)
anchorHint:SetTextColor(0.60, 0.60, 0.60, 1)
anchorHint:SetText("Drag to move · Right-click to confirm")

anchorFrame:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then self:StartMoving() end
end)
anchorFrame:SetScript("OnDragStop", function(self)
    if InCombatLockdown() then return end
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    addon.SetDB("insightFixedPoint", point)
    addon.SetDB("insightFixedX", math.floor(x + 0.5))
    addon.SetDB("insightFixedY", math.floor(y + 0.5))
end)

anchorFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        self:Hide()
        addon.SetDB("insightAnchorMode", "fixed")
        if addon.HSPrint then addon.HSPrint("Horizon Insight: Position saved. Anchor set to FIXED.") end
    end
end)

local function ShowAnchorFrame()
    if InCombatLockdown() then return end
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint(GetFixedPoint(), UIParent, GetFixedPoint(), GetFixedX(), GetFixedY())
    anchorFrame:Show()
    addon.SetDB("insightAnchorMode", "fixed")
    if addon.HSPrint then addon.HSPrint("Horizon Insight: Drag the anchor, then right-click to confirm.") end
end

local function HideAnchorFrame()
    anchorFrame:Hide()
end

-- ============================================================================
-- INIT / DISABLE / APPLY
-- ============================================================================

--- Show the draggable anchor frame to set fixed tooltip position.
function Insight.ShowAnchorFrame()
    ShowAnchorFrame()
end

--- Apply tooltip options (anchor position). Called when profile/options change.
function Insight.ApplyInsightOptions()
    if anchorFrame:IsShown() then
        anchorFrame:ClearAllPoints()
        anchorFrame:SetPoint(GetFixedPoint(), UIParent, GetFixedPoint(), GetFixedX(), GetFixedY())
    end
end

--- Initialize Horizon Insight. Called from InsightModule OnEnable.
function Insight.Init()
    tooltipsToStyle = {
        GameTooltip,
        ItemRefTooltip,
        ShoppingTooltip1,
        ShoppingTooltip2,
        EmbeddedItemTooltip,
    }

    for _, tt in ipairs(tooltipsToStyle) do
        if tt then
            StyleTooltipFull(tt)
            HookTooltipOnShow(tt)
            HookTooltipShowMethod(tt)
        end
    end

    HookGameTooltipAnimation()
    HideHealthBar()
    HookPositioning()

    if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnitTooltip)
    end

    if addon.HSPrint then addon.HSPrint("Horizon Insight loaded. Type /insight or /mtt for options.") end
end

--- Disable Horizon Insight. Restore default tooltip appearance.
function Insight.Disable()
    HideAnchorFrame()
    for _, tt in ipairs(tooltipsToStyle) do
        if tt then
            RestoreNineSlice(tt)
            if tt.SetBackdrop then tt:SetBackdrop(nil) end
        end
    end
end

-- ============================================================================
-- EVENT HANDLER (INSPECT_READY)
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("INSPECT_READY")
eventFrame:SetScript("OnEvent", function(self, event, guid)
    if event == "INSPECT_READY" then
        if not guid then return end
        if UnitExists("mouseover") and UnitGUID("mouseover") == guid then
            CacheInspect(guid, "mouseover")
            ProcessUnitTooltip()
        end
        PruneCache()
    end
end)

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_HORIZONSUITEINSIGHT1 = "/insight"
SLASH_HORIZONSUITEINSIGHT2 = "/hsi"
SLASH_HORIZONSUITEINSIGHT3 = "/mtt"

SlashCmdList["HORIZONSUITEINSIGHT"] = function(msg)
    if not addon:IsModuleEnabled("insight") then
        if addon.HSPrint then addon.HSPrint("Horizon Insight is disabled. Enable it in Horizon Suite options.") end
        return
    end

    local cmd = (msg or ""):lower():trim()

    if cmd == "anchor" then
        local mode = GetAnchorMode()
        if mode == "cursor" then
            addon.SetDB("insightAnchorMode", "fixed")
            if addon.HSPrint then addon.HSPrint("Horizon Insight: Anchor → FIXED (" .. GetFixedPoint() .. ")") end
        else
            addon.SetDB("insightAnchorMode", "cursor")
            if addon.HSPrint then addon.HSPrint("Horizon Insight: Anchor → CURSOR") end
        end

    elseif cmd == "move" then
        if anchorFrame:IsShown() then
            HideAnchorFrame()
            if addon.HSPrint then addon.HSPrint("Horizon Insight: Anchor hidden. Position saved.") end
        else
            ShowAnchorFrame()
        end

    elseif cmd == "resetpos" then
        addon.SetDB("insightFixedPoint", FIXED_POINT)
        addon.SetDB("insightFixedX", FIXED_X)
        addon.SetDB("insightFixedY", FIXED_Y)
        HideAnchorFrame()
        if addon.HSPrint then addon.HSPrint("Horizon Insight: Fixed position reset to default.") end

    elseif cmd == "test" then
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        GameTooltip:ClearLines()
        -- Name: faction icon + class colour
        GameTooltip:AddLine((FACTION_ICONS["Alliance"] or "") .. "Testplayer-Stormrage", 0.77, 0.12, 0.23)
        -- Guild
        GameTooltip:AddLine("<Ascension>", 0.25, 0.78, 0.92)
        -- Level + Race (no class — Blizzard combines class on its own line)
        GameTooltip:AddLine("Level 80 Human", 1, 0.82, 0)
        -- Class line with spec icon prepended (class colour)
        GameTooltip:AddLine(
            "|TInterface\\Icons\\spell_deathknight_bloodpresence:14:14:0:0|t Blood Death Knight",
            0.77, 0.12, 0.23)
        -- PvP title
        GameTooltip:AddLine("Duelist Testplayer", TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
        -- Status badges
        GameTooltip:AddLine("|cffff4444[Combat]|r  |cffffff55[AFK]|r", 1, 1, 1)
        -- Item level
        GameTooltip:AddLine("Item Level: 639", ILVL_COLOR[1], ILVL_COLOR[2], ILVL_COLOR[3])
        -- Mount
        GameTooltip:AddLine(
            "|TInterface\\Icons\\ability_mount_drake_proto:14:14:0:0|t Reins of the Thundering Cobalt Cloud Serpent",
            MOUNT_COLOR[1], MOUNT_COLOR[2], MOUNT_COLOR[3])
        GameTooltip:AddLine("Drop: Sha of Anger", MOUNT_SRC_COLOR[1], MOUNT_SRC_COLOR[2], MOUNT_SRC_COLOR[3])
        GameTooltip:AddLine("|cffff5555You don't own this mount|r", 1, 1, 1)
        GameTooltip:Show()
        if addon.HSPrint then addon.HSPrint("Horizon Insight: Test tooltip shown at cursor.") end

    elseif cmd == "status" then
        local cacheCount = 0
        for _ in pairs(inspectCache) do cacheCount = cacheCount + 1 end
        if addon.HSPrint then
            addon.HSPrint("Horizon Insight Status")
            addon.HSPrint("   Enabled : Yes")
            addon.HSPrint("   Anchor  : " .. GetAnchorMode())
            addon.HSPrint("   Cache   : " .. cacheCount .. " inspect entries")
        end

    else
        if addon.HSPrint then
            addon.HSPrint("Horizon Insight")
            addon.HSPrint("  /insight           This help")
            addon.HSPrint("  /insight anchor   Toggle cursor / fixed positioning")
            addon.HSPrint("  /insight move     Show draggable anchor to set fixed position")
            addon.HSPrint("  /insight resetpos Reset fixed position to default")
            addon.HSPrint("  /insight test     Show a sample styled tooltip")
            addon.HSPrint("  /insight status   Print current config")
        end
    end
end

addon.Insight = Insight
