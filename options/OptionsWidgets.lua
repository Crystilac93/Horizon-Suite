--[[
    Horizon Suite - Focus - Options Widgets
    Reusable widget library: toggle, slider, dropdown, color swatch, search input, reorder list, section card/header.
    Modern Cinematic styling. All widgets expose :Refresh() and .searchText for search indexing.
]]

local addon = _G.HorizonSuite
if not addon then return end

local L = addon.L

-- Design tokens (Cinematic, Modern, Minimalistic). Panel can override FontPath/HeaderSize via SetDef.
local Def = {
    Padding = 18,
    OptionGap = 14,
    SectionGap = 24,
    CardPadding = 18,
    BorderEdge = 1,
    CornerRadius = 8,
    LabelSize = 13,
    SectionSize = 11,
    FontPath = (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF",
    HeaderSize = addon.HEADER_SIZE or 16,
    TextColorNormal = { 1, 1, 1 },
    TextColorHighlight = { 0.72, 0.8, 0.95, 1 },
    TextColorLabel = { 0.84, 0.84, 0.88 },
    TextColorSection = { 0.58, 0.64, 0.74 },
    TextColorTitleBar = { 0.9, 0.92, 0.96, 1 },
    SectionCardBg = { 0.09, 0.09, 0.11, 0.96 },
    SectionCardBorder = { 0.18, 0.2, 0.24, 0.35 },
    AccentColor = { 0.48, 0.58, 0.82, 0.9 },
    DividerColor = { 0.35, 0.4, 0.5, 0.25 },
    InputBg = { 0.07, 0.07, 0.1, 0.96 },
    InputBorder = { 0.2, 0.22, 0.28, 0.4 },
    TrackOff = { 0.14, 0.14, 0.18, 0.95 },
    TrackOn = { 0.48, 0.58, 0.82, 0.85 },
    ThumbColor = { 1, 1, 1, 0.98 },
}
Def.BorderColor = Def.SectionCardBorder
if addon.StandardFont then
    Def.FontPath = addon.StandardFont
end

local _activeColorPickerCallbacks = nil  -- { setKeyVal, notify, tex } when our picker is open
local _hexBoxHooked = false

function _G.OptionsWidgets_SetDef(overrides)
    if not overrides then return end
    for k, v in pairs(overrides) do Def[k] = v end
end

local SetTextColor = addon.SetTextColor or function(obj, color)
    if not color or not obj then return end
    obj:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local easeOut = addon.easeOut or function(t) return 1 - (1 - t) * (1 - t) end
local TOGGLE_ANIM_DUR = 0.15

-- Rounded pill toggle: 48x22 track with inset for softer look, 18px thumb. On = accent fill, Off = dark.
local TOGGLE_TRACK_W, TOGGLE_TRACK_H = 48, 22
local TOGGLE_INSET = 2
local TOGGLE_THUMB_SIZE = 18

function OptionsWidgets_CreateToggleSwitch(parent, labelText, description, get, set, disabledFn)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(38)
    local searchText = (labelText or "") .. " " .. (description or "")
    row.searchText = searchText:lower()

    local trackW, trackH = TOGGLE_TRACK_W, TOGGLE_TRACK_H
    local thumbSize = TOGGLE_THUMB_SIZE
    local track = CreateFrame("Frame", nil, row)
    track:SetSize(trackW, trackH)
    track:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -10)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetPoint("TOPLEFT", track, "TOPLEFT", TOGGLE_INSET, -TOGGLE_INSET)
    trackBg:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", -TOGGLE_INSET, TOGGLE_INSET)
    trackBg:SetColorTexture(Def.TrackOff[1], Def.TrackOff[2], Def.TrackOff[3], Def.TrackOff[4])
    local trackFill = track:CreateTexture(nil, "ARTWORK")
    trackFill:SetPoint("TOPLEFT", track, "TOPLEFT", TOGGLE_INSET, -TOGGLE_INSET)
    trackFill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", TOGGLE_INSET, TOGGLE_INSET)
    trackFill:SetWidth(0)
    trackFill:SetColorTexture(Def.TrackOn[1], Def.TrackOn[2], Def.TrackOn[3], Def.TrackOn[4])
    local thumb = track:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(thumbSize, thumbSize)
    thumb:SetColorTexture(Def.ThumbColor[1], Def.ThumbColor[2], Def.ThumbColor[3], Def.ThumbColor[4])
    thumb:SetPoint("CENTER", track, "LEFT", TOGGLE_INSET + thumbSize/2, 0)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(labelText or "")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    label:SetPoint("RIGHT", track, "LEFT", -12, 0)
    label:SetWordWrap(true)

    local desc = row:CreateFontString(nil, "OVERLAY")
    desc:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    desc:SetJustifyH("LEFT")
    SetTextColor(desc, Def.TextColorSection)
    desc:SetText(description or "")
    desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", track, "LEFT", -12, 0)
    desc:SetWordWrap(true)

    local btn = CreateFrame("Button", nil, row)
    btn:SetAllPoints(track)

    row.thumbPos = get() and 1 or 0
    row.animStart = nil
    row.animFrom = nil
    row.animTo = nil

    local fillW = trackW - 2 * TOGGLE_INSET
    local thumbTravel = fillW - thumbSize
    local function updateVisuals(t)
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", track, "LEFT", TOGGLE_INSET + thumbSize/2 + t * thumbTravel, 0)
        trackFill:SetWidth(t * fillW)
    end

    local function applyDisabledVisuals()
        local dis = disabledFn and disabledFn() == true
        if dis then
            label:SetAlpha(0.45)
            desc:SetAlpha(0.45)
            track:SetAlpha(0.45)
        else
            label:SetAlpha(1)
            desc:SetAlpha(1)
            track:SetAlpha(1)
        end
    end

    local function toggleOnUpdate()
        if not row.animStart then
            track:SetScript("OnUpdate", nil)
            return
        end
        local elapsed = GetTime() - row.animStart
        if elapsed >= TOGGLE_ANIM_DUR then
            row.thumbPos = row.animTo
            row.animStart = nil
            updateVisuals(row.thumbPos)
            track:SetScript("OnUpdate", nil)
            return
        end
        row.thumbPos = row.animFrom + (row.animTo - row.animFrom) * easeOut(elapsed / TOGGLE_ANIM_DUR)
        updateVisuals(row.thumbPos)
    end

    btn:SetScript("OnClick", function()
        if disabledFn and disabledFn() == true then return end
        local next = not get()
        set(next)
        row.animStart = GetTime()
        row.animFrom = row.thumbPos
        row.animTo = next and 1 or 0
        track:SetScript("OnUpdate", toggleOnUpdate)
    end)

    function row:Refresh()
        local on = get()
        row.thumbPos = on and 1 or 0
        row.animStart = nil
        track:SetScript("OnUpdate", nil)
        updateVisuals(row.thumbPos)
        applyDisabledVisuals()
    end

    row:Refresh()
    return row
