--[[
    Horizon Suite - Vista - Core
    Cinematic square minimap with zone text, coordinates, time, instance difficulty, mail, tracking, button collector.
    Supports full options: map size, border, typography, visibility, button drawer modes, per-addon filtering.
]]

local addon = _G.HorizonSuite
if not addon then return end

addon.Vista = addon.Vista or {}
local Vista = addon.Vista

-- ============================================================================
-- DEFAULTS / CONSTANTS
-- ============================================================================

local FONT_PATH_DEFAULT = "Fonts\\FRIZQT__.TTF"
local ZONE_SIZE_DEFAULT   = 12
local COORD_SIZE_DEFAULT  = 10
local TIME_SIZE_DEFAULT   = 10

local BORDER_COLOR_DEFAULT  = { 1, 1, 1, 0.15 }
local ZONE_COLOR_DEFAULT    = { 1, 1, 1 }
local COORD_COLOR_DEFAULT   = { 0.55, 0.65, 0.75 }
local DIFF_COLOR            = { 0.55, 0.65, 0.75 }
local DIFF_SIZE             = 10

local SHADOW_OX = 2
local SHADOW_OY = -2
local SHADOW_A  = 0.8

local MAP_SIZE_DEFAULT = 200

local BTN_SIZE = 26
local BTN_GAP  = 4

local FADE_DUR       = 0.20
local COORD_THROTTLE = 0.1
local TIME_THROTTLE  = 1.0

local PULSE_MIN   = 0.40
local PULSE_MAX   = 1.00
local PULSE_SPEED = 2.0

local DEFAULT_POINT    = "TOPRIGHT"
local DEFAULT_RELPOINT = "TOPRIGHT"
local DEFAULT_X        = -20
local DEFAULT_Y        = -20

-- Sentinel value meaning "use the global font" for per-element font pickers
local FONT_USE_GLOBAL = "__global__"

-- Button modes
local BTN_MODE_MOUSEOVER  = "mouseover"
local BTN_MODE_RIGHTCLICK = "rightclick"
local BTN_MODE_DRAWER     = "drawer"

local function easeOut(t) return 1 - (1 - t) * (1 - t) end

-- Proxy frame for taint-free Minimap manipulation
local proxy = CreateFrame("Frame")

-- ============================================================================
-- DB HELPERS
-- ============================================================================

local function DB(key, default)
    if addon.GetDB then return addon.GetDB(key, default) end
    return default
end

local function SetDB(key, value)
    if addon.SetDB then addon.SetDB(key, value) end
end

local function GetMapSize() return tonumber(DB("vistaMapSize", MAP_SIZE_DEFAULT)) or MAP_SIZE_DEFAULT end
local function GetBorderShow()  return DB("vistaBorderShow", true) end
local function GetBorderW()     return tonumber(DB("vistaBorderWidth", 1)) or 1 end
local function GetBorderColor()
    return  tonumber(DB("vistaBorderColorR", BORDER_COLOR_DEFAULT[1])) or BORDER_COLOR_DEFAULT[1],
            tonumber(DB("vistaBorderColorG", BORDER_COLOR_DEFAULT[2])) or BORDER_COLOR_DEFAULT[2],
            tonumber(DB("vistaBorderColorB", BORDER_COLOR_DEFAULT[3])) or BORDER_COLOR_DEFAULT[3],
            tonumber(DB("vistaBorderColorA", BORDER_COLOR_DEFAULT[4])) or BORDER_COLOR_DEFAULT[4]
end

-- Resolve a per-element font path, falling back to global or the hard default.
-- Always pipes through addon.ResolveFontPath() so LSM keys (e.g. "Game Font",
-- "Friz Quadrata TT") are converted to actual file paths before being passed
-- to FontString:SetFont().
local function ResolveFont(dbKey)
    local v = DB(dbKey, FONT_USE_GLOBAL)
    if v == FONT_USE_GLOBAL or v == nil or v == "" then
        -- Fall back to the addon global font setting (also may be an LSM key)
        v = (addon.GetDB and addon.GetDB("fontPath", nil)) or nil
    end
    -- If we still have nothing, use the in-game default font path directly
    if not v or v == "" or v == FONT_USE_GLOBAL then
        return addon.GetDefaultFontPath and addon.GetDefaultFontPath() or FONT_PATH_DEFAULT
    end
    -- ResolveFontPath converts LSM keys → real file paths; passes real paths through unchanged
    if addon.ResolveFontPath then
        local resolved = addon.ResolveFontPath(v)
        if resolved and resolved ~= "" then return resolved end
    end
    -- Last resort: if it's already a path (contains slashes), use as-is
    if v:find("\\") or v:find("/") then return v end
    return addon.GetDefaultFontPath and addon.GetDefaultFontPath() or FONT_PATH_DEFAULT
end

local function GetZoneFont()  return ResolveFont("vistaZoneFontPath") end
local function GetZoneSize()  return tonumber(DB("vistaZoneFontSize",  ZONE_SIZE_DEFAULT))  or ZONE_SIZE_DEFAULT end
local function GetCoordFont() return ResolveFont("vistaCoordFontPath") end
local function GetCoordSize() return tonumber(DB("vistaCoordFontSize", COORD_SIZE_DEFAULT)) or COORD_SIZE_DEFAULT end
local function GetTimeFont()  return ResolveFont("vistaTimeFontPath") end
local function GetTimeSize()  return tonumber(DB("vistaTimeFontSize",  TIME_SIZE_DEFAULT))  or TIME_SIZE_DEFAULT end

local function GetShowZone()           return DB("vistaShowZoneText",             true) end
local function GetShowCoord()          return DB("vistaShowCoordText",            true) end
local function GetShowTime()           return DB("vistaShowTimeText",             false) end

-- Per-button visibility (replaces old single "show default minimap buttons" toggle)
local function GetShowTracking()       return DB("vistaShowTracking",   true)  end
local function GetShowCalendar()       return DB("vistaShowCalendar",   true)  end
local function GetShowZoomBtns()       return DB("vistaShowZoomBtns",   true)  end
local function GetMouseoverTracking()  return DB("vistaMouseoverTracking", false) end
local function GetMouseoverCalendar()  return DB("vistaMouseoverCalendar", false) end
local function GetMouseoverZoomBtns()  return DB("vistaMouseoverZoomBtns", false) end
-- Legacy: kept so old DB key still works if present, but no longer the main control
local function GetShowDefaultButtons() return DB("vistaShowDefaultMinimapButtons", true) end

-- Draggable element saved positions (stored as x,y offset from anchor point relative to Minimap)
local function GetElemX(key, def)    return tonumber(DB("vistaEX_"..key, def))  or def  end
local function GetElemY(key, def)    return tonumber(DB("vistaEY_"..key, def))  or def  end
local function GetElemLocked(key)    return DB("vistaLocked_"..key, false) end

-- Convenience: default offsets for each text element
local ZONE_DEFAULT_X,   ZONE_DEFAULT_Y   =   0, -6
local COORD_DEFAULT_X,  COORD_DEFAULT_Y  =   0, -6
local TIME_DEFAULT_X,   TIME_DEFAULT_Y   =   0, -6

local function GetZoneOffsetX()  return GetElemX("zone",  ZONE_DEFAULT_X)  end
local function GetZoneOffsetY()  return GetElemY("zone",  ZONE_DEFAULT_Y)  end
local function GetCoordOffsetX() return GetElemX("coord", COORD_DEFAULT_X) end
local function GetCoordOffsetY() return GetElemY("coord", COORD_DEFAULT_Y) end
local function GetTimeOffsetX()  return GetElemX("time",  TIME_DEFAULT_X)  end
local function GetTimeOffsetY()  return GetElemY("time",  TIME_DEFAULT_Y)  end

-- Button mode
local function GetButtonMode()          return DB("vistaButtonMode",           BTN_MODE_MOUSEOVER) end
local function GetButtonHandleButtons() return DB("vistaHandleAddonButtons",   true) end
local function GetButtonDrawerLocked()  return DB("vistaDrawerButtonLocked",   false) end

-- Per-addon whitelist: table of addonName -> true; nil means allow all
local function GetButtonWhitelist() return DB("vistaButtonWhitelist", nil) end

-- Minimap shape
local function GetCircular() return DB("vistaCircular", false) end
local MASK_SQUARE   = "Interface\\ChatFrame\\ChatFrameBackground"
local MASK_CIRCULAR = 186178  -- file ID for Textures\MinimapMask (reliable in all retail builds)

-- Button size getters (separate per-button type)
local TRACKING_BTN_SIZE_DEFAULT = 22
local CALENDAR_BTN_SIZE_DEFAULT = 22
local QUEUE_BTN_SIZE_DEFAULT    = 22
local ZOOM_BTN_SIZE_DEFAULT     = 16
local MAIL_ICON_SIZE_DEFAULT    = 20
local ADDON_BTN_SIZE_DEFAULT    = 26

local function GetTrackingBtnSize() return tonumber(DB("vistaTrackingBtnSize", TRACKING_BTN_SIZE_DEFAULT)) or TRACKING_BTN_SIZE_DEFAULT end
local function GetCalendarBtnSize() return tonumber(DB("vistaCalendarBtnSize", CALENDAR_BTN_SIZE_DEFAULT)) or CALENDAR_BTN_SIZE_DEFAULT end
local function GetQueueBtnSize()    return tonumber(DB("vistaQueueBtnSize",    QUEUE_BTN_SIZE_DEFAULT))    or QUEUE_BTN_SIZE_DEFAULT end
local function GetZoomBtnSize()     return tonumber(DB("vistaZoomBtnSize",     ZOOM_BTN_SIZE_DEFAULT))     or ZOOM_BTN_SIZE_DEFAULT end
local function GetMailIconSize()    return tonumber(DB("vistaMailIconSize",     MAIL_ICON_SIZE_DEFAULT))    or MAIL_ICON_SIZE_DEFAULT end
local function GetAddonBtnSize()    return tonumber(DB("vistaAddonBtnSize",     ADDON_BTN_SIZE_DEFAULT))    or ADDON_BTN_SIZE_DEFAULT end

-- Per-button size lookup by key
local function GetProxyBtnSizeForKey(key)
    if key == "tracking" then return GetTrackingBtnSize()
    elseif key == "calendar" then return GetCalendarBtnSize()
    elseif key == "queue" then return GetQueueBtnSize()
    else return TRACKING_BTN_SIZE_DEFAULT end
end

-- Text color getters
local function GetZoneColor()
    return  tonumber(DB("vistaZoneColorR", ZONE_COLOR_DEFAULT[1])) or ZONE_COLOR_DEFAULT[1],
            tonumber(DB("vistaZoneColorG", ZONE_COLOR_DEFAULT[2])) or ZONE_COLOR_DEFAULT[2],
            tonumber(DB("vistaZoneColorB", ZONE_COLOR_DEFAULT[3])) or ZONE_COLOR_DEFAULT[3]
end
local function GetCoordColor()
    return  tonumber(DB("vistaCoordColorR", COORD_COLOR_DEFAULT[1])) or COORD_COLOR_DEFAULT[1],
            tonumber(DB("vistaCoordColorG", COORD_COLOR_DEFAULT[2])) or COORD_COLOR_DEFAULT[2],
            tonumber(DB("vistaCoordColorB", COORD_COLOR_DEFAULT[3])) or COORD_COLOR_DEFAULT[3]
end
local function GetTimeColor()
    return  tonumber(DB("vistaTimeColorR", COORD_COLOR_DEFAULT[1])) or COORD_COLOR_DEFAULT[1],
            tonumber(DB("vistaTimeColorG", COORD_COLOR_DEFAULT[2])) or COORD_COLOR_DEFAULT[2],
            tonumber(DB("vistaTimeColorB", COORD_COLOR_DEFAULT[3])) or COORD_COLOR_DEFAULT[3]
end
local function GetDiffColor()
    return  tonumber(DB("vistaDiffColorR", DIFF_COLOR[1])) or DIFF_COLOR[1],
            tonumber(DB("vistaDiffColorG", DIFF_COLOR[2])) or DIFF_COLOR[2],
            tonumber(DB("vistaDiffColorB", DIFF_COLOR[3])) or DIFF_COLOR[3]
end

-- Panel backdrop/border color getters
local PANEL_BG_DEFAULT    = { 0.08, 0.08, 0.12, 0.95 }
local PANEL_BORDER_DEFAULT = { 0.3, 0.4, 0.6, 0.7 }

local function GetPanelBgColor()
    return  tonumber(DB("vistaPanelBgR", PANEL_BG_DEFAULT[1])) or PANEL_BG_DEFAULT[1],
            tonumber(DB("vistaPanelBgG", PANEL_BG_DEFAULT[2])) or PANEL_BG_DEFAULT[2],
            tonumber(DB("vistaPanelBgB", PANEL_BG_DEFAULT[3])) or PANEL_BG_DEFAULT[3],
            tonumber(DB("vistaPanelBgA", PANEL_BG_DEFAULT[4])) or PANEL_BG_DEFAULT[4]
end
local function GetPanelBorderColor()
    return  tonumber(DB("vistaPanelBorderR", PANEL_BORDER_DEFAULT[1])) or PANEL_BORDER_DEFAULT[1],
            tonumber(DB("vistaPanelBorderG", PANEL_BORDER_DEFAULT[2])) or PANEL_BORDER_DEFAULT[2],
            tonumber(DB("vistaPanelBorderB", PANEL_BORDER_DEFAULT[3])) or PANEL_BORDER_DEFAULT[3],
            tonumber(DB("vistaPanelBorderA", PANEL_BORDER_DEFAULT[4])) or PANEL_BORDER_DEFAULT[4]
end

-- ============================================================================
-- BLIZZARD CHROME STRIP
-- ============================================================================

