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
    headerFontSize = true,
    titleFontSize = true,
    objectiveFontSize = true,
    zoneFontSize = true,
    sectionFontSize = true,
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
    presenceSuppressZoneInMplus = true,
    presenceLevelUp = true,
    presenceBossEmote = true,
    presenceAchievement = true,
    presenceQuestEvents = true,
    presenceAnimations = true,
    presenceEntranceDur = true,
    presenceExitDur = true,
    presenceHoldScale = true,
    presenceMainSize = true,
    presenceSubSize = true,
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
    if key == "fontPath" and updateOptionsPanelFontsRef then
        updateOptionsPanelFontsRef()
    end
    if TYPOGRAPHY_KEYS[key] and addon.UpdateFontObjectsFromDB then
        addon.UpdateFontObjectsFromDB()
    end
    if MPLUS_TYPOGRAPHY_KEYS[key] and addon.ApplyMplusTypography then
        addon.ApplyMplusTypography()
    end
    if PRESENCE_KEYS[key] and addon.Presence and addon.Presence.ApplyPresenceOptions then
        addon.Presence.ApplyPresenceOptions()
    end
    if INSIGHT_KEYS[key] and addon.Insight and addon.Insight.ApplyInsightOptions then
        addon.Insight.ApplyInsightOptions()
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
    OptionsData_NotifyMainAddon()
end