end

-- Slider: slim rounded track + draggable thumb + numeric readout
local SLIDER_TRACK_HEIGHT = 6
local SLIDER_THUMB_SIZE = 14
local SLIDER_TRACK_INSET = 2
function OptionsWidgets_CreateSlider(parent, labelText, description, get, set, minVal, maxVal)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(40)
    local searchText = (labelText or "") .. " " .. (description or "")
    row.searchText = searchText:lower()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(labelText or "")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    local desc = row:CreateFontString(nil, "OVERLAY")
    desc:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    desc:SetJustifyH("LEFT")
    SetTextColor(desc, Def.TextColorSection)
    desc:SetText(description or "")
    desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    desc:SetWordWrap(true)

    local trackWidth = 180
    local track = CreateFrame("Frame", nil, row)
    track:SetSize(trackWidth, SLIDER_TRACK_HEIGHT)
    track:SetPoint("TOPRIGHT", row, "TOPRIGHT", -52, -8)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetPoint("TOPLEFT", track, "TOPLEFT", SLIDER_TRACK_INSET, -SLIDER_TRACK_INSET)
    trackBg:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", -SLIDER_TRACK_INSET, SLIDER_TRACK_INSET)
    trackBg:SetColorTexture(Def.TrackOff[1], Def.TrackOff[2], Def.TrackOff[3], Def.TrackOff[4])
    local trackFill = track:CreateTexture(nil, "ARTWORK")
    trackFill:SetPoint("TOPLEFT", track, "TOPLEFT", SLIDER_TRACK_INSET, -SLIDER_TRACK_INSET)
    trackFill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", SLIDER_TRACK_INSET, SLIDER_TRACK_INSET)
    trackFill:SetColorTexture(Def.TrackOn[1], Def.TrackOn[2], Def.TrackOn[3], Def.TrackOn[4])

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetSize(SLIDER_THUMB_SIZE, SLIDER_THUMB_SIZE)
    thumb:SetPoint("CENTER", track, "LEFT", 0, 0)
    local thumbTex = thumb:CreateTexture(nil, "BACKGROUND")
    thumbTex:SetAllPoints(thumb)
    thumbTex:SetColorTexture(Def.ThumbColor[1], Def.ThumbColor[2], Def.ThumbColor[3], Def.ThumbColor[4])

    local edit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    edit:SetSize(44, 20)
    edit:SetPoint("LEFT", track, "RIGHT", 8, 0)
    edit:SetMaxLetters(6)
    edit:SetNumeric(true)
    edit:SetAutoFocus(false)
    edit:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    edit:SetScript("OnEscapePressed", function() edit:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function()
        local v = tonumber(edit:GetText())
        if v ~= nil then
            v = math.max(minVal, math.min(maxVal, v))
            set(v)
            edit:SetText(tostring(v))
        end
        edit:ClearFocus()
    end)
    edit:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local v = tonumber(self:GetText())
        if v ~= nil then
            v = math.max(minVal, math.min(maxVal, v))
            set(v)
        end
    end)

    local function valueToNorm(v)
        if maxVal <= minVal then return 0 end
        return (v - minVal) / (maxVal - minVal)
    end
    local function normToValue(n)
        return minVal + n * (maxVal - minVal)
    end

    local fillWidth = trackWidth - 2 * SLIDER_TRACK_INSET
    local thumbTravel = fillWidth - SLIDER_THUMB_SIZE
    local function updateFromValue(v)
        v = math.max(minVal, math.min(maxVal, v))
        local n = valueToNorm(v)
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", track, "LEFT", SLIDER_TRACK_INSET + SLIDER_THUMB_SIZE/2 + n * thumbTravel, 0)
        trackFill:SetWidth(n * fillWidth)
        edit:SetText(tostring(math.floor(v + 0.5)))
    end

    local dragging = false
    local startNorm, startX
    thumb:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        dragging = true
        startNorm = valueToNorm(get())
        local scale = track:GetEffectiveScale()
        startX = GetCursorPosition() / scale
        thumb:GetParent():SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then
                thumb:GetParent():SetScript("OnUpdate", nil)
                dragging = false
                return
            end
            local x = GetCursorPosition() / scale
            local delta = (x - startX) / fillWidth
            local n = math.max(0, math.min(1, startNorm + delta))
            local v = normToValue(n)
            set(v)
            updateFromValue(v)
            startNorm = n
            startX = x
        end)
    end)

    function row:Refresh()
        updateFromValue(get())
    end

    row:Refresh()
    return row
end

