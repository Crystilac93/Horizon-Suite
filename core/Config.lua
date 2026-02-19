--[[
    Horizon Suite - Focus - Config
    Constants, colors, fonts, labels, and group order. Loaded after Utilities, before Core.
]]

local addon = _G.HorizonSuite
if not addon then return end

-- ============================================================================
-- CONFIGURATION (constants, colors, fonts, labels, group order)
-- ============================================================================

addon.HEADER_SIZE     = 16
addon.TITLE_SIZE      = 13
addon.OBJ_SIZE        = 11

addon.POOL_SIZE       = 25
addon.MAX_OBJECTIVES  = 7

addon.PANEL_WIDTH     = 260
addon.PANEL_X         = -40
addon.PANEL_Y         = -100
addon.PADDING              = 14
addon.CONTENT_RIGHT_PADDING = 20
addon.HEADER_HEIGHT         = 28
addon.MINIMAL_HEADER_HEIGHT = 24  -- Super-minimal mode bar height (chevron + O)
addon.DIVIDER_HEIGHT  = 2
addon.TITLE_SPACING   = 8
addon.OBJ_SPACING     = 2
addon.OBJ_INDENT      = 12
addon.COMPACT_TITLE_SPACING = 4
addon.COMPACT_OBJ_SPACING   = 1
addon.COMPACT_OBJ_INDENT    = 8
-- Delve-specific spacing (slightly more room between entries and objectives).
addon.DELVE_ENTRY_SPACING   = 12
addon.DELVE_OBJ_SPACING     = 4
addon.MIN_HEIGHT      = 50

addon.MAX_CONTENT_HEIGHT = 480
addon.SCROLL_STEP        = 30

addon.ITEM_BTN_SIZE   = 26
addon.ITEM_BTN_OFFSET = 4

addon.QUEST_TYPE_ICON_SIZE = 16
addon.QUEST_TYPE_ICON_GAP  = 4
addon.ICON_COLUMN_WIDTH    = addon.QUEST_TYPE_ICON_SIZE + addon.QUEST_TYPE_ICON_GAP
addon.BAR_LEFT_OFFSET      = 9
addon.TRACKED_OTHER_ZONE_ICON_SIZE = 12
addon.WQ_TIMER_BAR_HEIGHT = 6
addon.SCENARIO_TIMER_BAR_SLOTS = 5
addon.DELVE_TIER_ATLAS = "delves-scenario-flag"  -- Blizzard atlas for Delve tier/flag (TierFrame.Flag)

addon.SHADOW_OX       = 2
addon.SHADOW_OY       = -2
addon.SHADOW_A        = 0.8

-- Single source of truth for Focus fade/transition. All animation code reads from here.
addon.FOCUS_ANIM = {
    dur        = 0.4,
    stagger    = 0.05,
    slideInX   = 20,
    slideOutX  = 20,
    driftOutY  = 10,
}
addon.COMPLETE_HOLD   = 0.50
addon.HEIGHT_SPEED    = 8
addon.FLASH_DUR       = 0.55

-- Backward-compatible aliases (derived from FOCUS_ANIM).
addon.FOCUS_ANIM_DUR  = addon.FOCUS_ANIM.dur
addon.FADE_IN_DUR     = addon.FOCUS_ANIM.dur
addon.FADE_OUT_DUR    = addon.FOCUS_ANIM.dur
addon.COLLAPSE_DUR    = addon.FOCUS_ANIM.dur
addon.COMBAT_FADE_DUR = addon.FOCUS_ANIM.dur
addon.ENTRY_STAGGER   = addon.FOCUS_ANIM.stagger
addon.SLIDE_IN_X      = addon.FOCUS_ANIM.slideInX
addon.SLIDE_OUT_X     = addon.FOCUS_ANIM.slideOutX
addon.DRIFT_OUT_Y     = addon.FOCUS_ANIM.driftOutY

