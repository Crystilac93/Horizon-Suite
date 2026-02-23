--[[
    Horizon Suite - Focus - Options Data
    OptionCategories (Modules, Panel, Display, Typography, Behaviour, Mythic+, Delves, Content Types, Colors, Blacklist), getDB/setDB/notifyMainAddon, search index.
]]

if not HorizonDB then HorizonDB = {} end
local addon = _G.HorizonSuite
if not addon then return end

local L = addon.L

-- ---------------------------------------------------------------------------
-- DB helpers
-- ---------------------------------------------------------------------------

local TYPOGRAPHY_KEYS = {
    fontPath = true,
    titleFontPath = true,
    presenceTitleFontPath = true,
    presenceSubtitleFontPath = true,
    zoneFontPath = true,
    objectiveFontPath = true,
    sectionFontPath = true,
    progressBarFontPath = true,
    headerFontSize = true,
    titleFontSize = true,
    objectiveFontSize = true,
    zoneFontSize = true,
    sectionFontSize = true,
    progressBarFontSize = true,
    fontOutline = true,
}

local INSIGHT_KEYS = {
    insightAnchorMode = true,
    insightFixedPoint = true,
    insightFixedX = true,
    insightFixedY = true,
}

local PRESENCE_KEYS = {
    presenceFrameY = true,
    presenceFrameScale = true,
    presenceBossEmoteColor = true,
    presenceDiscoveryColor = true,
    presenceZoneChange = true,
    presenceSubzoneChange = true,
    presenceHideZoneForSubzone = true,
    presenceSuppressZoneInMplus = true,
    presenceLevelUp = true,
    presenceBossEmote = true,
    presenceAchievement = true,
    presenceQuestEvents = true,
    presenceQuestAccept = true,
    presenceWorldQuestAccept = true,
    presenceQuestComplete = true,
    presenceWorldQuest = true,
    presenceQuestUpdate = true,
    presenceScenarioStart = true,
    presenceScenarioUpdate = true,
    presenceAnimations = true,
    presenceEntranceDur = true,
    presenceExitDur = true,
    presenceHoldScale = true,
    presenceMainSize = true,
    presenceSubSize = true,
    presenceTitleFontPath = true,
    presenceSubtitleFontPath = true,
}

local MPLUS_TYPOGRAPHY_KEYS = {
    fontPath = true,
    fontOutline = true,
    shadowOffsetX = true,
    shadowOffsetY = true,
    showTextShadow = true,
    shadowAlpha = true,
    mplusDungeonSize = true,
    mplusDungeonColorR = true, mplusDungeonColorG = true, mplusDungeonColorB = true,
    mplusTimerSize = true,
    mplusTimerColorR = true, mplusTimerColorG = true, mplusTimerColorB = true,
    mplusTimerOvertimeColorR = true, mplusTimerOvertimeColorG = true, mplusTimerOvertimeColorB = true,
    mplusProgressSize = true,
    mplusProgressColorR = true, mplusProgressColorG = true, mplusProgressColorB = true,
    mplusAffixSize = true,
    mplusAffixColorR = true, mplusAffixColorG = true, mplusAffixColorB = true,
    mplusBossSize = true,
    mplusBossColorR = true, mplusBossColorG = true, mplusBossColorB = true,
    mplusBarColorR = true, mplusBarColorG = true, mplusBarColorB = true,
    mplusBarDoneColorR = true, mplusBarDoneColorG = true, mplusBarDoneColorB = true,
}

-- Keys written by color pickers during drag. When _colorPickerLive is true and key is in this list,
-- we skip NotifyMainAddon to avoid FullLayout spam; key-specific handlers (e.g. ApplyBackdropOpacity) still run.
local COLOR_LIVE_KEYS = {
    backdropOpacity = true, backdropColorR = true, backdropColorG = true, backdropColorB = true,
    headerColor = true,
    colorMatrix = true,
    highlightColor = true, completedObjectiveColor = true, sectionColors = true,
    objectiveProgressFlashColor = true, presenceBossEmoteColor = true, presenceDiscoveryColor = true,
    mplusDungeonColorR = true, mplusDungeonColorG = true, mplusDungeonColorB = true,
    mplusTimerColorR = true, mplusTimerColorG = true, mplusTimerColorB = true,
    mplusTimerOvertimeColorR = true, mplusTimerOvertimeColorG = true, mplusTimerOvertimeColorB = true,
    mplusProgressColorR = true, mplusProgressColorG = true, mplusProgressColorB = true,
    mplusBarColorR = true, mplusBarColorG = true, mplusBarColorB = true,
    mplusBarDoneColorR = true, mplusBarDoneColorG = true, mplusBarDoneColorB = true,
    mplusAffixColorR = true, mplusAffixColorG = true, mplusAffixColorB = true,
    mplusBossColorR = true, mplusBossColorG = true, mplusBossColorB = true,
    progressBarFillColor = true, progressBarTextColor = true,
    progressBarUseCategoryColor = true,
    vistaBorderColorR = true, vistaBorderColorG = true, vistaBorderColorB = true, vistaBorderColorA = true,
    vistaZoneColorR = true, vistaZoneColorG = true, vistaZoneColorB = true,
    vistaCoordColorR = true, vistaCoordColorG = true, vistaCoordColorB = true,
    vistaTimeColorR = true, vistaTimeColorG = true, vistaTimeColorB = true,
    vistaDiffColorR = true, vistaDiffColorG = true, vistaDiffColorB = true,
    vistaPanelBgR = true, vistaPanelBgG = true, vistaPanelBgB = true, vistaPanelBgA = true,
    vistaPanelBorderR = true, vistaPanelBorderG = true, vistaPanelBorderB = true, vistaPanelBorderA = true,
}

-- Vista option keys — trigger Vista.ApplyOptions when changed
local VISTA_KEYS = {
    vistaMapSize = true,
    vistaCircular = true,
    vistaBorderShow = true, vistaBorderWidth = true,
    vistaBorderColorR = true, vistaBorderColorG = true, vistaBorderColorB = true, vistaBorderColorA = true,
    vistaZoneFontPath = true, vistaZoneFontSize = true,
    vistaCoordFontPath = true, vistaCoordFontSize = true,
    vistaTimeFontPath = true, vistaTimeFontSize = true,
    vistaShowZoneText = true, vistaShowCoordText = true, vistaShowTimeText = true,
    vistaShowDefaultMinimapButtons = true,  -- legacy key kept for compatibility
    vistaLock = true,
    vistaPoint = true, vistaRelPoint = true, vistaX = true, vistaY = true,
    vistaDrawerBtnX = true, vistaDrawerBtnY = true,
    vistaShowTracking = true, vistaMouseoverTracking = true,
    vistaShowCalendar = true, vistaMouseoverCalendar = true,
    vistaShowZoomBtns = true, vistaMouseoverZoomBtns = true,
    vistaQueueBtnX = true, vistaQueueBtnY = true,
    -- Draggable element positions (stored by MakeDraggable on drag-stop)
    vistaEX_zone = true, vistaEY_zone = true,
    vistaEX_coord = true, vistaEY_coord = true,
    vistaEX_time = true, vistaEY_time = true,
    -- Proxy button positions (tracking + calendar + queue only; landing page removed)
    ["vistaEX_proxy_tracking"] = true, ["vistaEY_proxy_tracking"] = true,
    ["vistaEX_proxy_calendar"] = true, ["vistaEY_proxy_calendar"] = true,
    ["vistaEX_proxy_queue"]    = true, ["vistaEY_proxy_queue"]    = true,
    -- Lock toggles
    vistaLocked_zone = true, vistaLocked_coord = true, vistaLocked_time = true,
    vistaLocked_zoomIn = true, vistaLocked_zoomOut = true,
    ["vistaLocked_proxy_tracking"] = true,
    ["vistaLocked_proxy_calendar"] = true,
    ["vistaLocked_proxy_queue"]    = true,
    vistaButtonMode = true, vistaHandleAddonButtons = true,
    vistaDrawerButtonLocked = true, vistaButtonWhitelist = true,
    -- Button sizes (separate per type)
    vistaTrackingBtnSize = true, vistaCalendarBtnSize = true, vistaQueueBtnSize = true,
    vistaZoomBtnSize = true, vistaMailIconSize = true, vistaAddonBtnSize = true,
    -- Text colors
    vistaZoneColorR = true, vistaZoneColorG = true, vistaZoneColorB = true,
    vistaCoordColorR = true, vistaCoordColorG = true, vistaCoordColorB = true,
    vistaTimeColorR = true, vistaTimeColorG = true, vistaTimeColorB = true,
    vistaDiffColorR = true, vistaDiffColorG = true, vistaDiffColorB = true,
    -- Panel colors
    vistaPanelBgR = true, vistaPanelBgG = true, vistaPanelBgB = true, vistaPanelBgA = true,
    vistaPanelBorderR = true, vistaPanelBorderG = true, vistaPanelBorderB = true, vistaPanelBorderA = true,
}
-- Vista border color keys: live updates without full layout
local VISTA_COLOR_LIVE_KEYS = {
    vistaBorderColorR = true, vistaBorderColorG = true, vistaBorderColorB = true, vistaBorderColorA = true,
    vistaZoneColorR = true, vistaZoneColorG = true, vistaZoneColorB = true,
    vistaCoordColorR = true, vistaCoordColorG = true, vistaCoordColorB = true,
    vistaTimeColorR = true, vistaTimeColorG = true, vistaTimeColorB = true,
    vistaDiffColorR = true, vistaDiffColorG = true, vistaDiffColorB = true,
    vistaPanelBgR = true, vistaPanelBgG = true, vistaPanelBgB = true, vistaPanelBgA = true,
    vistaPanelBorderR = true, vistaPanelBorderG = true, vistaPanelBorderB = true, vistaPanelBorderA = true,
}