-- Custom dropdown: button + popup list (no UIDropDownMenuTemplate)
-- When searchable is true, adds an EditBox above the list to filter options by name (e.g. font dropdown).
function OptionsWidgets_CreateCustomDropdown(parent, labelText, description, options, get, set, displayFn, searchable, disabledFn)
    local labelFn = type(labelText) == "function" and labelText or nil
    local resolvedLabel = labelFn and labelFn() or labelText
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(52)
    local searchText = (resolvedLabel or "") .. " " .. (description or "")
    row.searchText = searchText:lower()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorLabel)
    label:SetText(resolvedLabel or "")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

    local desc = row:CreateFontString(nil, "OVERLAY")
    desc:SetFont(Def.FontPath, Def.SectionSize, "OUTLINE")
    desc:SetJustifyH("LEFT")
    SetTextColor(desc, Def.TextColorSection)
    desc:SetText(description or "")
    desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    desc:SetWordWrap(true)

    local btn = CreateFrame("Button", nil, row)
    btn:SetHeight(26)
    btn:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -28)
    btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    local btnBg = btn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    btnBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    btnBg:SetColorTexture(Def.InputBg[1], Def.InputBg[2], Def.InputBg[3], Def.InputBg[4])

    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(btnText, Def.TextColorLabel)
    btnText:SetPoint("LEFT", btn, "LEFT", 8, 0)
    btnText:SetPoint("RIGHT", btn, "RIGHT", -24, 0)
    btnText:SetJustifyH("LEFT")

    local chevron = btn:CreateFontString(nil, "OVERLAY")
    chevron:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(chevron, Def.TextColorSection)
    chevron:SetText("v")
    chevron:SetPoint("RIGHT", btn, "RIGHT", -6, 0)

    local list = CreateFrame("Frame", nil, UIParent)
    list:SetFrameStrata("TOOLTIP")
    list:Hide()
    list:SetSize(200, 1)

    local listBg = list:CreateTexture(nil, "BACKGROUND")
    listBg:SetAllPoints(list)
    listBg:SetColorTexture(Def.SectionCardBg[1], Def.SectionCardBg[2], Def.SectionCardBg[3], Def.SectionCardBg[4])
    addon.CreateBorder(list, Def.SectionCardBorder)

    local searchEdit
    if searchable then
        searchEdit = CreateFrame("EditBox", nil, list)
        searchEdit:SetHeight(26)
        searchEdit:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -6)
        searchEdit:SetPoint("TOPRIGHT", list, "TOPRIGHT", -6, 0)
        searchEdit:SetAutoFocus(false)
        searchEdit:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        searchEdit:SetTextInsets(8, 8, 0, 0)
        local tc = Def.TextColorLabel
        searchEdit:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
        local searchBg = searchEdit:CreateTexture(nil, "BACKGROUND")
        searchBg:SetAllPoints(searchEdit)
        searchBg:SetColorTexture(Def.InputBg[1], Def.InputBg[2], Def.InputBg[3], Def.InputBg[4])
        local ph = searchEdit:CreateFontString(nil, "OVERLAY")
        ph:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        SetTextColor(ph, Def.TextColorSection)
        ph:SetText(L["Search fonts..."] or "Search fonts...")
        ph:SetPoint("LEFT", searchEdit, "LEFT", 8, 0)
        ph:SetJustifyH("LEFT")
        searchEdit.placeholder = ph
        searchEdit:SetScript("OnEditFocusGained", function() if ph then ph:Hide() end end)
        searchEdit:SetScript("OnEditFocusLost", function() if ph and searchEdit:GetText() == "" then ph:Show() end end)
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, list)
    if searchable then
        scrollFrame:SetPoint("TOPLEFT", searchEdit, "BOTTOMLEFT", 0, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -4, 4)
    else
        scrollFrame:SetAllPoints(list)
    end

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(1)
    scrollChild:SetHeight(1)

    -- Ensure the dropdown list scrolls internally and doesn't forward wheel events to the parent panel.
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetPropagateMouseMotion(false)
    list:EnableMouseWheel(true)
    list:SetPropagateMouseMotion(false)

    local function consumeWheel() end
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        if not list:IsShown() then return end
        if self.StopMovingOrSizing then self:StopMovingOrSizing() end -- no-op consume
        local step = 22 * 3
        local cur = self:GetVerticalScroll() or 0
        local childH = (scrollChild and scrollChild:GetHeight()) or 0
        local frameH = self:GetHeight() or 0
        local maxScroll = math.max(0, childH - frameH)
        local new = math.max(0, math.min(cur - delta * step, maxScroll))
        self:SetVerticalScroll(new)
    end)
    -- Capture mouse wheel on the outer list too, so the options panel underneath doesn't scroll.
    list:SetScript("OnMouseWheel", function() consumeWheel() end)

    -- Keep our own list of option buttons; GetNumChildren()/GetChildren() is unreliable.
    local optionButtons = {}

    local catch = CreateFrame("Button", "HorizonSuite_DropdownCatch" .. tostring(row):gsub("table: ", ""), UIParent)
    catch:SetFrameStrata("TOOLTIP")
    catch:SetAllPoints(UIParent)
    catch:Hide()

    -- Allow ESC to close an open dropdown.
    -- WoW's CloseSpecialWindows() hides frames listed in UISpecialFrames.
    catch.__horizonDropdownCatch = true
    if _G.UISpecialFrames then
        local n = catch:GetName()
        local exists = false
        for i = 1, #_G.UISpecialFrames do
            if _G.UISpecialFrames[i] == n then exists = true break end
        end
        if not exists then tinsert(_G.UISpecialFrames, n) end
    end

    local function closeList()
        if addon._OnDropdownClosed then addon._OnDropdownClosed(closeList) end
        if searchable and searchEdit and searchEdit:HasFocus() then
            searchEdit:ClearFocus()
        end
        list:Hide()
        catch:Hide()
    end
    catch:SetScript("OnClick", closeList)
    catch:SetScript("OnHide", function()
        -- Keep list in sync if the catch is hidden via ESC.
        if list:IsShown() then
            if addon._OnDropdownClosed then addon._OnDropdownClosed(closeList) end
            list:Hide()
        end
    end)

    local function setValue(value, display)
        set(value)
        btnText:SetText(display or tostring(value))
        closeList()
    end

    local function normalizeOptions(opts)
        if type(opts) ~= "table" then return {} end
        -- Rebuild into a dense array.
        local out = {}
        for k, v in pairs(opts) do
            if type(k) == "number" and type(v) == "table" then
                -- Expected shape: { name, value }
                out[#out + 1] = v
            elseif type(k) == "string" then
                -- Map shape: name -> value
                out[#out + 1] = { k, v }
            end
        end
        table.sort(out, function(a, b)
            return tostring(a and a[1] or "") < tostring(b and b[1] or "")
        end)
        return out
    end

    local SEARCH_BOX_HEIGHT = searchable and 36 or 0

    local function populate()
        list:SetParent(UIParent)
        list:ClearAllPoints()
        list:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)

        local fullOpts = normalizeOptions((type(options) == "function" and options()) or options or {})
        local opts = fullOpts
        if searchable and searchEdit then
            local filterText = searchEdit:GetText()
            if type(filterText) == "string" and filterText ~= "" then
                local lower = filterText:lower()
                opts = {}
                for _, opt in ipairs(fullOpts) do
                    local name = opt and opt[1] or ""
                    if name:lower():find(lower, 1, true) then
                        opts[#opts + 1] = opt
                    end
                end
            end
        end

        local num = #opts

        local rowH = 22
        local maxHeight = 330
        local totalHeight = num * rowH

        list:SetWidth(btn:GetWidth())
        list:SetHeight(SEARCH_BOX_HEIGHT + math.min(totalHeight, maxHeight))
        scrollChild:SetWidth(btn:GetWidth())
        scrollChild:SetHeight(math.max(totalHeight, 1))
        scrollFrame:SetVerticalScroll(0)

        if searchable and searchEdit then
            searchEdit:Show()
        end

         for i = 1, num do
             local b = optionButtons[i]
             if not b then
                 b = CreateFrame("Button", nil, scrollChild)
                 b:SetHeight(rowH)

                local tb = b:CreateFontString(nil, "OVERLAY")
                tb:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
                tb:SetPoint("LEFT", b, "LEFT", 8, 0)
                tb:SetJustifyH("LEFT")
                b.text = tb

                local hi = b:CreateTexture(nil, "BACKGROUND")
                hi:SetAllPoints(b)
                hi:SetColorTexture(1, 1, 1, 0.06)
                hi:Hide()
                b:SetScript("OnEnter", function() hi:Show() end)
                b:SetScript("OnLeave", function() hi:Hide() end)

                optionButtons[i] = b
            end
        end

        for i = 1, num do
            local opt = opts[i]
            local name = opt and opt[1]
            local value = opt and opt[2]
            local b = optionButtons[i]

            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * rowH)
            b:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(i - 1) * rowH)

            b.text:SetText(name)
            b:SetScript("OnClick", function()
                setValue(value, name)
            end)
            b:Show()
        end

        for i = num + 1, #optionButtons do
            optionButtons[i]:Hide()
        end

        if addon._OnDropdownOpened then addon._OnDropdownOpened(closeList) end
        list:Show()
        catch:Show()
    end

    if searchable and searchEdit then
        searchEdit:SetScript("OnTextChanged", function() populate() end)
    end

    local function isDisabled()
        return disabledFn and disabledFn() == true
    end

    local function applyDisabledVisuals()
        local dis = isDisabled()
        if dis then
            btn:Disable()
            SetTextColor(btnText, Def.TextColorSection)
            chevron:SetAlpha(0.5)
            btnBg:SetAlpha(0.6)
        else
            btn:Enable()
            SetTextColor(btnText, Def.TextColorLabel)
            chevron:SetAlpha(1)
            btnBg:SetAlpha(1)
        end
    end

    btn:SetScript("OnClick", function()
        if isDisabled() then return end
        if list:IsShown() then
            closeList()
            return
        end
        if searchable and searchEdit then
            searchEdit:SetText("")
            if searchEdit.placeholder then searchEdit.placeholder:Show() end
        end
        populate()
        if searchable and searchEdit then
            searchEdit:SetFocus()
        end
    end)

    function row:Refresh()
        if labelFn then
            local newLabel = labelFn()
            if newLabel then label:SetText(newLabel) end
        end
        local val = get()
        local opts = normalizeOptions((type(options) == "function" and options()) or options or {})

        for _, opt in ipairs(opts) do
            local optVal = opt[2]
            if optVal == val then
                btnText:SetText(opt[1])
                applyDisabledVisuals()
                return
            end
        end

        if searchable and addon.ResolveFontPath then
            local valResolved = addon.ResolveFontPath(val) or val
            for _, opt in ipairs(opts) do
                local optVal = opt[2]
                local optResolved = addon.ResolveFontPath(optVal) or optVal
                if optResolved == valResolved then
                    if displayFn then
                        btnText:SetText(displayFn(optVal))
                    else
                        btnText:SetText(opt[1])
                    end
                    applyDisabledVisuals()
                    return
                end
            end
        end

        if displayFn then
            btnText:SetText(displayFn(val))
        elseif val == nil or val == "" then
            btnText:SetText("")
        else
            btnText:SetText(tostring(val))
        end
        applyDisabledVisuals()
    end

    row:Refresh()
    return row
