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

local FACTION_COLORS = {
    Alliance = { 0.00, 0.44, 0.87 },   -- alliance blue
    Horde    = { 0.87, 0.17, 0.17 },   -- horde red
}

local SPEC_COLOR      = { 0.65, 0.75, 0.85 }
local MOUNT_COLOR     = { 0.80, 0.65, 1.00 }   -- soft purple for mount name
local MOUNT_SRC_COLOR = { 0.55, 0.55, 0.55 }   -- grey for source text
local ILVL_COLOR      = { 0.60, 0.85, 1.00 }   -- ice blue for item level
local TITLE_COLOR     = { 1.00, 0.82, 0.00 }   -- gold for PvP title
local TRANSMOG_HAVE   = { 0.40, 1.00, 0.55 }   -- green: appearance collected
local TRANSMOG_MISS   = { 0.65, 0.65, 0.65 }   -- grey: not collected

local ROLE_COLORS = {
    TANK    = { 0.30, 0.60, 1.00 },   -- blue
    HEALER  = { 0.30, 1.00, 0.40 },   -- green
    DAMAGER = { 1.00, 0.55, 0.20 },   -- orange
}

local MYTHIC_ICON = "|TInterface\\Icons\\achievement_challengemode_gold:14:14:0:0|t "
local SEPARATOR   = string.rep("-", 22)
local SEP_COLOR   = { 0.18, 0.18, 0.18 }

-- Returns r, g, b for a Mythic+ score using WoW's tier thresholds.
local function MythicScoreColor(score)
    if score >= 3000 then return 1.00, 0.50, 0.00  -- orange: Mythic Hero+
    elseif score >= 2500 then return 0.85, 0.40, 1.00  -- purple: Mythic
    elseif score >= 2000 then return 0.20, 0.75, 1.00  -- blue: Heroic
    elseif score >= 1500 then return 0.40, 1.00, 0.40  -- green: Normal
    else                       return 0.65, 0.65, 0.65  -- grey: unranked
    end
end

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