-- Frames that are purely decorative Blizzard chrome — hide them by name only.
local CHROME_KILL_LIST = {
    "MinimapBorderTop", "MiniMapWorldMapButton",
    "MinimapCompassTexture", "MinimapBackdrop", "MinimapNorthTag",
    "MinimapZoneTextButton", "MiniMapInstanceDifficulty",
    "MinimapBorder",
    -- Zoom buttons: hide visually (re-anchored off-screen so they don't drift on resize)
    "MinimapZoomIn", "MinimapZoomOut",
    -- GameTimeFrame: Blizzard clock
    "GameTimeFrame",
    -- Addon compartment: always hidden from minimap surface
    "AddonCompartmentFrame",
}

local function KillFrame(name)
    local frame = _G[name]
    if not frame then return end
    pcall(function()
        frame:Hide()
        frame:SetAlpha(0)
        frame.Show = function() end
    end)
end

-- Kill a frame object directly (not by global name)
local function KillFrameObj(f)
    if not f then return end
    pcall(function()
        f:Hide()
        f:SetAlpha(0)
        f.Show = function() end
    end)
end

-- Permanently suppress Blizzard zoom buttons — we draw our own on decor.
local function SuppressZoomButtons()
    pcall(function()
        local function suppressBtn(btn)
            if not btn then return end
            btn:Hide(); btn:SetAlpha(0)
            btn.Show = function() end
            if hooksecurefunc and not btn._vistaZoomHooked then
                btn._vistaZoomHooked = true
                hooksecurefunc(btn, "SetPoint", function(self) self:SetAlpha(0) end)
                hooksecurefunc(btn, "Show",     function(self) self:SetAlpha(0) end)
            end
        end
        suppressBtn(MinimapZoomIn)
        suppressBtn(MinimapZoomOut)
        -- Also kill sub-frame zoom buttons (WoW 10.x+)
        suppressBtn(Minimap and Minimap.ZoomIn)
        suppressBtn(Minimap and Minimap.ZoomOut)
    end)
end

local chromeSuppressHooked = false

-- Called once after init to hook any child that tries to Show itself
local function HookMinimapClusterChildrenShow()
    if chromeSuppressHooked then return end
    chromeSuppressHooked = true
    pcall(function()
        if not MinimapCluster then return end
        -- Hook each existing child's Show so re-shows are suppressed
        for _, child in ipairs({ MinimapCluster:GetChildren() }) do
            if child ~= Minimap then
                local cName = child:GetName()
                if not cName or not cName:find("^HorizonSuite") then
                    if hooksecurefunc and not child._vistaShowHooked then
                        child._vistaShowHooked = true
                        pcall(function()
                            hooksecurefunc(child, "Show", function(self)
                                self:SetAlpha(0)
                            end)
                        end)
                    end
                end
            end
        end
        -- Also hook BorderTop specifically if it exists
        if MinimapCluster.BorderTop and hooksecurefunc and not MinimapCluster.BorderTop._vistaShowHooked then
            MinimapCluster.BorderTop._vistaShowHooked = true
            pcall(function()
                hooksecurefunc(MinimapCluster.BorderTop, "Show", function(self) self:SetAlpha(0) end)
            end)
        end
        if MinimapCluster.Tracking and hooksecurefunc and not MinimapCluster.Tracking._vistaShowHooked then
            MinimapCluster.Tracking._vistaShowHooked = true
            pcall(function()
                hooksecurefunc(MinimapCluster.Tracking, "Show", function(self) self:SetAlpha(0) end)
            end)
            if MinimapCluster.Tracking.Background then
                pcall(function()
                    hooksecurefunc(MinimapCluster.Tracking.Background, "Show", function(self) self:SetAlpha(0) end)
                end)
            end
        end
    end)
end

local function StripBlizzardChrome()
    for _, name in ipairs(CHROME_KILL_LIST) do KillFrame(name) end
    SuppressZoomButtons()

    -- Kill MinimapCluster named sub-frames directly via object references
    pcall(function()
        if not MinimapCluster then return end

        -- Known named sub-frames on MinimapCluster
        local subFrameNames = {
            "BorderTop", "Tracking", "ZoneTextButton",
            "InstanceDifficulty", "MailFrame", "CraftingOrderIcon",
            "GuildInstanceDifficulty", "DungeonDifficulty",
            "ZoomIn", "ZoomOut",
        }
        for _, key in ipairs(subFrameNames) do
            KillFrameObj(MinimapCluster[key])
            -- Also kill sub-sub-frames (e.g. Tracking.Background)
            if MinimapCluster[key] then
                for subKey, subVal in pairs(MinimapCluster[key]) do
                    if type(subVal) == "table" and subVal.Hide then
                        KillFrameObj(subVal)
                    end
                end
            end
        end

        -- Walk ALL children of MinimapCluster and kill anything that isn't Minimap itself
        -- or one of our own frames
        for _, child in ipairs({ MinimapCluster:GetChildren() }) do
            if child ~= Minimap then
                local cName = child:GetName()
                -- Don't kill our own frames
                if not cName or not cName:find("^HorizonSuite") then
                    KillFrameObj(child)
                    -- Also kill any regions (textures) on this child
                    for _, region in ipairs({ child:GetRegions() }) do
                        pcall(function() region:Hide(); region:SetAlpha(0) end)
                    end
                    -- Kill the child's own children
                    for _, grandchild in ipairs({ child:GetChildren() }) do
                        KillFrameObj(grandchild)
                    end
                end
            end
        end

        -- Kill all regions on MinimapCluster itself
        for _, region in ipairs({ MinimapCluster:GetRegions() }) do
            pcall(function() region:Hide(); region:SetAlpha(0) end)
        end
    end)

    -- Aggressively hide ALL textures/regions on Minimap itself that are Blizzard artwork.
    pcall(function()
        for _, region in ipairs({ Minimap:GetRegions() }) do
            if region then
                pcall(function() region:SetAlpha(0); region:Hide() end)
            end
        end
    end)

    pcall(function()
        Minimap:SetArchBlobRingScalar(0); Minimap:SetArchBlobRingAlpha(0)
        Minimap:SetQuestBlobRingScalar(0); Minimap:SetQuestBlobRingAlpha(0)
    end)

    pcall(function()
        if MinimapZoneText then MinimapZoneText:Hide(); MinimapZoneText:SetAlpha(0) end
    end)
end

-- ============================================================================
-- STATE
-- ============================================================================

local decor
local borderTextures = {}   -- top, bottom, left, right
local circularBorderFrame   -- ring shown instead of rect borders when circular mode is active
local zoneText,  zoneShadow
local diffText,  diffShadow
local coordText, coordShadow
local timeText,  timeShadow
local mailFrame, mailPulsing
local collectorBar
local collectedButtons   = {}
local drawerPanelButtons = {}
local barAlpha, hoverTarget, hoverElapsed = 0, 0, 0
local coordElapsed = 0
local timeElapsed  = 0
local zoomStarted, zoomCurrent = 0, 0
local hookedButtons = {}
local setParentHook
local eventFrame

-- Drawer button state
local drawerButton, drawerPanel
local drawerOpen    = false
local drawerDragging = false

-- Right-click panel state
local rightClickPanel
local rightClickVisible = false

-- Our custom zoom buttons (replace Blizzard MinimapZoomIn/Out)
local zoomInBtn, zoomOutBtn

-- Our default-button proxies anchored to decor
local defaultProxies = {}  -- list of proxy frames we created

-- ============================================================================
-- DRAGGABLE ELEMENT HELPER
-- ============================================================================

-- Makes `frame` draggable. On drag-stop saves the position as an offset
-- relative to `relFrame` using `anchorPoint`/`relPoint`.
-- `lockKey` is the DB key for the lock toggle.
-- `xKey`/`yKey` are the DB keys where we persist the offsets.
local function MakeDraggable(frame, lockKey, xKey, yKey, anchorPoint, relFrame, relPoint)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if DB("vistaLocked_" .. lockKey, false) then return end
        if InCombatLockdown() then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Compute offset relative to relFrame so the element keeps following it.
        -- After StopMovingOrSizing, WoW re-anchors to BOTTOMLEFT/UIParent.
        -- We need to figure out our new offset from the intended anchor.
        local sx, sy = self:GetCenter()
        local rx, ry = relFrame:GetCenter()
        -- For the anchors used (TOP→BOTTOM, TOPRIGHT→BOTTOMRIGHT, TOPLEFT→BOTTOMLEFT),
        -- the offset is relative to a specific edge of relFrame.
        local relW, relH = relFrame:GetSize()
        local selfW, selfH = self:GetSize()
        local ox, oy
        if anchorPoint == "TOP" and relPoint == "BOTTOM" then
            -- x offset from center of relFrame, y offset from bottom of relFrame to top of self
            ox = sx - rx
            oy = (sy + selfH / 2) - (ry - relH / 2)
        elseif anchorPoint == "TOPRIGHT" and relPoint == "BOTTOMRIGHT" then
            ox = (sx + selfW / 2) - (rx + relW / 2)
            oy = (sy + selfH / 2) - (ry - relH / 2)
        elseif anchorPoint == "TOPLEFT" and relPoint == "BOTTOMLEFT" then
            ox = (sx - selfW / 2) - (rx - relW / 2)
            oy = (sy + selfH / 2) - (ry - relH / 2)
        else
            -- Generic fallback: center-to-center
            ox = sx - rx
            oy = sy - ry
        end
        SetDB("vistaEX_" .. xKey, ox)
        SetDB("vistaEY_" .. yKey, oy)
        -- Re-anchor to relFrame so element follows when minimap moves
        self:ClearAllPoints()
        self:SetPoint(anchorPoint, relFrame, relPoint, ox, oy)
    end)
end

-- ============================================================================
-- AUTO ZOOM
-- ============================================================================

local autoZoomTimer = nil  -- track current pending timer so we can cancel on reset

local function ScheduleAutoZoom()
    -- Cancel any in-flight timer first so re-enable after 0 works correctly.
    if autoZoomTimer then
        autoZoomTimer:Cancel()
        autoZoomTimer = nil
    end
    local autoZoom = tonumber(DB("vistaAutoZoom", 5)) or 0
    if autoZoom <= 0 then return end
    autoZoomTimer = C_Timer.NewTimer(autoZoom, function()
        autoZoomTimer = nil
        for _ = 1, Minimap:GetZoom() or 0 do
            if Minimap_ZoomOutClick then Minimap_ZoomOutClick()
            elseif Minimap.ZoomOut then Minimap.ZoomOut:Click() end
        end
    end)
end

-- ============================================================================
-- MINIMAP SETUP
-- ============================================================================

local function SetupMinimap()
    local pt    = DB("vistaPoint",    nil)
    local rp    = DB("vistaRelPoint", nil)
    local vx    = DB("vistaX",        nil)
    local vy    = DB("vistaY",        nil)
    local scale = DB("vistaScale",    1.0)

    local sz = GetMapSize()
    Minimap:SetSize(sz, sz)
    Minimap:SetMaskTexture(GetCircular() and MASK_CIRCULAR or MASK_SQUARE)

    if pt then
        proxy.ClearAllPoints(Minimap)
        proxy.SetPoint(Minimap, pt, UIParent, rp or pt, vx or 0, vy or 0)
    else
        proxy.ClearAllPoints(Minimap)
        proxy.SetPoint(Minimap, DEFAULT_POINT, UIParent, DEFAULT_RELPOINT, DEFAULT_X, DEFAULT_Y)
    end

    if hooksecurefunc and not Vista._setPointHooked then
        Vista._setPointHooked = true
        hooksecurefunc(Minimap, "SetPoint", function()
            if not addon:IsModuleEnabled("vista") then return end
            local dpt = DB("vistaPoint", nil)
            if dpt then
                proxy.ClearAllPoints(Minimap)
                proxy.SetPoint(Minimap, dpt, UIParent, DB("vistaRelPoint", dpt) or dpt, DB("vistaX", 0) or 0, DB("vistaY", 0) or 0)
            end
        end)
    end

    local moduleScale = (addon.GetModuleScale and addon.GetModuleScale("vista")) or 1
    proxy.SetScale(Minimap, (scale or 1.0) * moduleScale)
    Minimap:Show()
    Minimap:SetAlpha(1)
end

-- ============================================================================
-- BORDER HELPERS
-- ============================================================================

local function ApplyBorderTextures()
    if not decor then return end
    local show       = GetBorderShow()
    local bw         = GetBorderW()
    local r, g, b, a = GetBorderColor()
    local isCircular = GetCircular()

    if isCircular and circularBorderFrame then
        -- Hide the four rectangular border lines
        for _, tex in pairs(borderTextures) do
            if tex then tex:Hide() end
        end
        -- Show/update the circular ring border
        if show then
            local sz = GetMapSize()
            circularBorderFrame:SetSize(sz + bw * 2, sz + bw * 2)
            circularBorderFrame:ClearAllPoints()
            circularBorderFrame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
            circularBorderFrame._tex:SetColorTexture(r, g, b, a)
            circularBorderFrame:Show()
        else
            circularBorderFrame:Hide()
        end
        return
    end

    -- Square mode: hide circular ring, show rect borders
    if circularBorderFrame then circularBorderFrame:Hide() end

    for _, tex in pairs(borderTextures) do
        if tex then
            tex:SetColorTexture(r, g, b, a)
            if show then tex:Show() else tex:Hide() end
        end
    end

    if borderTextures.top then
        borderTextures.top:ClearAllPoints()
        borderTextures.top:SetHeight(bw)
        borderTextures.top:SetPoint("TOPLEFT",  Minimap, "TOPLEFT",  0,  bw)
        borderTextures.top:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0,  bw)
    end
    if borderTextures.bottom then
        borderTextures.bottom:ClearAllPoints()
        borderTextures.bottom:SetHeight(bw)
        borderTextures.bottom:SetPoint("BOTTOMLEFT",  Minimap, "BOTTOMLEFT",  0, -bw)
        borderTextures.bottom:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, -bw)
    end
    if borderTextures.left then
        borderTextures.left:ClearAllPoints()
        borderTextures.left:SetWidth(bw)
        borderTextures.left:SetPoint("TOPLEFT",    Minimap, "TOPLEFT",    -bw,  bw)
        borderTextures.left:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -bw, -bw)
    end
    if borderTextures.right then
        borderTextures.right:ClearAllPoints()
        borderTextures.right:SetWidth(bw)
        borderTextures.right:SetPoint("TOPRIGHT",    Minimap, "TOPRIGHT",    bw,  bw)
        borderTextures.right:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", bw, -bw)
    end
end

-- ============================================================================
-- DECOR CREATION
-- ============================================================================