end

-- Helper: get effective color from ColorPickerFrame, preferring HexBox if user typed hex (10.2.5+).
-- Returns r, g, b in 0-1 range. HexBox may contain "ff0000", "#ff0000", or "f00" (3-char shorthand).
local function GetColorPickerEffectiveRGB()
    if not ColorPickerFrame then return 0.5, 0.5, 0.5 end
    local content = ColorPickerFrame.Content
    local hexBox = content and content.HexBox
    if hexBox and hexBox.GetText then
        local raw = hexBox:GetText()
        if type(raw) == "string" and #raw > 0 then
            local hex = raw:gsub("^#", ""):gsub("%s+", "")
            if #hex >= 3 then
                if #hex == 3 then
                    hex = hex:gsub("(%x)(%x)(%x)", "%1%1%2%2%3%3")
                end
                hex = hex:sub(1, 6)
                while #hex < 6 do hex = hex .. "0" end
                local r = tonumber(hex:sub(1, 2), 16)
                local g = tonumber(hex:sub(3, 4), 16)
                local b = tonumber(hex:sub(5, 6), 16)
                if r and g and b then
                    return r / 255, g / 255, b / 255
                end
            end
        end
    end
    return ColorPickerFrame:GetColorRGB()
end

-- Sync hex box to picker visual and apply color (live update when user types). Only runs when our picker is open.
local function SyncHexBoxToPicker()
    if not ColorPickerFrame:IsVisible() or not _activeColorPickerCallbacks then return end
    local content = ColorPickerFrame.Content
    local hexBox = content and content.HexBox
    if not hexBox or not hexBox.GetText then return end
    local raw = hexBox:GetText()
    if type(raw) ~= "string" or #raw < 3 then return end
    local hex = raw:gsub("^#", ""):gsub("%s+", "")
    if #hex < 3 then return end
    if #hex == 3 then hex = hex:gsub("(%x)(%x)(%x)", "%1%1%2%2%3%3") end
    hex = hex:sub(1, 6)
    while #hex < 6 do hex = hex .. "0" end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then return end
    r, g, b = r / 255, g / 255, b / 255
    local cp = content.ColorPicker
    local swatchCurrent = content.ColorSwatchCurrent
    if cp and cp.SetColorRGB then cp:SetColorRGB(r, g, b) end
    if swatchCurrent and swatchCurrent.SetColorTexture then swatchCurrent:SetColorTexture(r, g, b) end
    local cb = _activeColorPickerCallbacks
    if cb then
        cb.setKeyVal({ r, g, b })
        if cb.tex then cb.tex:SetColorTexture(r, g, b, 1) end
        -- No notify during live hex typing; finishedFunc/cancelFunc will notify.
    end
end

local function EnsureHexBoxHooked()
    if _hexBoxHooked then return end
    local content = ColorPickerFrame and ColorPickerFrame.Content
    local hexBox = content and content.HexBox
    if not hexBox or not hexBox.SetScript then return end
    hexBox:SetScript("OnTextChanged", function()
        SyncHexBoxToPicker()
    end)
    -- Hide the "hex" label inside the box (it obstructs the UI)
    local function hideHexLabel()
        for i = 1, select("#", hexBox:GetRegions()) do
            local r = select(i, hexBox:GetRegions())
            if r and r.GetText and r.Hide then
                local t = r:GetText()
                if t and t:lower():find("hex") then
                    r:Hide()
                    return
                end
            end
        end
        local hash = hexBox.Hash
        if hash and hash.GetText and hash.Hide then
            local ok, t = pcall(function() return hash:GetText() end)
            if ok and t and t:lower():find("hex") then hash:Hide() end
        end
    end
    hideHexLabel()
    _hexBoxHooked = true
end

