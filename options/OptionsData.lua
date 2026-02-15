--[[
    Horizon Suite - Focus - Options Data
    OptionCategories (Modules, Layout, Visibility, Display, Features, Typography, Appearance, Colors, Organization), getDB/setDB/notifyMainAddon, search index.
]]

if not HorizonDB then HorizonDB = {} end
local addon = _G.HorizonSuite
if not addon then return end

-- ---------------------------------------------------------------------------
-- DB helpers
-- ---------------------------------------------------------------------------

local TYPOGRAPHY_KEYS = {
    fontPath = true,
    headerFontSize = true,
    titleFontSize = true,
    objectiveFontSize = true,
    zoneFontSize = true,
    sectionFontSize = true,
    fontOutline = true,
}

function OptionsData_GetDB(key, default)
    return addon.GetDB(key, default)
end

local updateOptionsPanelFontsRef
function OptionsData_SetUpdateFontsRef(fn)
    updateOptionsPanelFontsRef = fn
end

function OptionsData_SetDB(key, value)
    addon.SetDB(key, value)
    if key == "fontPath" and updateOptionsPanelFontsRef then
        updateOptionsPanelFontsRef()
    end
    if TYPOGRAPHY_KEYS[key] and addon.UpdateFontObjectsFromDB then
        addon.UpdateFontObjectsFromDB()
    end
    if key == "lockPosition" and addon.UpdateResizeHandleVisibility then
        addon.UpdateResizeHandleVisibility()
    end
    OptionsData_NotifyMainAddon()
end

function OptionsData_NotifyMainAddon()
    local applyTy = _G.HorizonSuite_ApplyTypography or addon.ApplyTypography
    if applyTy then applyTy() end
    if _G.HorizonSuite_ApplyDimensions then _G.HorizonSuite_ApplyDimensions() end
    if addon.ApplyBackdropOpacity then addon.ApplyBackdropOpacity() end
    if addon.ApplyBorderVisibility then addon.ApplyBorderVisibility() end
    if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end
    if _G.HorizonSuite_FullLayout and not InCombatLockdown() then _G.HorizonSuite_FullLayout() end
end

-- ---------------------------------------------------------------------------
-- Option value helpers (used in category descriptors)
-- ---------------------------------------------------------------------------

local function getDB(k, d) return addon.GetDB(k, d) end
local function setDB(k, v) return OptionsData_SetDB(k, v) end