local function CreateDecor()
    decor = CreateFrame("Frame", "HorizonSuiteVistaDecor", Minimap)
    decor:SetAllPoints(Minimap)
    decor:SetFrameLevel(Minimap:GetFrameLevel() + 5)

    local function MakeBorderTex(name)
        local t = decor:CreateTexture(nil, "OVERLAY")
        borderTextures[name] = t
        return t
    end
    MakeBorderTex("top"); MakeBorderTex("bottom"); MakeBorderTex("left"); MakeBorderTex("right")

    -- Circular border ring is rendered as a masked color circle behind Minimap.
    -- The inside is covered by Minimap itself, leaving a clean visible rim outside.
    -- Parent to Minimap's parent so we're not clipped by Minimap's circular mask.
    local minimapParent = Minimap:GetParent()
    if minimapParent then
        circularBorderFrame = CreateFrame("Frame", "HorizonSuiteVistaCircularBorder", minimapParent)
        circularBorderFrame:SetFrameStrata(Minimap:GetFrameStrata())
        circularBorderFrame:SetFrameLevel(math.max((Minimap:GetFrameLevel() or 1) - 1, 0))
        circularBorderFrame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
        circularBorderFrame:SetSize(GetMapSize(), GetMapSize())
        local cbt = circularBorderFrame:CreateTexture(nil, "OVERLAY")
        cbt:SetColorTexture(1, 1, 1, 1)
        cbt:SetAllPoints()
        local mask = circularBorderFrame:CreateMaskTexture(nil, "OVERLAY")
        mask:SetTexture(MASK_CIRCULAR, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(cbt)
        cbt:AddMaskTexture(mask)
        circularBorderFrame._tex = cbt
        circularBorderFrame._mask = mask
        circularBorderFrame:Hide()
    end

    ApplyBorderTextures()

    -- Draggable minimap
    Minimap:SetMovable(true)
    Minimap:SetClampedToScreen(true)
    Minimap:RegisterForDrag("LeftButton")
    Minimap:SetScript("OnDragStart", function(self)
        local lock = DB("vistaLock", false)
        if not lock and self:IsMovable() then
            if not InCombatLockdown() then self:StartMoving() end
        end
    end)
    Minimap:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        if not addon.SetDB then return end
        local p, _, rp, x, y = self:GetPoint()
        SetDB("vistaPoint", p); SetDB("vistaRelPoint", rp)
        SetDB("vistaX", x);     SetDB("vistaY", y)
    end)

    -- Mouse wheel zoom
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(_, d)
        if d > 0 then
            if MinimapZoomIn  then MinimapZoomIn:Click()  elseif Minimap.ZoomIn  then Minimap.ZoomIn:Click()  end
        else
            if MinimapZoomOut then MinimapZoomOut:Click() elseif Minimap.ZoomOut then Minimap.ZoomOut:Click() end
        end
    end)

    pcall(function()
        if MinimapZoomIn then
            MinimapZoomIn:HookScript("OnClick",  ScheduleAutoZoom)
            MinimapZoomOut:HookScript("OnClick", ScheduleAutoZoom)
        elseif Minimap.ZoomIn then
            Minimap.ZoomIn:HookScript("OnClick",  ScheduleAutoZoom)
            Minimap.ZoomOut:HookScript("OnClick", ScheduleAutoZoom)
        end
    end)
    Minimap:HookScript("OnMouseWheel", ScheduleAutoZoom)

    -- ---- Zone text (in a draggable container) ----
    local zoneContainer = CreateFrame("Frame", nil, decor)
    zoneContainer:SetSize(GetMapSize(), 20)
    zoneContainer:SetPoint("TOP", Minimap, "BOTTOM", GetZoneOffsetX(), GetZoneOffsetY())
    zoneContainer:SetFrameLevel(decor:GetFrameLevel() + 1)
    MakeDraggable(zoneContainer, "zone", "zone", "zone", "TOP", Minimap, "BOTTOM")

    zoneShadow = zoneContainer:CreateFontString(nil, "BORDER")
    zoneShadow:SetFont(GetZoneFont(), GetZoneSize(), "OUTLINE")
    zoneShadow:SetTextColor(0, 0, 0, SHADOW_A)
    zoneShadow:SetJustifyH("CENTER")
    zoneShadow:SetAllPoints()

    zoneText = zoneContainer:CreateFontString(nil, "OVERLAY")
    zoneText:SetFont(GetZoneFont(), GetZoneSize(), "OUTLINE")
    zoneText:SetTextColor(unpack(ZONE_COLOR_DEFAULT))
    zoneText:SetJustifyH("CENTER")
    zoneText:SetAllPoints()

    -- ---- Difficulty text ----
    diffShadow = decor:CreateFontString(nil, "BORDER")
    diffShadow:SetFont(FONT_PATH_DEFAULT, DIFF_SIZE, "OUTLINE")
    diffShadow:SetTextColor(0, 0, 0, SHADOW_A)
    diffShadow:SetJustifyH("CENTER")

    diffText = decor:CreateFontString(nil, "OVERLAY")
    diffText:SetFont(FONT_PATH_DEFAULT, DIFF_SIZE, "OUTLINE")
    diffText:SetTextColor(unpack(DIFF_COLOR))
    diffText:SetJustifyH("CENTER")
    diffText:SetPoint("TOP", zoneText, "BOTTOM", 0, -2)
    diffText:SetWidth(GetMapSize())
    diffShadow:SetAllPoints(diffText)

    -- ---- Coord text (in a draggable container) ----
    local coordContainer = CreateFrame("Frame", nil, decor)
    coordContainer:SetSize(120, 16)
    coordContainer:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", GetCoordOffsetX(), GetCoordOffsetY())
    coordContainer:SetFrameLevel(decor:GetFrameLevel() + 1)
    MakeDraggable(coordContainer, "coord", "coord", "coord", "TOPRIGHT", Minimap, "BOTTOMRIGHT")

    coordShadow = coordContainer:CreateFontString(nil, "BORDER")
    coordShadow:SetFont(GetCoordFont(), GetCoordSize(), "OUTLINE")
    coordShadow:SetTextColor(0, 0, 0, SHADOW_A)
    coordShadow:SetJustifyH("RIGHT")
    coordShadow:SetAllPoints()

    coordText = coordContainer:CreateFontString(nil, "OVERLAY")
    coordText:SetFont(GetCoordFont(), GetCoordSize(), "OUTLINE")
    coordText:SetTextColor(unpack(COORD_COLOR_DEFAULT))
    coordText:SetJustifyH("RIGHT")
    coordText:SetAllPoints()

    -- ---- Time text (in a draggable container) ----
    -- Start small; we'll resize to fit the text each update
    local TIME_PAD = 4  -- horizontal padding each side
    local timeContainer = CreateFrame("Frame", nil, decor)
    timeContainer:SetSize(60, 16)
    timeContainer:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", GetTimeOffsetX(), GetTimeOffsetY())
    timeContainer:SetFrameLevel(decor:GetFrameLevel() + 1)
    MakeDraggable(timeContainer, "time", "time", "time", "TOPLEFT", Minimap, "BOTTOMLEFT")

    timeShadow = timeContainer:CreateFontString(nil, "BORDER")
    timeShadow:SetFont(GetTimeFont(), GetTimeSize(), "OUTLINE")
    timeShadow:SetTextColor(0, 0, 0, SHADOW_A)
    timeShadow:SetJustifyH("LEFT")
    timeShadow:SetPoint("TOPLEFT", timeContainer, "TOPLEFT", TIME_PAD, 0)
    timeShadow:SetPoint("BOTTOMRIGHT", timeContainer, "BOTTOMRIGHT", -TIME_PAD, 0)

    timeText = timeContainer:CreateFontString(nil, "OVERLAY")
    timeText:SetFont(GetTimeFont(), GetTimeSize(), "OUTLINE")
    timeText:SetTextColor(unpack(COORD_COLOR_DEFAULT))
    timeText:SetJustifyH("LEFT")
    timeText:SetPoint("TOPLEFT", timeContainer, "TOPLEFT", TIME_PAD, 0)
    timeText:SetPoint("BOTTOMRIGHT", timeContainer, "BOTTOMRIGHT", -TIME_PAD, 0)

    -- Resize container to fit text width each time text changes
    local function ResizeTimeContainer()
        local w = timeText:GetStringWidth()
        if w and w > 0 then
            timeContainer:SetWidth(w + TIME_PAD * 2)
        end
    end
    -- Hook into UpdateTimeText via a timer-based resize
    local timeResizeElapsed = 0
    timeContainer:SetScript("OnUpdate", function(_, elapsed)
        timeResizeElapsed = timeResizeElapsed + elapsed
        if timeResizeElapsed < 0.5 then return end
        timeResizeElapsed = 0
        ResizeTimeContainer()
    end)

    -- Invisible click overlay on top — separate from the draggable frame so drag still works
    local timeClickBtn = CreateFrame("Button", nil, timeContainer)
    timeClickBtn:SetAllPoints(timeContainer)
    timeClickBtn:SetFrameLevel(timeContainer:GetFrameLevel() + 2)
    timeClickBtn:RegisterForClicks("LeftButtonUp")
    -- Forward drag events to the parent timeContainer so click-and-drag repositioning works
    timeClickBtn:RegisterForDrag("LeftButton")
    timeClickBtn:SetScript("OnDragStart", function()
        if DB("vistaLocked_time", false) then return end
        if InCombatLockdown() then return end
        timeContainer:StartMoving()
    end)
    timeClickBtn:SetScript("OnDragStop", function()
        timeContainer:StopMovingOrSizing()
        -- Compute offset relative to Minimap (TOPLEFT→BOTTOMLEFT anchor)
        local sx, sy = timeContainer:GetCenter()
        local rx, ry = Minimap:GetCenter()
        local relW, relH = Minimap:GetSize()
        local selfW, selfH = timeContainer:GetSize()
        local ox = (sx - selfW / 2) - (rx - relW / 2)
        local oy = (sy + selfH / 2) - (ry - relH / 2)
        SetDB("vistaEX_time", ox)
        SetDB("vistaEY_time", oy)
        -- Re-anchor to Minimap so it follows when minimap moves
        timeContainer:ClearAllPoints()
        timeContainer:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", ox, oy)
    end)
    timeClickBtn:SetScript("OnClick", function()
        pcall(function()
            -- Open the stopwatch / time manager (NOT the calendar)
            if TimeManagerFrame then
                if TimeManagerFrame:IsShown() then
                    TimeManagerFrame:Hide()
                else
                    TimeManagerFrame:Show()
                end
            elseif _G["ToggleTimeManager"] then
                ToggleTimeManager()
            else
                -- Last resort: temporarily restore the clock button and click it
                local btn = TimeManagerClockButton
                if btn then
                    btn.Show = nil; btn:Show()
                    local s = btn:GetScript("OnClick")
                    if s then s(btn, "LeftButton") else btn:Click("LeftButton") end
                    btn:Hide(); btn.Show = function() end
                end
            end
        end)
    end)
    timeClickBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("Open Stopwatch")
        GameTooltip:Show()
    end)
    timeClickBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- store containers for ApplyOptions
    decor._zoneContainer  = zoneContainer
    decor._coordContainer = coordContainer
    decor._timeContainer  = timeContainer

    -- Apply initial visibility
    local showZone  = GetShowZone()
    local showCoord = GetShowCoord()
    local showTime  = GetShowTime()
    zoneText:SetShown(showZone);   zoneShadow:SetShown(showZone);   zoneContainer:SetShown(showZone)
    coordText:SetShown(showCoord); coordShadow:SetShown(showCoord); coordContainer:SetShown(showCoord)
    timeText:SetShown(showTime);   timeShadow:SetShown(showTime);   timeContainer:SetShown(showTime)
end

-- ============================================================================
-- TEXT UPDATES
-- ============================================================================

local function UpdateZoneText()
    if not zoneText then return end
    local zone = GetMinimapZoneText() or ""
    zoneText:SetText(zone); zoneShadow:SetText(zone)
end

local function UpdateDifficultyText()
    if not diffText then return end
    local _, instanceType, difficultyID = GetInstanceInfo()
    if instanceType == "none" or difficultyID == 0 then
        diffText:SetText(""); diffShadow:SetText(""); return
    end
    local diffName = GetDifficultyInfo(difficultyID)
    if not diffName or diffName == "" then
        diffText:SetText(""); diffShadow:SetText(""); return
    end
    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
        if keystoneLevel and keystoneLevel > 0 then diffName = diffName .. " +" .. keystoneLevel end
    end
    diffText:SetText(diffName); diffShadow:SetText(diffName)
end

local function UpdateCoords(_, elapsed)
    if not coordText or not GetShowCoord() then return end
    coordElapsed = coordElapsed + elapsed
    if coordElapsed < COORD_THROTTLE then return end
    coordElapsed = 0
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID and C_Map.GetPlayerMapPosition then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                local x, y = pos:GetXY()
                local str = format("%.1f, %.1f", x * 100, y * 100)
                coordText:SetText(str); coordShadow:SetText(str)
                return
            end
        end
    end
    coordText:SetText("--"); coordShadow:SetText("--")
end

local function UpdateTimeText(_, elapsed)
    if not timeText or not GetShowTime() then return end
    timeElapsed = timeElapsed + elapsed
    if timeElapsed < TIME_THROTTLE then return end
    timeElapsed = 0
    local hours, minutes = GetGameTime()
    if hours == nil then return end
    local use24 = GetCVar and GetCVar("timeMgrUseMilitaryTime") == "1"
    local str
    if use24 then
        str = format("%02d:%02d", hours, minutes)
    else
        local period = hours >= 12 and "PM" or "AM"
        hours = hours % 12
        if hours == 0 then hours = 12 end
        str = format("%d:%02d %s", hours, minutes, period)
    end
    timeText:SetText(str); timeShadow:SetText(str)
end

-- ============================================================================
-- MAIL INDICATOR
-- ============================================================================