-- Color swatch row: label + clickable swatch (for colorMatrix/colorGroup in options panel).
-- defaultTbl: {r,g,b} or nil (nil => {0.5,0.5,0.5}). getTbl() returns current color or nil. setKeyVal({r,g,b}), notify() on change.
function OptionsWidgets_CreateColorSwatchRow(parent, anchor, labelText, defaultTbl, getTbl, setKeyVal, notify)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(280, 24)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    local lab = row:CreateFontString(nil, "OVERLAY")
    lab:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    lab:SetJustifyH("LEFT")
    SetTextColor(lab, Def.TextColorLabel)
    lab:SetText(labelText or "")
    lab:SetPoint("LEFT", row, "LEFT", 0, 0)
    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(22, 18)
    swatch:SetPoint("LEFT", lab, "RIGHT", 10, 0)
    local tex = swatch:CreateTexture(nil, "BACKGROUND")
    local swInset = 1
    tex:SetPoint("TOPLEFT", swatch, "TOPLEFT", swInset, -swInset)
    tex:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -swInset, swInset)
    addon.CreateBorder(swatch, Def.SectionCardBorder)
    swatch.tex = tex
    local def = defaultTbl and #defaultTbl >= 3 and defaultTbl or { 0.5, 0.5, 0.5 }
    function swatch:Refresh()
        local r, g, b = def[1], def[2], def[3]
        if getTbl then
            local result = getTbl()
            -- Handle both table return {r,g,b} and multiple returns (r,g,b)
            if type(result) == "table" and result[1] then
                r, g, b = result[1], result[2], result[3]
            elseif type(result) == "number" then
                -- Multiple return values - result is r, need to get g,b
                local rVal, gVal, bVal = getTbl()
                if type(rVal) == "number" and type(gVal) == "number" and type(bVal) == "number" then
                    r, g, b = rVal, gVal, bVal
                end
            end
        end
        tex:SetColorTexture(r, g, b, 1)
    end
    swatch:SetScript("OnClick", function()
        if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then return end
        local r, g, b = def[1], def[2], def[3]
        if getTbl then
            local result = getTbl()
            if type(result) == "table" and result[1] then
                r, g, b = result[1], result[2], result[3]
            elseif type(result) == "number" then
                local rVal, gVal, bVal = getTbl()
                if type(rVal) == "number" and type(gVal) == "number" and type(bVal) == "number" then
                    r, g, b = rVal, gVal, bVal
                end
            end
        end
        addon._colorPickerLive = true
        _activeColorPickerCallbacks = { setKeyVal = setKeyVal, notify = notify, tex = tex }
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = false,
            swatchFunc = function()
                local nr, ng, nb = GetColorPickerEffectiveRGB()
                setKeyVal({ nr, ng, nb })
                tex:SetColorTexture(nr, ng, nb, 1)
            end,
            cancelFunc = function()
                addon._colorPickerLive = nil
                _activeColorPickerCallbacks = nil
                local p = ColorPickerFrame.previousValues
                if p and type(p.r) == "number" and type(p.g) == "number" and type(p.b) == "number" then
                    setKeyVal({ p.r, p.g, p.b })
                elseif getTbl then
                    local res = getTbl()
                    if type(res) == "table" and res[1] then
                        setKeyVal({ res[1], res[2], res[3] })
                    end
                end
                swatch:Refresh()
                if notify then notify() end
            end,
            finishedFunc = function()
                addon._colorPickerLive = nil
                _activeColorPickerCallbacks = nil
                local nr, ng, nb = GetColorPickerEffectiveRGB()
                setKeyVal({ nr, ng, nb })
                tex:SetColorTexture(nr, ng, nb, 1)
                if notify then notify() end
            end,
        })
        EnsureHexBoxHooked()
    end)
    row.Refresh = function() swatch:Refresh() end
    row:Refresh()
    return row
end

