--[[
    Horizon Suite - Focus - Section Headers
    HideAllSectionHeaders, GetFocusedGroupKey, AcquireSectionHeader.
]]

local addon = _G.HorizonSuite

local sectionPool = addon.sectionPool
local scrollFrame = addon.scrollFrame

local function HideAllSectionHeaders()
    for i = 1, addon.SECTION_POOL_SIZE do
        sectionPool[i].active = false
        sectionPool[i]:Hide()
        sectionPool[i]:SetAlpha(0)
    end
end

local function GetFocusedGroupKey(grouped)
    if not grouped then return nil end
    for _, grp in ipairs(grouped) do
        for _, qData in ipairs(grp.quests) do
            if qData.isSuperTracked then
                return grp.key
            end
        end
    end
    return nil
end

local function AcquireSectionHeader(groupKey, focusedGroupKey)
    addon.focus.layout.sectionIdx = addon.focus.layout.sectionIdx + 1
    if addon.focus.layout.sectionIdx > addon.SECTION_POOL_SIZE then return nil end
    local s = sectionPool[addon.focus.layout.sectionIdx]
    s.groupKey = groupKey

    local label = addon.L[addon.SECTION_LABELS[groupKey] or groupKey]
    label = addon.ApplyTextCase(label, "sectionHeaderTextCase", "upper")
    local color = addon.GetSectionColor(groupKey)
    if addon.GetDB("dimNonSuperTracked", false) and focusedGroupKey and groupKey ~= focusedGroupKey then
        color = { color[1] * 0.60, color[2] * 0.60, color[3] * 0.60 }
    end
    s.text:SetText(label)
    s.shadow:SetText(label)
    s.text:SetTextColor(color[1], color[2], color[3], addon.SECTION_COLOR_A)

    if s.chevron then
        if addon.focus.collapsed and addon.GetDB("showSectionHeadersWhenCollapsed", false) then
            s.chevron:SetText("+")
        elseif addon.IsCategoryCollapsed(groupKey) then
            s.chevron:SetText("+")
        else
            s.chevron:SetText("−")
        end
    end

    s:SetScript("OnClick", function(self)
        local key = self.groupKey
        if not key then return end

        if addon.IsCategoryCollapsed(key) then
            addon.SetCategoryCollapsed(key, false)
            if self.chevron then
                self.chevron:SetText("−")
            end
            if addon.focus.collapsed then
                addon.focus.collapsed = false
                addon.EnsureDB()
                if HorizonDB then HorizonDB.collapsed = false end
                addon.chevron:SetText("-")
                scrollFrame:Show()
            end
            addon.FullLayout()
        else
            if self.chevron then
                self.chevron:SetText("+")
            end
            if addon.StartGroupCollapse then
                addon.StartGroupCollapse(key)
            end
        end
    end)

    s.active = true
    s:SetAlpha(1)
    s:Show()
    return s
end

addon.HideAllSectionHeaders = HideAllSectionHeaders
addon.GetFocusedGroupKey    = GetFocusedGroupKey
addon.AcquireSectionHeader  = AcquireSectionHeader