local function CreateMailIndicator()
    mailFrame = CreateFrame("Frame", nil, decor)
    mailFrame:SetSize(GetMailIconSize(), GetMailIconSize())
    mailFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 4, -4)
    mailFrame:SetFrameLevel(decor:GetFrameLevel() + 2)
    mailFrame:Hide()

    local icon = mailFrame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\MINIMAP\\TRACKING\\Mailbox")
    icon:SetAllPoints(); icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    mailFrame.icon = icon

    mailFrame:EnableMouse(true)
    mailFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("You have mail"); GameTooltip:Show()
    end)
    mailFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local pulseTime = 0
    mailFrame:SetScript("OnUpdate", function(self, elapsed)
        if not mailPulsing then self.icon:SetAlpha(1); return end
        pulseTime = pulseTime + elapsed
        local t = (math.sin(pulseTime * PULSE_SPEED * math.pi * 2) + 1) / 2
        self.icon:SetAlpha(PULSE_MIN + (PULSE_MAX - PULSE_MIN) * t)
    end)
end

local function UpdateMailIndicator()
    if not mailFrame then return end
    local hasMail = HasNewMail()
    if hasMail then mailFrame:Show(); mailPulsing = true
    else mailFrame:Hide(); mailPulsing = false end
end

local function SuppressBlizzardMail()
    pcall(function()
        if MiniMapMailFrame then
            MiniMapMailFrame:Hide(); MiniMapMailFrame:SetAlpha(0)
            MiniMapMailFrame.Show = function() end
        end
    end)
    pcall(function()
        if MinimapCluster and MinimapCluster.IndicatorFrame then
            local ind = MinimapCluster.IndicatorFrame
            if ind.MailFrame then
                ind.MailFrame:Hide(); ind.MailFrame:SetAlpha(0)
                ind.MailFrame.Show = function() end
            end
            ind:Hide(); ind:SetAlpha(0); ind.Show = function() end
        end
    end)
    pcall(function()
        if MiniMapMailIcon then
            MiniMapMailIcon:Hide(); MiniMapMailIcon:SetAlpha(0)
            MiniMapMailIcon.Show = function() end
        end
    end)
end

-- ============================================================================
-- OUR OWN ZOOM BUTTONS
-- ============================================================================

local function CreateZoomButtons()
    -- Parent to UIParent so zoom buttons work when minimap is locked (Minimap:SetMovable(false)
    -- can block child input; UIParent children are unaffected)
    local zoomParent = UIParent
    local function makeZoomBtn(lockKey, defaultXOff, zoomDelta)
        local label = zoomDelta > 0 and "+" or "-"
        local btn = CreateFrame("Button", nil, zoomParent)
        btn:SetSize(GetZoomBtnSize(), GetZoomBtnSize())
        btn:SetFrameLevel(decor:GetFrameLevel() + 10)

        -- Restore saved position or use default BOTTOMRIGHT offset
        -- Positions are stored as CENTER offset relative to Minimap CENTER
        local savedX = tonumber(DB("vistaEX_" .. lockKey, nil))
        local savedY = tonumber(DB("vistaEY_" .. lockKey, nil))
        if savedX and savedY then
            btn:SetPoint("CENTER", Minimap, "CENTER", savedX, savedY)
        else
            btn:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", defaultXOff, 2)
        end

        -- No background — outline text over the map
        local zoomFontSize = math.max(10, math.floor(GetZoomBtnSize() * 0.875))
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_PATH_DEFAULT, zoomFontSize, "OUTLINE")
        lbl:SetText(label)
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        btn._label = lbl

        -- Draggable
        btn:SetMovable(true)
        btn:SetClampedToScreen(true)
        btn:RegisterForDrag("LeftButton")
        btn:SetScript("OnDragStart", function(self)
            if DB("vistaLocked_" .. lockKey, false) then return end
            if InCombatLockdown() then return end
            self:StartMoving()
        end)
        btn:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save position as offset from Minimap center so button follows minimap
            local mx, my = Minimap:GetCenter()
            local bx, by = self:GetCenter()
            local ox, oy = bx - mx, by - my
            SetDB("vistaEX_" .. lockKey, ox)
            SetDB("vistaEY_" .. lockKey, oy)
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", ox, oy)
        end)

        btn:SetScript("OnClick", function()
            local cur = Minimap:GetZoom() or 0
            local new = math.max(0, math.min(Minimap:GetZoomLevels() or 5, cur + zoomDelta))
            Minimap:SetZoom(new)
            ScheduleAutoZoom()
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            GameTooltip:SetText(zoomDelta > 0 and "Zoom In" or "Zoom Out")
            if not DB("vistaLocked_" .. lockKey, false) then
                GameTooltip:AddLine("Drag to move", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return btn
    end

    -- ZoomIn on the far right, ZoomOut just to its left
    zoomInBtn  = makeZoomBtn("zoomIn",  -2,  1)
    zoomOutBtn = makeZoomBtn("zoomOut", -20, -1)

    -- Apply initial zoom button visibility
    local function ApplyZoomButtonVisibility()
        if not zoomInBtn or not zoomOutBtn then return end
        local show      = GetShowZoomBtns()
        local mouseover = GetMouseoverZoomBtns()
        if not show then
            zoomInBtn:Hide(); zoomOutBtn:Hide()
        elseif mouseover then
            -- Shown but invisible; becomes visible on hover of the button itself
            zoomInBtn:SetAlpha(0); zoomOutBtn:SetAlpha(0)
            zoomInBtn:Show(); zoomOutBtn:Show()
        else
            zoomInBtn:SetAlpha(1); zoomOutBtn:SetAlpha(1)
            zoomInBtn:Show(); zoomOutBtn:Show()
        end
    end
    ApplyZoomButtonVisibility()

    -- Per-button mouseover: show only when hovering the individual zoom button
    local function hookZoomMouseover(btn)
        btn:HookScript("OnEnter", function(self)
            if GetShowZoomBtns() and GetMouseoverZoomBtns() then
                self:SetAlpha(1)
            end
        end)
        btn:HookScript("OnLeave", function(self)
            if GetShowZoomBtns() and GetMouseoverZoomBtns() then
                self:SetAlpha(0)
            end
        end)
    end
    hookZoomMouseover(zoomInBtn)
    hookZoomMouseover(zoomOutBtn)
end

-- ============================================================================
-- DEFAULT BUTTON PROXIES  (tracking, calendar/landing page, queue)
-- ============================================================================

-- Blizzard default minimap buttons we create proxies for.
-- Landing page button removed — disabled by Blizzard until next expansion cycle.
local DEFAULT_BTN_DEFS = {
    {
        key     = "tracking",
        names   = { "MiniMapTracking", "MinimapTrackingFrame", "MiniMapTrackingButton" },
        anchor  = "TOPRIGHT",
        xOff    = -4, yOff = -4,
        tooltip = "Tracking",
        getIcon = function()
            -- Walk MiniMapTracking regions for the current tracking icon texture
            if MiniMapTracking then
                for _, r in ipairs({ MiniMapTracking:GetRegions() }) do
                    if r and r:IsObjectType("Texture") then
                        local t = r:GetTexture()
                        if t and type(t) == "string" and t ~= ""
                            and not t:lower():find("highlight")
                            and not t:lower():find("pushed")
                            and not t:lower():find("border") then
                            return t
                        end
                    end
                end
            end
            return "Interface\\MINIMAP\\TRACKING\\None"
        end,
        onClick = function(self, btn)
            -- Build a tracking menu using C_Minimap API directly.
            -- This is independent of any Blizzard frame that StripBlizzardChrome may kill.
            pcall(function()
                if not C_Minimap or not C_Minimap.GetNumTrackingTypes then return end
                -- Create/reuse a simple dropdown menu frame
                if not Vista._trackingMenu then
                    local menu = CreateFrame("Frame", "HorizonSuiteTrackingMenu", UIParent, "BackdropTemplate")
                    menu:SetFrameStrata("TOOLTIP")
                    menu:SetClampedToScreen(true)
                    menu:SetBackdrop({
                        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        edgeSize = 12,
                        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
                    })
                    menu:SetBackdropColor(0.06, 0.06, 0.1, 0.95)
                    menu:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.8)
                    menu:EnableMouse(true)
                    menu:Hide()
                    menu._rows = {}
                    menu:SetScript("OnLeave", function(s)
                        C_Timer.After(0.2, function()
                            if s and not s:IsMouseOver() then s:Hide() end
                        end)
                    end)
                    Vista._trackingMenu = menu
                end
                local menu = Vista._trackingMenu
                if menu:IsShown() then menu:Hide(); return end

                -- Clear old rows
                for _, row in ipairs(menu._rows) do row:Hide() end

                local numTypes = C_Minimap.GetNumTrackingTypes()
                local rowIdx = 0
                local ROW_H = 20
                local PAD = 6
                local maxW = 120

                for i = 1, numTypes do
                    local info = C_Minimap.GetTrackingInfo(i)
                    if info then
                        rowIdx = rowIdx + 1
                        local row = menu._rows[rowIdx]
                        if not row then
                            row = CreateFrame("Button", nil, menu)
                            row:SetHeight(ROW_H)
                            row._icon = row:CreateTexture(nil, "ARTWORK")
                            row._icon:SetSize(16, 16)
                            row._icon:SetPoint("LEFT", row, "LEFT", 4, 0)
                            row._check = row:CreateTexture(nil, "OVERLAY")
                            row._check:SetSize(12, 12)
                            row._check:SetPoint("LEFT", row._icon, "RIGHT", 2, 0)
                            row._check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                            row._label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                            row._label:SetPoint("LEFT", row._check, "RIGHT", 2, 0)
                            row._label:SetJustifyH("LEFT")
                            row._hl = row:CreateTexture(nil, "HIGHLIGHT")
                            row._hl:SetAllPoints()
                            row._hl:SetColorTexture(1, 1, 1, 0.1)
                            menu._rows[rowIdx] = row
                        end
                        row:SetPoint("TOPLEFT", menu, "TOPLEFT", PAD, -(PAD + (rowIdx - 1) * ROW_H))
                        row:SetPoint("RIGHT", menu, "RIGHT", -PAD, 0)
                        row._icon:SetTexture(info.texture)
                        row._label:SetText(info.name or "")
                        row._check:SetShown(info.active)
                        local w = (row._label:GetStringWidth() or 0) + 48
                        if w > maxW then maxW = w end
                        local trackIdx = i
                        row:SetScript("OnClick", function()
                            C_Minimap.SetTracking(trackIdx, not info.active)
                            menu:Hide()
                        end)
                        row:Show()
                    end
                end

                if rowIdx == 0 then return end
                menu:SetSize(maxW + PAD * 2, PAD * 2 + rowIdx * ROW_H)
                menu:ClearAllPoints()
                menu:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -2)
                menu:Show()
            end)
        end,
    },
    {
        key     = "calendar",
        names   = { "GameTimeFrame" },
        anchor  = "TOPLEFT",
        xOff    = 4, yOff = -4,
        tooltip = "Calendar",
        getIcon = function()
            return nil  -- we use SetAtlas below; nil means skip SetTexture
        end,
        setIcon = function(iconTex)
            -- Use a clean calendar icon without the circular minimap frame.
            -- Try the Calendarbutton atlas first (just the page, no circle).
            local ok = pcall(function() iconTex:SetAtlas("CalendarButton") end)
            if ok and iconTex:GetAtlas() and iconTex:GetAtlas() ~= "" then
                iconTex:SetTexCoord(0, 1, 0, 1)
                return
            end
            -- Fallback: inventory calendar/note icon (clean, no circle)
            iconTex:SetTexture("Interface\\Icons\\INV_Misc_Note_06")
            iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end,
        onClick = function(_, btn)
            pcall(function()
                local target = _G["GameTimeFrame"]
                if target then
                    target.Show = nil; target:Show()
                    target:Click(btn or "LeftButton")
                    target:Hide(); target.Show = function() end
                end
            end)
        end,
    },
    {
        key     = "queue",
        names   = { "QueueStatusButton", "QueueStatusMinimapButton", "MiniMapBattlefieldFrame" },
        anchor  = "BOTTOMLEFT",
        xOff    = 4, yOff = 4,
        tooltip = "Queue Status",
        getIcon = function() return nil end,
        setIcon = function(iconTex)
            local ok = pcall(function() iconTex:SetAtlas("QueueStatusIcon-Small") end)
            if not ok or not iconTex:GetTexture() then
                -- Fallback: try the eye frame atlas
                ok = pcall(function() iconTex:SetAtlas("groupfinder-eye-frame") end)
                if not ok or not iconTex:GetTexture() then
                    iconTex:SetTexture("Interface\\LFGFrame\\LFG-Eye")
                    iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                else
                    iconTex:SetTexCoord(0, 1, 0, 1)
                end
            else
                iconTex:SetTexCoord(0, 1, 0, 1)
            end
        end,
        onClick = function(_, btn)
            pcall(function()
                local target = _G["QueueStatusButton"] or _G["QueueStatusMinimapButton"] or _G["MiniMapBattlefieldFrame"]
                if target then
                    -- Real button is shown but invisible (alpha 0, offscreen).
                    -- Just click it to open the queue status popup.
                    target:Click(btn or "LeftButton")
                else
                    if _G["PVPUIFrame"] then PVPUIFrame:Show()
                    elseif _G["LFGListFrame"] then LFGListFrame:Show() end
                end
            end)
        end,
        -- Conditional: only shown when player is queued
        isConditional = true,
    },
}

local function SuppressDefaultBlizzardButtons()
    local allNames = {
        "MiniMapTracking", "MinimapTrackingFrame", "MiniMapTrackingButton",
        "ExpansionLandingPageMinimapButton", "GarrisonLandingPageMinimapButton",
        "QueueStatusButton", "QueueStatusMinimapButton", "MiniMapBattlefieldFrame",
        "TimeManagerClockButton", "GameTimeFrame", "MiniMapInstanceDifficulty",
    }
    for _, name in ipairs(allNames) do
        pcall(function()
            local f = _G[name]
            -- Skip buttons that have our proxy hook installed
            if f and not f._vistaProxyHooked then
                f:Hide(); f:SetAlpha(0); f.Show = function() end
            end
        end)
    end
end

