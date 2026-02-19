--[[
    Horizon Suite - Focus - Entry Pool
    Quest entry frames, section headers, ApplyTypography, ApplyDimensions.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- ENTRY POOL
-- ============================================================================

local pool      = {}
local activeMap = {}

local function CreateQuestEntry(parent, index)
    local e = CreateFrame("Frame", nil, parent)
    local w = addon.GetPanelWidth() - addon.PADDING * 2
    local textW = w - (addon.CONTENT_RIGHT_PADDING or 0)
    e:SetSize(w, 20)

    -- Active-quest bar (left or right; position set in Layout)
    e.trackBar = e:CreateTexture(nil, "OVERLAY")
    e.trackBar:SetColorTexture(0.45, 0.75, 1.00, 0.70)
    e.trackBar:Hide()

    -- Highlight inset
    local highlightInset = 5
    e.highlightBg = e:CreateTexture(nil, "BACKGROUND")
    e.highlightBg:SetPoint("TOPLEFT", e, "TOPLEFT", highlightInset, -highlightInset)
    e.highlightBg:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -highlightInset, highlightInset)
    e.highlightBg:SetColorTexture(0.2, 0.4, 0.6, 0.25)
    e.highlightBg:Hide()
    -- Top strip
    e.highlightTop = e:CreateTexture(nil, "BACKGROUND")
    e.highlightTop:SetHeight(2)
    e.highlightTop:SetPoint("TOPLEFT", e, "TOPLEFT", highlightInset, -highlightInset)
    e.highlightTop:SetPoint("TOPRIGHT", e, "TOPRIGHT", -highlightInset, 0)
    e.highlightTop:SetColorTexture(0.35, 0.55, 0.85, 0.4)
    e.highlightTop:Hide()
    -- 1px highlight border
    local borderW = 1
    e.highlightBorderT = e:CreateTexture(nil, "BORDER")
    e.highlightBorderT:SetHeight(borderW)
    e.highlightBorderT:SetPoint("TOPLEFT", e, "TOPLEFT", highlightInset, -highlightInset)
    e.highlightBorderT:SetPoint("TOPRIGHT", e, "TOPRIGHT", -highlightInset, 0)
    e.highlightBorderT:SetColorTexture(0.40, 0.70, 1.00, 0.6)
    e.highlightBorderT:Hide()
    e.highlightBorderB = e:CreateTexture(nil, "BORDER")
    e.highlightBorderB:SetHeight(borderW)
    e.highlightBorderB:SetPoint("BOTTOMLEFT", e, "BOTTOMLEFT", highlightInset, 0)
    e.highlightBorderB:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -highlightInset, highlightInset)
    e.highlightBorderB:SetColorTexture(0.40, 0.70, 1.00, 0.6)
    e.highlightBorderB:Hide()
    e.highlightBorderL = e:CreateTexture(nil, "BORDER")
    e.highlightBorderL:SetWidth(borderW)
    e.highlightBorderL:SetPoint("TOPLEFT", e, "TOPLEFT", highlightInset, -highlightInset)
    e.highlightBorderL:SetPoint("BOTTOMLEFT", e, "BOTTOMLEFT", highlightInset, highlightInset)
    e.highlightBorderL:SetColorTexture(0.40, 0.70, 1.00, 0.6)
    e.highlightBorderL:Hide()
    e.highlightBorderR = e:CreateTexture(nil, "BORDER")
    e.highlightBorderR:SetWidth(borderW)
    e.highlightBorderR:SetPoint("TOPRIGHT", e, "TOPRIGHT", -highlightInset, -highlightInset)
    e.highlightBorderR:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -highlightInset, highlightInset)
    e.highlightBorderR:SetColorTexture(0.40, 0.70, 1.00, 0.6)
    e.highlightBorderR:Hide()

    -- Left of the active-quest bar: icon right edge at (BAR_LEFT_OFFSET + 2) px left of entry (shared for quest type icon and item btn)
    local iconRight = (addon.BAR_LEFT_OFFSET or 12) + 2

    local btnName = "HSItemBtn" .. index
    e.itemBtn = CreateFrame("Button", btnName, e, "SecureActionButtonTemplate")
    e.itemBtn:SetSize(addon.ITEM_BTN_SIZE, addon.ITEM_BTN_SIZE)
    e.itemBtn:SetPoint("TOPRIGHT", e, "TOPLEFT", -(iconRight + addon.QUEST_TYPE_ICON_SIZE + 4), 2)
    e.itemBtn:SetAttribute("type", "item")
    e.itemBtn:RegisterForClicks("AnyDown")

    addon.StyleQuestItemButton(e.itemBtn)

    e.itemBtn.icon = e.itemBtn:CreateTexture(nil, "ARTWORK")
    e.itemBtn.icon:SetAllPoints()
    e.itemBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    e.itemBtn.cooldown = CreateFrame("Cooldown", btnName .. "CD", e.itemBtn, "CooldownFrameTemplate")
    e.itemBtn.cooldown:SetAllPoints()

    e.itemBtn:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        local entry = self:GetParent()
        if entry.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetHyperlink, GameTooltip, entry.itemLink)
            GameTooltip:Show()
        end
    end)
    e.itemBtn:SetScript("OnLeave", function(self)
        self:SetAlpha(0.9)
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)
    e.itemBtn:SetAlpha(0.9)

    e.itemBtn:Hide()

    e.questTypeIcon = e:CreateTexture(nil, "ARTWORK")
    e.questTypeIcon:SetSize(addon.QUEST_TYPE_ICON_SIZE, addon.QUEST_TYPE_ICON_SIZE)
    e.questTypeIcon:SetPoint("TOPRIGHT", e, "TOPLEFT", -iconRight, 0)
    e.questTypeIcon:Hide()

    -- Small icon for "tracked from other zone" (world quest on watch list but not on current map).
    local iconSz = addon.TRACKED_OTHER_ZONE_ICON_SIZE or 12
    e.trackedFromOtherZoneIcon = e:CreateTexture(nil, "ARTWORK")
    e.trackedFromOtherZoneIcon:SetSize(iconSz, iconSz)
    e.trackedFromOtherZoneIcon:SetPoint("TOPLEFT", e, "TOPLEFT", 0, 0)
    e.trackedFromOtherZoneIcon:Hide()

    e.titleShadow = e:CreateFontString(nil, "BORDER")
    e.titleShadow:SetFontObject(addon.TitleFont)
    e.titleShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
    e.titleShadow:SetJustifyH("LEFT")
    e.titleShadow:SetWordWrap(true)
    e.titleShadow:SetWidth(textW)

    e.titleText = e:CreateFontString(nil, "OVERLAY")
    e.titleText:SetFontObject(addon.TitleFont)
    e.titleText:SetTextColor(1, 1, 1, 1)
    e.titleText:SetJustifyH("LEFT")
    e.titleText:SetWordWrap(true)
    e.titleText:SetWidth(textW)
    e.titleText:SetPoint("TOPLEFT", e, "TOPLEFT", 0, 0)
    e.titleShadow:SetPoint("CENTER", e.titleText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

    e.zoneShadow = e:CreateFontString(nil, "BORDER")
    e.zoneShadow:SetFontObject(addon.ZoneFont)
    e.zoneShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
    e.zoneShadow:SetJustifyH("LEFT")

    e.zoneText = e:CreateFontString(nil, "OVERLAY")
    e.zoneText:SetFontObject(addon.ZoneFont)
    e.zoneText:SetTextColor(addon.ZONE_COLOR[1], addon.ZONE_COLOR[2], addon.ZONE_COLOR[3], 1)
    e.zoneText:SetJustifyH("LEFT")
    e.zoneShadow:SetPoint("CENTER", e.zoneText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)
    e.zoneText:Hide()
    e.zoneShadow:Hide()

    e.objectives = {}
    for j = 1, addon.MAX_OBJECTIVES do
        local objShadow = e:CreateFontString(nil, "BORDER")
        objShadow:SetFontObject(addon.ObjFont)
        objShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
        objShadow:SetJustifyH("LEFT")
        objShadow:SetWordWrap(true)
        objShadow:SetWidth(textW - addon.OBJ_INDENT)

        local objText = e:CreateFontString(nil, "OVERLAY")
        objText:SetFontObject(addon.ObjFont)
        objText:SetTextColor(addon.OBJ_COLOR[1], addon.OBJ_COLOR[2], addon.OBJ_COLOR[3], 1)
        objText:SetJustifyH("LEFT")
        objText:SetWordWrap(true)
        objText:SetWidth(textW - addon.OBJ_INDENT)

        objShadow:SetPoint("CENTER", objText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

        local tickTex = e:CreateTexture(nil, "OVERLAY")
        tickTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        tickTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        tickTex:Hide()

        e.objectives[j] = { text = objText, shadow = objShadow, tick = tickTex }
        objText:Hide()
        objShadow:Hide()
    end

    e.wqTimerText = e:CreateFontString(nil, "OVERLAY")
    e.wqTimerText:SetFontObject(addon.ObjFont)
    e.wqTimerText:SetTextColor(1, 1, 1, 1)
    e.wqTimerText:SetJustifyH("LEFT")
    e.wqTimerText:Hide()

    e.wqProgressBg = e:CreateTexture(nil, "BACKGROUND")
    e.wqProgressBg:SetHeight(addon.WQ_TIMER_BAR_HEIGHT or 6)
    e.wqProgressBg:SetColorTexture(0.2, 0.2, 0.25, 0.8)
    e.wqProgressBg:Hide()

    e.wqProgressFill = e:CreateTexture(nil, "ARTWORK")
    e.wqProgressFill:SetHeight(addon.WQ_TIMER_BAR_HEIGHT or 6)
    e.wqProgressFill:SetColorTexture(0.45, 0.35, 0.65, 0.9)
    e.wqProgressFill:Hide()

    e.wqProgressText = e:CreateFontString(nil, "OVERLAY")
    e.wqProgressText:SetFontObject(addon.ObjFont)
    e.wqProgressText:SetTextColor(0.9, 0.9, 0.9, 1)
    e.wqProgressText:SetJustifyH("CENTER")
    e.wqProgressText:Hide()

    -- Per-criteria scenario timer bars (KT-aligned; 1s tick driven).
    local slots = addon.SCENARIO_TIMER_BAR_SLOTS or 5
    e.scenarioTimerBars = {}
    for si = 1, slots do
        local bar = CreateFrame("Frame", nil, e)
        bar:SetHeight(addon.WQ_TIMER_BAR_HEIGHT or 6)
        bar.Bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.Bg:SetAllPoints()
        bar.Bg:SetColorTexture(0.08, 0.06, 0.12, 0.5)
        bar.Fill = bar:CreateTexture(nil, "ARTWORK")
        bar.Fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        bar.Fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        bar.Fill:SetColorTexture(0.45, 0.32, 0.75, 0.88)
        bar.Label = bar:CreateFontString(nil, "OVERLAY")
        bar.Label:SetFontObject(addon.ObjFont)
        bar.Label:SetPoint("CENTER", bar, "CENTER", 0, 0)
        bar.Label:SetJustifyH("CENTER")
        bar.duration = nil
        bar.startTime = nil
        bar._expiredAt = nil
        bar:Hide()
        e.scenarioTimerBars[si] = bar
    end

    e.flash = e:CreateTexture(nil, "OVERLAY")
    e.flash:SetAllPoints(e)
    e.flash:SetColorTexture(1, 1, 1, 0)

    e.animState      = "idle"
    e.animTime       = 0
    e.entryHeight    = 0
    e.questID        = nil
    e.flashTime      = 0
    e.finalX         = 0
    e.finalY         = 0
    e.staggerDelay   = 0
    e.collapseDelay  = 0
    e.groupKey       = nil

    e:SetAlpha(0)
    e:Hide()
    return e
end

local scrollChild = addon.scrollChild
for i = 1, addon.POOL_SIZE do
    pool[i] = CreateQuestEntry(scrollChild, i)
end

local function UpdateScenarioBar(bar, now)
    local d, s = bar.duration, bar.startTime
    if not d or not s then return end
    local remaining = d - (now - s)
    -- Hold at 0 for 1s then trigger refresh and stop (KT-aligned).
    if remaining < 0 then
        if not bar._expiredAt then bar._expiredAt = now end
        if (now - bar._expiredAt) > 1 then
            bar.duration = nil
            bar.startTime = nil
            bar._expiredAt = nil
            if addon.ScheduleRefresh then addon.ScheduleRefresh() end
            return
        end
        remaining = 0
    else
        bar._expiredAt = nil
    end
    local pct = (d > 0) and (remaining / d) or 0
    local w = bar:GetWidth() or 1
    bar.Fill:SetWidth(math.max(2, w * pct))
    local m = math.floor(remaining / 60)
    local sec = math.floor(remaining % 60)
    bar.Label:SetText(("%02d:%02d"):format(m, sec))
    -- Percentage-based color (KT: 66% white, 33% yellow, below red).
    local pctLeft = (d > 0) and pct or 0
    local r, g, b
    if pctLeft > 0.66 then
        local sc = addon.GetQuestColor and addon.GetQuestColor("SCENARIO") or (addon.QUEST_COLORS and addon.QUEST_COLORS.SCENARIO) or { 0.55, 0.35, 0.85 }
        r, g, b = sc[1], sc[2], sc[3]
    elseif pctLeft > 0.33 then
        local blueOffset = (pctLeft - 0.33) / 0.33
        r, g, b = 1, 1, blueOffset
    else
        local greenOffset = pctLeft / 0.33
        r, g, b = 1, greenOffset, 0
    end
    bar.Label:SetTextColor(r, g, b, 1)
end

function addon.UpdateScenarioTimerBars()
    if not addon.focus.enabled or not addon.pool then return end
    local now = GetTime()
    for i = 1, addon.POOL_SIZE do
        local entry = pool[i]
        if entry.scenarioTimerBars then
            for _, bar in ipairs(entry.scenarioTimerBars) do
                if bar.duration and bar.startTime then
                    UpdateScenarioBar(bar, now)
                end
            end
        end
    end
end

local sectionPool = {}

local function CreateSectionHeader(parent)
    local s = CreateFrame("Button", nil, parent)
    s:SetSize(addon.GetPanelWidth() - addon.PADDING * 2, addon.SECTION_SIZE + 4)

    s:RegisterForClicks("LeftButtonUp")

    s.shadow = s:CreateFontString(nil, "BORDER")
    s.shadow:SetFontObject(addon.SectionFont)
    s.shadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
    s.shadow:SetJustifyH("LEFT")

    s.text = s:CreateFontString(nil, "OVERLAY")
    s.text:SetFontObject(addon.SectionFont)
    s.text:SetJustifyH("LEFT")
    s.text:SetPoint("BOTTOMLEFT", s, "BOTTOMLEFT", 10, 0)
    s.shadow:SetPoint("CENTER", s.text, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

    -- Small chevron indicating expanded/collapsed state for this category.
    s.chevron = s:CreateFontString(nil, "OVERLAY")
    s.chevron:SetFont(addon.FONT_PATH, addon.SECTION_SIZE, "OUTLINE")
    s.chevron:SetJustifyH("LEFT")
    s.chevron:SetPoint("BOTTOMLEFT", s, "BOTTOMLEFT", 0, 0)
    s.chevron:SetText("")

    s.active = false
    s:SetAlpha(0)
    s:Hide()
    return s
end

for i = 1, addon.SECTION_POOL_SIZE do
    sectionPool[i] = CreateSectionHeader(scrollChild)
end

local function UpdateFontObjectsFromDB()
    local fontPath   = addon.GetDB("fontPath", addon.GetDefaultFontPath())
    local outline    = addon.GetDB("fontOutline", "OUTLINE")
    local headerSz   = tonumber(addon.GetDB("headerFontSize", 16)) or 16
    local titleSz    = tonumber(addon.GetDB("titleFontSize", 13)) or 13
    local objSz      = tonumber(addon.GetDB("objectiveFontSize", 11)) or 11
    local zoneSz     = tonumber(addon.GetDB("zoneFontSize", 10)) or 10
    local sectionSz  = tonumber(addon.GetDB("sectionFontSize", 10)) or 10

    addon.HeaderFont:SetFont(fontPath, headerSz, outline)
    addon.TitleFont:SetFont(fontPath, titleSz, outline)
    addon.ObjFont:SetFont(fontPath, objSz, outline)
    addon.ZoneFont:SetFont(fontPath, zoneSz, outline)
    addon.SectionFont:SetFont(fontPath, sectionSz, outline)
end

local function ApplyTypography()
    UpdateFontObjectsFromDB()

    local shadowOx = tonumber(addon.GetDB("shadowOffsetX", 2)) or 2
    local shadowOy = tonumber(addon.GetDB("shadowOffsetY", -2)) or -2
    local shadowA  = addon.GetDB("showTextShadow", true) and (tonumber(addon.GetDB("shadowAlpha", 0.8)) or 0.8) or 0

    addon.headerShadow:SetTextColor(0, 0, 0, shadowA)
    addon.headerShadow:SetPoint("CENTER", addon.headerText, "CENTER", shadowOx, shadowOy)

    local headerC = addon.GetHeaderColor()
    addon.headerText:SetTextColor(headerC[1], headerC[2], headerC[3], 1)

    addon.countShadow:SetTextColor(0, 0, 0, shadowA)
    addon.countShadow:SetPoint("CENTER", addon.countText, "CENTER", shadowOx, shadowOy)

    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        e.titleShadow:SetTextColor(0, 0, 0, shadowA)
        e.titleShadow:SetPoint("CENTER", e.titleText, "CENTER", shadowOx, shadowOy)
        e.zoneShadow:SetTextColor(0, 0, 0, shadowA)
        e.zoneShadow:SetPoint("CENTER", e.zoneText, "CENTER", shadowOx, shadowOy)
        for j = 1, addon.MAX_OBJECTIVES do
            local obj = e.objectives[j]
            obj.shadow:SetTextColor(0, 0, 0, shadowA)
            obj.shadow:SetPoint("CENTER", obj.text, "CENTER", shadowOx, shadowOy)
        end
    end

    for i = 1, addon.SECTION_POOL_SIZE do
        local s = sectionPool[i]
        s.shadow:SetTextColor(0, 0, 0, shadowA)
        s.shadow:SetPoint("CENTER", s.text, "CENTER", shadowOx, shadowOy)
    end
end

local function ApplyDimensions(widthOverride)
    if InCombatLockdown() then
        addon.focus.pendingDimensionsAfterCombat = true
        return
    end
    addon.focus.pendingDimensionsAfterCombat = false
    local w = (widthOverride and type(widthOverride) == "number") and widthOverride or addon.GetPanelWidth()
    addon.HS:SetSize(w, addon.HS:GetHeight() or addon.MIN_HEIGHT)
    addon.divider:SetSize(w - addon.PADDING * 2, addon.DIVIDER_HEIGHT)
    addon.divider:SetPoint("TOP", addon.HS, "TOPLEFT", w / 2, -(addon.PADDING + addon.GetHeaderHeight()))
    addon.scrollChild:SetWidth(w)
    local leftOffset = addon.GetContentLeftOffset and addon.GetContentLeftOffset() or (addon.PADDING + addon.ICON_COLUMN_WIDTH)
    for i = 1, addon.POOL_SIZE do
        local e = pool[i]
        local contentW = w - addon.PADDING - leftOffset
        local textW = contentW - (addon.CONTENT_RIGHT_PADDING or 0)
        e:SetSize(contentW, 20)
        e.titleShadow:SetWidth(textW)
        e.titleText:SetWidth(textW)
        for j = 1, addon.MAX_OBJECTIVES do
            local obj = e.objectives[j]
            local objIndent = addon.GetObjIndent and addon.GetObjIndent() or addon.OBJ_INDENT
            obj.shadow:SetWidth(textW - objIndent)
            obj.text:SetWidth(textW - objIndent)
        end
    end
    for i = 1, addon.SECTION_POOL_SIZE do
        sectionPool[i]:SetSize(w - addon.PADDING - leftOffset, addon.SECTION_SIZE + 4)
    end
end

local function ClearEntry(entry, full)
    if not entry then return end
    entry.questID    = nil
    entry.entryKey   = nil
    entry.creatureID = nil
    entry.achievementID = nil
    entry.endeavorID = nil
    entry.decorID    = nil
    entry.itemLink   = nil
    entry.animState  = "idle"
    entry.groupKey   = nil
    if full ~= false then
        entry:Hide()
        entry:SetAlpha(0)
        entry:SetHitRectInsets(0, 0, 0, 0)
        if entry.itemBtn then entry.itemBtn:Hide() end
        if entry.trackBar then entry.trackBar:Hide() end
        if entry.wqTimerText then entry.wqTimerText:Hide() end
        if entry.wqProgressBg then entry.wqProgressBg:Hide() end
        if entry.wqProgressFill then entry.wqProgressFill:Hide() end
        if entry.wqProgressText then entry.wqProgressText:Hide() end
        if entry.scenarioTimerBars then
            for _, bar in ipairs(entry.scenarioTimerBars) do
                bar.duration = nil
                bar.startTime = nil
                bar._expiredAt = nil
                bar:Hide()
            end
        end
    end
end

addon.pool                   = pool
addon.activeMap             = activeMap
addon.sectionPool           = sectionPool
addon.ClearEntry            = ClearEntry
addon.ApplyTypography       = ApplyTypography
addon.UpdateFontObjectsFromDB = UpdateFontObjectsFromDB
addon.ApplyDimensions       = ApplyDimensions
