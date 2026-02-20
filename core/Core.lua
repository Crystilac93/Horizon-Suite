--[[
    Horizon Suite - Focus - Core
    DB access, easing, and main frame (HS + scroll, resize, drag, position).
    Constants, colors, fonts, and labels live in Config.lua.
]]

if not _G.HorizonSuite then _G.HorizonSuite = {} end
local addon = _G.HorizonSuite

-- ============================================================================
-- DB AND DIMENSION HELPERS (depend on Config constants)
-- ============================================================================

function addon.GetTitleSpacing()
    if addon.GetDB("compactMode", false) then
        return addon.COMPACT_TITLE_SPACING
    end
    local v = tonumber(addon.GetDB("titleSpacing", addon.TITLE_SPACING)) or addon.TITLE_SPACING
    return math.max(2, math.min(20, v))
end
function addon.GetObjSpacing()
    if addon.GetDB("compactMode", false) then
        return addon.COMPACT_OBJ_SPACING
    end
    local v = tonumber(addon.GetDB("objSpacing", addon.OBJ_SPACING)) or addon.OBJ_SPACING
    return math.max(0, math.min(8, v))
end
function addon.GetSectionSpacing()
    local v = tonumber(addon.GetDB("sectionSpacing", addon.SECTION_SPACING)) or addon.SECTION_SPACING
    return math.max(0, math.min(24, v))
end
function addon.GetSectionToEntryGap()
    local v = tonumber(addon.GetDB("sectionToEntryGap", 6)) or 6
    return math.max(0, math.min(16, v))
end
function addon.GetObjIndent()
    return addon.GetDB("compactMode", false) and addon.COMPACT_OBJ_INDENT or addon.OBJ_INDENT
end

function addon.GetPanelWidth()
    return tonumber(addon.GetDB("panelWidth", addon.PANEL_WIDTH)) or addon.PANEL_WIDTH
end
function addon.GetMaxContentHeight()
    return tonumber(addon.GetDB("maxContentHeight", addon.MAX_CONTENT_HEIGHT)) or addon.MAX_CONTENT_HEIGHT
end

--- Returns the header text color from DB or default.
--- @return table {r,g,b}
function addon.GetHeaderColor()
    local c = addon.GetDB("headerColor", nil)
    if c and type(c) == "table" and c[1] and c[2] and c[3] then
        return c
    end
    return addon.HEADER_COLOR
end

--- Returns the header bar height from DB or default, clamped to 18–48 px.
--- @return number
function addon.GetHeaderHeight()
    local v = tonumber(addon.GetDB("headerHeight", addon.HEADER_HEIGHT)) or addon.HEADER_HEIGHT
    return math.max(18, math.min(48, v))
end

function addon.GetContentLeftOffset()
    -- Left gutter contains (optional) quest-type icon and (optional) quest item button.
    -- When quest-type icons are off, don't reserve ICON_COLUMN_WIDTH, so the list sits tighter.
    local showQuestIcons = addon.GetDB("showQuestTypeIcons", false)
    local base = addon.PADDING + (showQuestIcons and addon.ICON_COLUMN_WIDTH or 0)

    if addon.GetDB("showQuestItemButtons", false) then
        -- Ensure enough space for the supertrack bar + (optional) quest-type icon + item button.
        local iconRight = (addon.BAR_LEFT_OFFSET or 12) + 2
        local iconWidth = (showQuestIcons and addon.QUEST_TYPE_ICON_SIZE + 4) or 0
        local minLeft = iconRight + iconWidth + addon.ITEM_BTN_SIZE
        return math.max(addon.PADDING, base, minLeft)
    end
    return math.max(addon.PADDING, base)
end

function addon.GetDB(key, default)
    if not HorizonDB then return default end
    local v = HorizonDB[key]
    if v == nil then return default end
    return v
end

function addon.SetDB(key, value)
    addon.EnsureDB()
    HorizonDB[key] = value
end

function addon.ShouldHideInCombat()
    return addon.GetDB("hideInCombat", false) and UnitAffectingCombat("player")
end

function addon.EnsureDB()
    if not HorizonDB then HorizonDB = {} end
    if addon.EnsureModulesDB then addon:EnsureModulesDB() end
end