local function CreateDefaultButtonProxies()
    -- Clean up old proxies
    for _, f in ipairs(defaultProxies) do
        -- Do NOT clear _vistaProxyHooked — hooks are permanent (hooksecurefunc)
        -- and the flag must remain set so SuppressDefaultBlizzardButtons won't
        -- override Show/Hide on the real button.
        pcall(function() f:Hide() end)
    end
    wipe(defaultProxies)

    if not decor then return end

    -- Per-button show/mouseover DB lookups
    local showFuncs = {
        tracking = GetShowTracking,
        calendar = GetShowCalendar,
    }
    local mouseoverFuncs = {
        tracking = GetMouseoverTracking,
        calendar = GetMouseoverCalendar,
    }

    for _, def in ipairs(DEFAULT_BTN_DEFS) do
        local key = def.key
        local lockKey = "proxy_" .. key
        local getShow      = showFuncs[key]      or function() return true end
        local getMouseover = mouseoverFuncs[key]  or function() return false end

        -- Parent to decor so the proxy always moves with Minimap
        local proxy = CreateFrame("Button", nil, decor)
        local proxySize = GetProxyBtnSizeForKey(key)
        proxy:SetSize(proxySize, proxySize)
        proxy._vistaKey = key
        proxy:SetFrameStrata("HIGH")
        proxy:SetFrameLevel(decor:GetFrameLevel() + 20)
        proxy:SetClampedToScreen(true)
        proxy:SetAlpha(1)  -- always full alpha; visibility controlled by Show/Hide

        -- Position: saved center-offset from Minimap, else default corner
        local savedX = tonumber(DB("vistaEX_" .. lockKey, nil))
        local savedY = tonumber(DB("vistaEY_" .. lockKey, nil))
        if savedX and savedY then
            proxy:SetPoint("CENTER", Minimap, "CENTER", savedX, savedY)
        else
            proxy:SetPoint(def.anchor, Minimap, def.anchor, def.xOff, def.yOff)
        end

        -- Draggable
        proxy:SetMovable(true)
        proxy:RegisterForDrag("LeftButton")
        proxy:SetScript("OnDragStart", function(self)
            if DB("vistaLocked_" .. lockKey, false) then return end
            if InCombatLockdown() then return end
            self:StartMoving()
        end)
        proxy:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local mx, my = Minimap:GetCenter()
            local px, py = self:GetCenter()
            SetDB("vistaEX_" .. lockKey, px - mx)
            SetDB("vistaEY_" .. lockKey, py - my)
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER",
                tonumber(DB("vistaEX_" .. lockKey, 0)) or 0,
                tonumber(DB("vistaEY_" .. lockKey, 0)) or 0)
        end)

        -- Icon — use NormalTexture slot so it's always full-brightness
        local icon = proxy:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetAlpha(1)
        if def.setIcon then
            def.setIcon(icon)
        else
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            local tex = def.getIcon()
            if tex then icon:SetTexture(tex) end
        end
        proxy._icon = icon

        -- Highlight (skip for tracking and queue — no mouseover box wanted)
        if key ~= "tracking" and key ~= "queue" then
            local hl = proxy:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.25)
        end

        -- Click
        proxy:RegisterForClicks("AnyUp")
        proxy:SetScript("OnClick", function(self, btn)
            pcall(function() def.onClick(self, btn) end)
        end)

        proxy:SetScript("OnEnter", function(self)
            -- Mouseover mode: reveal button when hovering its position
            if getShow() and getMouseover() then self:SetAlpha(1) end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            GameTooltip:SetText(def.tooltip)
            GameTooltip:Show()
        end)
        proxy:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            -- Mouseover mode: hide again when mouse leaves this button
            if getShow() and getMouseover() then
                self:SetAlpha(0)
            end
        end)

        -- Tracking icon sync (lightweight, only for tracking button)
        local isTracking = (key == "tracking")
        if isTracking then
            proxy:SetScript("OnUpdate", function(self, elapsed)
                self._syncTimer = (self._syncTimer or 0) + elapsed
                if self._syncTimer < 0.5 then return end
                self._syncTimer = 0
                local t = def.getIcon()
                if t and t ~= "" then
                    local ok = pcall(function() self._icon:SetAtlas(t) end)
                    if not ok then self._icon:SetTexture(t) end
                end
            end)
        end

        -- Conditional visibility (queue): mirror real button's visibility to proxy.
        -- Instead of overriding Show/Hide, we let Blizzard show/hide the real button
        -- normally but keep it invisible (alpha 0, moved offscreen). We use
        -- hooksecurefunc to detect state changes and mirror them to our proxy.
        -- IMPORTANT: hooks are permanent (hooksecurefunc can't be removed), so we
        -- store the current proxy on realBtn._vistaProxy and all hooks reference
        -- that indirection. When CreateDefaultButtonProxies() recreates proxies,
        -- it just updates _vistaProxy and the existing hooks follow automatically.
        if def.isConditional then
            -- Find the real Blizzard button to hook
            local realBtn
            for _, bName in ipairs(def.names or {}) do
                realBtn = _G[bName]
                if realBtn then break end
            end

            if realBtn then
                -- Mark so SuppressDefaultBlizzardButtons won't overwrite
                realBtn._vistaProxyHooked = true
                -- Store ref for cleanup
                proxy._hookedRealBtn = realBtn
                -- Set indirection: all hooks use this to find the current proxy
                realBtn._vistaProxy = proxy

                -- Undo the Show override so Blizzard can call Show/Hide normally
                -- (we suppressed Show = function() end earlier)
                realBtn.Show = nil
                realBtn.Hide = nil
                realBtn.SetShown = nil

                -- Keep the real button invisible: alpha 0 and offscreen
                realBtn:SetAlpha(0)
                realBtn:ClearAllPoints()
                realBtn:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -200, 200)

                -- Mirror function: sync proxy visibility to real button state
                local function SyncProxyToReal()
                    local p = realBtn._vistaProxy
                    if not p then return end
                    if realBtn:IsShown() then
                        p:Show()
                    else
                        p:Hide()
                    end
                end

                -- hooksecurefunc catches ALL calls to Show/Hide, including from C code
                -- Only install hooks ONCE; on subsequent calls we just update _vistaProxy above
                if hooksecurefunc and not realBtn._vistaShowSynced then
                    realBtn._vistaShowSynced = true
                    hooksecurefunc(realBtn, "Show", function()
                        local p = realBtn._vistaProxy
                        if p then p:Show() end
                        -- Keep it invisible
                        realBtn:SetAlpha(0)
                    end)
                    hooksecurefunc(realBtn, "Hide", function()
                        local p = realBtn._vistaProxy
                        if p then p:Hide() end
                    end)
                    hooksecurefunc(realBtn, "SetShown", function(_, shown)
                        local p = realBtn._vistaProxy
                        if not p then return end
                        if shown then
                            p:Show()
                            realBtn:SetAlpha(0)
                        else
                            p:Hide()
                        end
                    end)
                    -- Also intercept SetAlpha to keep it at 0
                    local alphaGuard = false
                    hooksecurefunc(realBtn, "SetAlpha", function(self, a)
                        if alphaGuard then return end
                        if a > 0 and self._vistaProxyHooked then
                            alphaGuard = true
                            self:SetAlpha(0)
                            alphaGuard = false
                        end
                    end)
                    -- Intercept SetPoint to keep alpha at 0 after repositioning
                    hooksecurefunc(realBtn, "SetPoint", function(self)
                        if self._vistaProxyHooked then
                            C_Timer.After(0, function()
                                if self._vistaProxyHooked and not alphaGuard then
                                    alphaGuard = true
                                    self:SetAlpha(0)
                                    alphaGuard = false
                                end
                            end)
                        end
                    end)
                end

                -- Immediate sync + delayed syncs (Blizzard may not have set state yet on first login)
                SyncProxyToReal()
                C_Timer.After(0.1, SyncProxyToReal)
                C_Timer.After(1.0, SyncProxyToReal)
                C_Timer.After(3.0, SyncProxyToReal)
            else
                -- No real button found at all — stay hidden
                proxy:Hide()
            end
        end


        -- Apply initial show/mouseover state
        -- Conditional buttons (queue) are managed by their event listener above
        if not def.isConditional then
            if not getShow() then
                proxy:Hide()
            elseif getMouseover() then
                proxy:Show(); proxy:SetAlpha(0)
            else
                proxy:Show(); proxy:SetAlpha(1)
            end
        end

        defaultProxies[#defaultProxies + 1] = proxy
    end
end


-- ============================================================================
-- BUTTON COLLECTOR  (blacklist / whitelist)

-- Buttons that are pure Vista-internal frames — never touch these
local INTERNAL_BLACKLIST = {
    ["HorizonSuiteVistaDecor"]       = true,
    ["HorizonSuiteVistaButtonBar"]   = true,
    ["HorizonSuiteVistaDrawerBtn"]   = true,
    ["MinimapBackdrop"]              = true,
    ["MinimapCompassTexture"]        = true,
    ["MinimapBorder"]                = true,
    ["MinimapBorderTop"]             = true,
    ["MinimapNorthTag"]              = true,
    ["MinimapZoneTextButton"]        = true,
    ["MiniMapWorldMapButton"]        = true,
    -- Zoom buttons: handled separately by StripBlizzardChrome, never collect
    ["MinimapZoomIn"]                = true,
    ["MinimapZoomOut"]               = true,
    -- Addon compartment button: always hidden, never managed
    ["AddonCompartmentFrame"]        = true,
    ["AddonCompartmentFrameButton"]  = true,
}

local BLIZZARD_DEFAULT_BUTTONS = {
    ["TimeManagerClockButton"]            = true,
    ["GameTimeFrame"]                     = true,
    ["MiniMapTracking"]                   = true,
    ["MinimapTrackingFrame"]              = true,
    ["MiniMapTrackingButton"]             = true,
    ["MiniMapTrackingIcon"]               = true,
    ["GarrisonLandingPageMinimapButton"]  = true,
    ["ExpansionLandingPageMinimapButton"] = true,
    ["MiniMapInstanceDifficulty"]         = true,
    ["QueueStatusMinimapButton"]          = true,
    ["QueueStatusButton"]                 = true,
    ["MiniMapBattlefieldFrame"]           = true,
}

-- Per-button original state (parent + anchor + strata) saved before Vista moves them.
-- Used to restore buttons precisely when management is disabled.
local buttonOriginalState = {}  -- [btn] = { parent, point, relFrame, relPoint, x, y, strata }

local function SaveButtonState(btn)
    if buttonOriginalState[btn] then return end  -- already saved
    local parent = btn:GetParent()
    local point, relFrame, relPoint, x, y = btn:GetPoint()
    local ok, strata = pcall(function() return btn:GetFrameStrata() end)
    buttonOriginalState[btn] = {
        parent   = parent,
        point    = point    or "CENTER",
        relFrame = relFrame or parent,
        relPoint = relPoint or "CENTER",
        x        = x or 0,
        y        = y or 0,
        strata   = (ok and strata) or "MEDIUM",
    }
end

-- Reset button brightness without hiding decorative textures.
-- Used when buttons stay on the minimap (mouseover bar, unmanaged).
local function ResetButtonBrightness(btn)
    pcall(function() btn:SetAlpha(1) end)
    -- Restore the LibDBIcon decorative ring/background textures
    pcall(function() if btn.background then btn.background:Show() end end)
    pcall(function() if btn.border then btn.border:Show() end end)
    -- Ensure the icon texture itself is full brightness
    pcall(function()
        if btn.icon then
            btn.icon:SetAlpha(1)
            btn.icon:SetDesaturated(false)
            btn.icon:SetVertexColor(1, 1, 1, 1)
        end
    end)
    -- Walk all regions and reset alpha/desaturation
    pcall(function()
        for _, region in ipairs({ btn:GetRegions() }) do
            if region then
                pcall(function() region:SetDesaturated(false) end)
                pcall(function() region:SetAlpha(1) end)
                pcall(function() region:SetVertexColor(1, 1, 1, 1) end)
            end
        end
    end)
end

-- Reset button for use inside a panel (drawer / right-click).
-- Instead of placing the original LibDBIcon button (which has dark rendering issues),
-- we create a clean proxy button that copies the icon texture and forwards events.
local proxyButtonCache = {}  -- [originalBtn] = proxyBtn

local function GetOrCreateProxyButton(originalBtn, parent)
    if proxyButtonCache[originalBtn] then
        local proxy = proxyButtonCache[originalBtn]
        proxy:SetParent(parent)
        return proxy
    end

    local proxy = CreateFrame("Button", nil, parent)
    proxy:SetSize(GetAddonBtnSize(), GetAddonBtnSize())
    proxy._vistaOriginalBtn = originalBtn

    -- Create our own icon texture
    local proxyIcon = proxy:CreateTexture(nil, "ARTWORK")
    proxyIcon:SetAllPoints()
    proxy._vistaIcon = proxyIcon

    -- Extract icon texture from the original button
    local function UpdateProxyIcon()
        local tex = nil
        -- Try .icon first (LibDBIcon standard)
        if originalBtn.icon then
            tex = originalBtn.icon:GetTexture()
        end
        -- Fallback: scan regions for a texture with content
        if not tex then
            pcall(function()
                for _, region in ipairs({ originalBtn:GetRegions() }) do
                    if region and region:IsObjectType("Texture") then
                        local t = region:GetTexture()
                        if t and region ~= originalBtn.background and region ~= originalBtn.border then
                            tex = t
                            break
                        end
                    end
                end
            end)
        end
        if tex then
            proxyIcon:SetTexture(tex)
            -- Copy texcoords if available
            if originalBtn.icon then
                pcall(function()
                    proxyIcon:SetTexCoord(originalBtn.icon:GetTexCoord())
                end)
            end
        else
            proxyIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        proxyIcon:SetDesaturated(false)
        proxyIcon:SetAlpha(1)
        proxyIcon:SetVertexColor(1, 1, 1, 1)
    end

    UpdateProxyIcon()
    proxy._vistaUpdateIcon = UpdateProxyIcon

    -- Forward clicks to the original button
    proxy:SetScript("OnClick", function(self, button)
        -- The original btn may have dataObject (LibDBIcon)
        if originalBtn.dataObject then
            local dObj = originalBtn.dataObject
            if button == "LeftButton" then
                if dObj.OnClick then dObj.OnClick(originalBtn, button) end
            elseif button == "RightButton" then
                if dObj.OnClick then dObj.OnClick(originalBtn, button) end
            end
        else
            -- Fallback: simulate a click on the original
            pcall(function() originalBtn:Click(button) end)
        end
    end)
    proxy:RegisterForClicks("AnyUp")

    -- Forward tooltip
    proxy:SetScript("OnEnter", function(self)
        if originalBtn.dataObject then
            local dObj = originalBtn.dataObject
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            if dObj.OnTooltipShow then
                dObj.OnTooltipShow(GameTooltip)
            elseif dObj.text then
                GameTooltip:SetText(dObj.text)
            end
            GameTooltip:Show()
        else
            -- Try to fire original OnEnter
            pcall(function()
                local script = originalBtn:GetScript("OnEnter")
                if script then script(originalBtn) end
            end)
        end
    end)
    proxy:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        pcall(function()
            local script = originalBtn:GetScript("OnLeave")
            if script then script(originalBtn) end
        end)
    end)

    -- Highlight on hover
    local highlight = proxy:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.15)

    proxyButtonCache[originalBtn] = proxy
    return proxy