local defaultFontPath = (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF"

local function GetFontDropdownOptions()
    if addon.RefreshFontList then addon.RefreshFontList() end
    local list = (addon.GetFontList and addon.GetFontList()) or {}
    local saved = getDB("fontPath", defaultFontPath)
    for _, o in ipairs(list) do
        if o[2] == saved then return list end
    end
    local out = {}
    for i = 1, #list do out[i] = list[i] end
    out[#out + 1] = { "Custom", saved }
    return out
end

local OUTLINE_OPTIONS = {
    { "None", "" },
    { "Outline", "OUTLINE" },
    { "Thick Outline", "THICKOUTLINE" },
}
local HIGHLIGHT_OPTIONS = {
    { "Bar (left edge)", "bar-left" },
    { "Bar (right edge)", "bar-right" },
    { "Bar (top edge)", "bar-top" },
    { "Bar (bottom edge)", "bar-bottom" },
    { "Outline only", "outline" },
    { "Soft glow", "glow" },
    { "Dual edge bars", "bar-both" },
    { "Pill left accent", "pill-left" },
    { "Highlight", "highlight" },
}
local MPLUS_POSITION_OPTIONS = {
    { "Top", "top" },
    { "Bottom", "bottom" },
}
local TEXT_CASE_OPTIONS = {
    { "Lower Case", "lower" },
    { "Upper Case", "upper" },
    { "Proper", "proper" },
}
-- Use addon.QUEST_COLORS from Config as single source for quest type colors.
local COLOR_KEYS_ORDER = { "DEFAULT", "CAMPAIGN", "IMPORTANT", "LEGENDARY", "WORLD", "DELVES", "SCENARIO", "ACHIEVEMENT", "WEEKLY", "DAILY", "COMPLETE", "RARE" }
local ZONE_COLOR_DEFAULT = { 0.55, 0.65, 0.75 }
local OBJ_COLOR_DEFAULT = { 0.78, 0.78, 0.78 }
local OBJ_DONE_COLOR_DEFAULT = { 0.30, 0.80, 0.30 }
local HIGHLIGHT_COLOR_DEFAULT = { 0.4, 0.7, 1 }

local VALID_HIGHLIGHT_STYLES = {
    ["bar-left"] = true, ["bar-right"] = true, ["bar-top"] = true, ["bar-bottom"] = true,
    ["outline"] = true, ["glow"] = true, ["bar-both"] = true, ["pill-left"] = true, ["highlight"] = true,
}
local function getActiveQuestHighlight()
    local v = addon.NormalizeHighlightStyle(getDB("activeQuestHighlight", "bar-left"))
    if not VALID_HIGHLIGHT_STYLES[v] then return "bar-left" end
    return v
end

-- ---------------------------------------------------------------------------
-- OptionCategories: Modules, Layout, Visibility, Display, Features, Typography, Appearance, Colors, Organization
-- ---------------------------------------------------------------------------

local OptionCategories = {
    {
        key = "Modules",
        name = "Modules",
        moduleKey = nil,
        options = {
            { type = "section", name = "" },
            { type = "toggle", name = "Enable Focus module", desc = "Show the objective tracker for quests, world quests, rares, achievements, and scenarios.", dbKey = "_module_focus", get = function() return addon:IsModuleEnabled("focus") end, set = function(v) addon:SetModuleEnabled("focus", v) end },
            { type = "toggle", name = "Enable Presence module", desc = "Cinematic zone text and notifications (zone changes, level up, boss emotes, achievements, quest updates).", dbKey = "_module_presence", get = function() return addon:IsModuleEnabled("presence") end, set = function(v) addon:SetModuleEnabled("presence", v) end },
        },
    },
    {
        key = "Layout",
        name = "Layout",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Panel behaviour" },
            { type = "toggle", name = "Lock position", desc = "Prevent dragging the tracker.", dbKey = "lockPosition", get = function() return (HorizonDB and HorizonDB.lockPosition) == true end, set = function(v) setDB("lockPosition", v) end },
            { type = "toggle", name = "Grow upward", desc = "Anchor at bottom so the list grows upward.", dbKey = "growUp", get = function() return getDB("growUp", false) end, set = function(v) setDB("growUp", v) end },
            { type = "toggle", name = "Start collapsed", desc = "Start with only the header shown until you expand.", dbKey = "collapsed", get = function() return (HorizonDB and HorizonDB.collapsed) == true end, set = function(v) setDB("collapsed", v) end },
            { type = "section", name = "Dimensions" },
            { type = "slider", name = "Panel width", desc = "Tracker width in pixels.", dbKey = "panelWidth", min = 180, max = 800, get = function() return getDB("panelWidth", 260) end, set = function(v) setDB("panelWidth", math.max(180, math.min(800, v))) end },
            { type = "slider", name = "Max content height", desc = "Max height of the scrollable list (pixels).", dbKey = "maxContentHeight", min = 200, max = 1000, get = function() return getDB("maxContentHeight", 480) end, set = function(v) setDB("maxContentHeight", math.max(200, math.min(1000, v))) end },
        },
    },
    {
        key = "Visibility",
        name = "Visibility",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Instance" },
            { type = "toggle", name = "Show in dungeon", desc = "Show tracker in party dungeons.", dbKey = "showInDungeon", get = function() return getDB("showInDungeon", false) end, set = function(v) setDB("showInDungeon", v) end },
            { type = "toggle", name = "Show in raid", desc = "Show tracker in raids.", dbKey = "showInRaid", get = function() return getDB("showInRaid", false) end, set = function(v) setDB("showInRaid", v) end },
            { type = "toggle", name = "Show in battleground", desc = "Show tracker in battlegrounds.", dbKey = "showInBattleground", get = function() return getDB("showInBattleground", false) end, set = function(v) setDB("showInBattleground", v) end },
            { type = "toggle", name = "Show in arena", desc = "Show tracker in arenas.", dbKey = "showInArena", get = function() return getDB("showInArena", false) end, set = function(v) setDB("showInArena", v) end },
            { type = "section", name = "Combat" },
            { type = "toggle", name = "Hide in combat", desc = "Hide tracker and floating quest item in combat.", dbKey = "hideInCombat", get = function() return getDB("hideInCombat", false) end, set = function(v) setDB("hideInCombat", v) end },
            { type = "section", name = "Filtering" },
            { type = "toggle", name = "Only show quests in current zone", desc = "Hide quests outside your current zone.", dbKey = "filterByZone", get = function() return getDB("filterByZone", false) end, set = function(v) setDB("filterByZone", v) end },
        },
    },
    {
        key = "Display",
        name = "Display",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Header" },
            { type = "toggle", name = "Show quest count", desc = "Show quest count in header.", dbKey = "showQuestCount", get = function() return getDB("showQuestCount", true) end, set = function(v) setDB("showQuestCount", v) end },
            { type = "dropdown", name = "Header count format", desc = "Tracked/in-log or in-log/max-slots. Tracked excludes world/live-in-zone quests.", dbKey = "headerCountMode", options = { { "Tracked / in log", "trackedLog" }, { "In log / max slots", "logMax" } }, get = function() return getDB("headerCountMode", "trackedLog") end, set = function(v) setDB("headerCountMode", v) end },
            { type = "toggle", name = "Show header divider", desc = "Show the line below the header.", dbKey = "showHeaderDivider", get = function() return getDB("showHeaderDivider", true) end, set = function(v) setDB("showHeaderDivider", v) end },
            { type = "toggle", name = "Super-minimal mode", desc = "Hide header for a pure text list.", dbKey = "hideObjectivesHeader", get = function() return getDB("hideObjectivesHeader", false) end, set = function(v) setDB("hideObjectivesHeader", v) end },
            { type = "section", name = "List" },
            { type = "toggle", name = "Show section headers", desc = "Show category labels above each group.", dbKey = "showSectionHeaders", get = function() return getDB("showSectionHeaders", true) end, set = function(v) setDB("showSectionHeaders", v) end },
            { type = "toggle", name = "Show category headers when collapsed", desc = "Keep section headers visible when collapsed; click to expand a category.", dbKey = "showSectionHeadersWhenCollapsed", get = function() return getDB("showSectionHeadersWhenCollapsed", false) end, set = function(v) setDB("showSectionHeadersWhenCollapsed", v) end },
            { type = "toggle", name = "Show Nearby (Current Zone) group", desc = "Show in-zone quests in a dedicated Current Zone section. When off, they appear in their normal category.", dbKey = "showNearbyGroup", get = function() return getDB("showNearbyGroup", true) end, set = function(v) setDB("showNearbyGroup", v) end },
            { type = "toggle", name = "Show zone labels", desc = "Show zone name under each quest title.", dbKey = "showZoneLabels", get = function() return getDB("showZoneLabels", true) end, set = function(v) setDB("showZoneLabels", v) end },
            { type = "dropdown", name = "Active quest highlight", desc = "How the focused quest is highlighted.", dbKey = "activeQuestHighlight", options = HIGHLIGHT_OPTIONS, get = getActiveQuestHighlight, set = function(v) setDB("activeQuestHighlight", v) end },
            { type = "toggle", name = "Show quest item buttons", desc = "Show usable quest item button next to each quest.", dbKey = "showQuestItemButtons", get = function() return getDB("showQuestItemButtons", false) end, set = function(v) setDB("showQuestItemButtons", v) end },
            { type = "toggle", name = "Show objective numbers", desc = "Prefix objectives with 1., 2., 3.", dbKey = "showObjectiveNumbers", get = function() return getDB("showObjectiveNumbers", false) end, set = function(v) setDB("showObjectiveNumbers", v) end },
            { type = "toggle", name = "Show completed count", desc = "Show X/Y progress in quest title.", dbKey = "showCompletedCount", get = function() return getDB("showCompletedCount", false) end, set = function(v) setDB("showCompletedCount", v) end },
            { type = "toggle", name = "Show '**' in-zone suffix", desc = "Append ** to world quests and weeklies/dailies that are not yet in your quest log (in-zone only).", dbKey = "showInZoneSuffix", get = function() return getDB("showInZoneSuffix", true) end, set = function(v) setDB("showInZoneSuffix", v) end },
            { type = "section", name = "Spacing" },
            { type = "toggle", name = "Compact mode", desc = "Preset: sets entry and objective spacing to 4 and 1 px.", dbKey = "compactMode", get = function() return getDB("compactMode", false) end, set = function(v) setDB("compactMode", v); if v then setDB("titleSpacing", 4); setDB("objSpacing", 1) end end },
            { type = "slider", name = "Spacing between quest entries (px)", desc = "Vertical gap between quest entries.", dbKey = "titleSpacing", min = 2, max = 20, get = function() return math.max(2, math.min(20, tonumber(getDB("titleSpacing", 8)) or 8)) end, set = function(v) setDB("titleSpacing", math.max(2, math.min(20, v))) end },
            { type = "slider", name = "Spacing before category header (px)", desc = "Gap between last entry of a group and the next category label.", dbKey = "sectionSpacing", min = 0, max = 24, get = function() return math.max(0, math.min(24, tonumber(getDB("sectionSpacing", 10)) or 10)) end, set = function(v) setDB("sectionSpacing", math.max(0, math.min(24, v))) end },
            { type = "slider", name = "Spacing after category header (px)", desc = "Gap between category label and first quest entry below it.", dbKey = "sectionToEntryGap", min = 0, max = 16, get = function() return math.max(0, math.min(16, tonumber(getDB("sectionToEntryGap", 6)) or 6)) end, set = function(v) setDB("sectionToEntryGap", math.max(0, math.min(16, v))) end },
            { type = "slider", name = "Spacing between objectives (px)", desc = "Vertical gap between objective lines within a quest.", dbKey = "objSpacing", min = 0, max = 8, get = function() return math.max(0, math.min(8, tonumber(getDB("objSpacing", 2)) or 2)) end, set = function(v) setDB("objSpacing", math.max(0, math.min(8, v))) end },
            { type = "slider", name = "Spacing below header (px)", desc = "Vertical gap between the objectives bar and the quest list.", dbKey = "headerToContentGap", min = 0, max = 24, get = function() return math.max(0, math.min(24, tonumber(getDB("headerToContentGap", 6)) or 6)) end, set = function(v) setDB("headerToContentGap", math.max(0, math.min(24, v))) end },
            { type = "button", name = "Reset spacing", onClick = function()
                setDB("compactMode", false)
                setDB("titleSpacing", 8)
                setDB("sectionSpacing", 10)
                setDB("sectionToEntryGap", 6)
                setDB("objSpacing", 2)
                setDB("headerToContentGap", 6)
            end, refreshIds = { "compactMode", "titleSpacing", "sectionSpacing", "sectionToEntryGap", "objSpacing", "headerToContentGap" } },
            { type = "toggle", name = "Show quest level", desc = "Show quest level next to title.", dbKey = "showQuestLevel", get = function() return getDB("showQuestLevel", false) end, set = function(v) setDB("showQuestLevel", v) end },
            { type = "toggle", name = "Dim non-focused quests", desc = "Slightly dim title, zone, objectives, and section headers that are not focused.", dbKey = "dimNonSuperTracked", get = function() return getDB("dimNonSuperTracked", false) end, set = function(v) setDB("dimNonSuperTracked", v) end },
        },
    },
    {
        key = "Features",
        name = "Features",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Rare bosses" },
            { type = "toggle", name = "Show rare bosses", desc = "Show rare boss vignettes in the list.", dbKey = "showRareBosses", get = function() return getDB("showRareBosses", true) end, set = function(v) setDB("showRareBosses", v) end },
            { type = "toggle", name = "Rare added sound", desc = "Play a sound when a rare is added.", dbKey = "rareAddedSound", get = function() return getDB("rareAddedSound", true) end, set = function(v) setDB("rareAddedSound", v) end },
            { type = "section", name = "World quests" },
            { type = "toggle", name = "Show world quests", desc = "Show world quests and callings in the list.", dbKey = "showWorldQuests", get = function() return getDB("showWorldQuests", true) end, set = function(v) setDB("showWorldQuests", v) end },
            { type = "section", name = "Floating quest item" },
            { type = "toggle", name = "Show floating quest item", desc = "Show quick-use button for the focused quest's usable item.", dbKey = "showFloatingQuestItem", get = function() return getDB("showFloatingQuestItem", false) end, set = function(v) setDB("showFloatingQuestItem", v) end },
            { type = "toggle", name = "Lock floating quest item position", desc = "Prevent dragging the floating quest item button.", dbKey = "lockFloatingQuestItemPosition", get = function() return getDB("lockFloatingQuestItemPosition", false) end, set = function(v) setDB("lockFloatingQuestItemPosition", v) end },
            { type = "section", name = "Mythic+" },
            { type = "toggle", name = "Show Mythic+ block", desc = "Show timer, completion %, and affixes in Mythic+ dungeons.", dbKey = "showMythicPlusBlock", get = function() return getDB("showMythicPlusBlock", false) end, set = function(v) setDB("showMythicPlusBlock", v) end },
            { type = "dropdown", name = "M+ block position", desc = "Position of the Mythic+ block relative to the quest list.", dbKey = "mplusBlockPosition", options = MPLUS_POSITION_OPTIONS, get = function() return getDB("mplusBlockPosition", "top") end, set = function(v) setDB("mplusBlockPosition", v) end },
            { type = "section", name = "Achievements" },
            { type = "toggle", name = "Show achievements", desc = "Show tracked achievements in the list.", dbKey = "showAchievements", get = function() return getDB("showAchievements", true) end, set = function(v) setDB("showAchievements", v) end },
            { type = "toggle", name = "Show completed achievements", desc = "Include completed achievements in the tracker. When off, only in-progress tracked achievements are shown.", dbKey = "showCompletedAchievements", get = function() return getDB("showCompletedAchievements", false) end, set = function(v) setDB("showCompletedAchievements", v) end },
            { type = "toggle", name = "Show achievement icons", desc = "Show each achievement's icon next to the title. Requires 'Show quest type icons' in Display.", dbKey = "showAchievementIcons", get = function() return getDB("showAchievementIcons", true) end, set = function(v) setDB("showAchievementIcons", v) end },
            { type = "toggle", name = "Only show missing requirements", desc = "Show only criteria you haven't completed for each tracked achievement. When off, all criteria are shown.", dbKey = "achievementOnlyMissingRequirements", get = function() return getDB("achievementOnlyMissingRequirements", false) end, set = function(v) setDB("achievementOnlyMissingRequirements", v) end },
            { type = "section", name = "Endeavors" },
            { type = "toggle", name = "Show endeavors", desc = "Show tracked Endeavors (Player Housing) in the list.", dbKey = "showEndeavors", get = function() return getDB("showEndeavors", true) end, set = function(v) setDB("showEndeavors", v) end },
            { type = "toggle", name = "Show completed endeavors", desc = "Include completed Endeavors in the tracker. When off, only in-progress tracked Endeavors are shown.", dbKey = "showCompletedEndeavors", get = function() return getDB("showCompletedEndeavors", false) end, set = function(v) setDB("showCompletedEndeavors", v) end },
            { type = "section", name = "Decor" },
            { type = "toggle", name = "Show decor", desc = "Show tracked housing decor in the list.", dbKey = "showDecor", get = function() return getDB("showDecor", true) end, set = function(v) setDB("showDecor", v) end },
            { type = "toggle", name = "Show decor icons", desc = "Show each decor item's icon next to the title. Requires 'Show quest type icons' in Display.", dbKey = "showDecorIcons", get = function() return getDB("showDecorIcons", true) end, set = function(v) setDB("showDecorIcons", v) end },
            { type = "section", name = "Scenario & Delve" },
            { type = "toggle", name = "Show scenario events", desc = "Show active scenario and Delve activities. Delves appear in DELVES; other scenarios in SCENARIO EVENTS.", dbKey = "showScenarioEvents", get = function() return getDB("showScenarioEvents", true) end, set = function(v) setDB("showScenarioEvents", v) end },
            { type = "toggle", name = "Hide other categories in Delve or Dungeon", desc = "In Delves or party dungeons, show only the Delve/Dungeon section.", dbKey = "hideOtherCategoriesInDelve", get = function() return getDB("hideOtherCategoriesInDelve", false) end, set = function(v) setDB("hideOtherCategoriesInDelve", v) end },
            { type = "toggle", name = "Cinematic scenario bar", desc = "Show timer and progress bar for scenario entries.", dbKey = "cinematicScenarioBar", get = function() return getDB("cinematicScenarioBar", true) end, set = function(v) setDB("cinematicScenarioBar", v) end },
            { type = "slider", name = "Scenario bar opacity", desc = "Opacity of scenario timer/progress bar (0–1).", dbKey = "scenarioBarOpacity", min = 0.3, max = 1, get = function() return tonumber(getDB("scenarioBarOpacity", 0.85)) or 0.85 end, set = function(v) setDB("scenarioBarOpacity", v) end },
            { type = "slider", name = "Scenario bar height", desc = "Height of scenario progress bar (4–8 px).", dbKey = "scenarioBarHeight", min = 4, max = 8, get = function() return math.max(4, math.min(8, tonumber(getDB("scenarioBarHeight", 6)) or 6)) end, set = function(v) setDB("scenarioBarHeight", math.max(4, math.min(8, v))) end },
        },
    },
    {
        key = "Typography",
        name = "Typography",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Font" },
            { type = "dropdown", name = "Font", desc = "Font family.", dbKey = "fontPath", options = GetFontDropdownOptions, get = function() return getDB("fontPath", defaultFontPath) end, set = function(v) setDB("fontPath", v) end, displayFn = addon.GetFontNameForPath },
            { type = "slider", name = "Header size", desc = "Header font size.", dbKey = "headerFontSize", min = 8, max = 32, get = function() return getDB("headerFontSize", 16) end, set = function(v) setDB("headerFontSize", v) end },
            { type = "slider", name = "Title size", desc = "Quest title font size.", dbKey = "titleFontSize", min = 8, max = 24, get = function() return getDB("titleFontSize", 13) end, set = function(v) setDB("titleFontSize", v) end },
            { type = "slider", name = "Objective size", desc = "Objective text font size.", dbKey = "objectiveFontSize", min = 8, max = 20, get = function() return getDB("objectiveFontSize", 11) end, set = function(v) setDB("objectiveFontSize", v) end },
            { type = "slider", name = "Zone size", desc = "Zone label font size.", dbKey = "zoneFontSize", min = 8, max = 18, get = function() return getDB("zoneFontSize", 10) end, set = function(v) setDB("zoneFontSize", v) end },
            { type = "slider", name = "Section size", desc = "Section header font size.", dbKey = "sectionFontSize", min = 8, max = 18, get = function() return getDB("sectionFontSize", 10) end, set = function(v) setDB("sectionFontSize", v) end },
            { type = "dropdown", name = "Outline", desc = "Font outline style.", dbKey = "fontOutline", options = OUTLINE_OPTIONS, get = function() return getDB("fontOutline", "OUTLINE") end, set = function(v) setDB("fontOutline", v) end },
            { type = "section", name = "Text case" },
            { type = "dropdown", name = "Header text case", desc = "Display case for header.", dbKey = "headerTextCase", options = TEXT_CASE_OPTIONS, get = function() local v = getDB("headerTextCase", "upper"); return (v == "default") and "upper" or v end, set = function(v) setDB("headerTextCase", v) end },
            { type = "dropdown", name = "Section header case", desc = "Display case for category labels.", dbKey = "sectionHeaderTextCase", options = TEXT_CASE_OPTIONS, get = function() local v = getDB("sectionHeaderTextCase", "upper"); return (v == "default") and "upper" or v end, set = function(v) setDB("sectionHeaderTextCase", v) end },
            { type = "dropdown", name = "Quest title case", desc = "Display case for quest titles.", dbKey = "questTitleCase", options = TEXT_CASE_OPTIONS, get = function() local v = getDB("questTitleCase", "proper"); return (v == "default") and "proper" or v end, set = function(v) setDB("questTitleCase", v) end },
            { type = "section", name = "Shadow" },
            { type = "toggle", name = "Show text shadow", desc = "Enable drop shadow on text.", dbKey = "showTextShadow", get = function() return getDB("showTextShadow", true) end, set = function(v) setDB("showTextShadow", v) end },
            { type = "slider", name = "Shadow X", desc = "Horizontal shadow offset.", dbKey = "shadowOffsetX", min = -10, max = 10, get = function() return getDB("shadowOffsetX", 2) end, set = function(v) setDB("shadowOffsetX", v) end },
            { type = "slider", name = "Shadow Y", desc = "Vertical shadow offset.", dbKey = "shadowOffsetY", min = -10, max = 10, get = function() return getDB("shadowOffsetY", -2) end, set = function(v) setDB("shadowOffsetY", v) end },
            { type = "slider", name = "Shadow alpha", desc = "Shadow opacity (0–1).", dbKey = "shadowAlpha", min = 0, max = 1, get = function() return getDB("shadowAlpha", 0.8) end, set = function(v) setDB("shadowAlpha", v) end },
        },
    },
    {
        key = "Appearance",
        name = "Appearance",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Panel" },
            { type = "slider", name = "Backdrop opacity", desc = "Panel background opacity (0–1).", dbKey = "backdropOpacity", min = 0, max = 1, get = function() return tonumber(getDB("backdropOpacity", 0)) or 0 end, set = function(v) setDB("backdropOpacity", v) end },
            { type = "toggle", name = "Show border", desc = "Show border around the tracker.", dbKey = "showBorder", get = function() return getDB("showBorder", false) end, set = function(v) setDB("showBorder", v) end },
            { type = "section", name = "Highlight" },
            { type = "slider", name = "Highlight alpha", desc = "Opacity of focused quest highlight (0–1).", dbKey = "highlightAlpha", min = 0, max = 1, get = function() return tonumber(getDB("highlightAlpha", 0.25)) or 0.25 end, set = function(v) setDB("highlightAlpha", v) end },
            { type = "slider", name = "Bar width", desc = "Width of bar-style highlights (2–6 px).", dbKey = "highlightBarWidth", min = 2, max = 6, get = function() return math.max(2, math.min(6, tonumber(getDB("highlightBarWidth", 2)) or 2)) end, set = function(v) setDB("highlightBarWidth", math.max(2, math.min(6, v))) end },
        },
    },
    {
        key = "Colors",
        name = "Colors",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Color matrix" },
            { type = "colorMatrixFull", name = "Colors", dbKey = "colorMatrix" },
        },
    },
    {
        key = "Organization",
        name = "Organization",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Focus order" },
            { type = "reorderList", name = "Focus category order", labelMap = addon.SECTION_LABELS, presets = addon.GROUP_ORDER_PRESETS, get = function() return addon.GetGroupOrder() end, set = function(order) addon.SetGroupOrder(order) end, desc = "Apply a preset or drag to reorder categories." },
            { type = "section", name = "Sort" },
            { type = "dropdown", name = "Focus sort mode", desc = "Order of entries within each category.", dbKey = "entrySortMode", options = { { "Alphabetical", "alpha" }, { "Quest Type", "questType" }, { "Zone", "zone" }, { "Quest Level", "level" } }, get = function() return getDB("entrySortMode", "questType") end, set = function(v) setDB("entrySortMode", v) end },
            { type = "section", name = "Behaviour" },
            { type = "toggle", name = "Auto-track accepted quests", desc = "When you accept a quest (quest log only, not world quests), add it to the tracker automatically.", dbKey = "autoTrackOnAccept", get = function() return getDB("autoTrackOnAccept", true) end, set = function(v) setDB("autoTrackOnAccept", v) end },
            { type = "toggle", name = "Require Ctrl for focus & remove", desc = "Require Ctrl for focus/add (Left) and unfocus/untrack (Right) to prevent misclicks.", dbKey = "requireCtrlForQuestClicks", get = function() return getDB("requireCtrlForQuestClicks", false) end, set = function(v) setDB("requireCtrlForQuestClicks", v) end },
            { type = "toggle", name = "Animations", desc = "Enable slide and fade for quests.", dbKey = "animations", get = function() return getDB("animations", true) end, set = function(v) setDB("animations", v) end },
            { type = "toggle", name = "Objective progress flash", desc = "Show green flash when an objective completes.", dbKey = "objectiveProgressFlash", get = function() return getDB("objectiveProgressFlash", true) end, set = function(v) setDB("objectiveProgressFlash", v) end },
            { type = "toggle", name = "Suppress untracked until reload", desc = "When on, right-click untrack on world quests and in-zone weeklies/dailies hides them until you reload or start a new session. When off, they reappear when you return to the zone.", dbKey = "suppressUntrackedUntilReload", get = function() return getDB("suppressUntrackedUntilReload", false) end, set = function(v) setDB("suppressUntrackedUntilReload", v) end },
            { type = "toggle", name = "Permanently suppress untracked quests", desc = "When on, right-click untracked world quests and in-zone weeklies/dailies are hidden permanently (persists across reloads). Takes priority over 'Suppress until reload'. Accepting a suppressed quest removes it from the blacklist.", dbKey = "permanentlySuppressUntracked", get = function() return getDB("permanentlySuppressUntracked", false) end, set = function(v) setDB("permanentlySuppressUntracked", v) end },
        },
    },
    {
        key = "Blacklist",
        name = "Blacklisted quests",
        moduleKey = "focus",
        options = {
            { type = "section", name = "Permanently suppressed quests", desc = "Right-click untrack quests with 'Permanently suppress untracked quests' enabled to add them here." },
            { type = "blacklistGrid", name = "Blacklisted quests" },
        },
    },
    {
        key = "Presence",
        name = "Presence",
        moduleKey = "presence",
        options = {
            { type = "section", name = "Display" },
            { type = "toggle", name = "Show quest type icons", desc = "Show quest type icon on Presence toasts and in the Focus tracker (quest accept/complete, world quest, quest update).", dbKey = "showQuestTypeIcons", get = function() return getDB("showQuestTypeIcons", false) end, set = function(v) setDB("showQuestTypeIcons", v) end },
            { type = "slider", name = "Presence icon size", desc = "Quest icon size on toasts (16–36 px). Default 24.", dbKey = "presenceIconSize", min = 16, max = 36, get = function() return math.max(16, math.min(36, getDB("presenceIconSize", 24) or 24)) end, set = function(v) setDB("presenceIconSize", math.max(16, math.min(36, v))) end },
            { type = "toggle", name = "Show discovery line", desc = "Show 'Discovered' under zone/subzone when entering a new area.", dbKey = "showPresenceDiscovery", get = function() return getDB("showPresenceDiscovery", true) end, set = function(v) setDB("showPresenceDiscovery", v) end },
        },
    },
}

