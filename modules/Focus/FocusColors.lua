--[[
    Horizon Suite - Focus - Colors
    Color matrix: defaults + per-category overrides for title/objective/zone/section.
]]

local addon = _G.HorizonSuite

local function EnsureColorMatrix()
    if not HorizonDB then return end
    if HorizonDB.colorMatrix and type(HorizonDB.colorMatrix) == "table" then return end

    local cm = { categories = {}, overrides = {} }

    -- Migrate legacy quest title colors into per-category title.
    local qc = HorizonDB.questColors
    if qc and type(qc) == "table" then
        for k, v in pairs(qc) do
            if type(v) == "table" and v[1] and v[2] and v[3] then
                if not cm.categories[k] then cm.categories[k] = {} end
                cm.categories[k].title = { v[1], v[2], v[3] }
            end
        end
    end

    -- Migrate legacy section header colors into per-category section.
    local sc = HorizonDB.sectionColors
    if sc and type(sc) == "table" then
        for k, v in pairs(sc) do
            if type(v) == "table" and v[1] and v[2] and v[3] then
                if not cm.categories[k] then cm.categories[k] = {} end
                cm.categories[k].section = { v[1], v[2], v[3] }
            end
        end
    end

    HorizonDB.colorMatrix = cm
end

local function GetColorMatrix()
    if not HorizonDB then return nil end
    EnsureColorMatrix()
    return HorizonDB.colorMatrix
end

-- When override toggles are on, Completed and Current Zone sections use their row colours for all elements.
-- When off, COMPLETE/NEARBY use baseCategory (the underlying quest type) for colours.
local function GetEffectiveColorCategory(category, groupKey, baseCategory)
    if not category then return groupKey or "DEFAULT" end
    local cm = GetColorMatrix()
    local ov = cm and cm.overrides and type(cm.overrides) == "table" and cm.overrides or {}
    if groupKey == "COMPLETE" and (ov.useCompletedOverride == nil or ov.useCompletedOverride) then
        return "COMPLETE"  -- Default true when not explicitly set to false
    end
    if groupKey == "COMPLETE" and baseCategory then
        return baseCategory  -- Use underlying category when override is off
    end
    if groupKey == "NEARBY" and ov.useCurrentZoneOverride then
        return "NEARBY"
    end
    return category
end

-- Matrix rows use group keys (e.g. RARES); quest category can be RARE. Use same row for RARE.
local function MatrixKey(category)
    if category == "RARE" then return "RARES" end
    if category == "ACHIEVEMENT" then return "ACHIEVEMENTS" end
    if category == "ENDEAVOR" then return "ENDEAVORS" end
    if category == "DECOR" then return "DECOR" end
    return category
end

local function GetTitleColor(category)
    if not category then
        return addon.QUEST_COLORS.DEFAULT
    end

    local cm = GetColorMatrix()
    local key = MatrixKey(category)
    if cm and cm.categories and cm.categories[key] and cm.categories[key].title then
        return cm.categories[key].title
    end

    -- Legacy per-category questColors support (for safety if migration didn't run yet).
    local db = HorizonDB and HorizonDB.questColors
    if db then
        if db[category] then return db[category] end
        if category == "CALLING" and db.WORLD then return db.WORLD end
    end

    return addon.QUEST_COLORS[category] or addon.QUEST_COLORS.DEFAULT
end

local function GetObjectiveColor(category)
    local cm = GetColorMatrix()
    local key = category and MatrixKey(category) or nil
    if cm and cm.categories and key and cm.categories[key] and cm.categories[key].objective then
        return cm.categories[key].objective
    end
    return addon.QUEST_COLORS[category] or addon.QUEST_COLORS.DEFAULT
end

local function GetZoneColor(category)
    local cm = GetColorMatrix()
    local key = category and MatrixKey(category) or nil
    if cm and cm.categories and key and cm.categories[key] and cm.categories[key].zone then
        return cm.categories[key].zone
    end
    return addon.ZONE_COLOR
end

local function GetQuestColor(category)
    -- Backwards-compatible wrapper for title color.
    return GetTitleColor(category)
end

local function GetSectionColor(groupKey)
    local cm = GetColorMatrix()
    if cm and cm.categories and groupKey and cm.categories[groupKey] and cm.categories[groupKey].section then
        return cm.categories[groupKey].section
    end
    return addon.SECTION_COLORS[groupKey] or addon.SECTION_COLORS.DEFAULT
end

--- Returns the color for completed objectives when the override is on; nil when off (caller uses same as incomplete).
--- @param category string Optional category (unused when override is on)
--- @return table|nil {r,g,b} or nil
local function GetCompletedObjectiveColor(category)
    if not (addon.GetDB and addon.GetDB("useCompletedObjectiveColor", true)) then
        return nil
    end
    local c = addon.GetDB and addon.GetDB("completedObjectiveColor", nil)
    if c and type(c) == "table" and c[1] and c[2] and c[3] then
        return c
    end
    return addon.OBJ_DONE_COLOR or { 0.30, 0.80, 0.30 }
end

addon.GetEffectiveColorCategory   = GetEffectiveColorCategory
addon.GetCompletedObjectiveColor = GetCompletedObjectiveColor
addon.GetTitleColor        = GetTitleColor
addon.GetObjectiveColor    = GetObjectiveColor
addon.GetZoneColor         = GetZoneColor
addon.GetQuestColor        = GetQuestColor
addon.GetSectionColor      = GetSectionColor