addon.HEADER_COLOR    = { 1, 1, 1 }
addon.DIVIDER_COLOR   = { 1, 1, 1, 0.5 }
addon.OBJ_COLOR       = { 0.78, 0.78, 0.78 }
addon.OBJ_DONE_COLOR  = { 0.30, 0.80, 0.30 }
addon.ZONE_SIZE       = 10
addon.ZONE_COLOR      = { 0.55, 0.65, 0.75 }

addon.QUEST_COLORS = {
    DEFAULT   = { 0.90, 0.90, 0.90 },
    NEARBY    = { 0.35, 0.75, 0.98 },  -- sky blue, matches SECTION_COLORS.NEARBY (Current Zone)
    CAMPAIGN  = { 1.00, 0.82, 0.20 },
    IMPORTANT = { 1.00, 0.45, 0.80 },  -- pink to match importantavailablequesticon
    LEGENDARY = { 1.00, 0.50, 0.00 },
    DUNGEON   = { 0.60, 0.40, 1.00 },  -- purple: party dungeon quests (Normal/Heroic/Mythic/M+)
    DELVES    = { 0.32, 0.72, 0.68 },  -- teal/seafoam: Delve steps (distinct from all other categories)
    SCENARIO  = { 0.38, 0.52, 0.88 },  -- deep blue: event/scenario steps (Twilight's Call etc.)
    WORLD     = { 0.60, 0.20, 1.00 },
    WEEKLY    = { 0.25, 0.88, 0.92 },  -- match quest-recurring-available icon (cyan)
    DAILY     = { 0.25, 0.88, 0.92 },  -- match quest-recurring-available icon (cyan)
    CALLING   = { 0.20, 0.60, 1.00 },
    COMPLETE  = { 0.20, 1.00, 0.40 },
    RARE      = { 1.00, 0.55, 0.25 },
    ACHIEVEMENT = { 0.78, 0.48, 0.22 },  -- bronze, trophy feel
    ENDEAVOR   = { 0.45, 0.95, 0.75 },  -- mint green (housing/endeavor)
    ENDEAVORS  = { 0.45, 0.95, 0.75 },  -- mint green (color matrix group default)
    DECOR      = { 0.65, 0.55, 0.45 },  -- warm brown (housing decor)
}

-- Presence-only (no Focus category): boss emote alert, discovery line
addon.PRESENCE_BOSS_EMOTE_COLOR = { 1, 0.2, 0.2 }
addon.PRESENCE_DISCOVERY_COLOR  = { 0.4, 1, 0.5 }

addon.SECTION_SIZE      = 10
addon.SECTION_SPACING   = 10
addon.SECTION_COLOR_A   = 1
addon.SECTION_POOL_SIZE = 8

function addon.GetDefaultFontPath()
    local path = GameFontNormal and GameFontNormal:GetFont()
    if path and path ~= "" then return path end
    return "Fonts\\FRIZQT__.TTF"
end

addon.FONT_PATH = addon.GetDefaultFontPath()
addon.HeaderFont  = CreateFont("HorizonSuiteHeaderFont")
addon.HeaderFont:SetFont(addon.FONT_PATH, addon.HEADER_SIZE, "OUTLINE")
addon.TitleFont   = CreateFont("HorizonSuiteTitleFont")
addon.TitleFont:SetFont(addon.FONT_PATH, addon.TITLE_SIZE, "OUTLINE")
addon.ObjFont     = CreateFont("HorizonSuiteObjFont")
addon.ObjFont:SetFont(addon.FONT_PATH, addon.OBJ_SIZE, "OUTLINE")
addon.ZoneFont    = CreateFont("HorizonSuiteZoneFont")
addon.ZoneFont:SetFont(addon.FONT_PATH, addon.ZONE_SIZE, "OUTLINE")
addon.SectionFont = CreateFont("HorizonSuiteSectionFont")
addon.SectionFont:SetFont(addon.FONT_PATH, addon.SECTION_SIZE, "OUTLINE")

addon.SECTION_LABELS = {
    DUNGEON   = "DUNGEON",
    DELVES    = "DELVES",
    SCENARIO  = "SCENARIO EVENTS",
    AVAILABLE = "AVAILABLE IN ZONE",
    NEARBY    = "CURRENT ZONE",
    CAMPAIGN  = "CAMPAIGN",
    IMPORTANT = "IMPORTANT",
    LEGENDARY = "LEGENDARY",
    WORLD     = "WORLD QUESTS",
    WEEKLY    = "WEEKLY QUESTS",
    DAILY     = "DAILY QUESTS",
    RARES     = "RARE BOSSES",
    ACHIEVEMENTS = "ACHIEVEMENTS",
    ENDEAVORS  = "ENDEAVORS",
    DECOR      = "DECOR",
    DEFAULT   = "QUESTS",
    COMPLETE  = "READY TO TURN IN",
}

addon.SECTION_COLORS = {
    DUNGEON   = { 0.60, 0.40, 1.00 },
    DELVES    = { 0.32, 0.72, 0.68 },  -- teal: Delve section
    SCENARIO  = { 0.38, 0.52, 0.88 },  -- deep blue: event/scenario steps
    AVAILABLE = { 0.25, 0.88, 0.92 },  -- cyan/teal (available to pick up)
    NEARBY    = { 0.35, 0.75, 0.98 },  -- sky blue (accepted, in zone)
    CAMPAIGN  = { 1.00, 0.82, 0.20 },
    IMPORTANT = { 1.00, 0.45, 0.80 },  -- pink to match importantavailablequesticon
    LEGENDARY = { 1.00, 0.50, 0.00 },
    WORLD     = { 0.60, 0.20, 1.00 },
    WEEKLY    = { 0.25, 0.88, 0.92 },  -- match quest-recurring-available icon (cyan)
    DAILY     = { 0.25, 0.88, 0.92 },  -- match quest-recurring-available icon (cyan)
    RARES     = { 1.00, 0.55, 0.25 },
    ACHIEVEMENTS = { 0.78, 0.48, 0.22 },  -- bronze
    ENDEAVORS  = { 0.45, 0.95, 0.75 },  -- mint green (housing/endeavor)
    DECOR      = { 0.65, 0.55, 0.45 },  -- warm brown (housing decor)
    DEFAULT   = { 0.70, 0.70, 0.70 },
    COMPLETE  = { 0.20, 1.00, 0.40 },
}

addon.GROUP_ORDER = { "DELVES", "SCENARIO", "ACHIEVEMENTS", "ENDEAVORS", "DECOR", "DUNGEON", "NEARBY", "COMPLETE", "WORLD", "WEEKLY", "DAILY", "RARES", "AVAILABLE", "CAMPAIGN", "IMPORTANT", "LEGENDARY", "DEFAULT" }

addon.GROUP_ORDER_PRESETS = {
    ["Collection Focused"] = { "ACHIEVEMENTS", "ENDEAVORS", "DECOR", "DELVES", "SCENARIO", "DUNGEON", "NEARBY", "COMPLETE", "WORLD", "WEEKLY", "DAILY", "RARES", "AVAILABLE", "CAMPAIGN", "IMPORTANT", "LEGENDARY", "DEFAULT" },
    ["Quest Focused"]      = { "COMPLETE", "NEARBY", "AVAILABLE", "DELVES", "SCENARIO", "DUNGEON", "WORLD", "WEEKLY", "DAILY", "CAMPAIGN", "IMPORTANT", "LEGENDARY", "RARES", "ACHIEVEMENTS", "ENDEAVORS", "DECOR", "DEFAULT" },
    ["Campaign Focused"]   = { "CAMPAIGN", "IMPORTANT", "LEGENDARY", "COMPLETE", "NEARBY", "DELVES", "SCENARIO", "DUNGEON", "AVAILABLE", "WORLD", "WEEKLY", "DAILY", "RARES", "ACHIEVEMENTS", "ENDEAVORS", "DECOR", "DEFAULT" },
    ["World / Rare Focused"] = { "WORLD", "WEEKLY", "DAILY", "RARES", "NEARBY", "COMPLETE", "AVAILABLE", "DELVES", "SCENARIO", "DUNGEON", "CAMPAIGN", "IMPORTANT", "LEGENDARY", "ACHIEVEMENTS", "ENDEAVORS", "DECOR", "DEFAULT" },
}

-- Category keys (enum-style) for consistent string usage across modules.
addon.CATEGORY_KEYS = {
    DUNGEON = "DUNGEON", DELVES = "DELVES", SCENARIO = "SCENARIO", AVAILABLE = "AVAILABLE", NEARBY = "NEARBY", CAMPAIGN = "CAMPAIGN",
    IMPORTANT = "IMPORTANT", LEGENDARY = "LEGENDARY", WORLD = "WORLD", WEEKLY = "WEEKLY",
    DAILY = "DAILY", RARES = "RARES", RARE = "RARE",     ACHIEVEMENT = "ACHIEVEMENT", ACHIEVEMENTS = "ACHIEVEMENTS",
    ENDEAVOR = "ENDEAVOR", ENDEAVORS = "ENDEAVORS",
    DECOR = "DECOR",
    DEFAULT = "DEFAULT", COMPLETE = "COMPLETE", CALLING = "CALLING",
}

-- Quest type atlas names (Blizzard texture atlases for quest icons).
addon.ATLAS_QUEST_TURNIN = "QuestTurnin"
addon.ATLAS_QUEST_CAMPAIGN = "Quest-Campaign-Available"
addon.ATLAS_QUEST_RECURRING = "quest-recurring-available"
addon.ATLAS_QUEST_IMPORTANT = "importantavailablequesticon"
addon.ATLAS_QUEST_LEGENDARY = "UI-QuestPoiLegendary-QuestBang"
addon.ATLAS_QUEST_PVP = "questlog-questtypeicon-pvp"

addon.CATEGORY_TO_GROUP = {
    COMPLETE  = "COMPLETE",
    DUNGEON   = "DUNGEON",
    DELVES    = "DELVES",
    SCENARIO  = "SCENARIO",
    LEGENDARY = "LEGENDARY",
    IMPORTANT = "IMPORTANT",
    CAMPAIGN  = "CAMPAIGN",
    WORLD     = "WORLD",
    WEEKLY    = "WEEKLY",
    DAILY     = "DAILY",
    CALLING   = "WORLD",
    ACHIEVEMENT = "ACHIEVEMENTS",
    ENDEAVOR   = "ENDEAVORS",
    DECOR      = "DECOR",
    DEFAULT   = "DEFAULT",
}

-- Font list for options: "Game Font" first, then LibSharedMedia fonts if available
local fontListNames, fontListPaths = {}, {}
function addon.RefreshFontList()
    table.wipe(fontListNames)
    table.wipe(fontListPaths)
    local gamePath = addon.GetDefaultFontPath()
    fontListNames[1] = "Game Font"
    fontListPaths[1] = gamePath
    local LSM = (LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)) or nil
    if LSM and LSM.HashTable and LSM:HashTable("font") then
        local t = {}
        for name, path in pairs(LSM:HashTable("font")) do
            t[#t + 1] = { name = name, path = path }
        end
        table.sort(t, function(a, b) return (a.name or "") < (b.name or "") end)
        for _, f in ipairs(t) do
            fontListNames[#fontListNames + 1] = f.name
            fontListPaths[#fontListPaths + 1] = f.path
        end
    end
end

function addon.GetFontList()
    if #fontListNames == 0 then addon.RefreshFontList() end
    local list = {}
    for i = 1, #fontListNames do
        list[i] = { fontListNames[i], fontListPaths[i] }
    end
    return list
end

function addon.GetFontPathForIndex(index)
    if #fontListPaths == 0 then addon.RefreshFontList() end
    if not index or index < 1 or index > #fontListPaths then return addon.GetDefaultFontPath() end
    return fontListPaths[index]
end

function addon.GetFontNameForPath(path)
    if #fontListNames == 0 then addon.RefreshFontList() end
    for i = 1, #fontListPaths do
        if fontListPaths[i] == path then return fontListNames[i] end
    end
    return "Custom"
end