--- Lightweight notify for live color picker: updates visuals without FullLayout.
function OptionsData_NotifyMainAddon_Live()
    local applyTy = _G.HorizonSuite_ApplyTypography or addon.ApplyTypography
    if applyTy then applyTy() end
    if addon.ApplyBackdropOpacity then addon.ApplyBackdropOpacity() end
    if addon.ApplyBorderVisibility then addon.ApplyBorderVisibility() end
    if addon.ApplyFocusColors then addon.ApplyFocusColors() end
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
            }
            if dev and dev.showInsightToggle then
                opts[#opts + 1] = { type = "toggle", name = L["Enable Horizon Insight module"] .. betaSuffix, desc = L["Cinematic tooltips with class colors, spec display, and faction icons."], dbKey = "_module_insight", get = function() return addon:IsModuleEnabled("insight") end, set = function(v) addon:SetModuleEnabled("insight", v) end }
            end
            if dev and dev.showYieldToggle then
                opts[#opts + 1] = { type = "toggle", name = L["Enable Yield module"] .. betaSuffix, desc = L["Cinematic loot notifications (items, money, currency, reputation)."], dbKey = "_module_yield", get = function() return addon:IsModuleEnabled("yield") end, set = function(v) addon:SetModuleEnabled("yield", v) end }
            end
            if dev and dev.showVistaToggle then
                opts[#opts + 1] = { type = "toggle", name = L["Enable Vista module"] .. betaSuffix, desc = L["Cinematic square minimap with zone text, coordinates, and button collector."], dbKey = "_module_vista", get = function() return addon:IsModuleEnabled("vista") end, set = function(v) addon:SetModuleEnabled("vista", v) end }
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
            { type = "toggle", name = L["Show objective numbers"], desc = L["Prefix objectives with 1., 2., 3."], dbKey = "showObjectiveNumbers", get = function() return getDB("showObjectiveNumbers", false) end, set = function(v) setDB("showObjectiveNumbers", v) end },
            { type = "toggle", name = L["Show entry numbers"], desc = L["Prefix quest titles with 1., 2., 3. within each category."], dbKey = "showCategoryEntryNumbers", get = function() return getDB("showCategoryEntryNumbers", true) end, set = function(v) setDB("showCategoryEntryNumbers", v) end },
            { type = "toggle", name = L["Show completed count"], desc = L["Show X/Y progress in quest title."], dbKey = "showCompletedCount", get = function() return getDB("showCompletedCount", false) end, set = function(v) setDB("showCompletedCount", v) end },
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
            { type = "slider", name = L["Header size"], desc = L["Header font size."], dbKey = "headerFontSize", min = 8, max = 32, get = function() return getDB("headerFontSize", 16) end, set = function(v) setDB("headerFontSize", v) end },
            { type = "slider", name = L["Title size"], desc = L["Quest title font size."], dbKey = "titleFontSize", min = 8, max = 24, get = function() return getDB("titleFontSize", 13) end, set = function(v) setDB("titleFontSize", v) end },
            { type = "slider", name = L["Objective size"], desc = L["Objective text font size."], dbKey = "objectiveFontSize", min = 8, max = 20, get = function() return getDB("objectiveFontSize", 11) end, set = function(v) setDB("objectiveFontSize", v) end },
            { type = "slider", name = L["Zone size"], desc = L["Zone label font size."], dbKey = "zoneFontSize", min = 8, max = 18, get = function() return getDB("zoneFontSize", 10) end, set = function(v) setDB("zoneFontSize", v) end },
            { type = "slider", name = L["Section size"], desc = L["Section header font size."], dbKey = "sectionFontSize", min = 8, max = 18, get = function() return getDB("sectionFontSize", 10) end, set = function(v) setDB("sectionFontSize", v) end },
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
            { type = "toggle", name = L["Show zone changes"], desc = L["Show zone and subzone change notifications."], dbKey = "presenceZoneChange", get = function() return getDB("presenceZoneChange", true) end, set = function(v) setDB("presenceZoneChange", v) end },
            { type = "toggle", name = L["Suppress zone changes in Mythic+"], desc = L["In Mythic+, only show boss emotes, achievements, and level-up. Hide zone, quest, and scenario notifications."], dbKey = "presenceSuppressZoneInMplus", get = function() return getDB("presenceSuppressZoneInMplus", true) end, set = function(v) setDB("presenceSuppressZoneInMplus", v) end },
            { type = "toggle", name = L["Show level up"], desc = L["Show level-up notification."], dbKey = "presenceLevelUp", get = function() return getDB("presenceLevelUp", true) end, set = function(v) setDB("presenceLevelUp", v) end },
            { type = "toggle", name = L["Show boss emotes"], desc = L["Show raid and dungeon boss emote notifications."], dbKey = "presenceBossEmote", get = function() return getDB("presenceBossEmote", true) end, set = function(v) setDB("presenceBossEmote", v) end },
            { type = "toggle", name = L["Show achievements"], desc = L["Show achievement earned notifications."], dbKey = "presenceAchievement", get = function() return getDB("presenceAchievement", true) end, set = function(v) setDB("presenceAchievement", v) end },
            { type = "toggle", name = L["Show quest events"], desc = L["Show quest accept, complete, and progress notifications."], dbKey = "presenceQuestEvents", get = function() return getDB("presenceQuestEvents", true) end, set = function(v) setDB("presenceQuestEvents", v) end },
        },
    },
    {
        key = "PresenceAnimation",
        name = L["Animation"],
        moduleKey = "presence",
        options = {
            { type = "section", name = L["Animation"] },
            { type = "toggle", name = L["Enable animations"], desc = L["Enable entrance and exit animations for Presence notifications."], dbKey = "presenceAnimations", get = function() return getDB("presenceAnimations", true) end, set = function(v) setDB("presenceAnimations", v) end },
            { type = "slider", name = L["Entrance duration"], desc = L["Duration of the entrance animation in seconds (0.2–1.5)."], dbKey = "presenceEntranceDur", min = 0.2, max = 1.5, get = function() return math.max(0.2, math.min(1.5, tonumber(getDB("presenceEntranceDur", 0.7)) or 0.7)) end, set = function(v) setDB("presenceEntranceDur", math.max(0.2, math.min(1.5, v))) end },
            { type = "slider", name = L["Exit duration"], desc = L["Duration of the exit animation in seconds (0.2–1.5)."], dbKey = "presenceExitDur", min = 0.2, max = 1.5, get = function() return math.max(0.2, math.min(1.5, tonumber(getDB("presenceExitDur", 0.8)) or 0.8)) end, set = function(v) setDB("presenceExitDur", math.max(0.2, math.min(1.5, v))) end },
            { type = "slider", name = L["Hold duration scale"], desc = L["Multiplier for how long each notification stays on screen (0.5–2)."], dbKey = "presenceHoldScale", min = 0.5, max = 2, get = function() return math.max(0.5, math.min(2, tonumber(getDB("presenceHoldScale", 1)) or 1)) end, set = function(v) setDB("presenceHoldScale", math.max(0.5, math.min(2, v))) end },
        },
    },
    {
        key = "PresenceTypography",
        name = L["Typography"],
        moduleKey = "presence",
        options = {
            { type = "section", name = L["Typography"] },
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
    for catIdx, cat in ipairs(OptionCategories) do
        local currentSection = ""
        local moduleKey = cat.moduleKey
        local moduleLabel = (moduleKey == "focus" and L["Focus"]) or (moduleKey == "presence" and L["Presence"]) or (moduleKey == "insight" and (L["Insight"] or "Insight")) or (moduleKey == "yield" and L["Yield"]) or L["Modules"]
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