local function ShowMount()        return addon.GetDB("insightShowMount",        true)  end
local function ShowIlvl()         return addon.GetDB("insightShowIlvl",         true)  end
local function ShowPvPTitle()     return addon.GetDB("insightShowPvPTitle",     true)  end
local function ShowStatusBadges() return addon.GetDB("insightShowStatusBadges", true)  end
local function ShowMythicScore()  return addon.GetDB("insightShowMythicScore",  true)  end
local function ShowTransmog()     return addon.GetDB("insightShowTransmog",     true)  end
local function ShowGuildRank()    return addon.GetDB("insightShowGuildRank",    true)  end
local function ShowHonorLevel()   return addon.GetDB("insightShowHonorLevel",   true)  end

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
        if Insight.accentBar then Insight.accentBar:Hide() end
    end)
    GameTooltip:HookScript("OnHide", function(self)
        fadeState = "idle"
        animFrame:Hide()
        self:SetAlpha(1)
        if Insight.accentBar then Insight.accentBar:Hide() end
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

    -- Non-player: reaction-coloured name, plain border, no accent bar
    if not isPlayer then
        GameTooltip:SetBackdropBorderColor(PANEL_BORDER[1], PANEL_BORDER[2], PANEL_BORDER[3], PANEL_BORDER[4])
        if Insight.accentBar then Insight.accentBar:Hide() end
        local nameLeft = _G["GameTooltipTextLeft1"]
        if nameLeft then
            local reaction = UnitReaction(unit, "player")
            if reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction] then
                local c = FACTION_BAR_COLORS[reaction]
                nameLeft:SetTextColor(c.r, c.g, c.b)
            end
        end
        StyleFonts(GameTooltip)
        return
    end

    local className, classFile, classColor, guildName, guildRankName
    pcall(function()
        className, classFile = UnitClass(unit)
        classColor = classFile and C_ClassColor and C_ClassColor.GetClassColor(classFile)
        guildName, guildRankName = GetGuildInfo(unit)
    end)
    local cached = guid and inspectCache[guid]

    -- 1. Name line: faction icon + faction colour
    local nameLeft = _G["GameTooltipTextLeft1"]
    if nameLeft then
        local faction = UnitFactionGroup(unit)
        local icon    = FACTION_ICONS[faction] or ""
        local name    = GetUnitName(unit, true) or nameLeft:GetText() or ""
        nameLeft:SetText(icon .. name)
        local fc = FACTION_COLORS[faction]
        if fc then
            nameLeft:SetTextColor(fc[1], fc[2], fc[3])
        elseif classColor then
            nameLeft:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    end

    -- 2. Border tint + left accent bar
    if classColor then
        GameTooltip:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.60)
        if Insight.accentBar then
            Insight.accentBar:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.85)
            Insight.accentBar:Show()
        end
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

            -- Guild line: append rank name
            elseif guildName and text == "<" .. guildName .. ">" then
                if ShowGuildRank() and guildRankName and guildRankName ~= "" then
                    lineLeft:SetText(text .. "  |cffaaaaaa" .. guildRankName .. "|r")
                end

            -- Style the class line: class colour + spec icon + role badge
            elseif className and text ~= "" and text:find(className, 1, true) then
                if classColor then
                    lineLeft:SetTextColor(classColor.r, classColor.g, classColor.b)
                end
                local iconPrefix = (cached and cached.specIcon)
                    and ("|T" .. cached.specIcon .. ":14:14:0:0|t ") or ""
                local roleSuffix = ""
                if cached and cached.role then
                    local rc = ROLE_COLORS[cached.role]
                    if rc then
                        local hex = string.format("%02x%02x%02x",
                            math.floor(rc[1] * 255),
                            math.floor(rc[2] * 255),
                            math.floor(rc[3] * 255))
                        local label = cached.role == "TANK" and "Tank"
                            or cached.role == "HEALER" and "Healer" or "DPS"
                        roleSuffix = "  |cff" .. hex .. label .. "|r"
                    end
                end
                lineLeft:SetText(iconPrefix .. text .. roleSuffix)
            end
        end
    end

    -- Separator: identity block → PvP/status block
    GameTooltip:AddLine(SEPARATOR, SEP_COLOR[1], SEP_COLOR[2], SEP_COLOR[3])

    -- 4. PvP title + honor level
    -- All string comparisons on unit-API results are wrapped in pcall because
    -- INSPECT_READY taints the "mouseover" token; comparing tainted strings
    -- causes "attempt to compare a secret string value" errors.
    if ShowPvPTitle() then
        pcall(function()
            local pvpFullName = UnitPVPName(unit)
            local baseName    = UnitName(unit)
            if pvpFullName and baseName and pvpFullName ~= baseName then
                GameTooltip:AddLine(pvpFullName, TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
            end
        end)
    end
    if ShowHonorLevel() then
        pcall(function()
            local honorLevel = UnitHonorLevel(unit)
            if honorLevel and honorLevel > 0 then
                GameTooltip:AddLine("Honor Level " .. honorLevel, 0.85, 0.70, 1.00)
            end
        end)
    end

    -- 5. Status badges (combat/AFK/DND + friend/pvp/group/targeting)
    if ShowStatusBadges() then
        local badges = {}
        pcall(function()
            if UnitAffectingCombat(unit) then badges[#badges + 1] = "|cffff4444[Combat]|r"      end
            if UnitIsAFK(unit)           then badges[#badges + 1] = "|cffffff55[AFK]|r"         end
            if UnitIsDND(unit)           then badges[#badges + 1] = "|cffaaaaaa[DND]|r"         end
            if UnitIsPVP(unit)           then badges[#badges + 1] = "|cffff8c00[PvP]|r"         end
            if UnitInRaid(unit)          then badges[#badges + 1] = "|cff88ddff[Raid]|r"
            elseif UnitInParty(unit)     then badges[#badges + 1] = "|cff88ddff[Party]|r"       end
            if C_FriendList and C_FriendList.IsFriend and guid and C_FriendList.IsFriend(guid) then
                                              badges[#badges + 1] = "|cff55ff55[Friend]|r"      end
            -- "mouseoverTarget" comparison is the primary taint source — guard it separately
            local ok, isTargeting = pcall(UnitIsUnit, "mouseoverTarget", "player")
            if ok and isTargeting then
                                              badges[#badges + 1] = "|cffff4466[Targeting You]|r" end
        end)
        if #badges > 0 then
            GameTooltip:AddLine(table.concat(badges, "  "), 1, 1, 1)
        end
    end

    -- Stats block (M+ score, item level) — prefixed with a separator if non-empty
    local hasStats = false
    local function EnsureStatsSep()
        if not hasStats then
            GameTooltip:AddLine(SEPARATOR, SEP_COLOR[1], SEP_COLOR[2], SEP_COLOR[3])
            hasStats = true
        end
    end

    -- 6. Mythic+ score (no inspect needed)
    if ShowMythicScore() and C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
        if summary and summary.currentSeasonScore and summary.currentSeasonScore > 0 then
            local score = summary.currentSeasonScore
            local r, g, b = MythicScoreColor(score)
            EnsureStatsSep()
            GameTooltip:AddLine(MYTHIC_ICON .. "M+ Score: " .. score, r, g, b)
        end
    end

    -- 7. Item level (only once inspect cache is available)
    if cached then
        if ShowIlvl() and cached.ilvl then
            EnsureStatsSep()
            GameTooltip:AddLine("Item Level: " .. cached.ilvl, ILVL_COLOR[1], ILVL_COLOR[2], ILVL_COLOR[3])
        end
        GameTooltip:Show()
    else
        RequestInspect(unit)
    end

    -- 8. Mount block
    if ShowMount() then
        local mount = GetPlayerMountInfo(unit)
        if mount and mount.name then
            local iconStr = mount.icon and ("|T" .. mount.icon .. ":14:14:0:0|t ") or ""
            GameTooltip:AddLine(SEPARATOR, SEP_COLOR[1], SEP_COLOR[2], SEP_COLOR[3])
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

-- ============================================================================
-- ITEM TOOLTIP ENHANCEMENTS
-- ============================================================================

local function OnItemTooltip(tooltip, data)
    if not IsEnabled() then return end
    if not ShowTransmog() then return end
    if not C_TransmogCollection then return end

    local itemID = data and data.id
    if not itemID then return end

    local hasTransmog = C_TransmogCollection.PlayerHasTransmogByItemInfo(itemID)
    if hasTransmog == nil then return end  -- not a transmoggable item

    if hasTransmog then
        tooltip:AddLine("Appearance: Collected", TRANSMOG_HAVE[1], TRANSMOG_HAVE[2], TRANSMOG_HAVE[3])
    else
        tooltip:AddLine("Appearance: Not collected", TRANSMOG_MISS[1], TRANSMOG_MISS[2], TRANSMOG_MISS[3])
    end
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

    -- Class-coloured left accent bar (created once, reused across tooltips)
    if not Insight.accentBar then
        local bar = GameTooltip:CreateTexture(nil, "BORDER")
        bar:SetWidth(3)
        bar:SetPoint("TOPLEFT",    GameTooltip, "TOPLEFT",    0, 0)
        bar:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMLEFT", 0, 0)
        bar:SetColorTexture(0.5, 0.5, 0.5, 0.8)
        bar:Hide()
        Insight.accentBar = bar
    end

    HookGameTooltipAnimation()
    HideHealthBar()
    HookPositioning()

    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        if Enum.TooltipDataType.Unit then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnitTooltip)
        end
        if Enum.TooltipDataType.Item then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
        end
    end

    if addon.HSPrint then addon.HSPrint("Horizon Insight loaded. Type /insight or /mtt for options.") end
end

--- Disable Horizon Insight. Restore default tooltip appearance.
function Insight.Disable()
    HideAnchorFrame()
    if Insight.accentBar then Insight.accentBar:Hide() end
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
        if not IsEnabled() then return end
        if not guid then return end
        if UnitExists("mouseover") and UnitGUID("mouseover") == guid then
            CacheInspect(guid, "mouseover")
            -- Refresh the tooltip from scratch so Blizzard's lines are rebuilt
            -- before we append ours — prevents every AddLine running twice.
            if GameTooltip:IsShown() then
                GameTooltip:SetUnit("mouseover")
            end
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
        -- Name: faction icon + class colour (DK = dark red)
        GameTooltip:AddLine((FACTION_ICONS["Alliance"] or "") .. "Testplayer-Stormrage", 0.77, 0.12, 0.23)
        -- Guild + rank
        GameTooltip:AddLine("<Ascension>  |cffaaaaaaOfficer|r", 0.25, 0.78, 0.92)
        -- Level + Race
        GameTooltip:AddLine("Level 80 Human", 1, 0.82, 0)
        -- Class line: spec icon + role badge (Tank = blue)
        GameTooltip:AddLine(
            "|TInterface\\Icons\\spell_deathknight_bloodpresence:14:14:0:0|t Blood Death Knight  |cff4d99ffTank|r",
            0.77, 0.12, 0.23)
        -- Identity / status separator
        GameTooltip:AddLine(SEPARATOR, SEP_COLOR[1], SEP_COLOR[2], SEP_COLOR[3])
        -- PvP title
        GameTooltip:AddLine("Duelist Testplayer", TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
        -- Honor level
        GameTooltip:AddLine("Honor Level 247", 0.85, 0.70, 1.00)
        -- Status badges
        GameTooltip:AddLine("|cffff4444[Combat]|r  |cffff8c00[PvP]|r  |cff88ddff[Party]|r  |cff55ff55[Friend]|r  |cffff4466[Targeting You]|r", 1, 1, 1)
        -- Stats separator
        GameTooltip:AddLine(SEPARATOR, SEP_COLOR[1], SEP_COLOR[2], SEP_COLOR[3])
        -- M+ score
        GameTooltip:AddLine(MYTHIC_ICON .. "M+ Score: 2847", MythicScoreColor(2847))
        -- Item level
        GameTooltip:AddLine("Item Level: 639", ILVL_COLOR[1], ILVL_COLOR[2], ILVL_COLOR[3])
        -- Mount separator
        GameTooltip:AddLine(SEPARATOR, SEP_COLOR[1], SEP_COLOR[2], SEP_COLOR[3])
        -- Mount
        GameTooltip:AddLine(
            "|TInterface\\Icons\\ability_mount_drake_proto:14:14:0:0|t Reins of the Thundering Cobalt Cloud Serpent",
            MOUNT_COLOR[1], MOUNT_COLOR[2], MOUNT_COLOR[3])
        GameTooltip:AddLine("Drop: Sha of Anger", MOUNT_SRC_COLOR[1], MOUNT_SRC_COLOR[2], MOUNT_SRC_COLOR[3])
        GameTooltip:AddLine("|cffff5555You don't own this mount|r", 1, 1, 1)
        -- Show accent bar + border in DK colour
        GameTooltip:SetBackdropBorderColor(0.77, 0.12, 0.23, 0.60)
        if Insight.accentBar then
            Insight.accentBar:SetColorTexture(0.77, 0.12, 0.23, 0.85)
            Insight.accentBar:Show()
        end
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