end

-- Hide all proxy buttons (used when switching modes)
local function HideAllProxyButtons()
    for _, proxy in pairs(proxyButtonCache) do
        proxy:Hide()
    end
end

local function RestoreButton(btn)
    local s = buttonOriginalState[btn]
    if not s then
        pcall(function() btn:SetParent(Minimap); btn:Show() end)
        ResetButtonBrightness(btn)
        return
    end
    pcall(function()
        btn:SetFrameStrata(s.strata or "MEDIUM")
        btn:SetParent(s.parent or Minimap)
        btn:ClearAllPoints()
        btn:SetPoint(s.point, s.relFrame or (s.parent or Minimap), s.relPoint, s.x, s.y)
        btn:Show()
    end)
    -- Restore .background/.border textures that ResetButtonForPanel may have hidden
    ResetButtonBrightness(btn)
end

local function ButtonPassesFilter(btn)
    local cName = btn:GetName()
    if cName and INTERNAL_BLACKLIST[cName] then return false end
    if cName and BLIZZARD_DEFAULT_BUTTONS[cName] then return false end

    local whitelist = GetButtonWhitelist()
    if whitelist and type(whitelist) == "table" then
        local hasAny = false
        for _ in pairs(whitelist) do hasAny = true; break end
        if hasAny and not whitelist[cName or ""] then return false end
    end
    return true
end


--- Scan button-like children of Minimap AND MinimapCluster for ADDON buttons only.
--- Only includes buttons that are currently shown (active addons).
local function ScanMinimapButtons()
    local result = {}
    local seen = {}

    local function tryAdd(child)
        if not child or seen[child] then return end
        if not child:IsObjectType("Button") then return end
        local cName = child:GetName()
        -- Skip hard-blacklisted frames
        if cName and INTERNAL_BLACKLIST[cName] then return end
        -- Skip Blizzard default buttons — handled separately
        if cName and BLIZZARD_DEFAULT_BUTTONS[cName] then return end
        -- Skip children of AddonCompartmentFrame
        local parent = child:GetParent()
        if parent then
            local pName = parent:GetName()
            if pName and (pName == "AddonCompartmentFrame" or pName:find("^AddonCompartment")) then return end
        end
        -- Only include currently-shown buttons (active addons register visible buttons)
        if not child:IsShown() then return end
        -- Size check: 10–100px covers most addon buttons
        local w, h = child:GetSize()
        if w >= 10 and w <= 100 and h >= 10 and h <= 100 then
            seen[child] = true
            result[#result + 1] = child
        end
    end

    -- Direct children of Minimap
    for _, child in ipairs({ Minimap:GetChildren() }) do
        tryAdd(child)
    end

    -- Children of MinimapCluster (many addons parent here)
    if MinimapCluster then
        for _, child in ipairs({ MinimapCluster:GetChildren() }) do
            if child ~= Minimap then
                tryAdd(child)
                -- One level deeper: Frame wrappers containing a Button
                if child:IsObjectType("Frame") and not child:IsObjectType("Button") then
                    for _, sub in ipairs({ child:GetChildren() }) do
                        tryAdd(sub)
                    end
                end
            end
        end
    end

    -- Children of MinimapBackdrop (some LibDBIcon buttons parent here)
    if MinimapBackdrop then
        for _, child in ipairs({ MinimapBackdrop:GetChildren() }) do
            tryAdd(child)
            if child:IsObjectType("Frame") and not child:IsObjectType("Button") then
                for _, sub in ipairs({ child:GetChildren() }) do
                    tryAdd(sub)
                end
            end
        end
    end

    -- LibDBIcon buttons parented to UIParent or other frames:
    -- scan _G for known LibDBIcon prefix pattern
    for gName, gObj in pairs(_G) do
        if type(gName) == "string" and gName:match("^LibDBIcon[%d]*_") then
            if type(gObj) == "table" and type(gObj.IsObjectType) == "function" then
                pcall(function() tryAdd(gObj) end)
            end
        end
    end


    return result
end

local function CreateCollectorBar()
    collectorBar = CreateFrame("Frame", "HorizonSuiteVistaButtonBar", decor)
    collectorBar:SetPoint("TOP", diffText, "BOTTOM", 0, -4)
    collectorBar:SetSize(1, GetAddonBtnSize())
    collectorBar:SetAlpha(0)
    collectorBar:Show()
end


local function LayoutCollectedButtons()
    if not collectorBar then return end
    local n = #collectedButtons
    local btnSz = GetAddonBtnSize()
    if n == 0 then collectorBar:SetWidth(1); collectorBar:SetHeight(btnSz); return end

    -- Max columns = how many buttons fit within the current minimap width
    local mapSz = GetMapSize()
    local maxCols = math.max(1, math.floor((mapSz + BTN_GAP) / (btnSz + BTN_GAP)))
    local cols = math.min(n, maxCols)
    local rows = math.ceil(n / cols)

    local totalWidth  = cols * btnSz + (cols - 1) * BTN_GAP
    local totalHeight = rows * btnSz + (rows - 1) * BTN_GAP
    collectorBar:SetSize(totalWidth, totalHeight)

    for i, btn in ipairs(collectedButtons) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        btn:ClearAllPoints()
        btn:SetParent(collectorBar)
        btn:SetSize(btnSz, btnSz)
        btn:SetPoint("TOPLEFT", collectorBar, "TOPLEFT",
            col * (btnSz + BTN_GAP),
            -(row * (btnSz + BTN_GAP)))
        btn:SetFrameLevel(collectorBar:GetFrameLevel() + 2)
        ResetButtonBrightness(btn)
        btn:Show()
    end

    collectorBar:EnableMouse(true)
    collectorBar:SetScript("OnEnter", function() hoverTarget = 1; hoverElapsed = 0 end)
    collectorBar:SetScript("OnLeave", function()
        if Minimap:IsMouseOver() or collectorBar:IsMouseOver() then return end
        for _, b in ipairs(collectedButtons) do if b:IsMouseOver() then return end end
        hoverTarget = 0; hoverElapsed = 0
    end)

    for _, btn in ipairs(collectedButtons) do
        if not hookedButtons[btn] then
            hookedButtons[btn] = true
            btn:HookScript("OnEnter", function() hoverTarget = 1; hoverElapsed = 0 end)
            btn:HookScript("OnLeave", function()
                if Minimap:IsMouseOver() or collectorBar:IsMouseOver() then return end
                for _, b in ipairs(collectedButtons) do if b:IsMouseOver() then return end end
                hoverTarget = 0; hoverElapsed = 0
            end)
        end
    end
end

-- ============================================================================
-- DRAWER BUTTON
-- ============================================================================

local function UpdateDrawerPanelLayout()
    if not drawerPanel then return end
    local n = #drawerPanelButtons
    if n == 0 then drawerPanel:SetSize(1, 1); return end

    local PAD = 6
    local GAP = 4
    local btnSz = GetAddonBtnSize()
    local cols = math.min(n, 5)
    local rows = math.ceil(n / cols)
    drawerPanel:SetSize(
        cols * btnSz + (cols - 1) * GAP + PAD * 2,
        rows * btnSz + (rows - 1) * GAP + PAD * 2)

    for idx, originalBtn in ipairs(drawerPanelButtons) do
        local col = (idx - 1) % cols
        local row = math.floor((idx - 1) / cols)
        -- Hide original, show proxy
        originalBtn:Hide()
        local proxy = GetOrCreateProxyButton(originalBtn, drawerPanel)
        proxy:ClearAllPoints()
        proxy:SetSize(btnSz, btnSz)
        proxy:SetFrameLevel(drawerPanel:GetFrameLevel() + 10 + idx)
        proxy:SetPoint("TOPLEFT", drawerPanel, "TOPLEFT",
            PAD + col * (btnSz + GAP),
            -(PAD + row * (btnSz + GAP)))
        proxy._vistaUpdateIcon()
        proxy:Show()
    end
end

local function CreateDrawerButton()
    if drawerButton then drawerButton:Show(); return end

    drawerButton = CreateFrame("Button", "HorizonSuiteVistaDrawerBtn", UIParent)
    drawerButton:SetSize(GetAddonBtnSize() + 4, GetAddonBtnSize() + 4)
    drawerButton:SetFrameStrata("HIGH")
    drawerButton:SetClampedToScreen(true)
    drawerButton:SetMovable(true)
    drawerButton:RegisterForDrag("LeftButton")  -- use WoW drag API, not manual tracking

    local dbx = DB("vistaDrawerBtnX", nil)
    local dby = DB("vistaDrawerBtnY", nil)
    if dbx and dby then
        -- Saved as CENTER offset relative to Minimap CENTER
        drawerButton:SetPoint("CENTER", Minimap, "CENTER", dbx, dby)
    else
        drawerButton:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -10)
    end

    -- Visuals
    local bg = drawerButton:CreateTexture(nil, "BACKGROUND")
    local dbR, dbG, dbB, dbA = GetPanelBgColor()
    bg:SetAllPoints(); bg:SetColorTexture(dbR, dbG, dbB, dbA)
    drawerButton._bg = bg

    local icon = drawerButton:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER"); icon:SetSize(18, 18)
    icon:SetTexture("Interface\\MINIMAP\\TRACKING\\Recycle")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    drawerButton.icon = icon

    local brR, brG, brB, brA = GetPanelBorderColor()
    local border = drawerButton:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", -1, 1); border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(brR, brG, brB, brA)
    drawerButton._border = border

    drawerButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("Minimap Buttons")
        GameTooltip:AddLine("Click to toggle drawer", 0.7, 0.7, 0.7)
        if not GetButtonDrawerLocked() then
            GameTooltip:AddLine("Drag to move", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    drawerButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Drag via OnDragStart / OnDragStop (clean, no sticky-mouse bug)
    drawerButton:SetScript("OnDragStart", function(self)
        if not GetButtonDrawerLocked() and not InCombatLockdown() then
            drawerDragging = true
            self:StartMoving()
        end
    end)
    drawerButton:SetScript("OnDragStop", function(self)
        drawerDragging = false
        self:StopMovingOrSizing()
        -- Save as CENTER offset relative to Minimap CENTER so it follows minimap
        local mx, my = Minimap:GetCenter()
        local bx, by = self:GetCenter()
        if mx and my and bx and by then
            local ox, oy = bx - mx, by - my
            SetDB("vistaDrawerBtnX", ox)
            SetDB("vistaDrawerBtnY", oy)
            -- Re-anchor to Minimap
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", ox, oy)
        end
    end)

    -- Click to toggle the drawer (only fires when not dragging)
    drawerButton:SetScript("OnClick", function(self, button)
        if button ~= "LeftButton" or drawerDragging then return end
        drawerOpen = not drawerOpen
        if drawerPanel then
            if drawerOpen then drawerPanel:Show() else drawerPanel:Hide() end
        end
    end)

    -- Drawer panel: separate background child frame to avoid overlapping button icons
    drawerPanel = CreateFrame("Frame", nil, UIParent)
    drawerPanel:SetFrameStrata("FULLSCREEN_DIALOG")
    drawerPanel:SetFrameLevel(1)
    drawerPanel:SetClampedToScreen(true)

    -- Background is a child frame at very low level
    local dpBgFrame = CreateFrame("Frame", nil, drawerPanel)
    dpBgFrame:SetAllPoints()
    dpBgFrame:SetFrameLevel(0)
    local dpBgR, dpBgG, dpBgB, dpBgA = GetPanelBgColor()
    local dpBg = dpBgFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    dpBg:SetAllPoints(); dpBg:SetColorTexture(dpBgR, dpBgG, dpBgB, dpBgA)
    local dpBrR, dpBrG, dpBrB, dpBrA = GetPanelBorderColor()
    local dpBorderT = dpBgFrame:CreateTexture(nil, "BORDER"); dpBorderT:SetColorTexture(dpBrR, dpBrG, dpBrB, dpBrA)
    local dpBorderB = dpBgFrame:CreateTexture(nil, "BORDER"); dpBorderB:SetColorTexture(dpBrR, dpBrG, dpBrB, dpBrA)
    local dpBorderL = dpBgFrame:CreateTexture(nil, "BORDER"); dpBorderL:SetColorTexture(dpBrR, dpBrG, dpBrB, dpBrA)
    local dpBorderR = dpBgFrame:CreateTexture(nil, "BORDER"); dpBorderR:SetColorTexture(dpBrR, dpBrG, dpBrB, dpBrA)
    drawerPanel._bgTex = dpBg
    drawerPanel._borderTextures = { dpBorderT, dpBorderB, dpBorderL, dpBorderR }
    dpBorderT:SetPoint("TOPLEFT",0,0); dpBorderT:SetPoint("TOPRIGHT",0,0); dpBorderT:SetHeight(1)
    dpBorderB:SetPoint("BOTTOMLEFT",0,0); dpBorderB:SetPoint("BOTTOMRIGHT",0,0); dpBorderB:SetHeight(1)
    dpBorderL:SetPoint("TOPLEFT",0,0); dpBorderL:SetPoint("BOTTOMLEFT",0,0); dpBorderL:SetWidth(1)
    dpBorderR:SetPoint("TOPRIGHT",0,0); dpBorderR:SetPoint("BOTTOMRIGHT",0,0); dpBorderR:SetWidth(1)

    drawerPanel:SetPoint("BOTTOMLEFT", drawerButton, "TOPLEFT", 0, 4)
    drawerPanel:Hide()
    drawerOpen = false
end

local function DestroyDrawerButton()
    if drawerButton then
        drawerButton:Hide()
        if drawerPanel then drawerPanel:Hide() end
    end
end

-- ============================================================================
-- RIGHT-CLICK PANEL
-- ============================================================================

local function CreateRightClickPanel()
    if rightClickPanel then return end

    rightClickPanel = CreateFrame("Frame", nil, UIParent)
    rightClickPanel:SetFrameStrata("FULLSCREEN_DIALOG")
    rightClickPanel:SetFrameLevel(1)
    rightClickPanel:SetClampedToScreen(true)
    rightClickPanel:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -4)
    rightClickPanel:Hide()
    rightClickVisible = false

    -- Background is a child frame at very low level
    local rcBgFrame = CreateFrame("Frame", nil, rightClickPanel)
    rcBgFrame:SetAllPoints()
    rcBgFrame:SetFrameLevel(0)
    local rcBgR, rcBgG, rcBgB, rcBgA = GetPanelBgColor()
    local rcBg = rcBgFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    rcBg:SetAllPoints(); rcBg:SetColorTexture(rcBgR, rcBgG, rcBgB, rcBgA)
    local rcBrR, rcBrG, rcBrB, rcBrA = GetPanelBorderColor()
    local rcBT = rcBgFrame:CreateTexture(nil, "BORDER"); rcBT:SetColorTexture(rcBrR, rcBrG, rcBrB, rcBrA)
    local rcBB = rcBgFrame:CreateTexture(nil, "BORDER"); rcBB:SetColorTexture(rcBrR, rcBrG, rcBrB, rcBrA)
    local rcBL = rcBgFrame:CreateTexture(nil, "BORDER"); rcBL:SetColorTexture(rcBrR, rcBrG, rcBrB, rcBrA)
    local rcBR = rcBgFrame:CreateTexture(nil, "BORDER"); rcBR:SetColorTexture(rcBrR, rcBrG, rcBrB, rcBrA)
    rightClickPanel._bgTex = rcBg
    rightClickPanel._borderTextures = { rcBT, rcBB, rcBL, rcBR }
    rcBT:SetPoint("TOPLEFT",0,0); rcBT:SetPoint("TOPRIGHT",0,0); rcBT:SetHeight(1)
    rcBB:SetPoint("BOTTOMLEFT",0,0); rcBB:SetPoint("BOTTOMRIGHT",0,0); rcBB:SetHeight(1)
    rcBL:SetPoint("TOPLEFT",0,0); rcBL:SetPoint("BOTTOMLEFT",0,0); rcBL:SetWidth(1)
    rcBR:SetPoint("TOPRIGHT",0,0); rcBR:SetPoint("BOTTOMRIGHT",0,0); rcBR:SetWidth(1)

    rightClickPanel:SetScript("OnLeave", function()
        C_Timer.After(0.3, function()
            if rightClickPanel and not rightClickPanel:IsMouseOver() then
                rightClickPanel:Hide()
                rightClickVisible = false
            end
        end)
    end)