-- ---------------------------------------------------------------------------
-- Search index: flatten all options for search (name + desc + section)
-- Includes optionId, sectionName, categoryIndex for navigation.
-- ---------------------------------------------------------------------------

function OptionsData_BuildSearchIndex()
    local index = {}
    for catIdx, cat in ipairs(OptionCategories) do
        local currentSection = ""
        local moduleKey = cat.moduleKey
        local moduleLabel = (moduleKey == "focus" and "Focus") or (moduleKey == "presence" and "Presence") or "Modules"
        for _, opt in ipairs(cat.options) do
            if opt.type == "section" then
                currentSection = opt.name or ""
            elseif opt.type ~= "section" then
                local name = (opt.name or ""):lower()
                local desc = (opt.desc or opt.tooltip or ""):lower()
                local sectionLower = (currentSection or ""):lower()
                local searchText = name .. " " .. desc .. " " .. sectionLower .. " " .. (moduleLabel or ""):lower()
                local optionId = opt.dbKey or (cat.key .. "_" .. (opt.name or ""):gsub("%s+", "_"))
                index[#index + 1] = {
                    categoryKey = cat.key,
                    categoryName = cat.name,
                    categoryIndex = catIdx,
                    moduleKey = moduleKey,
                    moduleLabel = moduleLabel,
                    sectionName = currentSection,
                    option = opt,
                    optionId = optionId,
                    searchText = searchText,
                }
            end
        end
    end
    return index
end

-- Export for panel
addon.OptionsData_GetDB = OptionsData_GetDB
addon.OptionsData_SetDB = OptionsData_SetDB
addon.OptionsData_NotifyMainAddon = OptionsData_NotifyMainAddon
addon.OptionsData_SetUpdateFontsRef = OptionsData_SetUpdateFontsRef
addon.OptionCategories = OptionCategories
addon.OptionsData_BuildSearchIndex = OptionsData_BuildSearchIndex
addon.COLOR_KEYS_ORDER = COLOR_KEYS_ORDER
addon.ZONE_COLOR_DEFAULT = ZONE_COLOR_DEFAULT
addon.OBJ_COLOR_DEFAULT = OBJ_COLOR_DEFAULT
addon.OBJ_DONE_COLOR_DEFAULT = OBJ_DONE_COLOR_DEFAULT
addon.HIGHLIGHT_COLOR_DEFAULT = HIGHLIGHT_COLOR_DEFAULT