-- Scale keys managed by debounced callbacks in the slider set lambdas.
-- OptionsData_SetDB must NOT call OptionsData_NotifyMainAddon for these —
-- doing so would trigger FullLayout synchronously on every integer drag step,
-- defeating the debounce entirely.
local SCALE_DEBOUNCE_KEYS = {
    globalUIScale   = true,
    focusUIScale    = true,
    presenceUIScale = true,
    vistaUIScale    = true,
    insightUIScale  = true,
    yieldUIScale    = true,
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
    if key == "showWorldQuests" and addon.focus and addon.focus.collapse then
        if value == false then
            addon.focus.collapse.pendingWQCollapse = true
        elseif value == true then
            addon.focus.collapse.pendingWQExpand = true
        end
    end
    -- When the "Show in-zone world quests" toggle is flipped on, invalidate the nearby
    -- WQ scan cache so the next FullLayout immediately re-scans for the current zone.
    if key == "showWorldQuests" and value == true and addon.focus then
        addon.focus.nearbyQuestCacheDirty = true
        addon.focus.nearbyQuestCache = nil
        addon.focus.nearbyTaskQuestCache = nil
    end
    if (key == "fontPath" or key == "titleFontPath" or key == "zoneFontPath" or key == "objectiveFontPath" or key == "sectionFontPath" or key == "progressBarFontPath" or key == "presenceTitleFontPath" or key == "presenceSubtitleFontPath") and updateOptionsPanelFontsRef then
        updateOptionsPanelFontsRef()
    end
    if TYPOGRAPHY_KEYS[key] and addon.UpdateFontObjectsFromDB then
        addon.UpdateFontObjectsFromDB()
    end
    if MPLUS_TYPOGRAPHY_KEYS[key] and addon.ApplyMplusTypography then
        addon.ApplyMplusTypography()
    end
    if PRESENCE_KEYS[key] and addon.Presence then
        if addon.Presence.ApplyPresenceOptions then addon.Presence.ApplyPresenceOptions() end
        if addon.Presence.ApplyBlizzardSuppression then addon.Presence.ApplyBlizzardSuppression() end
    end
    if INSIGHT_KEYS[key] and addon.Insight and addon.Insight.ApplyInsightOptions then
        addon.Insight.ApplyInsightOptions()
    end
    if VISTA_KEYS[key] and addon.Vista then
        if addon._colorPickerLive and VISTA_COLOR_LIVE_KEYS[key] then
            if addon.Vista.ApplyColors then addon.Vista.ApplyColors() end
        elseif addon.Vista.ApplyOptions then
            local fn = addon.Vista.ApplyOptions
            if C_Timer and C_Timer.After then
                C_Timer.After(0, fn)
            else
                fn()
            end
        end
    end
    if key == "lockPosition" and addon.UpdateResizeHandleVisibility then
        addon.UpdateResizeHandleVisibility()
    end
    if (key == "backdropOpacity" or key == "backdropColorR" or key == "backdropColorG" or key == "backdropColorB") and addon.ApplyBackdropOpacity then
        addon.ApplyBackdropOpacity()
    end
    if addon._colorPickerLive and COLOR_LIVE_KEYS[key] then
        OptionsData_NotifyMainAddon_Live()
        return
    end
    -- Scale keys are handled by debounced callbacks in the slider set lambdas.
    -- Do NOT call NotifyMainAddon here or FullLayout runs on every integer drag step.
    if SCALE_DEBOUNCE_KEYS[key] then return end
    OptionsData_NotifyMainAddon()
end

--- Lightweight notify for live color picker: updates visuals without FullLayout.
function OptionsData_NotifyMainAddon_Live()
    local applyTy = _G.HorizonSuite_ApplyTypography or addon.ApplyTypography
    if applyTy then applyTy() end
    if addon.ApplyBackdropOpacity then addon.ApplyBackdropOpacity() end
    if addon.ApplyBorderVisibility then addon.ApplyBorderVisibility() end
    if addon.ApplyFocusColors then addon.ApplyFocusColors() end
    if addon.Vista and addon.Vista.ApplyColors then addon.Vista.ApplyColors() end
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
    -- Back-compat: if saved value is a concrete font file path, try to map it
    -- back to the corresponding LSM key so the dropdown can select it.
    if addon.GetFontNameForPath then
        local mapped = addon.GetFontNameForPath(saved)
        if mapped and mapped ~= "" and mapped ~= "Custom" and mapped ~= saved then
            local path = addon.ResolveFontPath and addon.ResolveFontPath(mapped) or nil
            if path and path == saved then
                saved = mapped
            end
        end
    end
    for _, o in ipairs(list) do
        if o[2] == saved then return list end
    end
    local out = {}
    for i = 1, #list do out[i] = list[i] end
    -- If it's not one of our known choices, keep it selectable as "Custom".
    out[#out + 1] = { L["Custom"], saved }
    return out
end

local FONT_USE_GLOBAL = "__global__"

local function GetPerElementFontDropdownOptions(dbKey)
    if addon.RefreshFontList then addon.RefreshFontList() end
    local list = (addon.GetFontList and addon.GetFontList()) or {}
    local out = { { L["Use global font"], FONT_USE_GLOBAL } }
    for i = 1, #list do out[#out + 1] = list[i] end
    local saved = getDB(dbKey, FONT_USE_GLOBAL)
    if saved == FONT_USE_GLOBAL then return out end
    for _, o in ipairs(out) do
        if o[2] == saved then return out end
    end
    out[#out + 1] = { L["Custom"], saved }
    return out
end

local function DisplayPerElementFont(value)
    if value == FONT_USE_GLOBAL then return L["Use global font"] end
    if addon.GetFontNameForPath then return addon.GetFontNameForPath(value) end
    return value
end

local OUTLINE_OPTIONS = {
    { L["None"], "" },
    { L["Outline"], "OUTLINE" },
    { L["Thick Outline"], "THICKOUTLINE" },
}
local HIGHLIGHT_OPTIONS = {
    { L["Bar (left edge)"], "bar-left" },
    { L["Bar (right edge)"], "bar-right" },
    { L["Bar (top edge)"], "bar-top" },
    { L["Bar (bottom edge)"], "bar-bottom" },
    { L["Outline only"], "outline" },
    { L["Soft glow"], "glow" },
    { L["Dual edge bars"], "bar-both" },
    { L["Pill left accent"], "pill-left" },
    { L["Highlight"], "highlight" },
}
local MPLUS_POSITION_OPTIONS = {
    { L["Top"], "top" },
    { L["Bottom"], "bottom" },
}
local MPLUS_FONT_OPTIONS = {
    { "Title Font", "TitleFont" },
    { "Objective Font", "ObjFont" },
    { "Section Font", "SectionFont" },
    { "Detail Font", "DetailFont" },
}
local TEXT_CASE_OPTIONS = {
    { L["Lower Case"], "lower" },
    { L["Upper Case"], "upper" },
    { L["Proper"], "proper" },
}
-- Use addon.QUEST_COLORS from Config as single source for quest type colors.
local COLOR_KEYS_ORDER = { "DEFAULT", "CAMPAIGN", "IMPORTANT", "LEGENDARY", "WORLD", "DELVES", "SCENARIO", "RAID", "ACHIEVEMENT", "WEEKLY", "DAILY", "COMPLETE", "RARE" }
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
-- OptionCategories: Modules, Panel, Display, Typography, Behaviour, Mythic+, Delves, Content Types, Colors, Blacklist
-- ---------------------------------------------------------------------------

local OptionCategories = {
    {
        key = "Profiles",
        name = L["Profiles"] or "Profiles",
        moduleKey = nil,
        options = function()
            local opts = {}

            local function profileDropdownOptions()
                local list = addon.ListProfiles and addon.ListProfiles() or {}
                local out = {}
                for _, k in ipairs(list) do
                    if k ~= "Default" then
                        out[#out + 1] = { k, k }
                    end
                end
                return out
            end

            -- Section A: Global switch + current profile
            opts[#opts + 1] = { type = "section", name = L["Profiles"] or "Profiles" }

            opts[#opts + 1] = {
                type = "toggle",
                name = L["Use global profile (account-wide)"] or "Use global profile (account-wide)",
                desc = L["All characters use the same profile."] or "All characters use the same profile.",
                dbKey = "_profiles_useGlobal",
                get = function()
                    local useGlobal = addon.GetProfileModeState and select(1, addon.GetProfileModeState())
                    return useGlobal == true
                end,
                set = function(v)
                    local currentKey = addon.GetActiveProfileKey and addon.GetActiveProfileKey()
                    if addon.SetUseGlobalProfile then addon.SetUseGlobalProfile(v) end
                    if v and currentKey and addon.SetGlobalProfileKey then
                        addon.SetGlobalProfileKey(currentKey)
                    end
                    OptionsData_NotifyMainAddon()
                    if addon.OptionsPanel_Refresh then addon.OptionsPanel_Refresh() end
                end,
            }

                opts[#opts + 1] = {
                    type = "dropdown",
                    name = L["Current profile"] or "Current profile",
                    desc = L["Select the profile currently in use."] or "Select the profile currently in use.",
                    dbKey = "_profiles_current",
                    options = profileDropdownOptions,
                    disabled = function()
                        if not addon.GetProfileModeState then return false end
                        local useGlobal, usePerSpec = addon.GetProfileModeState()
                        return (useGlobal ~= true) and (usePerSpec == true)
                    end,
                    get = function() return (addon.GetActiveProfileKey and addon.GetActiveProfileKey()) end,
                    set = function(v)
                        if addon.SetActiveProfileKey then addon.SetActiveProfileKey(v) end
                        addon._profileCopyFrom = nil
                        OptionsData_NotifyMainAddon()
                        if addon.OptionsPanel_Refresh then addon.OptionsPanel_Refresh() end
                    end,
                }

                -- Section B: Per-spec switch + spec dropdowns
                opts[#opts + 1] = { type = "section", name = L["Specialization"] or "Specialization" }

                opts[#opts + 1] = {
                    type = "toggle",
                    name = L["Enable per specialization profiles"] or "Enable per specialization profiles",
                    desc = L["Pick different profiles per spec."] or "Pick different profiles per spec.",
                    dbKey = "_profiles_usePerSpec",
                    disabled = function()
                        local useGlobal = addon.GetProfileModeState and select(1, addon.GetProfileModeState())
                        return useGlobal == true
                    end,
                    get = function()
                        if not addon.GetProfileModeState then return false end
                        local useGlobal, usePerSpec = addon.GetProfileModeState()
                        return (useGlobal ~= true) and (usePerSpec == true)
                    end,
                    set = function(v)
                        if v and addon.GetActiveProfileKey and addon.SetPerSpecProfileKey then
                            local baseKey = addon.GetActiveProfileKey()
                            if baseKey then
                                local currentSpec = GetSpecialization and GetSpecialization() or nil
                                for si = 1, 4 do
                                    if si == currentSpec then
                                        addon.SetPerSpecProfileKey(si, baseKey)
                                    else
                                        local _, _, _, perSpec = addon.GetProfileModeState()
                                        if not (type(perSpec) == "table" and type(perSpec[si]) == "string" and perSpec[si] ~= "") then
                                            addon.SetPerSpecProfileKey(si, baseKey)
                                        end
                                    end
                                end
                            end
                        end
                        if addon.SetUsePerSpecProfiles then addon.SetUsePerSpecProfiles(v) end
                        OptionsData_NotifyMainAddon()
                        if addon.OptionsPanel_Refresh then addon.OptionsPanel_Refresh() end
                    end,
                }

                local function specProfileOptions()
                    local list = addon.ListProfiles and addon.ListProfiles() or {}
                    local out = {}
                    for _, k in ipairs(list) do
                        if k ~= "Default" then
                            out[#out + 1] = { k, k }
                        end
                    end
                    return out
                end

                for specIndex = 1, 4 do
                    local function specNameFn()
                        if addon.ListSpecOptions then
                            local specOpts = addon.ListSpecOptions()
                            for _, pair in ipairs(specOpts) do
                                if tonumber(pair[1]) == specIndex then
                                    return pair[2]
                                end
                            end
                        end
                        return ("Spec %d"):format(specIndex)
                    end
                    local function specHiddenFn()
                        local numSpecs = _G.GetNumSpecializations and _G.GetNumSpecializations() or 0
                        if numSpecs < 1 then return false end
                        return specIndex > numSpecs
                    end
                    opts[#opts + 1] = {
                        type = "dropdown",
                        name = specNameFn,
                        dbKey = "_profiles_spec_" .. tostring(specIndex),
                        options = specProfileOptions,
                        hidden = specHiddenFn,
                        disabled = function()
                            if not addon.GetProfileModeState then return true end
                            local useGlobal, usePerSpec = addon.GetProfileModeState()
                            return (useGlobal == true) or (usePerSpec ~= true)
                        end,
                        get = function()
                            if not addon.GetProfileModeState then
                                return (addon.GetActiveProfileKey and addon.GetActiveProfileKey())
                            end
                            local useGlobal, usePerSpec, _, perSpec = addon.GetProfileModeState()
                            if useGlobal ~= true and usePerSpec == true then
                                if type(perSpec) == "table" and type(perSpec[specIndex]) == "string" and perSpec[specIndex] ~= "" then
                                    return perSpec[specIndex]
                                end
                            end
                            return (addon.GetActiveProfileKey and addon.GetActiveProfileKey())
                        end,
                        set = function(v)
                            if addon.SetPerSpecProfileKey then addon.SetPerSpecProfileKey(specIndex, v) end
                            OptionsData_NotifyMainAddon()
                            if addon.OptionsPanel_Refresh then addon.OptionsPanel_Refresh() end
                        end,
                    }
                end

                -- Section C: Create / Copy profile
                opts[#opts + 1] = { type = "section", name = L["Create"] or "Create" }

                opts[#opts + 1] = {
                    type = "button",
                    name = L["Create new profile from Default template"] or "Create new profile from Default template",
                    desc = L["Creates a new profile with all default settings."] or "Creates a new profile with all default settings.",
                    dbKey = "_profiles_create_new",
                    onClick = function()
                        if addon.ShowCreateProfilePopup then addon.ShowCreateProfilePopup("Default") end
                    end,
                }

                opts[#opts + 1] = {
                    type = "dropdown",
                    name = L["Copy from profile"] or "Copy from profile",
                    desc = L["Source profile for copying."] or "Source profile for copying.",
                    dbKey = "_profiles_copyFrom",
                    options = profileDropdownOptions,
                    get = function()
                        local current = addon.GetActiveProfileKey and addon.GetActiveProfileKey() or nil
                        local list = addon.ListProfiles and addon.ListProfiles() or {}
                        if addon._profileCopyFrom and addon._profileCopyFrom ~= "" then
                            for _, k in ipairs(list) do
                                if k == addon._profileCopyFrom then return addon._profileCopyFrom end
                            end
                        end
                        addon._profileCopyFrom = current
                        return current
                    end,
                    set = function(v) addon._profileCopyFrom = v end,
                }

                opts[#opts + 1] = {
                    type = "button",
                    name = L["Copy from selected"] or "Copy from selected",
                    desc = L["Creates a new profile copied from the selected source profile."] or "Creates a new profile copied from the selected source profile.",
                    dbKey = "_profiles_copy_selected",
                    onClick = function()
                        local src = addon._profileCopyFrom or (addon.GetActiveProfileKey and addon.GetActiveProfileKey())
                        if addon.ShowCreateProfilePopup then addon.ShowCreateProfilePopup(src) end
                    end,
                }

                -- Section D: Delete profile
                opts[#opts + 1] = { type = "section", name = L["Delete"] or "Delete" }

                opts[#opts + 1] = {
                    type = "dropdown",
                    name = L["Delete profile"] or "Delete profile",
                    desc = L["Select a profile to delete (current and Default not shown)."] or "Select a profile to delete (current and Default not shown).",
                    dbKey = "_profiles_delete",
                    options = function()
                        local current = addon.GetActiveProfileKey and addon.GetActiveProfileKey() or nil
                        local list = addon.ListProfiles and addon.ListProfiles() or {}
                        local out = {}
                        for _, k in ipairs(list) do
                            if k ~= current and k ~= "Default" then out[#out + 1] = { k, k } end
                        end
                        return out
                    end,
                    get = function()
                        local current = addon.GetActiveProfileKey and addon.GetActiveProfileKey() or nil
                        local list = addon.ListProfiles and addon.ListProfiles() or {}
                        local function exists(k)
                            if not k or k == "" then return false end
                            for _, kk in ipairs(list) do if kk == k then return true end end
                            return false
                        end
                        if exists(addon._profileDeleteKey) and addon._profileDeleteKey ~= current and addon._profileDeleteKey ~= "Default" then
                            return addon._profileDeleteKey
                        end
                        for _, k in ipairs(list) do
                            if k ~= current and k ~= "Default" then
                                addon._profileDeleteKey = k
                                return k
                            end
                        end
                        addon._profileDeleteKey = nil
                        return ""
                    end,
                    set = function(v) addon._profileDeleteKey = v end,
                }

                opts[#opts + 1] = {
                    type = "button",
                    name = L["Delete selected"] or "Delete selected",
                    desc = L["Deletes the selected profile."] or "Deletes the selected profile.",
                    dbKey = "_profiles_delete_btn",
                    onClick = function()
                        local k = addon._profileDeleteKey
                        if not k or k == "" then
                            local current = addon.GetActiveProfileKey and addon.GetActiveProfileKey() or nil
                            local list = addon.ListProfiles and addon.ListProfiles() or {}
                            for _, kk in ipairs(list) do
                                if kk ~= current then k = kk; addon._profileDeleteKey = kk; break end
                            end
                        end
                        if not k or k == "" then return end
                        if addon.ShowDeleteProfilePopup then
                            addon.ShowDeleteProfilePopup(k)
                            return
                        end
                        if addon.DeleteProfile and addon.DeleteProfile(k) then
                            addon._profileDeleteKey = nil
                            OptionsData_NotifyMainAddon()
                            if addon.OptionsPanel_Refresh then addon.OptionsPanel_Refresh() end
                        end
                    end,
                }

                opts[#opts + 1] = { type = "section", name = L["Sharing"] or "Sharing" }

                opts[#opts + 1] = {
                    type = "dropdown",
                    name = L["Export profile"] or "Export profile",
                    desc = L["Select a profile to export."] or "Select a profile to export.",
                    dbKey = "_profiles_export_select",
                    options = function()
                        local list = addon.ListProfiles and addon.ListProfiles() or {}
                        local out = {}
                        for _, k in ipairs(list) do
                            if k ~= "Default" then out[#out + 1] = { k, k } end
                        end
                        return out
                    end,
                    get = function()
                        local list = addon.ListProfiles and addon.ListProfiles() or {}
                        if addon._profileExportKey then
                            for _, k in ipairs(list) do
                                if k == addon._profileExportKey and k ~= "Default" then return k end
                            end
                        end
                        local current = addon.GetActiveProfileKey and addon.GetActiveProfileKey() or nil
                        if current and current ~= "Default" then
                            addon._profileExportKey = current
                            return current
                        end
                        for _, k in ipairs(list) do
                            if k ~= "Default" then addon._profileExportKey = k; return k end
                        end
                        return ""
                    end,
                    set = function(v)
                        addon._profileExportKey = v
                        if addon.OptionsPanel_Refresh then addon.OptionsPanel_Refresh() end
                    end,
                }

                opts[#opts + 1] = {
                    type = "editbox",
                    labelText = L["Export string"] or "Export string",
                    dbKey = "_profiles_export_box",
                    height = 60,
                    readonly = true,
                    storeRef = "_profileExportEditBox",
                    get = function()
                        local key = addon._profileExportKey
                        if not key or key == "" then
                            local current = addon.GetActiveProfileKey and addon.GetActiveProfileKey() or nil
                            if current and current ~= "Default" then
                                key = current
                                addon._profileExportKey = key
                            else
                                local list = addon.ListProfiles and addon.ListProfiles() or {}
                                for _, k in ipairs(list) do
                                    if k ~= "Default" then key = k; addon._profileExportKey = k; break end
                                end
                            end
                        end
                        if not key or key == "" then return "" end
                        return (addon.ExportProfile and addon.ExportProfile(key)) or ""
                    end,
                }

                opts[#opts + 1] = {
                    type = "editbox",
                    labelText = L["Import string"] or "Import string",
                    dbKey = "_profiles_import_box",
                    height = 60,
                    readonly = false,
                    get = function() return addon._profileImportString or "" end,
                    set = function(v)
                        addon._profileImportString = v
                        local valid = addon.ValidateProfileString and addon.ValidateProfileString(v) or false
                        addon._profileImportValid = valid
                    end,
                }

                opts[#opts + 1] = {
                    type = "button",
                    name = L["Import profile"] or "Import profile",
                    dbKey = "_profiles_import_btn",
                    onClick = function()
                        local str = addon._profileImportString
                        if not str or str == "" then
                            if addon.HSPrint then addon.HSPrint("No import string provided.") end
                            return
                        end
                        if not (addon.ValidateProfileString and addon.ValidateProfileString(str)) then
                            if addon.HSPrint then addon.HSPrint("Invalid profile string.") end
                            return
                        end
                        addon._profileImportSourceString = str
                        if StaticPopup_Show then
                            StaticPopup_Show("HORIZONSUITE_IMPORT_PROFILE")
                        end
                    end,
                }

                return opts
        end,
    },
    {
        key = "Modules",
        name = L["Modules"],
        moduleKey = nil,
        options = (function()
            local dev = _G.HorizonSuiteDevOverride
            local betaSuffix = dev and (" (" .. (L["Beta"] or "Beta") .. ")") or ""
            local opts = {
                { type = "section", name = "" },
                { type = "toggle", name = L["Enable Focus module"], desc = L["Show the objective tracker for quests, world quests, rares, achievements, and scenarios."], dbKey = "_module_focus", get = function() return addon:IsModuleEnabled("focus") end, set = function(v) addon:SetModuleEnabled("focus", v) end },
                { type = "toggle", name = L["Enable Presence module"], desc = L["Cinematic zone text and notifications (zone changes, level up, boss emotes, achievements, quest updates)."], dbKey = "_module_presence", get = function() return addon:IsModuleEnabled("presence") end, set = function(v) addon:SetModuleEnabled("presence", v) end },
                { type = "toggle", name = L["Enable Vista module"] or "Enable Vista module", desc = L["Cinematic square minimap with zone text, coordinates, time, and button collector."] or "Cinematic square minimap with zone text, coordinates, time, and button collector.", dbKey = "_module_vista", get = function() return addon:IsModuleEnabled("vista") end, set = function(v) addon:SetModuleEnabled("vista", v) end },
            }
            if dev and dev.showInsightToggle then
                opts[#opts + 1] = { type = "toggle", name = L["Enable Horizon Insight module"] .. betaSuffix, desc = L["Cinematic tooltips with class colors, spec display, and faction icons."], dbKey = "_module_insight", get = function() return addon:IsModuleEnabled("insight") end, set = function(v) addon:SetModuleEnabled("insight", v) end }
            end
            if dev and dev.showYieldToggle then
                opts[#opts + 1] = { type = "toggle", name = L["Enable Yield module"] .. betaSuffix, desc = L["Cinematic loot notifications (items, money, currency, reputation)."], dbKey = "_module_yield", get = function() return addon:IsModuleEnabled("yield") end, set = function(v) addon:SetModuleEnabled("yield", v) end }
            end
            opts[#opts + 1] = { type = "section", name = L["Scaling"] }
            -- helper: refresh all modules after any scale change
            local function refreshAllScaling()
                if addon.ApplyTypography then addon.ApplyTypography() end
                if addon.ApplyDimensions then addon.ApplyDimensions() end
                if addon.ApplyMplusTypography then addon.ApplyMplusTypography() end
                if addon.Presence and addon.Presence.ApplyPresenceOptions then addon.Presence.ApplyPresenceOptions() end
                if addon.Vista and addon.Vista.ApplyScale then addon.Vista.ApplyScale() end
                if addon.Yield and addon.Yield.ApplyScale then addon.Yield.ApplyScale() end
                if _G.HorizonSuite_FullLayout and not InCombatLockdown() then _G.HorizonSuite_FullLayout() end
            end
            -- Debounce: write DB immediately on every slider step, but delay the heavy
            -- apply call (typography, dimensions, FullLayout) until the user pauses.
            -- Each call cancels any in-flight timer and schedules a fresh one.
            local scalingDebounceTimers = {}
            local SCALE_DEBOUNCE = 0.15  -- seconds to wait after last change
            local function debouncedRefresh(key, applyFn)
                if scalingDebounceTimers[key] then
                    scalingDebounceTimers[key]:Cancel()
                    scalingDebounceTimers[key] = nil
                end
                scalingDebounceTimers[key] = C_Timer.NewTimer(SCALE_DEBOUNCE, function()
                    scalingDebounceTimers[key] = nil
                    applyFn()
                end)
            end
            local function isPerModule() return getDB("perModuleScaling", false) end
            local function isNotPerModule() return not isPerModule() end
            opts[#opts + 1] = { type = "slider", name = L["Global UI scale"], desc = L["Scale all sizes, spacings, and fonts by this factor (50–200%). Does not change your configured values."], dbKey = "globalUIScale_pct", min = 50, max = 200,
                disabled = isPerModule,
                get = function()
                    return math.floor((tonumber(getDB("globalUIScale", 1)) or 1) * 100 + 0.5)
                end, set = function(v)
                    local scale = math.max(50, math.min(200, v)) / 100
                    setDB("globalUIScale", scale)
                    debouncedRefresh("global", refreshAllScaling)
                end }
            opts[#opts + 1] = { type = "toggle", name = L["Per-module scaling"], desc = L["Override the global scale with individual sliders for each module."], dbKey = "perModuleScaling", get = function() return isPerModule() end, set = function(v)
                setDB("perModuleScaling", v)
                refreshAllScaling()
                if addon.OptionsPanel_Refresh then addon.OptionsPanel_Refresh() end
            end }
            -- Per-module sliders (visible always, but only active when per-module scaling is on)
            opts[#opts + 1] = { type = "slider", name = L["Focus scale"], desc = L["Scale for the Focus objective tracker (50–200%)."], dbKey = "focusUIScale_pct", min = 50, max = 200,
                disabled = isNotPerModule,
                get = function()
                    return math.floor((tonumber(getDB("focusUIScale", 1)) or 1) * 100 + 0.5)
                end, set = function(v)
                    setDB("focusUIScale", math.max(50, math.min(200, v)) / 100)
                    debouncedRefresh("focus", refreshAllScaling)
                end }
            opts[#opts + 1] = { type = "slider", name = L["Presence scale"], desc = L["Scale for the Presence cinematic text (50–200%)."], dbKey = "presenceUIScale_pct", min = 50, max = 200,
                disabled = isNotPerModule,
                get = function()
                    return math.floor((tonumber(getDB("presenceUIScale", 1)) or 1) * 100 + 0.5)
                end, set = function(v)
                    setDB("presenceUIScale", math.max(50, math.min(200, v)) / 100)
                    debouncedRefresh("presence", function()
                        if addon.Presence and addon.Presence.ApplyPresenceOptions then addon.Presence.ApplyPresenceOptions() end
                    end)
                end }
            opts[#opts + 1] = { type = "slider", name = L["Vista scale"], desc = L["Scale for the Vista minimap module (50–200%)."], dbKey = "vistaUIScale_pct", min = 50, max = 200,
                disabled = isNotPerModule,
                get = function()
                    return math.floor((tonumber(getDB("vistaUIScale", 1)) or 1) * 100 + 0.5)
                end, set = function(v)
                    setDB("vistaUIScale", math.max(50, math.min(200, v)) / 100)
                    debouncedRefresh("vista", function()
                        if addon.Vista and addon.Vista.ApplyScale then addon.Vista.ApplyScale() end
                    end)
                end }
            if dev and dev.showInsightToggle then
                opts[#opts + 1] = { type = "slider", name = L["Insight scale"], desc = L["Scale for the Insight tooltip module (50–200%)."], dbKey = "insightUIScale_pct", min = 50, max = 200,
                    disabled = isNotPerModule,
                    get = function()
                        return math.floor((tonumber(getDB("insightUIScale", 1)) or 1) * 100 + 0.5)
                    end, set = function(v)
                        setDB("insightUIScale", math.max(50, math.min(200, v)) / 100)
                        -- Insight has no heavy apply; no debounce needed.
                    end }
            end
            if dev and dev.showYieldToggle then
                opts[#opts + 1] = { type = "slider", name = L["Yield scale"], desc = L["Scale for the Yield loot toast module (50–200%)."], dbKey = "yieldUIScale_pct", min = 50, max = 200,
                    disabled = isNotPerModule,
                    get = function()
                        return math.floor((tonumber(getDB("yieldUIScale", 1)) or 1) * 100 + 0.5)
                    end, set = function(v)
                        setDB("yieldUIScale", math.max(50, math.min(200, v)) / 100)
                        debouncedRefresh("yield", function()
                            if addon.Yield and addon.Yield.ApplyScale then addon.Yield.ApplyScale() end
                        end)
                    end }
            end
            return opts
        end)(),
    },
    {
        key = "Panel",
        name = L["Panel"],
        moduleKey = "focus",
        options = {
            { type = "section", name = L["Panel behaviour"] },
            { type = "toggle", name = L["Lock position"], desc = L["Prevent dragging the tracker."], dbKey = "lockPosition", get = function() return getDB("lockPosition", false) end, set = function(v) setDB("lockPosition", v) end },
            { type = "toggle", name = L["Grow upward"], desc = L["Anchor at bottom so the list grows upward."], dbKey = "growUp", get = function() return getDB("growUp", false) end, set = function(v) setDB("growUp", v) end },
            { type = "toggle", name = L["Start collapsed"], desc = L["Start with only the header shown until you expand."], dbKey = "collapsed", get = function() return getDB("collapsed", false) end, set = function(v) setDB("collapsed", v) end },
            { type = "section", name = L["Dimensions"] },
            { type = "slider", name = L["Panel width"], desc = L["Tracker width in pixels."], dbKey = "panelWidth", min = 180, max = 800, get = function() return getDB("panelWidth", 260) end, set = function(v) setDB("panelWidth", math.max(180, math.min(800, v))) end },
            { type = "slider", name = L["Max content height"], desc = L["Max height of the scrollable list (pixels)."], dbKey = "maxContentHeight", min = 200, max = 1000, get = function() return getDB("maxContentHeight", 480) end, set = function(v) setDB("maxContentHeight", math.max(200, math.min(1000, v))) end },
            { type = "section", name = L["Appearance"] },
            { type = "slider", name = L["Backdrop opacity"], desc = L["Panel background opacity (0–1)."], dbKey = "backdropOpacity", min = 0, max = 1, get = function() return tonumber(getDB("backdropOpacity", 0)) or 0 end, set = function(v) setDB("backdropOpacity", v) end },
            { type = "color", name = L["Backdrop color"], desc = L["Panel background color."], dbKey = "backdropColor", get = function() return getDB("backdropColorR", 0.08), getDB("backdropColorG", 0.08), getDB("backdropColorB", 0.12) end, set = function(r, g, b) setDB("backdropColorR", r); setDB("backdropColorG", g); setDB("backdropColorB", b) end },
            { type = "toggle", name = L["Show border"], desc = L["Show border around the tracker."], dbKey = "showBorder", get = function() return getDB("showBorder", false) end, set = function(v) setDB("showBorder", v) end },
            { type = "toggle", name = L["Show scroll indicator"], desc = L["Show a visual hint when the list has more content than is visible."], dbKey = "showScrollIndicator", get = function() return getDB("showScrollIndicator", false) end, set = function(v) setDB("showScrollIndicator", v) end },
            { type = "dropdown", name = L["Scroll indicator style"], desc = L["Choose between a fade-out gradient or a small arrow to indicate scrollable content."], dbKey = "scrollIndicatorStyle", options = { { L["Fade"], "fade" }, { L["Arrow"], "arrow" } }, get = function() return getDB("scrollIndicatorStyle", "fade") end, set = function(v) setDB("scrollIndicatorStyle", v) end, disabled = function() return not getDB("showScrollIndicator", false) end },
            { type = "section", name = L["Instance"] },
            { type = "toggle", name = L["Show in dungeon"], desc = L["Show tracker in party dungeons."], dbKey = "showInDungeon", get = function() return getDB("showInDungeon", false) end, set = function(v) setDB("showInDungeon", v) end },
            { type = "toggle", name = L["Show in raid"], desc = L["Show tracker in raids."], dbKey = "showInRaid", get = function() return getDB("showInRaid", false) end, set = function(v) setDB("showInRaid", v) end },
            { type = "toggle", name = L["Show in battleground"], desc = L["Show tracker in battlegrounds."], dbKey = "showInBattleground", get = function() return getDB("showInBattleground", false) end, set = function(v) setDB("showInBattleground", v) end },
            { type = "toggle", name = L["Show in arena"], desc = L["Show tracker in arenas."], dbKey = "showInArena", get = function() return getDB("showInArena", false) end, set = function(v) setDB("showInArena", v) end },
            { type = "section", name = L["Combat"] },
            { type = "dropdown", name = L["Combat visibility"], desc = L["How the tracker behaves in combat: show, fade to reduced opacity, or hide."], dbKey = "combatVisibility", options = { { L["Show"], "show" }, { L["Fade"], "fade" }, { L["Hide"], "hide" } }, get = function() return addon.GetCombatVisibility() end, set = function(v) setDB("combatVisibility", v); if addon.FullLayout then addon.FullLayout() end end },
            { type = "slider", name = L["Combat fade opacity"], desc = L["How visible the tracker is when faded in combat (0 = invisible). Only applies when Combat visibility is Fade."], dbKey = "combatFadeOpacity", min = 0, max = 100, get = function() return math.max(0, math.min(100, tonumber(getDB("combatFadeOpacity", 30)) or 30)) end, set = function(v) setDB("combatFadeOpacity", math.max(0, math.min(100, v))); if addon.FullLayout then addon.FullLayout() end end },
            { type = "section", name = L["Mouseover"] },
            { type = "toggle", name = L["Show only on mouseover"], desc = L["Fade tracker when not hovering; move mouse over it to show."], dbKey = "showOnMouseoverOnly", get = function() return getDB("showOnMouseoverOnly", false) end, set = function(v) setDB("showOnMouseoverOnly", v); if addon.FullLayout then addon.FullLayout() end end },
            { type = "slider", name = L["Faded opacity"], desc = L["How visible the tracker is when faded (0 = invisible)."], dbKey = "fadeOnMouseoverOpacity", min = 0, max = 100, get = function() return math.max(0, math.min(100, tonumber(getDB("fadeOnMouseoverOpacity", 10)) or 10)) end, set = function(v) setDB("fadeOnMouseoverOpacity", math.max(0, math.min(100, v))); if addon.FullLayout then addon.FullLayout() end end },
            { type = "section", name = L["Filtering"] },
            { type = "toggle", name = L["Only show quests in current zone"], desc = L["Hide quests outside your current zone."], dbKey = "filterByZone", get = function() return getDB("filterByZone", false) end, set = function(v) setDB("filterByZone", v) end },
        },
    },
    {
        key = "Display",
        name = L["Display"],
        moduleKey = "focus",
        options = {
            { type = "section", name = L["Header"] },
            { type = "toggle", name = L["Show quest count"], desc = L["Show quest count in header."], dbKey = "showQuestCount", get = function() return getDB("showQuestCount", true) end, set = function(v) setDB("showQuestCount", v) end },
            { type = "dropdown", name = L["Header count format"], desc = L["Tracked/in-log or in-log/max-slots. Tracked excludes world/live-in-zone quests."], dbKey = "headerCountMode", options = { { L["Tracked / in log"], "trackedLog" }, { L["In log / max slots"], "logMax" } }, get = function() return getDB("headerCountMode", "trackedLog") end, set = function(v) setDB("headerCountMode", v) end },
            { type = "toggle", name = L["Show header divider"], desc = L["Show the line below the header."], dbKey = "showHeaderDivider", get = function() return getDB("showHeaderDivider", true) end, set = function(v) setDB("showHeaderDivider", v) end },
            { type = "color", name = L["Header color"], desc = L["Color of the OBJECTIVES header text."], dbKey = "headerColor", default = addon.HEADER_COLOR },
            { type = "slider", name = L["Header height"], desc = L["Height of the header bar in pixels (18–48)."], dbKey = "headerHeight", min = 18, max = 48, get = function() return math.max(18, math.min(48, tonumber(getDB("headerHeight", addon.HEADER_HEIGHT)) or addon.HEADER_HEIGHT)) end, set = function(v) setDB("headerHeight", math.max(18, math.min(48, v))) end },
            { type = "toggle", name = L["Super-minimal mode"], desc = L["Hide header for a pure text list."], dbKey = "hideObjectivesHeader", get = function() return getDB("hideObjectivesHeader", false) end, set = function(v) setDB("hideObjectivesHeader", v) end },
            { type = "toggle", name = L["Show options button"], desc = L["Show the Options button in the tracker header."], dbKey = "hideOptionsButton", get = function() return not getDB("hideOptionsButton", false) end, set = function(v) setDB("hideOptionsButton", not v) end },
            { type = "section", name = L["List"] },
            { type = "toggle", name = L["Show section headers"], desc = L["Show category labels above each group."], dbKey = "showSectionHeaders", get = function() return getDB("showSectionHeaders", true) end, set = function(v) setDB("showSectionHeaders", v) end },
            { type = "toggle", name = L["Show category headers when collapsed"], desc = L["Keep section headers visible when collapsed; click to expand a category."], dbKey = "showSectionHeadersWhenCollapsed", get = function() return getDB("showSectionHeadersWhenCollapsed", false) end, set = function(v) setDB("showSectionHeadersWhenCollapsed", v) end },
            { type = "toggle", name = L["Show Nearby (Current Zone) group"], desc = L["Show in-zone quests in a dedicated Current Zone section. When off, they appear in their normal category."], dbKey = "showNearbyGroup", get = function() return getDB("showNearbyGroup", true) end, set = function(v) setDB("showNearbyGroup", v) end },
            { type = "toggle", name = L["Show zone labels"], desc = L["Show zone name under each quest title."], dbKey = "showZoneLabels", get = function() return getDB("showZoneLabels", true) end, set = function(v) setDB("showZoneLabels", v) end },
            { type = "dropdown", name = L["Active quest highlight"], desc = L["How the focused quest is highlighted."], dbKey = "activeQuestHighlight", options = HIGHLIGHT_OPTIONS, get = getActiveQuestHighlight, set = function(v) setDB("activeQuestHighlight", v) end },
            { type = "toggle", name = L["Show quest item buttons"], desc = L["Show usable quest item button next to each quest."], dbKey = "showQuestItemButtons", get = function() return getDB("showQuestItemButtons", false) end, set = function(v) setDB("showQuestItemButtons", v) end },
            { type = "dropdown", name = L["Objective prefix"], desc = L["Prefix each objective with a number or hyphen."], dbKey = "objectivePrefixStyle", options = { { L["None"], "none" }, { L["Numbers (1. 2. 3.)"], "numbers" }, { L["Hyphens (-)"], "hyphens" } }, get = function() return getDB("objectivePrefixStyle", "none") end, set = function(v) setDB("objectivePrefixStyle", v) end },
            { type = "toggle", name = L["Show entry numbers"], desc = L["Prefix quest titles with 1., 2., 3. within each category."], dbKey = "showCategoryEntryNumbers", get = function() return getDB("showCategoryEntryNumbers", true) end, set = function(v) setDB("showCategoryEntryNumbers", v) end },
            { type = "toggle", name = L["Show completed count"], desc = L["Show X/Y progress in quest title."], dbKey = "showCompletedCount", get = function() return getDB("showCompletedCount", false) end, set = function(v) setDB("showCompletedCount", v) end },
            { type = "toggle", name = L["Show objective progress bar"], desc = L["Show a progress bar under objectives that have numeric progress (e.g. 3/250). Only applies to entries with a single arithmetic objective where the required amount is greater than 1."], dbKey = "showObjectiveProgressBar", get = function() return getDB("showObjectiveProgressBar", false) end, set = function(v)
                setDB("showObjectiveProgressBar", v)
                -- Defer refresh until after toggle animation (0.15s) so this toggle animates like the others
                if C_Timer and C_Timer.After and addon.OptionsPanel_Refresh then
                    C_Timer.After(0.2, addon.OptionsPanel_Refresh)
                elseif addon.OptionsPanel_Refresh then
                    addon.OptionsPanel_Refresh()
                end
            end },
            { type = "toggle", name = L["Use category color for progress bar"], desc = L["When on, the progress bar matches the quest/achievement category color. When off, uses the custom fill color below."], dbKey = "progressBarUseCategoryColor", get = function() return getDB("progressBarUseCategoryColor", true) end, set = function(v) setDB("progressBarUseCategoryColor", v) end, disabled = function() return not getDB("showObjectiveProgressBar", false) end },
            { type = "dropdown", name = L["Completed objectives"], desc = L["For multi-objective quests, how to display objectives you've completed (e.g. 1/1)."], dbKey = "questCompletedObjectiveDisplay", options = { { L["Show all"], "off" }, { L["Fade completed"], "fade" }, { L["Hide completed"], "hide" } }, get = function() return getDB("questCompletedObjectiveDisplay", "off") end, set = function(v) setDB("questCompletedObjectiveDisplay", v) end },
            { type = "toggle", name = L["Use tick for completed objectives"], desc = L["When on, completed objectives show a checkmark (✓) instead of green color."], dbKey = "useTickForCompletedObjectives", get = function() return getDB("useTickForCompletedObjectives", false) end, set = function(v) setDB("useTickForCompletedObjectives", v) end },
            { type = "toggle", name = L["Show quest type icons"], desc = L["Show quest type icon in the Focus tracker (quest accept/complete, world quest, quest update)."], dbKey = "showQuestTypeIcons", get = function() return getDB("showQuestTypeIcons", false) end, set = function(v) setDB("showQuestTypeIcons", v) end },
            { type = "toggle", name = L["Show icon for in-zone auto-tracking"], desc = L["Display an icon next to auto-tracked world quests and weeklies/dailies that are not yet in your quest log (in-zone only)."], dbKey = "showInZoneSuffix", get = function() return getDB("showInZoneSuffix", true) end, set = function(v) setDB("showInZoneSuffix", v) end },
            { type = "dropdown", name = L["Auto-track icon"], desc = L["Choose which icon to display next to auto-tracked in-zone entries."], dbKey = "autoTrackIcon", options = addon.GetRadarIconOptions and addon.GetRadarIconOptions() or {}, get = function() return getDB("autoTrackIcon", "radar1") end, set = function(v) setDB("autoTrackIcon", v) end, disabled = function() return not getDB("showInZoneSuffix", true) end },
            { type = "toggle", name = L["Show quest level"], desc = L["Show quest level next to title."], dbKey = "showQuestLevel", get = function() return getDB("showQuestLevel", false) end, set = function(v) setDB("showQuestLevel", v) end },
            { type = "toggle", name = L["Dim non-focused quests"], desc = L["Slightly dim title, zone, objectives, and section headers that are not focused."], dbKey = "dimNonSuperTracked", get = function() return getDB("dimNonSuperTracked", false) end, set = function(v) setDB("dimNonSuperTracked", v) end },
            { type = "section", name = L["Highlight"] },
            { type = "slider", name = L["Highlight alpha"], desc = L["Opacity of focused quest highlight (0–1)."], dbKey = "highlightAlpha", min = 0, max = 1, get = function() return tonumber(getDB("highlightAlpha", 0.25)) or 0.25 end, set = function(v) setDB("highlightAlpha", v) end },
            { type = "slider", name = L["Bar width"], desc = L["Width of bar-style highlights (2–6 px)."], dbKey = "highlightBarWidth", min = 2, max = 6, get = function() return math.max(2, math.min(6, tonumber(getDB("highlightBarWidth", 2)) or 2)) end, set = function(v) setDB("highlightBarWidth", math.max(2, math.min(6, v))) end },
            { type = "section", name = L["Spacing"] },
            { type = "toggle", name = L["Compact mode"], desc = L["Preset: sets entry and objective spacing to 4 and 1 px."], dbKey = "compactMode", get = function() return getDB("compactMode", false) end, set = function(v) setDB("compactMode", v); if v then setDB("titleSpacing", 4); setDB("objSpacing", 1) else setDB("titleSpacing", 8); setDB("objSpacing", 2) end end },
            { type = "slider", name = L["Spacing between quest entries (px)"], desc = L["Vertical gap between quest entries."], dbKey = "titleSpacing", min = 2, max = 20, get = function() return math.max(2, math.min(20, tonumber(getDB("titleSpacing", 8)) or 8)) end, set = function(v) setDB("titleSpacing", math.max(2, math.min(20, v))) end },
            { type = "slider", name = L["Spacing before category header (px)"], desc = L["Gap between last entry of a group and the next category label."], dbKey = "sectionSpacing", min = 0, max = 24, get = function() return math.max(0, math.min(24, tonumber(getDB("sectionSpacing", 10)) or 10)) end, set = function(v) setDB("sectionSpacing", math.max(0, math.min(24, v))) end },
            { type = "slider", name = L["Spacing after category header (px)"], desc = L["Gap between category label and first quest entry below it."], dbKey = "sectionToEntryGap", min = 0, max = 16, get = function() return math.max(0, math.min(16, tonumber(getDB("sectionToEntryGap", 6)) or 6)) end, set = function(v) setDB("sectionToEntryGap", math.max(0, math.min(16, v))) end },
            { type = "slider", name = L["Spacing between objectives (px)"], desc = L["Vertical gap between objective lines within a quest."], dbKey = "objSpacing", min = 0, max = 8, get = function() return math.max(0, math.min(8, tonumber(getDB("objSpacing", 2)) or 2)) end, set = function(v) setDB("objSpacing", math.max(0, math.min(8, v))) end },
            { type = "slider", name = L["Spacing below header (px)"], desc = L["Vertical gap between the objectives bar and the quest list."], dbKey = "headerToContentGap", min = 0, max = 24, get = function() return math.max(0, math.min(24, tonumber(getDB("headerToContentGap", 6)) or 6)) end, set = function(v) setDB("headerToContentGap", math.max(0, math.min(24, v))) end },
            { type = "button", name = L["Reset spacing"], onClick = function()
                setDB("compactMode", false)
                setDB("titleSpacing", 8)
                setDB("sectionSpacing", 10)
                setDB("sectionToEntryGap", 6)
                setDB("objSpacing", 2)
                setDB("headerToContentGap", 6)
            end, refreshIds = { "compactMode", "titleSpacing", "sectionSpacing", "sectionToEntryGap", "objSpacing", "headerToContentGap" } },
        },
    },
    {
        key = "Typography",
        name = L["Typography"],
        moduleKey = "focus",
        options = {
            { type = "section", name = L["Font"] },
            { type = "dropdown", name = L["Font"], desc = L["Font family."], dbKey = "fontPath", options = GetFontDropdownOptions, get = function() return getDB("fontPath", defaultFontPath) end, set = function(v) setDB("fontPath", v) end, displayFn = addon.GetFontNameForPath },
            { type = "dropdown", name = L["Title font"], desc = L["Font family for quest titles."], dbKey = "titleFontPath", searchable = true, options = function() return GetPerElementFontDropdownOptions("titleFontPath") end, get = function() return getDB("titleFontPath", FONT_USE_GLOBAL) end, set = function(v) setDB("titleFontPath", v) end, displayFn = DisplayPerElementFont },
            { type = "dropdown", name = L["Zone font"], desc = L["Font family for zone labels."], dbKey = "zoneFontPath", searchable = true, options = function() return GetPerElementFontDropdownOptions("zoneFontPath") end, get = function() return getDB("zoneFontPath", FONT_USE_GLOBAL) end, set = function(v) setDB("zoneFontPath", v) end, displayFn = DisplayPerElementFont },
            { type = "dropdown", name = L["Objective font"], desc = L["Font family for objective text."], dbKey = "objectiveFontPath", searchable = true, options = function() return GetPerElementFontDropdownOptions("objectiveFontPath") end, get = function() return getDB("objectiveFontPath", FONT_USE_GLOBAL) end, set = function(v) setDB("objectiveFontPath", v) end, displayFn = DisplayPerElementFont },
            { type = "dropdown", name = L["Section font"], desc = L["Font family for section headers."], dbKey = "sectionFontPath", searchable = true, options = function() return GetPerElementFontDropdownOptions("sectionFontPath") end, get = function() return getDB("sectionFontPath", FONT_USE_GLOBAL) end, set = function(v) setDB("sectionFontPath", v) end, displayFn = DisplayPerElementFont },
            { type = "dropdown", name = L["Progress bar font"], desc = L["Font family for the progress bar label."], dbKey = "progressBarFontPath", searchable = true, options = function() return GetPerElementFontDropdownOptions("progressBarFontPath") end, get = function() return getDB("progressBarFontPath", FONT_USE_GLOBAL) end, set = function(v) setDB("progressBarFontPath", v) end, displayFn = DisplayPerElementFont },
            { type = "slider", name = L["Header size"], desc = L["Header font size."], dbKey = "headerFontSize", min = 8, max = 32, get = function() return getDB("headerFontSize", 16) end, set = function(v) setDB("headerFontSize", v) end },
            { type = "slider", name = L["Title size"], desc = L["Quest title font size."], dbKey = "titleFontSize", min = 8, max = 24, get = function() return getDB("titleFontSize", 13) end, set = function(v) setDB("titleFontSize", v) end },
            { type = "slider", name = L["Objective size"], desc = L["Objective text font size."], dbKey = "objectiveFontSize", min = 8, max = 20, get = function() return getDB("objectiveFontSize", 11) end, set = function(v) setDB("objectiveFontSize", v) end },
            { type = "slider", name = L["Zone size"], desc = L["Zone label font size."], dbKey = "zoneFontSize", min = 8, max = 18, get = function() return getDB("zoneFontSize", 10) end, set = function(v) setDB("zoneFontSize", v) end },
            { type = "slider", name = L["Section size"], desc = L["Section header font size."], dbKey = "sectionFontSize", min = 8, max = 18, get = function() return getDB("sectionFontSize", 10) end, set = function(v) setDB("sectionFontSize", v) end },
            { type = "slider", name = L["Progress bar text size"], desc = L["Font size for the progress bar label. Also adjusts bar height."], dbKey = "progressBarFontSize", min = 7, max = 18, get = function() return getDB("progressBarFontSize", 10) end, set = function(v) setDB("progressBarFontSize", v) end },
            { type = "dropdown", name = L["Outline"], desc = L["Font outline style."], dbKey = "fontOutline", options = OUTLINE_OPTIONS, get = function() return getDB("fontOutline", "OUTLINE") end, set = function(v) setDB("fontOutline", v) end },
            { type = "section", name = L["Text case"] },
            { type = "dropdown", name = L["Header text case"], desc = L["Display case for header."], dbKey = "headerTextCase", options = TEXT_CASE_OPTIONS, get = function() local v = getDB("headerTextCase", "proper"); return (v == "default") and "proper" or v end, set = function(v) setDB("headerTextCase", v) end },
            { type = "dropdown", name = L["Section header case"], desc = L["Display case for category labels."], dbKey = "sectionHeaderTextCase", options = TEXT_CASE_OPTIONS, get = function() local v = getDB("sectionHeaderTextCase", "proper"); return (v == "default") and "proper" or v end, set = function(v) setDB("sectionHeaderTextCase", v) end },
            { type = "dropdown", name = L["Quest title case"], desc = L["Display case for quest titles."], dbKey = "questTitleCase", options = TEXT_CASE_OPTIONS, get = function() local v = getDB("questTitleCase", "proper"); return (v == "default") and "proper" or v end, set = function(v) setDB("questTitleCase", v) end },
            { type = "section", name = L["Shadow"] },
            { type = "toggle", name = L["Show text shadow"], desc = L["Enable drop shadow on text."], dbKey = "showTextShadow", get = function() return getDB("showTextShadow", true) end, set = function(v) setDB("showTextShadow", v) end },
            { type = "slider", name = L["Shadow X"], desc = L["Horizontal shadow offset."], dbKey = "shadowOffsetX", min = -10, max = 10, get = function() return getDB("shadowOffsetX", 2) end, set = function(v) setDB("shadowOffsetX", v) end },
            { type = "slider", name = L["Shadow Y"], desc = L["Vertical shadow offset."], dbKey = "shadowOffsetY", min = -10, max = 10, get = function() return getDB("shadowOffsetY", -2) end, set = function(v) setDB("shadowOffsetY", v) end },
            { type = "slider", name = L["Shadow alpha"], desc = L["Shadow opacity (0–1)."], dbKey = "shadowAlpha", min = 0, max = 1, get = function() return getDB("shadowAlpha", 0.8) end, set = function(v) setDB("shadowAlpha", v) end },
        },
    },
    {
        key = "Behaviour",
        name = L["Behaviour"],
        moduleKey = "focus",
        options = {
            { type = "section", name = L["Focus order"] },
            { type = "reorderList", name = L["Focus category order"], labelMap = addon.SECTION_LABELS, presets = addon.GROUP_ORDER_PRESETS, get = function() return addon.GetGroupOrder() end, set = function(order) addon.SetGroupOrder(order) end, desc = L["Drag to reorder categories. DELVES and SCENARIO EVENTS stay first."] },
            { type = "section", name = L["Sort"] },
            { type = "dropdown", name = L["Focus sort mode"], desc = L["Order of entries within each category."], dbKey = "entrySortMode", options = { { L["Alphabetical"], "alpha" }, { L["Quest Type"], "questType" }, { L["Zone"], "zone" }, { L["Quest Level"], "level" } }, get = function() return getDB("entrySortMode", "questType") end, set = function(v) setDB("entrySortMode", v) end },
            { type = "section", name = L["Interactions"] },
            { type = "toggle", name = L["Require Ctrl for focus & remove"], desc = L["Require Ctrl for focus/add (Left) and unfocus/untrack (Right) to prevent misclicks."], dbKey = "requireCtrlForQuestClicks", get = function() return getDB("requireCtrlForQuestClicks", false) end, set = function(v) setDB("requireCtrlForQuestClicks", v) end },
            { type = "toggle", name = L["Require Ctrl for click to complete"], desc = L["When on, requires Ctrl+Left-click to complete auto-complete quests. When off, plain Left-click completes them (Blizzard default). Only affects quests that can be completed by click (no NPC turn-in needed)."], dbKey = "requireModifierForClickToComplete", get = function() return getDB("requireModifierForClickToComplete", false) end, set = function(v) setDB("requireModifierForClickToComplete", v) end },
            { type = "toggle", name = L["Keep campaign quests in category"], desc = L["When on, campaign quests that are ready to turn in remain in the Campaign category instead of moving to Complete."], dbKey = "keepCampaignInCategory", get = function() return getDB("keepCampaignInCategory", false) end, set = function(v) setDB("keepCampaignInCategory", v); if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end; if _G.HorizonSuite_FullLayout then _G.HorizonSuite_FullLayout() end end },
            { type = "toggle", name = L["Keep important quests in category"], desc = L["When on, important quests that are ready to turn in remain in the Important category instead of moving to Complete."], dbKey = "keepImportantInCategory", get = function() return getDB("keepImportantInCategory", false) end, set = function(v) setDB("keepImportantInCategory", v); if _G.HorizonSuite_RequestRefresh then _G.HorizonSuite_RequestRefresh() end; if _G.HorizonSuite_FullLayout then _G.HorizonSuite_FullLayout() end end },
            { type = "section", name = L["Tracking"] },
            { type = "toggle", name = L["Auto-track accepted quests"], desc = L["When you accept a quest (quest log only, not world quests), add it to the tracker automatically."], dbKey = "autoTrackOnAccept", get = function() return getDB("autoTrackOnAccept", true) end, set = function(v) setDB("autoTrackOnAccept", v) end },
            { type = "toggle", name = L["Suppress untracked until reload"], desc = L["When on, right-click untrack on world quests and in-zone weeklies/dailies hides them until you reload or start a new session. When off, they reappear when you return to the zone."], dbKey = "suppressUntrackedUntilReload", get = function() return getDB("suppressUntrackedUntilReload", false) end, set = function(v) setDB("suppressUntrackedUntilReload", v) end },
            { type = "toggle", name = L["Permanently suppress untracked quests"], desc = L["When on, right-click untracked world quests and in-zone weeklies/dailies are hidden permanently (persists across reloads). Takes priority over 'Suppress until reload'. Accepting a suppressed quest removes it from the blacklist."], dbKey = "permanentlySuppressUntracked", get = function() return getDB("permanentlySuppressUntracked", false) end, set = function(v) setDB("permanentlySuppressUntracked", v) end },
            { type = "section", name = L["Animations"] },
            { type = "toggle", name = L["Animations"], desc = L["Enable slide and fade for quests."], dbKey = "animations", get = function() return getDB("animations", true) end, set = function(v) setDB("animations", v) end },
            { type = "toggle", name = L["Objective progress flash"], desc = L["Show flash when an objective completes."], dbKey = "objectiveProgressFlash", get = function() return getDB("objectiveProgressFlash", true) end, set = function(v) setDB("objectiveProgressFlash", v) end },
            { type = "dropdown", name = L["Flash intensity"], desc = L["How noticeable the objective-complete flash is."], dbKey = "objectiveProgressFlashIntensity", options = { { L["Subtle"], "subtle" }, { L["Medium"], "medium" }, { L["Strong"], "strong" } }, get = function() return getDB("objectiveProgressFlashIntensity", "subtle") end, set = function(v) setDB("objectiveProgressFlashIntensity", v) end },
            { type = "color", name = L["Flash color"], desc = L["Color of the objective-complete flash."], dbKey = "objectiveProgressFlashColor", default = { 1, 1, 1 } },
        },
    },
    {
        key = "MythicPlus",
        name = L["Mythic+"],
        moduleKey = "focus",
        options = {
            { type = "section", name = L["Behaviour"] },
            { type = "toggle", name = L["Show Mythic+ block"], desc = L["Show timer, completion %, and affixes in Mythic+ dungeons."], dbKey = "showMythicPlusBlock", get = function() return getDB("showMythicPlusBlock", false) end, set = function(v) setDB("showMythicPlusBlock", v) end },
            { type = "toggle", name = L["Always show M+ block"], desc = L["Show the M+ block whenever an active keystone is running"], dbKey = "mplusAlwaysShow", get = function() return getDB("mplusAlwaysShow", false) end, set = function(v) setDB("mplusAlwaysShow", v); if _G.HorizonSuite_FullLayout then _G.HorizonSuite_FullLayout() end end },
            { type = "toggle", name = L["Show affix icons"], desc = L["Show affix icons next to modifier names in the M+ block."], dbKey = "mplusShowAffixIcons", get = function() return getDB("mplusShowAffixIcons", true) end, set = function(v) setDB("mplusShowAffixIcons", v) end },
            { type = "toggle", name = L["Show affix descriptions in tooltip"], desc = L["Show affix descriptions when hovering over the M+ block."], dbKey = "mplusShowAffixDescriptions", get = function() return getDB("mplusShowAffixDescriptions", true) end, set = function(v) setDB("mplusShowAffixDescriptions", v) end },
            { type = "dropdown", name = L["M+ block position"], desc = L["Position of the Mythic+ block relative to the quest list."], dbKey = "mplusBlockPosition", options = MPLUS_POSITION_OPTIONS, get = function() return getDB("mplusBlockPosition", "top") end, set = function(v) setDB("mplusBlockPosition", v) end },
            { type = "dropdown", name = L["M+ completed boss display"], desc = L["How to show defeated bosses: checkmark icon or green color."], dbKey = "mplusBossCompletedDisplay", options = { { L["Checkmark"], "tick" }, { L["Green color"], "green" } }, get = function() return getDB("mplusBossCompletedDisplay", "tick") end, set = function(v) setDB("mplusBossCompletedDisplay", v); if addon.UpdateMplusBlock then addon.UpdateMplusBlock() end end },
            { type = "section", name = L["Typography"] },
            { type = "slider", name = L["Dungeon name size"], desc = L["Font size for dungeon name (8–32 px)."], dbKey = "mplusDungeonSize", min = 8, max = 32, step = 1, get = function() return math.max(8, math.min(32, tonumber(getDB("mplusDungeonSize", 14)) or 14)) end, set = function(v) setDB("mplusDungeonSize", math.max(8, math.min(32, v))) end },
            { type = "slider", name = L["Timer size"], desc = L["Font size for timer (8–32 px)."], dbKey = "mplusTimerSize", min = 8, max = 32, step = 1, get = function() return math.max(8, math.min(32, tonumber(getDB("mplusTimerSize", 13)) or 13)) end, set = function(v) setDB("mplusTimerSize", math.max(8, math.min(32, v))) end },
            { type = "slider", name = L["Progress size"], desc = L["Font size for enemy forces (8–32 px)."], dbKey = "mplusProgressSize", min = 8, max = 32, step = 1, get = function() return math.max(8, math.min(32, tonumber(getDB("mplusProgressSize", 12)) or 12)) end, set = function(v) setDB("mplusProgressSize", math.max(8, math.min(32, v))) end },
            { type = "slider", name = L["Affix size"], desc = L["Font size for affixes (8–32 px)."], dbKey = "mplusAffixSize", min = 8, max = 32, step = 1, get = function() return math.max(8, math.min(32, tonumber(getDB("mplusAffixSize", 12)) or 12)) end, set = function(v) setDB("mplusAffixSize", math.max(8, math.min(32, v))) end },
            { type = "slider", name = L["Boss size"], desc = L["Font size for boss names (8–32 px)."], dbKey = "mplusBossSize", min = 8, max = 32, step = 1, get = function() return math.max(8, math.min(32, tonumber(getDB("mplusBossSize", 12)) or 12)) end, set = function(v) setDB("mplusBossSize", math.max(8, math.min(32, v))) end },
            { type = "section", name = L["Colors"] },
            { type = "color", name = L["Dungeon name color"], desc = L["Text color for dungeon name."], dbKey = "mplusDungeonColor", get = function() return getDB("mplusDungeonColorR", 0.96), getDB("mplusDungeonColorG", 0.96), getDB("mplusDungeonColorB", 1.0) end, set = function(r, g, b) setDB("mplusDungeonColorR", r); setDB("mplusDungeonColorG", g); setDB("mplusDungeonColorB", b) end },
            { type = "color", name = L["Timer color"], desc = L["Text color for timer (in time)."], dbKey = "mplusTimerColor", get = function() return getDB("mplusTimerColorR", 0.6), getDB("mplusTimerColorG", 0.88), getDB("mplusTimerColorB", 1.0) end, set = function(r, g, b) setDB("mplusTimerColorR", r); setDB("mplusTimerColorG", g); setDB("mplusTimerColorB", b) end },
            { type = "color", name = L["Timer overtime color"], desc = L["Text color for timer when over the time limit."], dbKey = "mplusTimerOvertimeColor", get = function() return getDB("mplusTimerOvertimeColorR", 0.9), getDB("mplusTimerOvertimeColorG", 0.25), getDB("mplusTimerOvertimeColorB", 0.2) end, set = function(r, g, b) setDB("mplusTimerOvertimeColorR", r); setDB("mplusTimerOvertimeColorG", g); setDB("mplusTimerOvertimeColorB", b) end },
            { type = "color", name = L["Progress color"], desc = L["Text color for enemy forces."], dbKey = "mplusProgressColor", get = function() return getDB("mplusProgressColorR", 0.72), getDB("mplusProgressColorG", 0.76), getDB("mplusProgressColorB", 0.88) end, set = function(r, g, b) setDB("mplusProgressColorR", r); setDB("mplusProgressColorG", g); setDB("mplusProgressColorB", b) end },
            { type = "color", name = L["Bar fill color"], desc = L["Progress bar fill color (in progress)."], dbKey = "mplusBarColor", get = function() return getDB("mplusBarColorR", 0.20), getDB("mplusBarColorG", 0.45), getDB("mplusBarColorB", 0.60) end, set = function(r, g, b) setDB("mplusBarColorR", r); setDB("mplusBarColorG", g); setDB("mplusBarColorB", b) end },
            { type = "color", name = L["Bar complete color"], desc = L["Progress bar fill color when enemy forces are at 100%."], dbKey = "mplusBarDoneColor", get = function() return getDB("mplusBarDoneColorR", 0.15), getDB("mplusBarDoneColorG", 0.65), getDB("mplusBarDoneColorB", 0.25) end, set = function(r, g, b) setDB("mplusBarDoneColorR", r); setDB("mplusBarDoneColorG", g); setDB("mplusBarDoneColorB", b) end },
            { type = "color", name = L["Affix color"], desc = L["Text color for affixes."], dbKey = "mplusAffixColor", get = function() return getDB("mplusAffixColorR", 0.85), getDB("mplusAffixColorG", 0.85), getDB("mplusAffixColorB", 0.95) end, set = function(r, g, b) setDB("mplusAffixColorR", r); setDB("mplusAffixColorG", g); setDB("mplusAffixColorB", b) end },
            { type = "color", name = L["Boss color"], desc = L["Text color for boss names."], dbKey = "mplusBossColor", get = function() return getDB("mplusBossColorR", 0.78), getDB("mplusBossColorG", 0.82), getDB("mplusBossColorB", 0.92) end, set = function(r, g, b) setDB("mplusBossColorR", r); setDB("mplusBossColorG", g); setDB("mplusBossColorB", b) end },
            { type = "button", name = L["Reset Mythic+ typography"], onClick = function()
                setDB("mplusDungeonSize", 14)
                setDB("mplusDungeonColorR", 0.96); setDB("mplusDungeonColorG", 0.96); setDB("mplusDungeonColorB", 1.0)
                setDB("mplusTimerSize", 13)
                setDB("mplusTimerColorR", 0.6); setDB("mplusTimerColorG", 0.88); setDB("mplusTimerColorB", 1.0)
                setDB("mplusTimerOvertimeColorR", 0.9); setDB("mplusTimerOvertimeColorG", 0.25); setDB("mplusTimerOvertimeColorB", 0.2)
                setDB("mplusProgressSize", 12)
                setDB("mplusProgressColorR", 0.72); setDB("mplusProgressColorG", 0.76); setDB("mplusProgressColorB", 0.88)
                setDB("mplusBarColorR", 0.20); setDB("mplusBarColorG", 0.45); setDB("mplusBarColorB", 0.60)
                setDB("mplusBarDoneColorR", 0.15); setDB("mplusBarDoneColorG", 0.65); setDB("mplusBarDoneColorB", 0.25)
                setDB("mplusAffixSize", 12)
                setDB("mplusAffixColorR", 0.85); setDB("mplusAffixColorG", 0.85); setDB("mplusAffixColorB", 0.95)
                setDB("mplusBossSize", 12)
                setDB("mplusBossColorR", 0.78); setDB("mplusBossColorG", 0.82); setDB("mplusBossColorB", 0.92)
            end, refreshIds = { "mplusDungeonSize", "mplusDungeonColor", "mplusTimerSize", "mplusTimerColor", "mplusTimerOvertimeColor", "mplusProgressSize", "mplusProgressColor", "mplusBarColor", "mplusBarDoneColor", "mplusAffixSize", "mplusAffixColor", "mplusBossSize", "mplusBossColor" } },
        },
    },
    {
        key = "Delves",
        name = L["Delves"],
        moduleKey = "focus",
        options = {
            { type = "section", name = L["Behaviour"] },
            { type = "toggle", name = L["Show scenario events"], desc = L["Show active scenario and Delve activities. Delves appear in DELVES; other scenarios in SCENARIO EVENTS."], dbKey = "showScenarioEvents", get = function() return getDB("showScenarioEvents", true) end, set = function(v) setDB("showScenarioEvents", v) end },
            { type = "toggle", name = L["Hide other categories in Delve or Dungeon"], desc = L["In Delves or party dungeons, show only the Delve/Dungeon section."], dbKey = "hideOtherCategoriesInDelve", get = function() return getDB("hideOtherCategoriesInDelve", false) end, set = function(v) setDB("hideOtherCategoriesInDelve", v) end },
            { type = "toggle", name = L["Show affix names in Delves"], desc = L["Show season affix names on the first Delve entry. Requires Blizzard's objective tracker widgets to be populated; may not show when using a full tracker replacement."], dbKey = "showDelveAffixes", get = function() return getDB("showDelveAffixes", getDB("delveBlockShowAffixes", true)) end, set = function(v) setDB("showDelveAffixes", v); if addon.ScheduleRefresh then addon.ScheduleRefresh() end end },
            { type = "section", name = L["Scenario Bar"] },
            { type = "toggle", name = L["Cinematic scenario bar"], desc = L["Show timer and progress bar for scenario entries."], dbKey = "cinematicScenarioBar", get = function() return getDB("cinematicScenarioBar", true) end, set = function(v) setDB("cinematicScenarioBar", v) end },
            { type = "slider", name = L["Scenario bar opacity"], desc = L["Opacity of scenario timer/progress bar (0–1)."], dbKey = "scenarioBarOpacity", min = 0.3, max = 1, get = function() return tonumber(getDB("scenarioBarOpacity", 0.85)) or 0.85 end, set = function(v) setDB("scenarioBarOpacity", v) end },
            { type = "slider", name = L["Scenario bar height"], desc = L["Height of scenario progress bar (4–8 px)."], dbKey = "scenarioBarHeight", min = 4, max = 8, get = function() return math.max(4, math.min(8, tonumber(getDB("scenarioBarHeight", 6)) or 6)) end, set = function(v) setDB("scenarioBarHeight", math.max(4, math.min(8, v))) end },
        },
    },
    {
        key = "ContentTypes",
        name = L["Content Types"],
        moduleKey = "focus",
        options = {
            { type = "section", name = L["World quests"] },
            { type = "toggle", name = L["Show in-zone world quests"], desc = L["Auto-add world quests in your current zone. When off, only quests you've tracked or world quests you're in close proximity to appear (Blizzard default)."], dbKey = "showWorldQuests", get = function() return getDB("showWorldQuests", true) end, set = function(v) setDB("showWorldQuests", v) end },
            { type = "section", name = L["Rare bosses"] },
            { type = "toggle", name = L["Show rare bosses"], desc = L["Show rare boss vignettes in the list."], dbKey = "showRareBosses", get = function() return getDB("showRareBosses", true) end, set = function(v) setDB("showRareBosses", v) end },
            { type = "toggle", name = L["Rare added sound"], desc = L["Play a sound when a rare is added."], dbKey = "rareAddedSound", get = function() return getDB("rareAddedSound", true) end, set = function(v) setDB("rareAddedSound", v) end },
            { type = "section", name = L["Achievements"] },
            { type = "toggle", name = L["Show achievements"], desc = L["Show tracked achievements in the list."], dbKey = "showAchievements", get = function() return getDB("showAchievements", true) end, set = function(v) setDB("showAchievements", v) end },
            { type = "toggle", name = L["Show completed achievements"], desc = L["Include completed achievements in the tracker. When off, only in-progress tracked achievements are shown."], dbKey = "showCompletedAchievements", get = function() return getDB("showCompletedAchievements", false) end, set = function(v) setDB("showCompletedAchievements", v) end },
            { type = "toggle", name = L["Show achievement icons"], desc = L["Show each achievement's icon next to the title. Requires 'Show quest type icons' in Display."], dbKey = "showAchievementIcons", get = function() return getDB("showAchievementIcons", true) end, set = function(v) setDB("showAchievementIcons", v) end },
            { type = "toggle", name = L["Only show missing requirements"], desc = L["Show only criteria you haven't completed for each tracked achievement. When off, all criteria are shown."], dbKey = "achievementOnlyMissingRequirements", get = function() return getDB("achievementOnlyMissingRequirements", false) end, set = function(v) setDB("achievementOnlyMissingRequirements", v) end },
            { type = "section", name = L["Endeavors"] },
            { type = "toggle", name = L["Show endeavors"], desc = L["Show tracked Endeavors (Player Housing) in the list."], dbKey = "showEndeavors", get = function() return getDB("showEndeavors", true) end, set = function(v) setDB("showEndeavors", v) end },
            { type = "toggle", name = L["Show completed endeavors"], desc = L["Include completed Endeavors in the tracker. When off, only in-progress tracked Endeavors are shown."], dbKey = "showCompletedEndeavors", get = function() return getDB("showCompletedEndeavors", false) end, set = function(v) setDB("showCompletedEndeavors", v) end },
            { type = "section", name = L["Decor"] },
            { type = "toggle", name = L["Show decor"], desc = L["Show tracked housing decor in the list."], dbKey = "showDecor", get = function() return getDB("showDecor", true) end, set = function(v) setDB("showDecor", v) end },
            { type = "toggle", name = L["Show decor icons"], desc = L["Show each decor item's icon next to the title. Requires 'Show quest type icons' in Display."], dbKey = "showDecorIcons", get = function() return getDB("showDecorIcons", true) end, set = function(v) setDB("showDecorIcons", v) end },
            { type = "section", name = L["Adventure Guide"] },
            { type = "toggle", name = L["Show Traveler's Log"], desc = L["Show tracked Traveler's Log objectives (Shift+click in Adventure Guide) in the list."], dbKey = "showAdventureGuide", get = function() return getDB("showAdventureGuide", true) end, set = function(v) setDB("showAdventureGuide", v) end },
            { type = "toggle", name = L["Auto-remove completed activities"], desc = L["Automatically stop tracking Traveler's Log activities once they have been completed."], dbKey = "autoRemoveCompletedAdventureGuide", get = function() return getDB("autoRemoveCompletedAdventureGuide", true) end, set = function(v) setDB("autoRemoveCompletedAdventureGuide", v) end },
            { type = "section", name = L["Floating quest item"] },
            { type = "toggle", name = L["Show floating quest item"], desc = L["Show quick-use button for the focused quest's usable item."], dbKey = "showFloatingQuestItem", get = function() return getDB("showFloatingQuestItem", false) end, set = function(v) setDB("showFloatingQuestItem", v) end },
            { type = "toggle", name = L["Lock floating quest item position"], desc = L["Prevent dragging the floating quest item button."], dbKey = "lockFloatingQuestItemPosition", get = function() return getDB("lockFloatingQuestItemPosition", false) end, set = function(v) setDB("lockFloatingQuestItemPosition", v) end },
            { type = "dropdown", name = L["Floating quest item source"], desc = L["Which quest's item to show: super-tracked first, or current zone first."], dbKey = "floatingQuestItemMode", options = { { L["Super-tracked, then first"], "superTracked" }, { L["Current zone first"], "currentZone" } }, get = function() return getDB("floatingQuestItemMode", "superTracked") end, set = function(v) setDB("floatingQuestItemMode", v) end },
        },
    },
    {
        key = "Colors",
        name = L["Colors"],
        moduleKey = "focus",
        options = {
            { type = "colorMatrixFull", name = L["Colors"], dbKey = "colorMatrix" },
        },
    },
    {
        key = "Blacklist",
        name = L["Blacklisted quests"],
        moduleKey = "focus",
        options = {
            { type = "blacklistGrid", name = L["Blacklisted quests"], desc = L["Right-click untrack quests with 'Permanently suppress untracked quests' enabled to add them here."] },
        },
    },
    {
        key = "PresenceDisplay",
        name = L["Display"],
        moduleKey = "presence",
        options = {
            { type = "section", name = L["Display"] },
            { type = "toggle", name = L["Show quest type icons on toasts"], desc = L["Show quest type icon on Presence toasts (quest accept/complete, world quest, quest update)."], dbKey = "showPresenceQuestTypeIcons", get = function() local v = getDB("showPresenceQuestTypeIcons", nil); if v == nil then return getDB("showQuestTypeIcons", false) end; return v end, set = function(v) setDB("showPresenceQuestTypeIcons", v) end },
            { type = "slider", name = L["Toast icon size"], desc = L["Quest icon size on Presence toasts (16–36 px). Default 24."], dbKey = "presenceIconSize", min = 16, max = 36, get = function() return math.max(16, math.min(36, getDB("presenceIconSize", 24) or 24)) end, set = function(v) setDB("presenceIconSize", math.max(16, math.min(36, v))) end },
            { type = "toggle", name = L["Show discovery line"], desc = L["Show 'Discovered' under zone/subzone when entering a new area."], dbKey = "showPresenceDiscovery", get = function() return getDB("showPresenceDiscovery", true) end, set = function(v) setDB("showPresenceDiscovery", v) end },
            { type = "slider", name = L["Frame vertical position"], desc = L["Vertical offset of the Presence frame from center (-300 to 0)."], dbKey = "presenceFrameY", min = -300, max = 0, get = function() return math.max(-300, math.min(0, tonumber(getDB("presenceFrameY", -180)) or -180)) end, set = function(v) setDB("presenceFrameY", math.max(-300, math.min(0, v))) end },
            { type = "slider", name = L["Frame scale"], desc = L["Scale of the Presence frame (0.5–1.5)."], dbKey = "presenceFrameScale", min = 0.5, max = 1.5, get = function() return math.max(0.5, math.min(1.5, tonumber(getDB("presenceFrameScale", 1)) or 1)) end, set = function(v) setDB("presenceFrameScale", math.max(0.5, math.min(1.5, v))) end },
        },
    },
    {
        key = "PresenceColors",
        name = L["Colors"],
        moduleKey = "presence",
        options = {
            { type = "section", name = L["Colors"] },
            { type = "color", name = L["Boss emote color"], desc = L["Color of raid and dungeon boss emote text."], dbKey = "presenceBossEmoteColor", default = addon.PRESENCE_BOSS_EMOTE_COLOR },
            { type = "color", name = L["Discovery line color"], desc = L["Color of the 'Discovered' line under zone text."], dbKey = "presenceDiscoveryColor", default = addon.PRESENCE_DISCOVERY_COLOR },
        },
    },
    {
        key = "PresenceNotifications",
        name = L["Notification types"],
        moduleKey = "presence",
        options = {
            { type = "section", name = L["Notification types"] },
            { type = "toggle", name = L["Show zone entry"], desc = L["Show zone change when entering a new area."], dbKey = "presenceZoneChange", get = function() return getDB("presenceZoneChange", true) end, set = function(v) setDB("presenceZoneChange", v) end },
            { type = "toggle", name = L["Show subzone changes"], desc = L["Show subzone change when moving within the same zone."], dbKey = "presenceSubzoneChange", get = function() local v = getDB("presenceSubzoneChange", nil); if v ~= nil then return v end; return getDB("presenceZoneChange", true) end, set = function(v) setDB("presenceSubzoneChange", v) end },
            { type = "toggle", name = L["Hide zone name for subzone changes"], desc = L["When moving between subzones within the same zone, only show the subzone name. The zone name still appears when entering a new zone."], dbKey = "presenceHideZoneForSubzone", get = function() return getDB("presenceHideZoneForSubzone", false) end, set = function(v) setDB("presenceHideZoneForSubzone", v) end },
            { type = "toggle", name = L["Suppress zone changes in Mythic+"], desc = L["In Mythic+, only show boss emotes, achievements, and level-up. Hide zone, quest, and scenario notifications."], dbKey = "presenceSuppressZoneInMplus", get = function() return getDB("presenceSuppressZoneInMplus", true) end, set = function(v) setDB("presenceSuppressZoneInMplus", v) end },
            { type = "toggle", name = L["Show level up"], desc = L["Show level-up notification."], dbKey = "presenceLevelUp", get = function() return getDB("presenceLevelUp", true) end, set = function(v) setDB("presenceLevelUp", v) end },
            { type = "toggle", name = L["Show boss emotes"], desc = L["Show raid and dungeon boss emote notifications."], dbKey = "presenceBossEmote", get = function() return getDB("presenceBossEmote", true) end, set = function(v) setDB("presenceBossEmote", v) end },
            { type = "toggle", name = L["Show achievements"], desc = L["Show achievement earned notifications."], dbKey = "presenceAchievement", get = function() return getDB("presenceAchievement", true) end, set = function(v) setDB("presenceAchievement", v) end },
            { type = "toggle", name = L["Show quest accept"], desc = L["Show notification when accepting a quest."], dbKey = "presenceQuestAccept", get = function() local v = getDB("presenceQuestAccept", nil); if v ~= nil then return v end; return getDB("presenceQuestEvents", true) end, set = function(v) setDB("presenceQuestAccept", v) end },
            { type = "toggle", name = L["Show world quest accept"], desc = L["Show notification when accepting a world quest."], dbKey = "presenceWorldQuestAccept", get = function() local v = getDB("presenceWorldQuestAccept", nil); if v ~= nil then return v end; return getDB("presenceQuestEvents", true) end, set = function(v) setDB("presenceWorldQuestAccept", v) end },
            { type = "toggle", name = L["Show quest complete"], desc = L["Show notification when completing a quest."], dbKey = "presenceQuestComplete", get = function() local v = getDB("presenceQuestComplete", nil); if v ~= nil then return v end; return getDB("presenceQuestEvents", true) end, set = function(v) setDB("presenceQuestComplete", v) end },
            { type = "toggle", name = L["Show world quest complete"], desc = L["Show notification when completing a world quest."], dbKey = "presenceWorldQuest", get = function() local v = getDB("presenceWorldQuest", nil); if v ~= nil then return v end; return getDB("presenceQuestEvents", true) end, set = function(v) setDB("presenceWorldQuest", v) end },
            { type = "toggle", name = L["Show quest progress"], desc = L["Show notification when quest objectives update."], dbKey = "presenceQuestUpdate", get = function() local v = getDB("presenceQuestUpdate", nil); if v ~= nil then return v end; return getDB("presenceQuestEvents", true) end, set = function(v) setDB("presenceQuestUpdate", v) end },
            { type = "toggle", name = L["Show scenario start"], desc = L["Show notification when entering a scenario or Delve."], dbKey = "presenceScenarioStart", get = function() local v = getDB("presenceScenarioStart", nil); if v ~= nil then return v end; return getDB("showScenarioEvents", true) end, set = function(v) setDB("presenceScenarioStart", v) end },
            { type = "toggle", name = L["Show scenario progress"], desc = L["Show notification when scenario or Delve objectives update."], dbKey = "presenceScenarioUpdate", get = function() local v = getDB("presenceScenarioUpdate", nil); if v ~= nil then return v end; return getDB("showScenarioEvents", true) end, set = function(v) setDB("presenceScenarioUpdate", v) end },
        },
    },
    {
        key = "PresenceAnimation",
        name = L["Animation"],
        moduleKey = "presence",
        options = {
            { type = "section", name = L["Animation"] },
            { type = "toggle", name = L["Enable animations"], desc = L["Enable entrance and exit animations for Presence notifications."], dbKey = "presenceAnimations", get = function() return getDB("presenceAnimations", true) end, set = function(v) setDB("presenceAnimations", v) end },
            { type = "slider", name = L["Entrance duration"], desc = L["Duration of the entrance animation in seconds (0.2–1.5)."], dbKey = "presenceEntranceDur", min = 0.2, max = 1.5, step = 0.1, get = function() return math.max(0.2, math.min(1.5, tonumber(getDB("presenceEntranceDur", 0.7)) or 0.7)) end, set = function(v) setDB("presenceEntranceDur", math.max(0.2, math.min(1.5, v))) end },
            { type = "slider", name = L["Exit duration"], desc = L["Duration of the exit animation in seconds (0.2–1.5)."], dbKey = "presenceExitDur", min = 0.2, max = 1.5, step = 0.1, get = function() return math.max(0.2, math.min(1.5, tonumber(getDB("presenceExitDur", 0.8)) or 0.8)) end, set = function(v) setDB("presenceExitDur", math.max(0.2, math.min(1.5, v))) end },
            { type = "slider", name = L["Hold duration scale"], desc = L["Multiplier for how long each notification stays on screen (0.5–2)."], dbKey = "presenceHoldScale", min = 0.5, max = 2, step = 0.1, get = function() return math.max(0.5, math.min(2, tonumber(getDB("presenceHoldScale", 1)) or 1)) end, set = function(v) setDB("presenceHoldScale", math.max(0.5, math.min(2, v))) end },
        },
    },
    {
        key = "PresenceTypography",
        name = L["Typography"],
        moduleKey = "presence",
        options = {
            { type = "section", name = L["Typography"] },
            { type = "dropdown", name = L["Main title font"], desc = L["Font family for the main title."], dbKey = "presenceTitleFontPath", searchable = true, options = function() return GetPerElementFontDropdownOptions("presenceTitleFontPath") end, get = function() return getDB("presenceTitleFontPath", FONT_USE_GLOBAL) end, set = function(v) setDB("presenceTitleFontPath", v) end, displayFn = DisplayPerElementFont },
            { type = "dropdown", name = L["Subtitle font"], desc = L["Font family for the subtitle."], dbKey = "presenceSubtitleFontPath", searchable = true, options = function() return GetPerElementFontDropdownOptions("presenceSubtitleFontPath") end, get = function() return getDB("presenceSubtitleFontPath", FONT_USE_GLOBAL) end, set = function(v) setDB("presenceSubtitleFontPath", v) end, displayFn = DisplayPerElementFont },
            { type = "slider", name = L["Main title size"], desc = L["Font size for the main title (24–72 px)."], dbKey = "presenceMainSize", min = 24, max = 72, get = function() return math.max(24, math.min(72, tonumber(getDB("presenceMainSize", 48)) or 48)) end, set = function(v) setDB("presenceMainSize", math.max(24, math.min(72, v))) end },
            { type = "slider", name = L["Subtitle size"], desc = L["Font size for the subtitle (12–40 px)."], dbKey = "presenceSubSize", min = 12, max = 40, get = function() return math.max(12, math.min(40, tonumber(getDB("presenceSubSize", 24)) or 24)) end, set = function(v) setDB("presenceSubSize", math.max(12, math.min(40, v))) end },
        },
    },
    {
        key = "Insight",
        name = L["Insight"] or "Insight",
        moduleKey = "insight",
        options = {
            { type = "section", name = L["Position"] or "Position" },
            { type = "dropdown", name = L["Tooltip anchor mode"] or "Tooltip anchor mode", desc = L["Where tooltips appear: follow cursor or fixed position."] or "Where tooltips appear: follow cursor or fixed position.", dbKey = "insightAnchorMode", options = { { L["Cursor"] or "Cursor", "cursor" }, { L["Fixed"] or "Fixed", "fixed" } }, get = function() return getDB("insightAnchorMode", "cursor") end, set = function(v) setDB("insightAnchorMode", v) end },
            { type = "button", name = L["Show anchor to move"] or "Show anchor to move", desc = L["Show draggable frame to set fixed tooltip position. Drag, then right-click to confirm."] or "Show draggable frame to set fixed tooltip position. Drag, then right-click to confirm.", onClick = function()
                if addon.Insight and addon.Insight.ShowAnchorFrame then addon.Insight.ShowAnchorFrame() end
            end },
            { type = "button", name = L["Reset tooltip position"] or "Reset tooltip position", desc = L["Reset fixed position to default."] or "Reset fixed position to default.", onClick = function()
                setDB("insightFixedPoint", "BOTTOMRIGHT")
                setDB("insightFixedX", -40)
                setDB("insightFixedY", 120)
                if addon.Insight and addon.Insight.ApplyInsightOptions then addon.Insight.ApplyInsightOptions() end
            end },
        },
    },
    {
        key = "VistaGeneral",
        name = L["General"] or "General",
        moduleKey = "vista",
        options = {
            { type = "section", name = L["Minimap"] or "Minimap" },
            { type = "slider", name = L["Minimap size"] or "Minimap size",
              desc = L["Width and height of the minimap in pixels (100–400)."] or "Width and height of the minimap in pixels (100–400).",
              dbKey = "vistaMapSize", min = 100, max = 400,
              get = function() return math.max(100, math.min(400, tonumber(getDB("vistaMapSize", 200)) or 200)) end,
              set = function(v) setDB("vistaMapSize", math.max(100, math.min(400, v))) end },
            { type = "toggle", name = L["Circular minimap"] or "Circular minimap",
              desc = L["Use a circular minimap instead of square."] or "Use a circular minimap instead of square.",
              dbKey = "vistaCircular",
              get = function() return getDB("vistaCircular", false) end,
              set = function(v) setDB("vistaCircular", v) end },
            { type = "section", name = L["Position"] or "Position" },
            { type = "toggle", name = L["Lock minimap position"] or "Lock minimap position",
              desc = L["Prevent dragging the minimap."] or "Prevent dragging the minimap.",
              dbKey = "vistaLock",
              get = function() return getDB("vistaLock", true) end,
              set = function(v) setDB("vistaLock", v) end },
            { type = "button", name = L["Reset minimap position"] or "Reset minimap position",
              desc = L["Reset minimap to its default position (top-right)."] or "Reset minimap to its default position (top-right).",
              onClick = function()
                  if addon.Vista and addon.Vista.ResetMinimapPosition then
                      addon.Vista.ResetMinimapPosition()
                  end
              end },
            { type = "section", name = L["Auto Zoom"] or "Auto Zoom" },
            { type = "slider", name = L["Auto zoom-out delay"] or "Auto zoom-out delay",
              desc = L["Seconds after zooming before auto zoom-out fires. Set to 0 to disable."] or "Seconds after zooming before auto zoom-out fires. Set to 0 to disable.",
              dbKey = "vistaAutoZoom", min = 0, max = 30,
              get = function() return math.max(0, math.min(30, tonumber(getDB("vistaAutoZoom", 5)) or 5)) end,
              set = function(v) setDB("vistaAutoZoom", math.max(0, math.min(30, v))) end },
        },
    },
    {
        key = "VistaTypography",
        name = L["Typography"] or "Typography",
        moduleKey = "vista",
        options = function()
            local GLOBAL_SENTINEL = "__global__"
            local GLOBAL_LABEL = L["Use global font"] or "Use global font"

            -- Build font list with "Use global" as the first entry.
            local function fontOpts(dbKey)
                local list = { { GLOBAL_LABEL, GLOBAL_SENTINEL } }
                local fontList = (addon.GetFontList and addon.GetFontList()) or {}
                for _, f in ipairs(fontList) do list[#list + 1] = f end
                -- If the saved value is a custom path not in the list, append it.
                local saved = getDB(dbKey, GLOBAL_SENTINEL)
                if saved and saved ~= GLOBAL_SENTINEL and saved ~= "" then
                    local found = false
                    for _, o in ipairs(list) do if o[2] == saved then found = true; break end end
                    if not found then list[#list + 1] = { "Custom", saved } end
                end
                return list
            end

            -- Display name: global sentinel shows readable label, paths show font name.
            local function displayFont(v)
                if v == GLOBAL_SENTINEL or v == nil or v == "" then return GLOBAL_LABEL end
                if addon.GetFontNameForPath then return addon.GetFontNameForPath(v) end
                return v
            end

            -- Get: return sentinel when nothing (or sentinel) is stored.
            local function getFont(dbKey)
                local v = getDB(dbKey, GLOBAL_SENTINEL)
                if v == nil or v == "" then return GLOBAL_SENTINEL end
                return v
            end

            return {
                { type = "section", name = L["Zone Text"] or "Zone Text" },
                { type = "dropdown", name = L["Zone font"] or "Zone font",
                  desc = L["Font for the zone name below the minimap."] or "Font for the zone name below the minimap.",
                  dbKey = "vistaZoneFontPath", searchable = true,
                  options = function() return fontOpts("vistaZoneFontPath") end,
                  get = function() return getFont("vistaZoneFontPath") end,
                  set = function(v) setDB("vistaZoneFontPath", v) end,
                  displayFn = displayFont },
                { type = "slider", name = L["Zone font size"] or "Zone font size",
                  dbKey = "vistaZoneFontSize", min = 7, max = 24,
                  get = function() return math.max(7, math.min(24, tonumber(getDB("vistaZoneFontSize", 12)) or 12)) end,
                  set = function(v) setDB("vistaZoneFontSize", math.max(7, math.min(24, v))) end },
                { type = "color", name = L["Zone text color"] or "Zone text color",
                  desc = L["Color of the zone name text."] or "Color of the zone name text.",
                  dbKey = "vistaZoneColor",
                  get = function()
                      return getDB("vistaZoneColorR", 1), getDB("vistaZoneColorG", 1), getDB("vistaZoneColorB", 1)
                  end,
                  set = function(r, g, b)
                      setDB("vistaZoneColorR", r); setDB("vistaZoneColorG", g); setDB("vistaZoneColorB", b)
                  end },

                { type = "section", name = L["Coordinates Text"] or "Coordinates Text" },
                { type = "dropdown", name = L["Coordinates font"] or "Coordinates font",
                  desc = L["Font for the coordinates text below the minimap."] or "Font for the coordinates text below the minimap.",
                  dbKey = "vistaCoordFontPath", searchable = true,
                  options = function() return fontOpts("vistaCoordFontPath") end,
                  get = function() return getFont("vistaCoordFontPath") end,
                  set = function(v) setDB("vistaCoordFontPath", v) end,
                  displayFn = displayFont },
                { type = "slider", name = L["Coordinates font size"] or "Coordinates font size",
                  dbKey = "vistaCoordFontSize", min = 7, max = 20,
                  get = function() return math.max(7, math.min(20, tonumber(getDB("vistaCoordFontSize", 10)) or 10)) end,
                  set = function(v) setDB("vistaCoordFontSize", math.max(7, math.min(20, v))) end },
                { type = "color", name = L["Coordinates text color"] or "Coordinates text color",
                  desc = L["Color of the coordinates text."] or "Color of the coordinates text.",
                  dbKey = "vistaCoordColor",
                  get = function()
                      return getDB("vistaCoordColorR", 0.55), getDB("vistaCoordColorG", 0.65), getDB("vistaCoordColorB", 0.75)
                  end,
                  set = function(r, g, b)
                      setDB("vistaCoordColorR", r); setDB("vistaCoordColorG", g); setDB("vistaCoordColorB", b)
                  end },

                { type = "section", name = L["Time Text"] or "Time Text" },
                { type = "dropdown", name = L["Time font"] or "Time font",
                  desc = L["Font for the time text below the minimap."] or "Font for the time text below the minimap.",
                  dbKey = "vistaTimeFontPath", searchable = true,
                  options = function() return fontOpts("vistaTimeFontPath") end,
                  get = function() return getFont("vistaTimeFontPath") end,
                  set = function(v) setDB("vistaTimeFontPath", v) end,
                  displayFn = displayFont },
                { type = "slider", name = L["Time font size"] or "Time font size",
                  dbKey = "vistaTimeFontSize", min = 7, max = 20,
                  get = function() return math.max(7, math.min(20, tonumber(getDB("vistaTimeFontSize", 10)) or 10)) end,
                  set = function(v) setDB("vistaTimeFontSize", math.max(7, math.min(20, v))) end },
                { type = "color", name = L["Time text color"] or "Time text color",
                  desc = L["Color of the time text."] or "Color of the time text.",
                  dbKey = "vistaTimeColor",
                  get = function()
                      return getDB("vistaTimeColorR", 0.55), getDB("vistaTimeColorG", 0.65), getDB("vistaTimeColorB", 0.75)
                  end,
                  set = function(r, g, b)
                      setDB("vistaTimeColorR", r); setDB("vistaTimeColorG", g); setDB("vistaTimeColorB", b)
                  end },

                { type = "section", name = L["Difficulty Text"] or "Difficulty Text" },
                { type = "color", name = L["Difficulty text color"] or "Difficulty text color",
                  desc = L["Color of the instance difficulty text below zone name."] or "Color of the instance difficulty text below zone name.",
                  dbKey = "vistaDiffColor",
                  get = function()
                      return getDB("vistaDiffColorR", 0.55), getDB("vistaDiffColorG", 0.65), getDB("vistaDiffColorB", 0.75)
                  end,
                  set = function(r, g, b)
                      setDB("vistaDiffColorR", r); setDB("vistaDiffColorG", g); setDB("vistaDiffColorB", b)
                  end },
            }
        end,
    },
    {
        key = "VistaVisibility",
        name = L["Visibility"] or "Visibility",
        moduleKey = "vista",
        options = {
            { type = "section", name = L["Text Elements"] or "Text Elements" },
            { type = "toggle", name = L["Show zone text"] or "Show zone text",
              desc = L["Show the zone name below the minimap."] or "Show the zone name below the minimap.",
              dbKey = "vistaShowZoneText",
              get = function() return getDB("vistaShowZoneText", true) end,
              set = function(v) setDB("vistaShowZoneText", v) end },
            { type = "toggle", name = L["Show coordinates"] or "Show coordinates",
              desc = L["Show player coordinates below the minimap."] or "Show player coordinates below the minimap.",
              dbKey = "vistaShowCoordText",
              get = function() return getDB("vistaShowCoordText", true) end,
              set = function(v) setDB("vistaShowCoordText", v) end },
            { type = "toggle", name = L["Show time"] or "Show time",
              desc = L["Show current game time below the minimap."] or "Show current game time below the minimap.",
              dbKey = "vistaShowTimeText",
              get = function() return getDB("vistaShowTimeText", false) end,
              set = function(v) setDB("vistaShowTimeText", v) end },
            { type = "section", name = L["Minimap Buttons"] or "Minimap Buttons" },
            { type = "header", name = L["Queue status and mail indicator are always shown when relevant."] or "Queue status and mail indicator are always shown when relevant." },
            -- Tracking
            { type = "toggle", name = L["Show tracking button"] or "Show tracking button",
              desc = L["Show the minimap tracking button."] or "Show the minimap tracking button.",
              dbKey = "vistaShowTracking",
              get = function() return getDB("vistaShowTracking", true) end,
              set = function(v)
                  setDB("vistaShowTracking", v)
                  if addon.OptionsPanel_Refresh and C_Timer and C_Timer.After then
                      C_Timer.After(0, addon.OptionsPanel_Refresh)
                  elseif addon.OptionsPanel_Refresh then
                      addon.OptionsPanel_Refresh()
                  end
              end },
            { type = "toggle", name = L["Tracking button on mouseover only"] or "Tracking button on mouseover only",
              desc = L["Hide tracking button until you hover over the minimap."] or "Hide tracking button until you hover over the minimap.",
              dbKey = "vistaMouseoverTracking",
              get = function() return getDB("vistaMouseoverTracking", true) end,
              set = function(v) setDB("vistaMouseoverTracking", v) end,
              disabled = function() return not getDB("vistaShowTracking", true) end },
            -- Calendar
            { type = "toggle", name = L["Show calendar button"] or "Show calendar button",
              desc = L["Show the minimap calendar button."] or "Show the minimap calendar button.",
              dbKey = "vistaShowCalendar",
              get = function() return getDB("vistaShowCalendar", true) end,
              set = function(v)
                  setDB("vistaShowCalendar", v)
                  if addon.OptionsPanel_Refresh and C_Timer and C_Timer.After then
                      C_Timer.After(0, addon.OptionsPanel_Refresh)
                  elseif addon.OptionsPanel_Refresh then
                      addon.OptionsPanel_Refresh()
                  end
              end },
            { type = "toggle", name = L["Calendar button on mouseover only"] or "Calendar button on mouseover only",
              desc = L["Hide calendar button until you hover over the minimap."] or "Hide calendar button until you hover over the minimap.",
              dbKey = "vistaMouseoverCalendar",
              get = function() return getDB("vistaMouseoverCalendar", true) end,
              set = function(v) setDB("vistaMouseoverCalendar", v) end,
              disabled = function() return not getDB("vistaShowCalendar", true) end },
            -- Zoom buttons
            { type = "toggle", name = L["Show zoom buttons"] or "Show zoom buttons",
              desc = L["Show the + and - zoom buttons on the minimap."] or "Show the + and - zoom buttons on the minimap.",
              dbKey = "vistaShowZoomBtns",
              get = function() return getDB("vistaShowZoomBtns", true) end,
              set = function(v)
                  setDB("vistaShowZoomBtns", v)
                  if addon.OptionsPanel_Refresh and C_Timer and C_Timer.After then
                      C_Timer.After(0, addon.OptionsPanel_Refresh)
                  elseif addon.OptionsPanel_Refresh then
                      addon.OptionsPanel_Refresh()
                  end
              end },
            { type = "toggle", name = L["Zoom buttons on mouseover only"] or "Zoom buttons on mouseover only",
              desc = L["Hide zoom buttons until you hover over the minimap."] or "Hide zoom buttons until you hover over the minimap.",
              dbKey = "vistaMouseoverZoomBtns",
              get = function() return getDB("vistaMouseoverZoomBtns", true) end,
              set = function(v) setDB("vistaMouseoverZoomBtns", v) end,
              disabled = function() return not getDB("vistaShowZoomBtns", true) end },
        },
    },
    {
        key = "VistaDisplay",
        name = L["Display"] or "Display",
        moduleKey = "vista",
        options = {
            { type = "section", name = L["Border"] or "Border" },
            { type = "toggle", name = L["Show border"] or "Show border",
              desc = L["Show a border around the minimap."] or "Show a border around the minimap.",
              dbKey = "vistaBorderShow",
              get = function() return getDB("vistaBorderShow", true) end,
              set = function(v) setDB("vistaBorderShow", v) end },
            { type = "color", name = L["Border color"] or "Border color",
              desc = L["Color (and opacity) of the minimap border."] or "Color (and opacity) of the minimap border.",
              dbKey = "vistaBorderColor",
              get = function()
                  return getDB("vistaBorderColorR", 1), getDB("vistaBorderColorG", 1),
                         getDB("vistaBorderColorB", 1), getDB("vistaBorderColorA", 0.15)
              end,
              set = function(r, g, b, a)
                  setDB("vistaBorderColorR", r); setDB("vistaBorderColorG", g)
                  setDB("vistaBorderColorB", b)
                  if a then setDB("vistaBorderColorA", a) end
              end,
              hasAlpha = true },
            { type = "slider", name = L["Border thickness"] or "Border thickness",
              desc = L["Thickness of the minimap border in pixels (1–8)."] or "Thickness of the minimap border in pixels (1–8).",
              dbKey = "vistaBorderWidth", min = 1, max = 8,
              get = function() return math.max(1, math.min(8, tonumber(getDB("vistaBorderWidth", 1)) or 1)) end,
              set = function(v) setDB("vistaBorderWidth", math.max(1, math.min(8, v))) end },

            { type = "section", name = L["Text Positions"] or "Text Positions" },
            { type = "header", name = L["Drag text elements to reposition them. Lock to prevent accidental movement."] or "Drag text elements to reposition them. Lock to prevent accidental movement." },
            { type = "toggle", name = L["Lock zone text position"] or "Lock zone text position",
              desc = L["When on, the zone text cannot be dragged."] or "When on, the zone text cannot be dragged.",
              dbKey = "vistaLocked_zone",
              get = function() return getDB("vistaLocked_zone", true) end,
              set = function(v) setDB("vistaLocked_zone", v) end },
            { type = "toggle", name = L["Lock coordinates position"] or "Lock coordinates position",
              desc = L["When on, the coordinates text cannot be dragged."] or "When on, the coordinates text cannot be dragged.",
              dbKey = "vistaLocked_coord",
              get = function() return getDB("vistaLocked_coord", true) end,
              set = function(v) setDB("vistaLocked_coord", v) end },
            { type = "toggle", name = L["Lock time position"] or "Lock time position",
              desc = L["When on, the time text cannot be dragged."] or "When on, the time text cannot be dragged.",
              dbKey = "vistaLocked_time",
              get = function() return getDB("vistaLocked_time", true) end,
              set = function(v) setDB("vistaLocked_time", v) end },
            { type = "section", name = L["Button Positions"] or "Button Positions" },
            { type = "header", name = L["Drag buttons to reposition them. Lock to prevent movement."] or "Drag buttons to reposition them. Lock to prevent movement." },
            { type = "toggle", name = L["Lock Zoom In button"] or "Lock Zoom In button",
              desc = L["Prevent dragging the + zoom button."] or "Prevent dragging the + zoom button.",
              dbKey = "vistaLocked_zoomIn",
              get = function() return getDB("vistaLocked_zoomIn", false) end,
              set = function(v) setDB("vistaLocked_zoomIn", v) end },
            { type = "toggle", name = L["Lock Zoom Out button"] or "Lock Zoom Out button",
              desc = L["Prevent dragging the - zoom button."] or "Prevent dragging the - zoom button.",
              dbKey = "vistaLocked_zoomOut",
              get = function() return getDB("vistaLocked_zoomOut", false) end,
              set = function(v) setDB("vistaLocked_zoomOut", v) end },
            { type = "toggle", name = L["Lock Tracking button"] or "Lock Tracking button",
              desc = L["Prevent dragging the tracking button."] or "Prevent dragging the tracking button.",
              dbKey = "vistaLocked_proxy_tracking",
              get = function() return getDB("vistaLocked_proxy_tracking", false) end,
              set = function(v) setDB("vistaLocked_proxy_tracking", v) end },
            { type = "toggle", name = L["Lock Calendar button"] or "Lock Calendar button",
              desc = L["Prevent dragging the calendar button."] or "Prevent dragging the calendar button.",
              dbKey = "vistaLocked_proxy_calendar",
              get = function() return getDB("vistaLocked_proxy_calendar", false) end,
              set = function(v) setDB("vistaLocked_proxy_calendar", v) end },
            { type = "toggle", name = L["Lock Queue button"] or "Lock Queue button",
              desc = L["Prevent dragging the queue status button."] or "Prevent dragging the queue status button.",
              dbKey = "vistaLocked_proxy_queue",
              get = function() return getDB("vistaLocked_proxy_queue", false) end,
              set = function(v) setDB("vistaLocked_proxy_queue", v) end },
            { type = "section", name = L["Button Sizes"] or "Button Sizes" },
            { type = "header", name = L["Adjust the size of minimap overlay buttons."] or "Adjust the size of minimap overlay buttons." },
            { type = "slider", name = L["Tracking button size"] or "Tracking button size",
              desc = L["Size of the tracking button (pixels)."] or "Size of the tracking button (pixels).",
              dbKey = "vistaTrackingBtnSize", min = 14, max = 40,
              get = function() return math.max(14, math.min(40, tonumber(getDB("vistaTrackingBtnSize", 22)) or 22)) end,
              set = function(v) setDB("vistaTrackingBtnSize", math.max(14, math.min(40, v))) end },
            { type = "slider", name = L["Calendar button size"] or "Calendar button size",
              desc = L["Size of the calendar button (pixels)."] or "Size of the calendar button (pixels).",
              dbKey = "vistaCalendarBtnSize", min = 14, max = 40,
              get = function() return math.max(14, math.min(40, tonumber(getDB("vistaCalendarBtnSize", 22)) or 22)) end,
              set = function(v) setDB("vistaCalendarBtnSize", math.max(14, math.min(40, v))) end },
            { type = "slider", name = L["Queue button size"] or "Queue button size",
              desc = L["Size of the queue status button (pixels)."] or "Size of the queue status button (pixels).",
              dbKey = "vistaQueueBtnSize", min = 14, max = 40,
              get = function() return math.max(14, math.min(40, tonumber(getDB("vistaQueueBtnSize", 22)) or 22)) end,
              set = function(v) setDB("vistaQueueBtnSize", math.max(14, math.min(40, v))) end },
            { type = "slider", name = L["Zoom button size"] or "Zoom button size",
              desc = L["Size of the zoom in / zoom out buttons (pixels)."] or "Size of the zoom in / zoom out buttons (pixels).",
              dbKey = "vistaZoomBtnSize", min = 10, max = 32,
              get = function() return math.max(10, math.min(32, tonumber(getDB("vistaZoomBtnSize", 16)) or 16)) end,
              set = function(v) setDB("vistaZoomBtnSize", math.max(10, math.min(32, v))) end },
            { type = "slider", name = L["Mail indicator size"] or "Mail indicator size",
              desc = L["Size of the new mail icon (pixels)."] or "Size of the new mail icon (pixels).",
              dbKey = "vistaMailIconSize", min = 14, max = 40,
              get = function() return math.max(14, math.min(40, tonumber(getDB("vistaMailIconSize", 20)) or 20)) end,
              set = function(v) setDB("vistaMailIconSize", math.max(14, math.min(40, v))) end },
            { type = "slider", name = L["Addon button size"] or "Addon button size",
              desc = L["Size of collected addon minimap buttons (pixels)."] or "Size of collected addon minimap buttons (pixels).",
              dbKey = "vistaAddonBtnSize", min = 16, max = 48,
              get = function() return math.max(16, math.min(48, tonumber(getDB("vistaAddonBtnSize", 26)) or 26)) end,
              set = function(v) setDB("vistaAddonBtnSize", math.max(16, math.min(48, v))) end },
        },
    },
    {
        key = "VistaButtons",
        name = L["Minimap Addon Buttons"] or "Minimap Addon Buttons",
        moduleKey = "vista",
        options = function()
            local BUTTON_MODE_OPTIONS = {
                { L["Mouseover bar"] or "Mouseover bar", "mouseover" },
                { L["Right-click panel"] or "Right-click panel", "rightclick" },
                { L["Floating drawer"] or "Floating drawer", "drawer" },
            }

            local opts = {
                { type = "section", name = L["Button Management"] or "Button Management" },
                { type = "toggle", name = L["Manage addon minimap buttons"] or "Manage addon minimap buttons",
                  desc = L["When on, Vista takes control of addon minimap buttons and groups them by the selected mode."] or "When on, Vista takes control of addon minimap buttons and groups them by the selected mode.",
                  dbKey = "vistaHandleAddonButtons",
                  get = function() return getDB("vistaHandleAddonButtons", true) end,
                  set = function(v)
                      setDB("vistaHandleAddonButtons", v)
                      if addon.OptionsPanel_Refresh and C_Timer and C_Timer.After then
                          C_Timer.After(0, addon.OptionsPanel_Refresh)
                      elseif addon.OptionsPanel_Refresh then
                          addon.OptionsPanel_Refresh()
                      end
                  end },
                { type = "dropdown", name = L["Button mode"] or "Button mode",
                  desc = L["How addon buttons are presented: hover bar below minimap, panel on right-click, or floating drawer button."] or "How addon buttons are presented: hover bar below minimap, panel on right-click, or floating drawer button.",
                  dbKey = "vistaButtonMode",
                  options = BUTTON_MODE_OPTIONS,
                  get = function() return getDB("vistaButtonMode", "mouseover") end,
                  set = function(v)
                      if not getDB("vistaHandleAddonButtons", true) then return end
                      setDB("vistaButtonMode", v)
                      if addon.OptionsPanel_Refresh and C_Timer and C_Timer.After then
                          C_Timer.After(0, addon.OptionsPanel_Refresh)
                      elseif addon.OptionsPanel_Refresh then
                          addon.OptionsPanel_Refresh()
                      end
                  end,
                  disabled = function() return not getDB("vistaHandleAddonButtons", true) end },
                { type = "toggle", name = L["Lock drawer button position"] or "Lock drawer button position",
                  desc = L["Prevent dragging the floating drawer button."] or "Prevent dragging the floating drawer button.",
                  dbKey = "vistaDrawerButtonLocked",
                  get = function() return getDB("vistaDrawerButtonLocked", false) end,
                  set = function(v)
                      if not getDB("vistaHandleAddonButtons", true) then return end
                      if getDB("vistaButtonMode", "mouseover") ~= "drawer" then return end
                      setDB("vistaDrawerButtonLocked", v)
                  end,
                  disabled = function()
                      return not getDB("vistaHandleAddonButtons", true) or getDB("vistaButtonMode", "mouseover") ~= "drawer"
                  end },
                { type = "section", name = L["Panel Appearance"] or "Panel Appearance" },
                { type = "header", name = L["Colors for the drawer and right-click button panels."] or "Colors for the drawer and right-click button panels." },
                { type = "color", name = L["Panel background color"] or "Panel background color",
                  desc = L["Background color of the addon button panels."] or "Background color of the addon button panels.",
                  dbKey = "vistaPanelBg",
                  get = function()
                      return getDB("vistaPanelBgR", 0.08), getDB("vistaPanelBgG", 0.08),
                             getDB("vistaPanelBgB", 0.12), getDB("vistaPanelBgA", 0.95)
                  end,
                  set = function(r, g, b, a)
                      setDB("vistaPanelBgR", r); setDB("vistaPanelBgG", g)
                      setDB("vistaPanelBgB", b)
                      if a then setDB("vistaPanelBgA", a) end
                  end,
                  hasAlpha = true },
                { type = "color", name = L["Panel border color"] or "Panel border color",
                  desc = L["Border color of the addon button panels."] or "Border color of the addon button panels.",
                  dbKey = "vistaPanelBorder",
                  get = function()
                      return getDB("vistaPanelBorderR", 0.3), getDB("vistaPanelBorderG", 0.4),
                             getDB("vistaPanelBorderB", 0.6), getDB("vistaPanelBorderA", 0.7)
                  end,
                  set = function(r, g, b, a)
                      setDB("vistaPanelBorderR", r); setDB("vistaPanelBorderG", g)
                      setDB("vistaPanelBorderB", b)
                      if a then setDB("vistaPanelBorderA", a) end
                  end,
                  hasAlpha = true },
                { type = "section", name = L["Button Filter"] or "Button Filter" },
            }

            -- Per-button filter toggles from discovered minimap buttons
            local function getButtonNames()
                if addon.Vista and addon.Vista.GetDiscoveredButtonNames then
                    return addon.Vista.GetDiscoveredButtonNames()
                end
                return {}
            end

            opts[#opts + 1] = {
                type = "toggle",
                name = L["Filter to selected buttons only"] or "Filter to selected buttons only",
                desc = L["When on, only buttons checked below will appear. Unchecked buttons are hidden everywhere including the minimap."] or "When on, only buttons checked below will appear. Unchecked buttons are hidden everywhere including the minimap.",
                dbKey = "vistaButtonFilterEnabled",
                get = function()
                    local wl = getDB("vistaButtonWhitelist", nil)
                    if not wl or type(wl) ~= "table" then return false end
                    local hasAny = false
                    for _ in pairs(wl) do hasAny = true; break end
                    return hasAny
                end,
                set = function(v)
                    if not v then
                        setDB("vistaButtonWhitelist", nil)
                    else
                        local names = getButtonNames()
                        local wl = {}
                        for _, n in ipairs(names) do wl[n] = true end
                        setDB("vistaButtonWhitelist", wl)
                    end
                end,
                disabled = function() return not getDB("vistaHandleAddonButtons", true) end,
            }

            opts[#opts + 1] = {
                type = "section",
                name = L["Visible buttons (check to include)"] or "Visible buttons (check to include)",
            }

            local names = getButtonNames()
            for _, btnName in ipairs(names) do
                local localName = btnName
                local displayName = localName
                if addon.Vista and addon.Vista.GetButtonDisplayName then
                    displayName = addon.Vista.GetButtonDisplayName(localName) or localName
                end
                local label
                if displayName ~= localName and displayName ~= "" then
                    label = displayName
                else
                    label = localName
                end
                opts[#opts + 1] = {
                    type = "toggle",
                    name = label,
                    dbKey = "vistaBtn_" .. localName,
                    disabled = function()
                        return not getDB("vistaHandleAddonButtons", true)
                    end,
                    get = function()
                        local wl = getDB("vistaButtonWhitelist", nil)
                        if not wl or type(wl) ~= "table" then return true end  -- no filter = all visible
                        return wl[localName] == true
                    end,
                    set = function(v)
                        local wl = getDB("vistaButtonWhitelist", nil)
                        if not wl or type(wl) ~= "table" then
                            -- Build whitelist from all known buttons
                            local allNames = getButtonNames()
                            wl = {}
                            for _, n in ipairs(allNames) do wl[n] = true end
                        end
                        wl[localName] = v or nil
                        -- If whitelist is now all-true or empty, clear it
                        local hasAny = false
                        local hasFalse = false
                        for n, val in pairs(wl) do
                            if val then hasAny = true else hasFalse = true end
                        end
                        if not hasAny then wl = nil end
                        setDB("vistaButtonWhitelist", wl)
                    end,
                }
            end

            if #names == 0 then
                opts[#opts + 1] = {
                    type = "toggle",
                    name = L["(No addon buttons detected yet — open your minimap first)"] or "(No addon buttons detected yet — open your minimap first)",
                    dbKey = "_vista_no_buttons_placeholder",
                    get = function() return false end,
                    set = function() end,
                    disabled = function() return true end,
                }
            end

            return opts
        end,
    },
    {
        key = "YieldGeneral",
        name = L["General"],
        moduleKey = "yield",
        options = {
            { type = "section", name = L["Position"] },
            { type = "button", name = L["Reset position"], desc = L["Reset loot toast position to default."], onClick = function()
                if addon.Yield and addon.Yield.ResetPosition then addon.Yield.ResetPosition() end
            end },
        },
    },
}

-- ---------------------------------------------------------------------------
-- Search index: flatten all options for search (name + desc + section)
-- Includes optionId, sectionName, categoryIndex for navigation.
-- ---------------------------------------------------------------------------

function OptionsData_BuildSearchIndex()
    local index = {}
    local cats = addon.OptionCategories
    for catIdx, cat in ipairs(cats) do
        local currentSection = ""
        local moduleKey = cat.moduleKey
        local moduleLabel = (moduleKey == "focus" and L["Focus"]) or (moduleKey == "presence" and L["Presence"]) or (moduleKey == "insight" and (L["Insight"] or "Insight")) or (moduleKey == "yield" and L["Yield"]) or (moduleKey == "vista" and (L["Vista"] or "Vista")) or L["Modules"]
        local catOpts = type(cat.options) == "function" and cat.options() or cat.options
        for _, opt in ipairs(catOpts) do
            if opt.type == "section" then
                currentSection = type(opt.name) == "function" and opt.name() or opt.name or ""
            elseif opt.type ~= "section" then
                local rawName = type(opt.name) == "function" and opt.name() or opt.name
                local name = (rawName or ""):lower()
                local desc = (opt.desc or opt.tooltip or ""):lower()
                local sectionLower = (currentSection or ""):lower()
                local searchText = name .. " " .. desc .. " " .. sectionLower .. " " .. (moduleLabel or ""):lower()
                local optionId = opt.dbKey or (cat.key .. "_" .. (rawName or ""):gsub("%s+", "_"))
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

-- Filter out Insight/Yield categories when dev addon does not show their toggles.
local function getVisibleCategories()
    local dev = _G.HorizonSuiteDevOverride
    local showInsight = dev and dev.showInsightToggle
    local showYield = dev and dev.showYieldToggle
    local out = {}
    for _, cat in ipairs(OptionCategories) do
        local mk = cat.moduleKey
        if mk == "insight" and not showInsight then
            -- skip
        elseif mk == "yield" and not showYield then
            -- skip
        else
            out[#out + 1] = cat
        end
    end
    return out
end

-- Export for panel
addon.OptionsData_GetDB = OptionsData_GetDB
addon.OptionsData_SetDB = OptionsData_SetDB
addon.OptionsData_NotifyMainAddon = OptionsData_NotifyMainAddon
addon.OptionsData_SetUpdateFontsRef = OptionsData_SetUpdateFontsRef
addon.OptionCategories = getVisibleCategories()
addon.OptionsData_BuildSearchIndex = OptionsData_BuildSearchIndex
addon.COLOR_KEYS_ORDER = COLOR_KEYS_ORDER
addon.ZONE_COLOR_DEFAULT = ZONE_COLOR_DEFAULT
addon.OBJ_COLOR_DEFAULT = OBJ_COLOR_DEFAULT
addon.OBJ_DONE_COLOR_DEFAULT = OBJ_DONE_COLOR_DEFAULT
addon.HIGHLIGHT_COLOR_DEFAULT = HIGHLIGHT_COLOR_DEFAULT