end

local function LayoutRightClickPanel(buttons)
    if not rightClickPanel then return end
    local n = #buttons
    if n == 0 then rightClickPanel:Hide(); rightClickVisible = false; return end

    local PAD = 6; local GAP = 4
    local btnSz = GetAddonBtnSize()
    local cols = math.min(n, 5)
    local rows = math.ceil(n / cols)
    rightClickPanel:SetSize(
        cols * btnSz + (cols - 1) * GAP + PAD * 2,
        rows * btnSz + (rows - 1) * GAP + PAD * 2)

    for idx, originalBtn in ipairs(buttons) do
        local col = (idx - 1) % cols
        local row = math.floor((idx - 1) / cols)
        -- Hide original, show proxy
        originalBtn:Hide()
        local proxy = GetOrCreateProxyButton(originalBtn, rightClickPanel)
        proxy:ClearAllPoints()
        proxy:SetSize(btnSz, btnSz)
        proxy:SetFrameLevel(rightClickPanel:GetFrameLevel() + 10 + idx)
        proxy:SetPoint("TOPLEFT", rightClickPanel, "TOPLEFT",
            PAD + col * (btnSz + GAP),
            -(PAD + row * (btnSz + GAP)))
        proxy._vistaUpdateIcon()
        proxy:Show()
    end
end

local function RestoreButtonToMinimap(btn)
    RestoreButton(btn)
end

-- ============================================================================
-- MAIN BUTTON COLLECTION DISPATCH
-- ============================================================================

-- Master registry of all buttons Vista has ever taken ownership of.
-- This persists across CollectMinimapButtons calls so we can always restore them.
local allManagedButtons = {}  -- [btn] = true

-- The authoritative list lives on Vista._discoveredNames (persists across calls).
-- Initialized here; populated by CollectMinimapButtons each time it runs.
Vista._discoveredNames = Vista._discoveredNames or {}