-- Persisted Focus category order (validated, fallback to addon.GROUP_ORDER).
function addon.GetGroupOrder()
    local default = addon.GROUP_ORDER
    local saved = addon.GetDB("groupOrder", nil)
    if not saved or type(saved) ~= "table" or #saved == 0 then
        return default
    end
    local seen = {}
    local result = {}
    for _, key in ipairs(default) do
        seen[key] = true
    end
    for _, key in ipairs(saved) do
        if type(key) == "string" and seen[key] then
            result[#result + 1] = key
            seen[key] = nil
        end
    end
    for _, key in ipairs(default) do
        if seen[key] then
            result[#result + 1] = key
        end
    end
    return result
end

function addon.SetGroupOrder(order)
    if not order or type(order) ~= "table" then return end
    addon.EnsureDB()
    local default = addon.GROUP_ORDER
    local seen = {}
    for _, key in ipairs(default) do
        seen[key] = true
    end
    local result = {}
    for _, key in ipairs(order) do
        if type(key) == "string" and seen[key] then
            result[#result + 1] = key
            seen[key] = nil
        end
    end
    for _, key in ipairs(default) do
        if seen[key] then
            result[#result + 1] = key
        end
    end
    HorizonDB.groupOrder = result
end

-- Per-category collapse state ------------------------------------------------

local function EnsureCollapsedCategories()
    addon.EnsureDB()
    if not HorizonDB.collapsedCategories then
        HorizonDB.collapsedCategories = {}
    end
    return HorizonDB.collapsedCategories
end

function addon.IsCategoryCollapsed(groupKey)
    if not HorizonDB or not HorizonDB.collapsedCategories then
        return false
    end
    return HorizonDB.collapsedCategories[groupKey] == true
end

function addon.SetCategoryCollapsed(groupKey, collapsed)
    if not groupKey then return end
    local tbl = EnsureCollapsedCategories()
    if collapsed then
        tbl[groupKey] = true
    else
        -- Missing/nil means expanded by default.
        tbl[groupKey] = nil
    end
end

function addon.ToggleCategoryCollapsed(groupKey)
    if not groupKey then return false end
    local newState = not addon.IsCategoryCollapsed(groupKey)
    addon.SetCategoryCollapsed(groupKey, newState)
    return newState
end

-- ============================================================================
-- EASING FUNCTIONS
-- ============================================================================

function addon.easeOut(t)  return 1 - (1 - t) * (1 - t) end
function addon.easeIn(t)   return t * t end

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

local HS = CreateFrame("Frame", "HSFrame", UIParent)
HS:SetSize(addon.GetPanelWidth(), addon.MIN_HEIGHT)
HS:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", addon.PANEL_X, addon.PANEL_Y)
HS:SetFrameStrata("MEDIUM")
HS:SetClampedToScreen(true)
HS:Hide()

local hsBg = HS:CreateTexture(nil, "BACKGROUND")
hsBg:SetAllPoints(HS)
local backdropColor = (addon.Design and addon.Design.BACKDROP_COLOR) or { 0.08, 0.08, 0.12, 0.90 }
hsBg:SetColorTexture(backdropColor[1], backdropColor[2], backdropColor[3], backdropColor[4] or 1)
addon.hsBg = hsBg

local borderColor = (addon.Design and addon.Design.BORDER_COLOR) or nil
local hsBorderT, hsBorderB, hsBorderL, hsBorderR = addon.CreateBorder(HS, borderColor)
addon.hsBorderT, addon.hsBorderB = hsBorderT, hsBorderB
addon.hsBorderL, addon.hsBorderR = hsBorderL, hsBorderR

function addon.ApplyBackdropOpacity()
    if not addon.hsBg then return end
    local a = tonumber(addon.GetDB("backdropOpacity", 0)) or 0
    local base = (addon.Design and addon.Design.BACKDROP_COLOR) or { 0.08, 0.08, 0.12, 0.90 }
    addon.hsBg:SetColorTexture(base[1], base[2], base[3], math.max(0, math.min(1, a)))
end

function addon.ApplyBorderVisibility()
    local show = addon.GetDB("showBorder", false)
    if addon.hsBorderT then addon.hsBorderT:SetShown(show) end
    if addon.hsBorderB then addon.hsBorderB:SetShown(show) end
    if addon.hsBorderL then addon.hsBorderL:SetShown(show) end
    if addon.hsBorderR then addon.hsBorderR:SetShown(show) end
end

local headerShadow = HS:CreateFontString(nil, "BORDER")
headerShadow:SetFontObject(addon.HeaderFont)
headerShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
headerShadow:SetJustifyH("LEFT")
headerShadow:SetText(addon.L["OBJECTIVES"])

local headerText = HS:CreateFontString(nil, "OVERLAY")
headerText:SetFontObject(addon.HeaderFont)
do
    local c = addon.GetHeaderColor()
    headerText:SetTextColor(c[1], c[2], c[3], 1)
end
headerText:SetJustifyH("LEFT")
headerText:SetPoint("TOPLEFT", HS, "TOPLEFT", addon.PADDING, -addon.PADDING)
headerText:SetText(addon.L["OBJECTIVES"])
headerShadow:SetPoint("CENTER", headerText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

local countText = HS:CreateFontString(nil, "OVERLAY")
countText:SetFontObject(addon.ObjFont)
countText:SetTextColor(0.60, 0.65, 0.75, 1)
countText:SetJustifyH("RIGHT")
countText:SetPoint("TOPRIGHT", HS, "TOPRIGHT", -addon.PADDING, -addon.PADDING - 3)

local countShadow = HS:CreateFontString(nil, "BORDER")
countShadow:SetFontObject(addon.ObjFont)
countShadow:SetTextColor(0, 0, 0, addon.SHADOW_A)
countShadow:SetJustifyH("RIGHT")
countShadow:SetPoint("CENTER", countText, "CENTER", addon.SHADOW_OX, addon.SHADOW_OY)

local chevron = HS:CreateFontString(nil, "OVERLAY")
chevron:SetFontObject(addon.ObjFont)
chevron:SetTextColor(0.60, 0.65, 0.75, 1)
chevron:SetJustifyH("RIGHT")
chevron:SetPoint("RIGHT", countText, "LEFT", -6, 0)
chevron:SetText("-")

local optionsBtn = CreateFrame("Button", nil, HS)
local optionsLabel = optionsBtn:CreateFontString(nil, "OVERLAY")
optionsLabel:SetFontObject(addon.ObjFont)
optionsLabel:SetTextColor(0.60, 0.65, 0.75, 1)
optionsLabel:SetJustifyH("RIGHT")
optionsLabel:SetText(addon.L["Options"])
optionsBtn:SetSize(math.max(optionsLabel:GetStringWidth() + 4, 44), 20)
optionsBtn:SetPoint("RIGHT", chevron, "LEFT", -6, 0)
optionsLabel:SetPoint("RIGHT", optionsBtn, "RIGHT", -2, 0)
-- Delayed tooltip hide: cancels if mouse re-enters within 0.15s (stops flicker when cursor briefly leaves)
local optionsTooltipHideRequested = false
optionsBtn:SetScript("OnClick", function()
    if _G.HorizonSuite_ShowOptions then _G.HorizonSuite_ShowOptions() end
end)
optionsBtn:SetScript("OnEnter", function(self)
    optionsTooltipHideRequested = false
    optionsLabel:SetTextColor(0.85, 0.85, 0.90, 1)
    -- Super-minimal: keep chevron and options visible when hovering options (header OnLeave fires when we move here)
    if addon.GetDB("hideObjectivesHeader", false) and not addon.GetDB("hideOptionsButton", false) then
        addon.chevron:SetAlpha(1)
        addon.optionsBtn:SetAlpha(1)
    end
    if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(addon.L["Options"], nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end)
optionsBtn:SetScript("OnLeave", function()
    optionsLabel:SetTextColor(0.60, 0.65, 0.75, 1)
    optionsTooltipHideRequested = true
    C_Timer.After(0.15, function()
        if optionsTooltipHideRequested and GameTooltip then
            GameTooltip:Hide()
        end
        optionsTooltipHideRequested = false
    end)
end)

local divider = HS:CreateTexture(nil, "ARTWORK")
divider:SetSize(addon.GetPanelWidth() - addon.PADDING * 2, addon.DIVIDER_HEIGHT)
divider:SetPoint("TOP", HS, "TOPLEFT", addon.GetPanelWidth() / 2, -(addon.PADDING + addon.GetHeaderHeight()))
divider:SetColorTexture(addon.DIVIDER_COLOR[1], addon.DIVIDER_COLOR[2], addon.DIVIDER_COLOR[3], addon.DIVIDER_COLOR[4])

function addon.GetHeaderToContentGap()
    return math.max(0, math.min(24, tonumber(addon.GetDB("headerToContentGap", 6)) or 6))
end

function addon.GetContentTop()
    -- Super-minimal uses same offset as full header so categories/quests do not move up (no overlap with chevron/options)
    return -(addon.PADDING + addon.GetHeaderHeight() + addon.DIVIDER_HEIGHT + addon.GetHeaderToContentGap())
end
function addon.GetCollapsedHeight()
    if addon.GetDB("hideObjectivesHeader", false) then
        return addon.MINIMAL_HEADER_HEIGHT + 6
    end
    return addon.PADDING + addon.GetHeaderHeight() + 6
end

local scrollFrame = CreateFrame("ScrollFrame", nil, HS)
scrollFrame:SetPoint("TOPLEFT", HS, "TOPLEFT", 0, addon.GetContentTop())
scrollFrame:SetPoint("BOTTOMRIGHT", HS, "BOTTOMRIGHT", 0, addon.PADDING)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(addon.GetPanelWidth())
scrollChild:SetHeight(1)
scrollFrame:SetScrollChild(scrollChild)

addon.focus = addon.focus or {}
addon.focus.layout = addon.focus.layout or {
    scrollOffset = 0,
    targetHeight = addon.MIN_HEIGHT,
    currentHeight = addon.MIN_HEIGHT,
    sectionIdx = 0,
}
addon.focus.layout.scrollOffset = 0

local function HandleScroll(delta)
    if InCombatLockdown() then return end
    local childH  = scrollChild:GetHeight() or 0
    local frameH  = scrollFrame:GetHeight() or 0
    local maxScr  = math.max(childH - frameH, 0)
    local lo = addon.focus.layout
    lo.scrollOffset = math.max(0, math.min(lo.scrollOffset - delta * addon.SCROLL_STEP, maxScr))
    scrollFrame:SetVerticalScroll(lo.scrollOffset)
end

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(_, delta) HandleScroll(delta) end)

HS:EnableMouseWheel(true)
HS:SetScript("OnMouseWheel", function(_, delta) HandleScroll(delta) end)

HS:SetMovable(true)
HS:EnableMouse(true)
HS:RegisterForDrag("LeftButton")
HS:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    if HorizonDB and HorizonDB.lockPosition then return end
    self:StartMoving()
end)

local function SavePanelPosition()
    if InCombatLockdown() then return end
    local uiRight = UIParent:GetRight() or 0
    local right   = HS:GetRight()
    if not right then return end
    addon.EnsureDB()
    if addon.GetDB("growUp", false) then
        local bottom = HS:GetBottom()
        local uiBottom = UIParent:GetBottom() or 0
        if not bottom then return end
        local x, y = right - uiRight, bottom - uiBottom
        HS:ClearAllPoints()
        HS:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
        HorizonDB.point    = "BOTTOMRIGHT"
        HorizonDB.relPoint = "BOTTOMRIGHT"
        HorizonDB.x        = x
        HorizonDB.y        = y
    else
        local top = HS:GetTop()
        local uiTop = UIParent:GetTop() or 0
        if not top then return end
        local x, y = right - uiRight, top - uiTop
        HS:ClearAllPoints()
        HS:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", x, y)
        HorizonDB.point    = "TOPRIGHT"
        HorizonDB.relPoint = "TOPRIGHT"
        HorizonDB.x        = x
        HorizonDB.y        = y
    end
end

HS:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false)
    if InCombatLockdown() then return end
    SavePanelPosition()
end)

-- Resize handle: drag bottom-right corner to change panel width and height
local RESIZE_MIN, RESIZE_MAX = 180, 800
local RESIZE_HEIGHT_MIN = addon.MIN_HEIGHT
local function GetResizeHeightMax()
    return addon.PADDING + addon.GetHeaderHeight() + addon.DIVIDER_HEIGHT + 24 + 1000 + addon.PADDING
end
local RESIZE_CONTENT_HEIGHT_MIN, RESIZE_CONTENT_HEIGHT_MAX = 200, 1000

local resizeHandle = CreateFrame("Frame", nil, HS)
resizeHandle:SetSize(20, 20)
resizeHandle:SetPoint("BOTTOMRIGHT", HS, "BOTTOMRIGHT", 0, 0)
resizeHandle:EnableMouse(true)
resizeHandle:SetScript("OnEnter", function(self)
    if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(addon.L["Drag to resize"], nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
end)
resizeHandle:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
end)
local isResizing = false
local startWidth, startHeight, startMouseX, startMouseY
resizeHandle:RegisterForDrag("LeftButton")
local function ResizeOnUpdate(self, elapsed)
    if not isResizing then return end
    if InCombatLockdown() then
        isResizing = false
        self:SetScript("OnUpdate", nil)
        return
    end
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    local curX = select(1, GetCursorPosition()) / scale
    local curY = select(2, GetCursorPosition()) / scale
    local deltaX = curX - startMouseX
    local deltaY = curY - startMouseY
    local newWidth = math.max(RESIZE_MIN, math.min(RESIZE_MAX, startWidth + deltaX))
    local newHeight = math.max(RESIZE_HEIGHT_MIN, math.min(GetResizeHeightMax(), startHeight - deltaY))
    HS:SetWidth(newWidth)
    HS:SetHeight(newHeight)
    addon.focus.layout.targetHeight = newHeight
    addon.focus.layout.currentHeight = newHeight
    if addon.ApplyDimensions then addon.ApplyDimensions(newWidth) end
end
resizeHandle:SetScript("OnDragStart", function(self)
    if HorizonDB and HorizonDB.lockPosition then return end
    if InCombatLockdown() then return end
    isResizing = true
    startWidth = HS:GetWidth()
    startHeight = HS:GetHeight()
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    startMouseX = select(1, GetCursorPosition()) / scale
    startMouseY = select(2, GetCursorPosition()) / scale
    self:SetScript("OnUpdate", ResizeOnUpdate)
end)
resizeHandle:SetScript("OnDragStop", function(self)
    if not isResizing then return end
    isResizing = false
    self:SetScript("OnUpdate", nil)
    addon.EnsureDB()
    HorizonDB.panelWidth = HS:GetWidth()
    local h = HS:GetHeight()
    local headerArea = addon.PADDING + addon.GetHeaderHeight() + addon.DIVIDER_HEIGHT + addon.GetHeaderToContentGap()
    local contentH = h - headerArea - addon.PADDING
    -- M+ block at top: subtract its height so we persist only the scroll area.
    local mplus = addon.mplusBlock
    local hasMplus = mplus and mplus:IsShown()
    if hasMplus and addon.GetMplusBlockHeight then
        local gap = 4
        contentH = contentH - (addon.GetMplusBlockHeight() + gap * 2)
    end
    contentH = math.max(RESIZE_CONTENT_HEIGHT_MIN, math.min(RESIZE_CONTENT_HEIGHT_MAX, contentH))
    HorizonDB.maxContentHeight = contentH
    if not (addon.IsInMythicDungeon and addon.IsInMythicDungeon()) then
        HorizonDB.maxContentHeightOverworld = contentH
    end
    if addon.ApplyDimensions then addon.ApplyDimensions() end
    if addon.FullLayout and not InCombatLockdown() then addon.FullLayout() end
end)

-- Sleek L-shaped corner grip (two thin strips)
local gripR, gripG, gripB, gripA = 0.55, 0.56, 0.6, 0.65
local resizeLineH = resizeHandle:CreateTexture(nil, "OVERLAY")
resizeLineH:SetSize(12, 2)
resizeLineH:SetPoint("BOTTOMRIGHT", resizeHandle, "BOTTOMRIGHT", 0, 0)
resizeLineH:SetColorTexture(gripR, gripG, gripB, gripA)
local resizeLineV = resizeHandle:CreateTexture(nil, "OVERLAY")
resizeLineV:SetSize(2, 12)
resizeLineV:SetPoint("BOTTOMRIGHT", resizeHandle, "BOTTOMRIGHT", 0, 0)
resizeLineV:SetColorTexture(gripR, gripG, gripB, gripA)

function addon.UpdateResizeHandleVisibility()
    resizeHandle:SetShown(not (HorizonDB and HorizonDB.lockPosition))
end
-- Call on ADDON_LOADED to ensure it reflects current state
local visUpdateFrame = CreateFrame("Frame")
visUpdateFrame:RegisterEvent("ADDON_LOADED")
visUpdateFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "HorizonSuite" then
        addon.UpdateResizeHandleVisibility()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
addon.UpdateResizeHandleVisibility()

local function RestoreSavedPosition()
    if not HorizonDB or not HorizonDB.point then return end
    local db = HorizonDB
    HS:ClearAllPoints()
    HS:SetPoint(db.point, UIParent, db.relPoint or db.point, db.x, db.y)
end

local function ApplyGrowUpAnchor()
    if not addon.GetDB("growUp", false) then return end
    local right = HS:GetRight()
    local bottom = HS:GetBottom()
    if not right or not bottom then return end
    local uiRight = UIParent:GetRight() or 0
    local uiBottom = UIParent:GetBottom() or 0
    local x, y = right - uiRight, bottom - uiBottom
    HS:ClearAllPoints()
    HS:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
    addon.EnsureDB()
    HorizonDB.point    = "BOTTOMRIGHT"
    HorizonDB.relPoint = "BOTTOMRIGHT"
    HorizonDB.x        = x
    HorizonDB.y        = y
end

function addon.UpdateHeaderQuestCount(questCount, trackedInLogCount)
    local mode = addon.GetDB("headerCountMode", "trackedLog")
    local maxSlots = (C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept()) or 35
    -- Count only quests the player has actually accepted: iterate log, require non-header + questID + not WQ + IsOnQuest(questID).
    local numInLog = 0
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local isWQ = addon.IsQuestWorldQuest or (C_QuestLog.IsWorldQuest and function(q) return C_QuestLog.IsWorldQuest(q) end) or function() return false end
        local isOnQuest = C_QuestLog.IsOnQuest and function(q) return C_QuestLog.IsOnQuest(q) end or function() return true end
        local numEntries = select(1, C_QuestLog.GetNumQuestLogEntries()) or 0
        for i = 1, numEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and not info.isHidden and info.questID and (not isWQ or not isWQ(info.questID)) and isOnQuest(info.questID) then
                numInLog = numInLog + 1
            end
        end
    end
    local countStr
    if mode == "trackedLog" then
        local numerator = (trackedInLogCount ~= nil) and trackedInLogCount or questCount
        countStr = (numerator and numerator > 0) and (numerator .. "/" .. numInLog) or ""
    else
        countStr = (numInLog and numInLog > 0) and (numInLog .. "/" .. maxSlots) or ""
    end
    addon.countText:SetText(countStr)
    addon.countShadow:SetText(countStr)
    if addon.GetDB("showQuestCount", true) and not addon.GetDB("hideObjectivesHeader", false) then
        addon.countText:Show()
        addon.countShadow:Show()
    else
        addon.countText:Hide()
        addon.countShadow:Hide()
    end
end

-- Debug: run /horizon headercountdebug to print quest-log count breakdown and compare APIs.
function addon.DebugHeaderCount()
    if not addon.HSPrint then return end
    local maxSlots = (C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept()) or 35
    if not C_QuestLog or not C_QuestLog.GetNumQuestLogEntries or not C_QuestLog.GetInfo then
        addon.HSPrint("[HeaderCount debug] C_QuestLog APIs not available.")
        return
    end
    local isWQ = addon.IsQuestWorldQuest or (C_QuestLog.IsWorldQuest and function(q) return C_QuestLog.IsWorldQuest(q) end) or function() return false end
    local isOnQuest = C_QuestLog.IsOnQuest and function(q) return C_QuestLog.IsOnQuest(q) end or function() return true end
    local a, b = C_QuestLog.GetNumQuestLogEntries()
    local numEntries = a or 0

    -- API comparison: try different ways to get "accepted quests in log" count (excluding WQ).
    do
        local countByLogIndex = 0  -- GetQuestIDForLogIndex(i) + IsOnQuest + not WQ
        local getQidForIdx = C_QuestLog.GetQuestIDForLogIndex
        if getQidForIdx then
            for i = 1, numEntries do
                local qid = getQidForIdx(i)
                if qid and (not isWQ or not isWQ(qid)) and isOnQuest(qid) then countByLogIndex = countByLogIndex + 1 end
            end
        end
        local countWithNotHidden = 0  -- GetInfo + not isHidden + IsOnQuest + not WQ
        for i = 1, numEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.questID and not info.isHidden and (not isWQ or not isWQ(info.questID)) and isOnQuest(info.questID) then
                countWithNotHidden = countWithNotHidden + 1
            end
        end
        addon.HSPrint("[HeaderCount] API comparison (all exclude world quests):")
        addon.HSPrint(string.format("  numQuests (2nd return) = %s | GetQuestIDForLogIndex+IsOnQuest = %s | GetInfo+IsOnQuest = (below) | GetInfo+not isHidden+IsOnQuest = %s",
            tostring(b), tostring(countByLogIndex), tostring(countWithNotHidden)))
    end
    local numInLog, skippedHeader, skippedNoQid, skippedHidden, skippedWQ, skippedNotOnQuest = 0, 0, 0, 0, 0, 0
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if not info then
        elseif info.isHeader then
            skippedHeader = skippedHeader + 1
        elseif not info.questID then
            skippedNoQid = skippedNoQid + 1
        elseif info.isHidden then
            skippedHidden = skippedHidden + 1
        elseif isWQ and isWQ(info.questID) then
            skippedWQ = skippedWQ + 1
        elseif not isOnQuest(info.questID) then
            skippedNotOnQuest = skippedNotOnQuest + 1
        else
            numInLog = numInLog + 1
        end
    end
    local afterCap = math.min(numInLog, maxSlots)
    addon.HSPrint(string.format("[HeaderCount] GetNumQuestLogEntries first=%s second=%s maxSlots=%s | loop=%s counted=%s afterCap=%s | skip: header=%s noQid=%s hidden=%s wq=%s notOnQuest=%s",
        tostring(a), tostring(b), tostring(maxSlots), tostring(numEntries), tostring(numInLog), tostring(afterCap),
        tostring(skippedHeader), tostring(skippedNoQid), tostring(skippedHidden), tostring(skippedWQ), tostring(skippedNotOnQuest)))
    -- Breakdown: list each entry we counted (index, questID, title) — matches production (GetInfo + not isHidden + IsOnQuest + not WQ).
    addon.HSPrint("[HeaderCount] Breakdown of counted entries (production logic; index | questID | title):")
    local getTitle = C_QuestLog.GetTitleForQuestID
    local n = 0
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and not info.isHidden and info.questID and (not isWQ or not isWQ(info.questID)) and isOnQuest(info.questID) then
            n = n + 1
            local title = (getTitle and getTitle(info.questID)) or "(no title)"
            addon.HSPrint(string.format("  #%s idx=%s questID=%s | %s", tostring(n), tostring(i), tostring(info.questID), tostring(title)))
        end
    end
    addon.HSPrint(string.format("[HeaderCount] End breakdown: %s entries listed (production logic).", tostring(n)))
end

function addon.ApplyItemCooldown(cooldownFrame, itemLink)
    if not cooldownFrame or not itemLink then return end
    local ok, itemID = pcall(GetItemInfoInstant, itemLink)
    if not ok and addon.HSPrint then addon.HSPrint("GetItemInfoInstant failed: " .. tostring(itemLink)) end
    if not ok or not itemID or not GetItemCooldown then return end
    local start, duration = GetItemCooldown(itemID)
    if start and duration and duration > 0 then
        cooldownFrame:SetCooldown(start, duration)
    else
        cooldownFrame:Clear()
    end
end

addon.RARE_ADDED_SOUND = (SOUNDKIT and SOUNDKIT.UI_AUTO_QUEST_COMPLETE) or 61969

-- Export to addon table
addon.HS                  = HS
addon.scrollFrame         = scrollFrame
addon.scrollChild         = scrollChild
addon.headerText          = headerText
addon.headerShadow        = headerShadow
addon.countText           = countText
addon.countShadow         = countShadow
addon.chevron             = chevron
addon.optionsBtn          = optionsBtn
addon.optionsLabel        = optionsLabel
addon.divider             = divider
addon.HandleScroll        = HandleScroll
addon.SavePanelPosition   = SavePanelPosition
addon.RestoreSavedPosition = RestoreSavedPosition
addon.ApplyGrowUpAnchor   = ApplyGrowUpAnchor
