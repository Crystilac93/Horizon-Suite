--[[
    HORIZON SUITE
    Core addon with pluggable modules. Focus (objective tracker) is the first module.
    This file creates the addon namespace and module registry; behavior lives in Core and module files.

    Abbreviation glossary:
    - HS   = Horizon Suite (addon / frame prefix)
    - WQ   = World Quest
    - M+   = Mythic Plus (dungeon)
    - ATT  = All The Things (addon; rare vignette source)
    - WQT  = World Quest / Task Quest (C_TaskQuest API)
]]

if not _G.HorizonSuite then _G.HorizonSuite = {} end
local addon = _G.HorizonSuite

-- ============================================================================
-- MODULE REGISTRY AND LIFECYCLE
-- ============================================================================

addon.modules = {}

-- Localization: L[key] returns translated string or key as fallback. Locale files (e.g. options/koKR.lua) overwrite addon.L when loaded.
addon.L = setmetatable({}, { __index = function(t, k) return k end })

--- Register a module. Called by module files at load time.
-- @param key string Module identifier (e.g. "focus")
-- @param def table { title, description, order, OnInit, OnEnable, OnDisable }
function addon:RegisterModule(key, def)
    if not key or type(key) ~= "string" or key == "" then return end
    if self.modules[key] then return end
    self.modules[key] = {
        key         = key,
        title       = def.title or key,
        description = def.description or "",
        order       = def.order or 100,
        OnInit      = def.OnInit,
        OnEnable    = def.OnEnable,
        OnDisable   = def.OnDisable,
        initialized = false,
        enabled     = false,
    }
end

--- Check if a module is enabled (runtime state).
function addon:IsModuleEnabled(key)
    local m = self.modules[key]
    return m and m.enabled
end

--- Get module definition by key.
function addon:GetModule(key)
    return self.modules[key]
end

--- Iterate over all registered modules (for options, etc.).
function addon:IterateModules()
    local keys = {}
    for k in pairs(self.modules) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        local ma, mb = self.modules[a], self.modules[b]
        local oa = ma and ma.order or 100
        local ob = mb and mb.order or 100
        if oa ~= ob then return oa < ob end
        return (ma and ma.title or a) < (mb and mb.title or b)
    end)
    local i = 0
    return function()
        i = i + 1
        if keys[i] then return keys[i], self.modules[keys[i]] end
    end
end

--- Call callback for each enabled module.
function addon:ForEachEnabledModule(cb)
    for key, m in pairs(self.modules) do
        if m.enabled and cb then cb(key, m) end
    end
end

--- Enable a module. Loads DB, calls OnInit once, then OnEnable.
function addon:EnableModule(key)
    local m = self.modules[key]
    if not m or m.enabled then return end
    if not HorizonDB then HorizonDB = {} end
    if not HorizonDB.modules then HorizonDB.modules = {} end
    if not HorizonDB.modules[key] then HorizonDB.modules[key] = {} end
    HorizonDB.modules[key].enabled = true
    if not m.initialized and m.OnInit then
        m.OnInit(self)
        m.initialized = true
    end
    if m.OnEnable then m.OnEnable(self) end
    m.enabled = true
end

--- Disable a module. Calls OnDisable, updates DB.
function addon:DisableModule(key)
    local m = self.modules[key]
    if not m or not m.enabled then return end
    if m.OnDisable then m.OnDisable(self) end
    m.enabled = false
    if HorizonDB and HorizonDB.modules and HorizonDB.modules[key] then
        HorizonDB.modules[key].enabled = false
    end
end

--- Set module enabled state (convenience for toggles).
function addon:SetModuleEnabled(key, enabled)
    if enabled then self:EnableModule(key) else self:DisableModule(key) end
end

--- Ensure modules table exists and migrate legacy installs (no modules table = all defaults).
function addon:EnsureModulesDB()
    if not HorizonDB then HorizonDB = {} end
    if not HorizonDB.modules then
        HorizonDB.modules = {}
        -- Legacy install: default focus to enabled, Presence off (still has issues)
        HorizonDB.modules.focus = { enabled = true }
        HorizonDB.modules.presence = { enabled = false }
    end
    -- Migrate Vista module key to Presence (default off; user can enable in options)
    if HorizonDB.modules.vista and not HorizonDB.modules.presence then
        HorizonDB.modules.presence = { enabled = false }
    end
end

-- Binding display names for Key Bindings UI (must match Binding name in Bindings.xml exactly)
_G["BINDING_NAME_CLICK HSCollapseButton:LeftButton"] = "Collapse Tracker"
_G["BINDING_NAME_CLICK HSNearbyToggleButton:LeftButton"] = "Toggle Nearby Group"