local function CollectMinimapButtons()
    -- Hide any proxy buttons from previous layout
    HideAllProxyButtons()

    -- Step 1: restore buttons currently in our panels to their natural state
    -- so ScanMinimapButtons can find them again (they may be parented to our panel)
    for btn in pairs(allManagedButtons) do
        pcall(function()
            -- Re-parent to Minimap temporarily so the scan can see them
            local s = buttonOriginalState[btn]
            if s then
                btn:SetParent(s.parent or Minimap)
                btn:SetPoint(s.point, s.relFrame or s.parent or Minimap, s.relPoint, s.x, s.y)
                btn:Show()
            end
        end)
    end

    -- Scan for addon buttons
    local allCandidates = ScanMinimapButtons()

    -- Save original state for newly-discovered buttons
    for _, btn in ipairs(allCandidates) do
        SaveButtonState(btn)
        allManagedButtons[btn] = true
    end

    -- Cache candidate names for the options filter list (only update when scan found buttons)
    if #allCandidates > 0 then
        local newNames = {}
        local seen = {}
        for _, btn in ipairs(allCandidates) do
            local cName = btn.GetName and btn:GetName()
            if cName and not seen[cName] then
                seen[cName] = true
                newNames[#newNames + 1] = cName
            end
        end
        table.sort(newNames)
        local oldCount = Vista._discoveredNames and #Vista._discoveredNames or 0
        Vista._discoveredNames = newNames

        -- Rebuild VistaButtons options tab when list changes (e.g. 0 → N on first scan)
        if #newNames ~= oldCount and addon.OptionsPanel_RebuildCategory then
            C_Timer.After(0, function()
                addon.OptionsPanel_RebuildCategory("VistaButtons")
            end)
        end
    end

    wipe(collectedButtons)
    wipe(drawerPanelButtons)

    if not GetButtonHandleButtons() then
        -- Management off — restore all addon buttons to original positions
        HideAllProxyButtons()
        for btn in pairs(allManagedButtons) do
            RestoreButton(btn)
        end
        -- Clear management registry so next enable starts fresh
        wipe(allManagedButtons)
        DestroyDrawerButton()
        if rightClickPanel then rightClickPanel:Hide(); rightClickVisible = false end
        if collectorBar then collectorBar:SetWidth(1) end
        return
    end

    local mode = GetButtonMode()

    -- Separate: passes whitelist filter vs hidden everywhere
    local managed = {}
    for _, btn in ipairs(allCandidates) do
        if ButtonPassesFilter(btn) then
            managed[#managed + 1] = btn
        else
            pcall(function() btn:Hide() end)
        end
    end


    if mode == BTN_MODE_MOUSEOVER then
        -- Mouseover mode uses original buttons directly (with decorative textures)
        HideAllProxyButtons()
        DestroyDrawerButton()
        if rightClickPanel then rightClickPanel:Hide(); rightClickVisible = false end
        for _, btn in ipairs(managed) do
            collectedButtons[#collectedButtons + 1] = btn
        end
        LayoutCollectedButtons()

    elseif mode == BTN_MODE_RIGHTCLICK then
        DestroyDrawerButton()
        if not rightClickPanel then CreateRightClickPanel() end
        for _, btn in ipairs(managed) do
            collectedButtons[#collectedButtons + 1] = btn
            btn:Hide()  -- hide initially; shown when panel opens
        end
        LayoutRightClickPanel(collectedButtons)
        if collectorBar then collectorBar:SetWidth(1) end

    elseif mode == BTN_MODE_DRAWER then
        if rightClickPanel then rightClickPanel:Hide(); rightClickVisible = false end
        CreateDrawerButton()
        for _, btn in ipairs(managed) do
            drawerPanelButtons[#drawerPanelButtons + 1] = btn
            btn:Hide()  -- hide initially; shown when drawer opens
        end
        UpdateDrawerPanelLayout()
        if collectorBar then collectorBar:SetWidth(1) end
    end
end

-- ============================================================================
-- HOVER / ON-UPDATE
-- ============================================================================

local function OnHoverUpdate(_, elapsed)
    UpdateCoords(nil, elapsed)
    UpdateTimeText(nil, elapsed)

    -- Only animate the collector bar in mouseover mode
    if GetButtonMode() ~= BTN_MODE_MOUSEOVER then return end
    if not collectorBar or #collectedButtons == 0 then return end
    if barAlpha == hoverTarget then return end

    hoverElapsed = hoverElapsed + elapsed
    local t = math.min(hoverElapsed / FADE_DUR, 1)
    if hoverTarget > barAlpha then
        barAlpha = easeOut(t) * hoverTarget
    else
        barAlpha = 1 - easeOut(t)
        if barAlpha < 0 then barAlpha = 0 end
    end
    if t >= 1 then barAlpha = hoverTarget end
    collectorBar:SetAlpha(barAlpha)
end

-- ============================================================================
-- APPLY COLORS  (lightweight; called during live color-picker drags)
-- ============================================================================

function Vista.ApplyColors()
    if not decor then return end
    ApplyBorderTextures()
    if zoneText  then zoneText:SetTextColor(GetZoneColor())   end
    if coordText then coordText:SetTextColor(GetCoordColor()) end
    if timeText  then timeText:SetTextColor(GetTimeColor())   end
    if diffText  then diffText:SetTextColor(GetDiffColor())   end
    if drawerButton then
        if drawerButton._bg     then drawerButton._bg:SetColorTexture(GetPanelBgColor())     end
        if drawerButton._border then drawerButton._border:SetColorTexture(GetPanelBorderColor()) end
    end
    local bgR, bgG, bgB, bgA = GetPanelBgColor()
    local brR, brG, brB, brA = GetPanelBorderColor()
    if drawerPanel and drawerPanel._bgTex then
        drawerPanel._bgTex:SetColorTexture(bgR, bgG, bgB, bgA)
    end
    if drawerPanel and drawerPanel._borderTextures then
        for _, tex in ipairs(drawerPanel._borderTextures) do tex:SetColorTexture(brR, brG, brB, brA) end
    end
    if rightClickPanel and rightClickPanel._bgTex then
        rightClickPanel._bgTex:SetColorTexture(bgR, bgG, bgB, bgA)
    end
    if rightClickPanel and rightClickPanel._borderTextures then
        for _, tex in ipairs(rightClickPanel._borderTextures) do tex:SetColorTexture(brR, brG, brB, brA) end
    end
end

-- ============================================================================
-- APPLY OPTIONS  (called whenever any Vista DB key changes)
-- ============================================================================

function Vista.ApplyOptions()
    if not decor then return end

    -- Lock state
    Minimap:SetMovable(not DB("vistaLock", false))

    -- Map size  — resize Minimap itself, not just the decor overlay
    local sz = GetMapSize()
    Minimap:SetSize(sz, sz)
    Minimap:SetMaskTexture(GetCircular() and MASK_CIRCULAR or MASK_SQUARE)
    -- Force the map texture to redraw immediately by re-setting the current zoom level.
    pcall(function()
        local zoom = Minimap:GetZoom()
        if zoom then Minimap:SetZoom(zoom) end
    end)
    -- decor is SetAllPoints(Minimap) so it follows automatically

    -- Border
    ApplyBorderTextures()

    -- Zone text
    if zoneText and decor._zoneContainer then
        local show = GetShowZone()
        local fp, fs = GetZoneFont(), GetZoneSize()
        zoneText:SetFont(fp, fs, "OUTLINE")
        zoneShadow:SetFont(fp, fs, "OUTLINE")
        zoneText:SetTextColor(GetZoneColor())
        zoneText:SetShown(show); zoneShadow:SetShown(show)
        decor._zoneContainer:SetShown(show)
        decor._zoneContainer:SetWidth(sz)
        if not GetElemLocked("zone") then
            decor._zoneContainer:ClearAllPoints()
            decor._zoneContainer:SetPoint("TOP", Minimap, "BOTTOM", GetZoneOffsetX(), GetZoneOffsetY())
        end
        decor._zoneContainer:SetMovable(not GetElemLocked("zone"))
    end

    -- Coord text
    if coordText and decor._coordContainer then
        local show = GetShowCoord()
        local fp, fs = GetCoordFont(), GetCoordSize()
        coordText:SetFont(fp, fs, "OUTLINE")
        coordShadow:SetFont(fp, fs, "OUTLINE")
        coordText:SetTextColor(GetCoordColor())
        coordText:SetShown(show); coordShadow:SetShown(show)
        decor._coordContainer:SetShown(show)
        if not GetElemLocked("coord") then
            decor._coordContainer:ClearAllPoints()
            decor._coordContainer:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", GetCoordOffsetX(), GetCoordOffsetY())
        end
        decor._coordContainer:SetMovable(not GetElemLocked("coord"))
    end

    -- Time text
    if timeText and decor._timeContainer then
        local show = GetShowTime()
        local fp, fs = GetTimeFont(), GetTimeSize()
        timeText:SetFont(fp, fs, "OUTLINE")
        timeShadow:SetFont(fp, fs, "OUTLINE")
        timeText:SetTextColor(GetTimeColor())
        timeText:SetShown(show); timeShadow:SetShown(show)
        decor._timeContainer:SetShown(show)
        if not GetElemLocked("time") then
            decor._timeContainer:ClearAllPoints()
            decor._timeContainer:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", GetTimeOffsetX(), GetTimeOffsetY())
        end
        decor._timeContainer:SetMovable(not GetElemLocked("time"))
    end

    -- Diff text width tracks map size
    if diffText then
        diffText:SetWidth(sz); diffShadow:SetWidth(sz)
        diffText:SetTextColor(GetDiffColor())
    end

    -- Collector bar anchors below zone/diff text (location name)
    if collectorBar then
        collectorBar:ClearAllPoints()
        collectorBar:SetPoint("TOP", diffText, "BOTTOM", 0, -4)
    end

    -- Rebuild default button proxies (tracking, calendar) — show/hide based on per-button toggles
    CreateDefaultButtonProxies()

    -- Apply zoom button visibility / mouseover + size
    if zoomInBtn and zoomOutBtn then
        local zoomSz = GetZoomBtnSize()
        local zoomFontSz = math.max(10, math.floor(zoomSz * 0.875))
        zoomInBtn:SetSize(zoomSz, zoomSz)
        zoomOutBtn:SetSize(zoomSz, zoomSz)
        if zoomInBtn._label then zoomInBtn._label:SetFont(FONT_PATH_DEFAULT, zoomFontSz, "OUTLINE") end
        if zoomOutBtn._label then zoomOutBtn._label:SetFont(FONT_PATH_DEFAULT, zoomFontSz, "OUTLINE") end
        local showZoom = GetShowZoomBtns()
        local moZoom   = GetMouseoverZoomBtns()
        if not showZoom then
            zoomInBtn:Hide(); zoomOutBtn:Hide()
        elseif moZoom then
            zoomInBtn:Show();  zoomOutBtn:Show()
            zoomInBtn:SetAlpha(0); zoomOutBtn:SetAlpha(0)
        else
            zoomInBtn:Show();  zoomOutBtn:Show()
            zoomInBtn:SetAlpha(1); zoomOutBtn:SetAlpha(1)
        end
    end

    -- Apply mail indicator size
    if mailFrame then
        local mailSz = GetMailIconSize()
        mailFrame:SetSize(mailSz, mailSz)
    end

    -- Apply drawer button size
    if drawerButton then
        local addonSz = GetAddonBtnSize()
        drawerButton:SetSize(addonSz + 4, addonSz + 4)
        -- Update drawer button colors
        if drawerButton._bg then drawerButton._bg:SetColorTexture(GetPanelBgColor()) end
        if drawerButton._border then drawerButton._border:SetColorTexture(GetPanelBorderColor()) end
    end

    -- Apply panel backdrop/border colors
    local bgR, bgG, bgB, bgA = GetPanelBgColor()
    local brR, brG, brB, brA = GetPanelBorderColor()
    if drawerPanel and drawerPanel._bgTex then
        drawerPanel._bgTex:SetColorTexture(bgR, bgG, bgB, bgA)
    end
    if drawerPanel and drawerPanel._borderTextures then
        for _, tex in ipairs(drawerPanel._borderTextures) do tex:SetColorTexture(brR, brG, brB, brA) end
    end
    if rightClickPanel and rightClickPanel._bgTex then
        rightClickPanel._bgTex:SetColorTexture(bgR, bgG, bgB, bgA)
    end
    if rightClickPanel and rightClickPanel._borderTextures then
        for _, tex in ipairs(rightClickPanel._borderTextures) do tex:SetColorTexture(brR, brG, brB, brA) end
    end

    -- Apply proxy button sizes
    for _, p in ipairs(defaultProxies) do
        if p and p._vistaKey then
            local pSz = GetProxyBtnSizeForKey(p._vistaKey)
            p:SetSize(pSz, pSz)
        end
    end

    -- Re-run addon button collection to respect mode/filter/manage changes
    CollectMinimapButtons()
    C_Timer.After(0.05, CollectMinimapButtons)
end

-- ============================================================================
-- INIT / DISABLE
-- ============================================================================

function Vista.Init()
    if not Minimap or not MinimapCluster then return end

    proxy.SetFrameStrata(Minimap, "LOW")
    proxy.SetFrameLevel(Minimap, 2)
    pcall(function()
        proxy.SetFixedFrameStrata(Minimap, true)
        proxy.SetFixedFrameLevel(Minimap, true)
    end)

    proxy.SetParent(Minimap, UIParent)

    if hooksecurefunc then
        setParentHook = function()
            if addon:IsModuleEnabled("vista") then
                proxy.SetParent(Minimap, UIParent)
            end
        end
        hooksecurefunc(Minimap, "SetParent", setParentHook)
    end

    MinimapCluster:EnableMouse(false)

    if MinimapBackdrop then
        MinimapBackdrop:ClearAllPoints()
        MinimapBackdrop:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
    end


    StripBlizzardChrome()
    -- Explicitly hide AddonCompartmentFrame — it's UIParent-parented and loads late
    pcall(function()
        if AddonCompartmentFrame then
            AddonCompartmentFrame:Hide()
            AddonCompartmentFrame:SetAlpha(0)
            AddonCompartmentFrame.Show = function() end
        end
    end)
    SuppressDefaultBlizzardButtons()
    CreateDecor()
    SetupMinimap()
    CreateZoomButtons()
    CreateMailIndicator()
    CreateCollectorBar()
    SuppressBlizzardMail()
    CreateDefaultButtonProxies()

    UpdateZoneText()
    UpdateDifficultyText()
    UpdateMailIndicator()
    ScheduleAutoZoom()

    decor:SetScript("OnUpdate", OnHoverUpdate)

    Minimap:HookScript("OnEnter", function()
        if GetButtonMode() == BTN_MODE_MOUSEOVER then
            hoverTarget = 1; hoverElapsed = 0
        end
    end)
    Minimap:HookScript("OnLeave", function()
        if collectorBar and collectorBar:IsMouseOver() then return end
        for _, btn in ipairs(collectedButtons) do
            if btn:IsMouseOver() then return end
        end
        hoverTarget = 0; hoverElapsed = 0
    end)

    -- Right-click toggles the panel (right-click mode only)
    Minimap:HookScript("OnMouseUp", function(_, button)
        if button == "RightButton" and GetButtonMode() == BTN_MODE_RIGHTCLICK then
            if not rightClickPanel then CreateRightClickPanel() end
            rightClickVisible = not rightClickVisible
            if rightClickVisible then
                LayoutRightClickPanel(collectedButtons)
                rightClickPanel:Show()
            else
                rightClickPanel:Hide()
            end
        end
    end)

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    eventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
    eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
    eventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
    eventFrame:RegisterEvent("PET_BATTLE_CLOSE")
    eventFrame:RegisterEvent("MINIMAP_UPDATE_ZOOM")
    eventFrame:RegisterEvent("ADDON_LOADED")

    eventFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" then
            C_Timer.After(0.5, function()
                StripBlizzardChrome()
                SuppressDefaultBlizzardButtons()
                HookMinimapClusterChildrenShow()
            end)
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            local function reStrip()
                StripBlizzardChrome()
                SuppressDefaultBlizzardButtons()
                HookMinimapClusterChildrenShow()
            end
            reStrip()
            C_Timer.After(2.0, function()
                reStrip()
                CollectMinimapButtons()
            end)
            UpdateZoneText(); UpdateDifficultyText(); UpdateMailIndicator()
        elseif event == "MINIMAP_UPDATE_ZOOM" then
            -- WoW sometimes re-shows zoom buttons after zoom level changes — keep them gone
            SuppressZoomButtons()
            pcall(function()
                if Minimap.ZoomIn then Minimap.ZoomIn:SetAlpha(0) end
                if Minimap.ZoomOut then Minimap.ZoomOut:SetAlpha(0) end
            end)
        elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
            UpdateZoneText(); UpdateDifficultyText()
        elseif event == "UPDATE_INSTANCE_INFO" then
            UpdateDifficultyText()
        elseif event == "UPDATE_PENDING_MAIL" then
            UpdateMailIndicator()
        elseif event == "PET_BATTLE_OPENING_START" then
            Minimap:Hide()
        elseif event == "PET_BATTLE_CLOSE" then
            if addon:IsModuleEnabled("vista") then Minimap:Show() end
        end
    end)

    local showMinimap = DB("vistaShowMinimap", true)
    if showMinimap ~= false then Minimap:Show() else Minimap:Hide() end
end

function Vista.Disable()
    if not Minimap or not MinimapCluster then return end
    if eventFrame then eventFrame:UnregisterAllEvents(); eventFrame:SetScript("OnEvent", nil) end
    if decor then decor:SetScript("OnUpdate", nil) end
    HideAllProxyButtons()
    DestroyDrawerButton()
    if not InCombatLockdown() then proxy.SetParent(Minimap, MinimapCluster) end
    ReloadUI()
end

function Vista.CollectButtons()
    CollectMinimapButtons()
    return #collectedButtons + #drawerPanelButtons
end

function Vista.ApplyScale()
    if not Minimap then return end
    local scale = DB("vistaScale", 1.0) or 1.0
    local moduleScale = (addon.GetModuleScale and addon.GetModuleScale("vista")) or 1
    proxy.SetScale(Minimap, scale * moduleScale)
end

-- Convert PascalCase / camelCase to a human-readable string.
-- "MyAddonButton" -> "My Addon", "DBMMinimapButton" -> "DBM"
local function HumanizePascalCase(str)
    if not str or str == "" then return str end
    -- Insert spaces before uppercase letters that follow a lowercase letter or digit
    local spaced = str:gsub("(%l)(%u)", "%1 %2"):gsub("(%d)(%u)", "%1 %2"):gsub("(%u+)(%u%l)", "%1 %2")
    -- Trim and collapse multiple spaces
    spaced = spaced:gsub("  +", " "):match("^%s*(.-)%s*$")
    return spaced
end

-- Try to get a human-readable addon name from a frame name or its addon owner.
local function GetAddonDisplayName(btn)
    local cName = btn:GetName() or ""

    -- Handle LibDBIcon pattern: "LibDBIcon10_AddonName" → extract "AddonName"
    local libDBSuffix = cName:match("^LibDBIcon[%d]*_(.+)$")
    if libDBSuffix then
        -- Try to find the addon title from C_AddOns using the suffix as the addon name
        if C_AddOns and C_AddOns.GetAddOnInfo then
            local numAddons = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
            for i = 1, numAddons do
                local name, title = C_AddOns.GetAddOnInfo(i)
                if name and name:lower() == libDBSuffix:lower() then
                    return title or name, cName
                end
            end
        end
        -- No exact match found — humanize the suffix directly
        return HumanizePascalCase(libDBSuffix), cName
    end

    -- Try C_AddOns.GetAddOnInfo for the addon that owns this frame
    if C_AddOns and C_AddOns.GetAddOnInfo then
        -- Walk loaded addons and check if cName contains the addon name
        local numAddons = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
        for i = 1, numAddons do
            local name, title = C_AddOns.GetAddOnInfo(i)
            if name and cName:lower():find(name:lower(), 1, true) then
                return title or name, cName
            end
        end
    end
    -- Fallback: strip common suffixes from frame name, then humanize
    local stripped = cName:gsub("MinimapButton$",""):gsub("Button$",""):gsub("Frame$",""):gsub("Minimap$","")
    if stripped ~= "" and stripped ~= cName then
        return HumanizePascalCase(stripped), cName
    end
    return HumanizePascalCase(cName), cName
end

function Vista.GetDiscoveredButtonNames()
    local list = Vista._discoveredNames
    if list and #list > 0 then return list end

    -- Fallback: build from allManagedButtons if scan hasn't run yet
    local names = {}
    local seen = {}
    for btn in pairs(allManagedButtons) do
        local cName = btn.GetName and btn:GetName()
        if cName and not seen[cName] then
            seen[cName] = true
            names[#names + 1] = cName
        end
    end
    table.sort(names)
    return names
end

-- Returns a display name for a given frame name (for options panel labels)
function Vista.GetButtonDisplayName(frameName)
    local btn = _G[frameName]
    if not btn then return frameName end
    local display = GetAddonDisplayName(btn)
    return display
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_HORIZONSUITEVISTA1 = "/mmm"
--- Reset minimap to default position (top-right) and clear saved position from DB.
--- Call from options Reset button or slash command.
function Vista.ResetMinimapPosition()
    if not InCombatLockdown() then
        proxy.ClearAllPoints(Minimap)
        proxy.SetPoint(Minimap, DEFAULT_POINT, UIParent, DEFAULT_RELPOINT, DEFAULT_X, DEFAULT_Y)
    end
    SetDB("vistaPoint", nil)
    SetDB("vistaRelPoint", nil)
    SetDB("vistaX", nil)
    SetDB("vistaY", nil)
end

SLASH_HORIZONSUITEVISTA2 = "/modernminimap"

SlashCmdList["HORIZONSUITEVISTA"] = function(msg)
    if not addon:IsModuleEnabled("vista") then
        print("|cFF00CCFFHorizon Suite:|r Vista module is disabled.")
        return
    end
    local cmd = (msg or ""):trim():lower()

    if cmd == "reset" then
        Vista.ResetMinimapPosition()
        print("|cFF00CCFFHorizon Suite Vista:|r Position reset.")
    elseif cmd == "toggle" then
        if InCombatLockdown() then return end
        local show = not (DB("vistaShowMinimap", true) ~= false)
        SetDB("vistaShowMinimap", show)
        if show then Minimap:Show() else Minimap:Hide() end
    elseif cmd == "lock" then
        local lock = not DB("vistaLock", false)
        SetDB("vistaLock", lock)
        Minimap:SetMovable(not lock)
    elseif cmd:find("^scale") then
        local val = tonumber(cmd:match("scale%s+(.+)"))
        if val then
            SetDB("vistaScale", math.max(0.5, math.min(2.0, val)))
            Vista.ApplyScale()
        end
    elseif cmd:find("^autozoom") then
        local val = tonumber(cmd:match("autozoom%s+(.+)"))
        if val then
            SetDB("vistaAutoZoom", math.max(0, math.min(30, math.floor(val))))
            ScheduleAutoZoom()
        end
    elseif cmd == "buttons" then
        local n = Vista.CollectButtons()
        print("|cFF00CCFFHorizon Suite Vista:|r Buttons found: " .. n)
    else
        print("|cFF00CCFFHorizon Suite Vista Commands:|r")
        print("  /mmm lock · /mmm scale X · /mmm autozoom X · /mmm reset · /mmm toggle · /mmm buttons")
    end
end

addon.Vista = Vista