-- Search input: custom-styled, pill-shaped, search icon, integrated clear, focus state. onTextChanged(text) called on input.
local SEARCH_ICON_LEFT = 28
local SEARCH_CLEAR_SIZE = 20
local SEARCH_INSET = 6
function OptionsWidgets_CreateSearchInput(parent, onTextChanged, placeholder)
    local row = CreateFrame("Frame", nil, parent)
    row:SetAllPoints(parent)
    local edit = CreateFrame("EditBox", nil, row)
    edit:SetHeight(28)
    edit:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    edit:SetPoint("TOPRIGHT", row, "TOPRIGHT", -SEARCH_CLEAR_SIZE - 4, 0)
    edit:SetAutoFocus(false)
    edit:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    edit:SetTextInsets(SEARCH_ICON_LEFT, SEARCH_CLEAR_SIZE + 4, 0, 0)
    local tc = Def.TextColorLabel
    edit:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)

    local editBg = edit:CreateTexture(nil, "BACKGROUND")
    editBg:SetPoint("TOPLEFT", edit, "TOPLEFT", SEARCH_INSET, -SEARCH_INSET)
    editBg:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", -SEARCH_INSET, SEARCH_INSET)
    editBg:SetColorTexture(Def.InputBg[1], Def.InputBg[2], Def.InputBg[3], Def.InputBg[4])

    local borderTop = edit:CreateTexture(nil, "BORDER")
    borderTop:SetHeight(1)
    borderTop:SetPoint("TOPLEFT", edit, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", edit, "TOPRIGHT", 0, 0)
    local borderBottom = edit:CreateTexture(nil, "BORDER")
    borderBottom:SetHeight(1)
    borderBottom:SetPoint("BOTTOMLEFT", edit, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", 0, 0)
    local borderLeft = edit:CreateTexture(nil, "BORDER")
    borderLeft:SetWidth(1)
    borderLeft:SetPoint("TOPLEFT", edit, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", edit, "BOTTOMLEFT", 0, 0)
    local borderRight = edit:CreateTexture(nil, "BORDER")
    borderRight:SetWidth(1)
    borderRight:SetPoint("TOPRIGHT", edit, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", 0, 0)
    local function setBorderColor(r, g, b, a)
        local c = { r or Def.InputBorder[1], g or Def.InputBorder[2], b or Def.InputBorder[3], a or Def.InputBorder[4] }
        borderTop:SetColorTexture(c[1], c[2], c[3], c[4])
        borderBottom:SetColorTexture(c[1], c[2], c[3], c[4])
        borderLeft:SetColorTexture(c[1], c[2], c[3], c[4])
        borderRight:SetColorTexture(c[1], c[2], c[3], c[4])
    end
    setBorderColor(Def.InputBorder[1], Def.InputBorder[2], Def.InputBorder[3], Def.InputBorder[4])

    local searchIcon = edit:CreateTexture(nil, "OVERLAY")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("LEFT", edit, "LEFT", 10, 0)
    searchIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    searchIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    if placeholder then
        local ph = edit:CreateFontString(nil, "OVERLAY")
        ph:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        SetTextColor(ph, Def.TextColorSection)
        ph:SetText(placeholder)
        ph:SetPoint("LEFT", edit, "LEFT", SEARCH_ICON_LEFT, 0)
        ph:SetJustifyH("LEFT")
        edit.placeholder = ph
        edit:SetScript("OnEditFocusGained", function()
            if ph then ph:Hide() end
            setBorderColor(Def.AccentColor[1], Def.AccentColor[2], Def.AccentColor[3], 0.35)
            if row.clearBtn then row.clearBtn:SetShown(edit:GetText() ~= "") end
        end)
        edit:SetScript("OnEditFocusLost", function()
            if ph and edit:GetText() == "" then ph:Show() end
            setBorderColor(Def.InputBorder[1], Def.InputBorder[2], Def.InputBorder[3], Def.InputBorder[4])
            if row.clearBtn then row.clearBtn:SetShown(edit:GetText() ~= "") end
        end)
    else
        edit:SetScript("OnEditFocusGained", function()
            setBorderColor(Def.AccentColor[1], Def.AccentColor[2], Def.AccentColor[3], 0.35)
            if row.clearBtn then row.clearBtn:SetShown(edit:GetText() ~= "") end
        end)
        edit:SetScript("OnEditFocusLost", function()
            setBorderColor(Def.InputBorder[1], Def.InputBorder[2], Def.InputBorder[3], Def.InputBorder[4])
            if row.clearBtn then row.clearBtn:SetShown(edit:GetText() ~= "") end
        end)
    end
    edit:SetScript("OnEscapePressed", function()
        edit:SetText("")
        if edit.placeholder then edit.placeholder:Show() end
        edit:ClearFocus()
        if onTextChanged then onTextChanged("") end
        if row.clearBtn then row.clearBtn:Hide() end
    end)
    if not placeholder then
        edit:SetScript("OnTextChanged", function(self, userInput)
            if userInput and onTextChanged then onTextChanged(self:GetText()) end
            if row.clearBtn then row.clearBtn:SetShown(self:GetText() ~= "") end
        end)
    else
        edit:SetScript("OnTextChanged", function(self, userInput)
            if edit.placeholder then edit.placeholder:SetShown(self:GetText() == "") end
            if userInput and onTextChanged then onTextChanged(self:GetText()) end
            if row.clearBtn then row.clearBtn:SetShown(self:GetText() ~= "") end
        end)
    end

    local clearBtn = CreateFrame("Button", nil, row)
    clearBtn:SetSize(SEARCH_CLEAR_SIZE, SEARCH_CLEAR_SIZE)
    clearBtn:SetPoint("RIGHT", edit, "RIGHT", -6, 0)
    clearBtn:EnableMouse(true)
    clearBtn:Hide()
    local clearText = clearBtn:CreateFontString(nil, "OVERLAY")
    clearText:SetFont(Def.FontPath, Def.LabelSize - 1, "OUTLINE")
    SetTextColor(clearText, Def.TextColorSection)
    clearText:SetText("X")
    clearText:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
    clearBtn:SetScript("OnClick", function()
        edit:SetText("")
        if edit.placeholder then edit.placeholder:Show() end
        if onTextChanged then onTextChanged("") end
        clearBtn:Hide()
    end)
    clearBtn:SetScript("OnEnter", function() SetTextColor(clearText, Def.TextColorHighlight) end)
    clearBtn:SetScript("OnLeave", function() SetTextColor(clearText, Def.TextColorSection) end)

    row.edit = edit
    row.clearBtn = clearBtn
    row.searchText = ""
    return row
end

local CARD_HEADER_H = 24

-- Section card: soft cinematic background, subtle border, inset for softer edges.
-- When sectionKey and getCollapsedFn/setCollapsedFn are provided, the card is collapsible.
function OptionsWidgets_CreateSectionCard(parent, anchor, sectionKey, getCollapsedFn, setCollapsedFn)
    local card = CreateFrame("Frame", nil, parent)
    card:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -Def.SectionGap)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    local inset = 1
    local cardBg = card:CreateTexture(nil, "BACKGROUND")
    cardBg:SetPoint("TOPLEFT", card, "TOPLEFT", inset, -inset)
    cardBg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -inset, inset)
    cardBg:SetColorTexture(Def.SectionCardBg[1], Def.SectionCardBg[2], Def.SectionCardBg[3], Def.SectionCardBg[4])
    addon.CreateBorder(card, Def.SectionCardBorder)

    if sectionKey and getCollapsedFn and setCollapsedFn then
        local contentContainer = CreateFrame("Frame", nil, card)
        contentContainer:SetPoint("TOPLEFT", card, "TOPLEFT", Def.CardPadding, -Def.CardPadding - CARD_HEADER_H)
        contentContainer:SetPoint("RIGHT", card, "RIGHT", -Def.CardPadding, 0)
        contentContainer:SetHeight(1)
        contentContainer:SetFrameLevel(card:GetFrameLevel() + 1)
        card.contentContainer = contentContainer
        card.contentAnchor = contentContainer
        card.sectionKey = sectionKey
        card.getCardCollapsed = getCollapsedFn
        card.setCardCollapsed = setCollapsedFn
        card.headerHeight = CARD_HEADER_H + Def.CardPadding
    end

    return card
end

-- Section header: uppercase label, left-aligned. When sectionKey and getCollapsedFn/setCollapsedFn are
-- provided, returns a clickable Button with chevron for collapse; otherwise returns a FontString.
function OptionsWidgets_CreateSectionHeader(parent, text, sectionKey, getCollapsedFn, setCollapsedFn)
    local sk = sectionKey or parent.sectionKey
    local getFn = getCollapsedFn or parent.getCardCollapsed
    local setFn = setCollapsedFn or parent.setCardCollapsed

    if sk and getFn and setFn then
        local hdr = CreateFrame("Button", nil, parent)
        hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", Def.CardPadding, -Def.CardPadding)
        hdr:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -Def.CardPadding, 0)
        hdr:SetHeight(CARD_HEADER_H)
        hdr:EnableMouse(true)
        hdr:SetFrameLevel(parent:GetFrameLevel() + 2)

        local hdrBg = hdr:CreateTexture(nil, "BACKGROUND")
        hdrBg:SetAllPoints(hdr)
        hdrBg:SetColorTexture(0.10, 0.10, 0.12, 0.5)

        local chevron = hdr:CreateFontString(nil, "OVERLAY")
        chevron:SetFont(Def.FontPath, Def.LabelSize or 13, "OUTLINE")
        SetTextColor(chevron, Def.TextColorSection)
        chevron:SetText(getFn(sk) and "+" or "-")
        chevron:SetPoint("LEFT", hdr, "LEFT", 6, 0)
        hdr.chevron = chevron
        parent.header = hdr

        local hdrLabel = hdr:CreateFontString(nil, "OVERLAY")
        hdrLabel:SetFont(Def.FontPath, Def.SectionSize + 1, "OUTLINE")
        SetTextColor(hdrLabel, Def.TextColorSection)
        hdrLabel:SetText(text and text:upper() or "")
        hdrLabel:SetPoint("LEFT", chevron, "RIGHT", 6, 0)
        hdrLabel:SetJustifyH("LEFT")

        local hdrHi = hdr:CreateTexture(nil, "HIGHLIGHT")
        hdrHi:SetAllPoints(hdr)
        hdrHi:SetColorTexture(1, 1, 1, 0.03)

        hdr:SetScript("OnClick", function()
            local collapsed = not getFn(sk)
            setFn(sk, collapsed)
            chevron:SetText(collapsed and "+" or "-")
            local cc = parent.contentContainer
            if cc then
                cc:SetShown(not collapsed)
            end
            local fullH = parent.contentHeight and (parent.contentHeight + Def.CardPadding) or (parent.headerHeight or 0)
            parent:SetHeight(collapsed and (parent.headerHeight or CARD_HEADER_H + Def.CardPadding) or fullH)
        end)

        return hdr
    end

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(Def.FontPath, Def.SectionSize + 1, "OUTLINE")
    label:SetJustifyH("LEFT")
    SetTextColor(label, Def.TextColorSection)
    label:SetText(text and text:upper() or "")
    return label
end

-- Reorder list: drag rows with ghost and insertion line. scrollFrameRef and panelRef for auto-scroll.
local REORDER_ROW_GAP = 4
local REORDER_ROW_HEIGHT = 24
local REORDER_AUTOSCROLL_MARGIN = 40
local REORDER_AUTOSCROLL_STEP = 10

--- Create a drag-to-reorder list widget (e.g. for Focus category order). Rows show labelMap[key]; opt.get/set provide order array.
-- @param parent table Parent frame
-- @param anchor table Anchor for TOPLEFT
-- @param opt table Option descriptor: get(), set(order), labelMap, name, tooltip
-- @param scrollFrameRef table Scroll frame for auto-scroll during drag
-- @param panelRef table Options panel for scroll region
-- @param notifyMainAddonFn function Called when order changes (e.g. to refresh tracker)
-- @return table Container frame
function OptionsWidgets_CreateReorderList(parent, anchor, opt, scrollFrameRef, panelRef, notifyMainAddonFn)
    local keys = opt.get and opt.get() or {}
    if type(keys) == "function" then keys = keys() end
    if type(keys) ~= "table" then keys = {} end
    local defaultOrder = addon.GROUP_ORDER
    if #keys < #defaultOrder then
        local seen = {}
        for _, k in ipairs(keys) do seen[k] = true end
        for _, k in ipairs(defaultOrder) do
            if not seen[k] then keys[#keys + 1] = k end
        end
    end
    local labelMap = opt.labelMap or {}
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -Def.SectionGap)
    container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    local sectionLabel = OptionsWidgets_CreateSectionHeader(container, opt.name or L["Order"])
    sectionLabel:SetPoint("TOPLEFT", container, "TOPLEFT", Def.CardPadding, -Def.CardPadding)

    local rows = {}
    local keyToRow = {}
    local state = {
        active = false,
        sourceIndex = nil,
        targetIndex = nil,
        ghostFrame = nil,
        insertionLine = nil,
        sourceRow = nil,
        rows = rows,
        keyToRow = keyToRow,
        get = opt.get,
        set = opt.set,
    }

    local function ensureGhost()
        if state.ghostFrame then return state.ghostFrame end
        local ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:SetSize(240, REORDER_ROW_HEIGHT)
        ghost:SetAlpha(0.85)
        local bg = ghost:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(ghost)
        bg:SetColorTexture(Def.SectionCardBg[1], Def.SectionCardBg[2], Def.SectionCardBg[3], 0.95)
        state.ghostFrame = ghost
        state.ghostLabel = ghost:CreateFontString(nil, "OVERLAY")
        state.ghostLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        SetTextColor(state.ghostLabel, Def.TextColorLabel)
        state.ghostLabel:SetPoint("LEFT", ghost, "LEFT", 28, 0)
        return ghost
    end

    local function ensureInsertionLine()
        if state.insertionLine then return state.insertionLine end
        local line = container:CreateTexture(nil, "OVERLAY")
        line:SetHeight(3)
        line:SetColorTexture(Def.AccentColor[1], Def.AccentColor[2], Def.AccentColor[3], 1)
        state.insertionLine = line
        return line
    end

    --- Compute insertion index from cursor Y using row screen bounds (avoids IsMouseOver quirks in scroll frames).
    local function getInsertionIndexFromCursor()
        local activeRows = state.rows
        if not activeRows or #activeRows == 0 then return 1 end
        local _, cursorY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        cursorY = cursorY / scale
        for i = 1, #activeRows do
            local row = activeRows[i]
            local top = row:GetTop()
            local bottom = row:GetBottom()

            if top and bottom then
                local mid = (top + bottom) / 2
                if cursorY > mid then
                    return i
                end
            end
        end
        return #activeRows + 1
    end


    local presetOrder = { "Collection Focused", "Quest Focused", "Campaign Focused", "World / Rare Focused" }
    local presets = (opt.presets and addon.GROUP_ORDER_PRESETS) and opt.presets or nil
    local presetRow = nil
    if presets then
        presetRow = CreateFrame("Frame", nil, container)
        presetRow:SetHeight(56)  -- 2 rows of buttons + gap
        presetRow:SetPoint("TOPLEFT", sectionLabel, "BOTTOMLEFT", 0, -8)
        presetRow:SetPoint("TOPRIGHT", container, "TOPRIGHT", -Def.CardPadding, 0)
        local btnW, btnH, gapH, gapV = 130, 22, 8, 6
        local prevBtn = nil
        for idx, name in ipairs(presetOrder) do
            local presetOrderArr = presets[name]
            if presetOrderArr then
                local btn = CreateFrame("Button", nil, presetRow)
                btn:SetSize(btnW, btnH)
                if idx == 1 then
                    btn:SetPoint("TOPLEFT", presetRow, "TOPLEFT", 0, 0)
                elseif idx == 2 then
                    btn:SetPoint("TOPLEFT", prevBtn, "TOPRIGHT", gapH, 0)
                elseif idx == 3 then
                    btn:SetPoint("TOPLEFT", presetRow, "TOPLEFT", 0, -(btnH + gapV))
                else
                    btn:SetPoint("TOPLEFT", prevBtn, "TOPRIGHT", gapH, 0)
                end
                prevBtn = btn
                local lab = btn:CreateFontString(nil, "OVERLAY")
                lab:SetFont(Def.FontPath, Def.LabelSize - 1, "OUTLINE")
                SetTextColor(lab, Def.TextColorLabel)
                lab:SetText(name:gsub(" / Rare", "/Rare"))
                lab:SetPoint("CENTER", btn, "CENTER", 0, 0)
                lab:SetWordWrap(false)
                btn:SetScript("OnClick", function()
                    if opt.set then opt.set(presetOrderArr) end
                    if container.Refresh then container:Refresh() end
                    if notifyMainAddonFn then notifyMainAddonFn() end
                end)
                btn:SetScript("OnEnter", function() SetTextColor(lab, Def.TextColorHighlight) end)
                btn:SetScript("OnLeave", function() SetTextColor(lab, Def.TextColorLabel) end)
            end
        end
    end

    local rowListAnchor = presetRow or sectionLabel
    local function repositionRows(orderedKeys)
        local prev = rowListAnchor
        for i, key in ipairs(orderedKeys) do
            local row = keyToRow[key]
            if row then
                row.index = i
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -REORDER_ROW_GAP)
                prev = row
            end
        end
        local newRows = {}
        for i, key in ipairs(orderedKeys) do
            if keyToRow[key] then newRows[i] = keyToRow[key] end
        end
        state.rows = newRows
        local resetBtn = state.resetBtn
        if resetBtn and orderedKeys[#orderedKeys] then
            local lastRow = keyToRow[orderedKeys[#orderedKeys]]
            if lastRow then
                resetBtn:ClearAllPoints()
                resetBtn:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -6)
            end
        end
    end

    local function applyReorderAndCleanup()
        if not state.active or not state.rows or #state.rows == 0 then return end

        panelRef:SetScript("OnUpdate", nil)
        state.active = false

        local fromIdx = state.sourceIndex
        local toIdx = state.targetIndex or fromIdx

        if state.ghostFrame then state.ghostFrame:Hide() end
        if state.insertionLine then state.insertionLine:Hide() end
        if state.sourceRow then state.sourceRow:SetAlpha(1) end
        if toIdx == fromIdx then return end

        local orderedKeys = {}
        for i, row in ipairs(state.rows) do
            orderedKeys[i] = row.key
        end

        local key = orderedKeys[fromIdx]
        table.remove(orderedKeys, fromIdx)
        local insertAt = (fromIdx < toIdx) and (toIdx - 1) or toIdx
        table.insert(orderedKeys, insertAt, key)
        state.set(orderedKeys)
        repositionRows(orderedKeys)
        if notifyMainAddonFn then
                notifyMainAddonFn()
        end
    end


    local function onReorderUpdate()
    if not state.active or not IsMouseButtonDown("LeftButton") then
        applyReorderAndCleanup() return end

        local ghost = ensureGhost()
        local line = ensureInsertionLine()

        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        x, y = x / scale, y / scale

        ghost:ClearAllPoints()
        ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        ghost:Show()

        local insertIdx = getInsertionIndexFromCursor()
        state.targetIndex = insertIdx

        local activeRows = state.rows
        if not activeRows or #activeRows == 0 then return end

            if insertIdx <= #activeRows then
                local ref = activeRows[insertIdx]
                line:ClearAllPoints()
                line:SetPoint("LEFT", ref, "LEFT", 0, 0)
                line:SetPoint("RIGHT", ref, "RIGHT", 0, 0)
                line:SetPoint("BOTTOM", ref, "TOP", 0, REORDER_ROW_GAP / 2)
                line:Show()
            else
                local last = activeRows[#activeRows]
                line:ClearAllPoints()
                line:SetPoint("LEFT", last, "LEFT", 0, 0)
                line:SetPoint("RIGHT", last, "RIGHT", 0, 0)
                line:SetPoint("TOP", last, "BOTTOM", 0, -REORDER_ROW_GAP / 2)
                line:Show()
            end

            -- Auto scroll
            if scrollFrameRef then
                local sy = y
                local sfTop = scrollFrameRef:GetTop()
                local sfBottom = scrollFrameRef:GetBottom()
                local cur = scrollFrameRef:GetVerticalScroll()
                local vh = scrollFrameRef:GetHeight()
                local scrollChild = scrollFrameRef:GetScrollChild()
                local maxScroll = math.max(((scrollChild and scrollChild:GetHeight() or 0) - vh), 0)

                if sfTop and sy > sfTop - REORDER_AUTOSCROLL_MARGIN and cur > 0 then
                    scrollFrameRef:SetVerticalScroll(math.max(cur - REORDER_AUTOSCROLL_STEP, 0))
                elseif sfBottom and sy < sfBottom + REORDER_AUTOSCROLL_MARGIN and maxScroll > 0 then
                    scrollFrameRef:SetVerticalScroll(math.min(cur + REORDER_AUTOSCROLL_STEP, maxScroll))
                end
            end
    end

    local prevAnchor = rowListAnchor
    for i, key in ipairs(keys) do
        local row = CreateFrame("Button", nil, container)
        row:SetSize(240, REORDER_ROW_HEIGHT)
        row:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -REORDER_ROW_GAP)
        prevAnchor = row
        row.key = key
        row.index = i
        keyToRow[key] = row
        local lab = row:CreateFontString(nil, "OVERLAY")
        lab:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        lab:SetJustifyH("LEFT")
        SetTextColor(lab, Def.TextColorLabel)
        lab:SetText(addon.L[(labelMap[key]) or key:gsub("^%l", string.upper)])
        lab:SetPoint("LEFT", row, "LEFT", 24, 0)
        row.label = lab
        local grip = row:CreateFontString(nil, "OVERLAY")
        grip:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
        SetTextColor(grip, Def.TextColorSection)
        grip:SetText("::")
        grip:SetPoint("LEFT", row, "LEFT", 4, 0)
        row:SetScript("OnMouseDown", function(_, btn)
            if btn ~= "LeftButton" then return end
            state.active = true
            state.sourceIndex = row.index
            state.targetIndex = row.index
            state.sourceRow = row
            row:SetAlpha(0.5)
            ensureGhost():Show()
            state.ghostLabel:SetText(lab:GetText())
            panelRef:SetScript("OnUpdate", onReorderUpdate)
        end)
        rows[i] = row
    end
    state.rows = rows

    local resetBtn = CreateFrame("Button", nil, container)
    state.resetBtn = resetBtn
    resetBtn:SetSize(100, 22)
    resetBtn:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -6)
    local resetLabel = resetBtn:CreateFontString(nil, "OVERLAY")
    resetLabel:SetFont(Def.FontPath, Def.LabelSize, "OUTLINE")
    SetTextColor(resetLabel, Def.TextColorLabel)
    resetLabel:SetText(L["Reset to default"])
    resetLabel:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
    resetBtn:SetScript("OnClick", function()
        if opt.set then opt.set(nil) end
        if addon.SetDB then addon.SetDB("groupOrder", nil) end
        local newKeys = opt.get and opt.get() or {}
        if type(newKeys) == "function" then newKeys = newKeys() end
        if type(newKeys) == "table" then repositionRows(newKeys) end
        if notifyMainAddonFn then notifyMainAddonFn() end
    end)
    resetBtn:SetScript("OnEnter", function() SetTextColor(resetLabel, Def.TextColorHighlight) end)
    resetBtn:SetScript("OnLeave", function() SetTextColor(resetLabel, Def.TextColorLabel) end)

    local presetH = presetRow and (8 + 56) or 0
    local totalH = Def.CardPadding + 14 + presetH + (#keys * (REORDER_ROW_HEIGHT + REORDER_ROW_GAP)) + 6 + 22 + Def.CardPadding
    container:SetHeight(totalH)
    container.searchText = (opt.name or "order") .. " " .. (opt.desc or opt.tooltip or "")
    function container:Refresh()
        local newKeys = opt.get and opt.get() or {}
        if type(newKeys) == "function" then newKeys = newKeys() end
        if type(newKeys) == "table" then repositionRows(newKeys) end
    end
    return container
end

-- Export Def for panel (font updates)
addon.OptionsWidgetsDef = Def
