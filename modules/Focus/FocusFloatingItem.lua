--[[
    Horizon Suite - Focus - Floating Quest Item
    Extra Action style button for quest item; keybindable. Source: super-tracked/first or current-zone first.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- FLOATING QUEST ITEM BUTTON
-- ============================================================================

local floatingQuestItemBtn = CreateFrame("Button", "HSFloatingQuestItem", UIParent, "SecureActionButtonTemplate")
floatingQuestItemBtn:SetSize(addon.GetDB("floatingQuestItemSize", 36) or 36, addon.GetDB("floatingQuestItemSize", 36) or 36)
floatingQuestItemBtn:SetPoint("RIGHT", addon.HS, "LEFT", -12, 0)
floatingQuestItemBtn:SetAttribute("type", "item")
floatingQuestItemBtn:RegisterForClicks("AnyDown")
floatingQuestItemBtn:SetMovable(true)
floatingQuestItemBtn:RegisterForDrag("LeftButton")
floatingQuestItemBtn:SetScript("OnDragStart", function(self)
    if addon.GetDB("lockFloatingQuestItemPosition", false) then return end
    if InCombatLockdown() then return end
    self:StartMoving()
end)
floatingQuestItemBtn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false)
    if InCombatLockdown() then return end
    addon.EnsureDB()
    local l, b = self:GetLeft(), self:GetBottom()
    if l and b then
        addon.SetDB("floatingQuestItemPoint", "BOTTOMLEFT")
        addon.SetDB("floatingQuestItemRelPoint", "BOTTOMLEFT")
        addon.SetDB("floatingQuestItemX", l)
        addon.SetDB("floatingQuestItemY", b)
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b)
    end
end)
floatingQuestItemBtn:Hide()
C_Timer.After(0, function()
    if floatingQuestItemBtn and not floatingQuestItemBtn:IsForbidden() then
        addon.ApplyBlizzardFloatingQuestItemStyle(floatingQuestItemBtn)
    end
end)
local INSET = 0
local floatingQuestItemIcon = floatingQuestItemBtn:CreateTexture(nil, "ARTWORK")
floatingQuestItemIcon:SetPoint("TOPLEFT", floatingQuestItemBtn, "TOPLEFT", INSET, -INSET)
floatingQuestItemIcon:SetPoint("BOTTOMRIGHT", floatingQuestItemBtn, "BOTTOMRIGHT", -INSET, INSET)
floatingQuestItemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
floatingQuestItemBtn.icon = floatingQuestItemIcon
floatingQuestItemBtn.cooldown = CreateFrame("Cooldown", nil, floatingQuestItemBtn, "CooldownFrameTemplate")
floatingQuestItemBtn.cooldown:SetPoint("TOPLEFT", floatingQuestItemBtn, "TOPLEFT", INSET, -INSET)
floatingQuestItemBtn.cooldown:SetPoint("BOTTOMRIGHT", floatingQuestItemBtn, "BOTTOMRIGHT", -INSET, INSET)
floatingQuestItemBtn:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
    if self._itemLink and GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        pcall(GameTooltip.SetHyperlink, GameTooltip, self._itemLink)
        GameTooltip:Show()
    end
end)
floatingQuestItemBtn:SetScript("OnLeave", function(self)
    self:SetAlpha(0.9)
    if GameTooltip and GameTooltip:GetOwner() == self then GameTooltip:Hide() end
end)
floatingQuestItemBtn:SetAlpha(0.9)

local function UpdateFloatingQuestItem(questsFlat)
    if addon.ShouldHideInCombat() or not addon.GetDB("showFloatingQuestItem", false) then
        floatingQuestItemBtn:Hide()
        return
    end
    local superTracked = (C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID) and C_SuperTrack.GetSuperTrackedQuestID() or 0
    local mode = addon.GetDB("floatingQuestItemMode", "superTracked") or "superTracked"
    local playerZone = (addon.GetPlayerCurrentZoneName and addon.GetPlayerCurrentZoneName()) or nil

    local function inCurrentZone(q)
        return q.isNearby or (q.zoneName and playerZone and q.zoneName:lower() == playerZone:lower())
    end

    local chosenLink, chosenTex
    if mode == "currentZone" then
        -- Current zone mode: super-tracked in zone first, else first in-zone with item, else first with item
        local superTrackedInZoneLink, superTrackedInZoneTex
        local firstInZoneLink, firstInZoneTex
        local firstAnyLink, firstAnyTex
        for _, q in ipairs(questsFlat or {}) do
            if q.questID and q.itemLink and q.itemTexture then
                local inZone = inCurrentZone(q)
                if q.questID == superTracked and inZone then
                    superTrackedInZoneLink, superTrackedInZoneTex = q.itemLink, q.itemTexture
                end
                if not firstInZoneLink and inZone then
                    firstInZoneLink, firstInZoneTex = q.itemLink, q.itemTexture
                end
                if not firstAnyLink then
                    firstAnyLink, firstAnyTex = q.itemLink, q.itemTexture
                end
            end
        end
        chosenLink = superTrackedInZoneLink or firstInZoneLink or firstAnyLink
        chosenTex = superTrackedInZoneTex or firstInZoneTex or firstAnyTex
    else
        -- Super-tracked mode: super-tracked first, else first with item
        for _, q in ipairs(questsFlat or {}) do
            if q.questID and q.itemLink and q.itemTexture then
                if q.questID == superTracked then
                    chosenLink, chosenTex = q.itemLink, q.itemTexture
                    break
                end
                if not chosenLink then chosenLink, chosenTex = q.itemLink, q.itemTexture end
            end
        end
    end
    if chosenLink and chosenTex then
        floatingQuestItemBtn.icon:SetTexture(chosenTex)
        if not InCombatLockdown() then
            floatingQuestItemBtn:SetAttribute("item", chosenLink)
        end
        floatingQuestItemBtn._itemLink = chosenLink
        local sz = tonumber(addon.GetDB("floatingQuestItemSize", 36)) or 36
        floatingQuestItemBtn:SetSize(sz, sz)
        local savedPoint = addon.GetDB("floatingQuestItemPoint", nil)
        floatingQuestItemBtn:ClearAllPoints()
        if savedPoint then
            local relPoint = addon.GetDB("floatingQuestItemRelPoint", "BOTTOMLEFT") or "BOTTOMLEFT"
            local sx = tonumber(addon.GetDB("floatingQuestItemX", 0)) or 0
            local sy = tonumber(addon.GetDB("floatingQuestItemY", 0)) or 0
            floatingQuestItemBtn:SetPoint(savedPoint, UIParent, relPoint, sx, sy)
        else
            local anchor = addon.GetDB("floatingQuestItemAnchor", "LEFT") or "LEFT"
            local ox = tonumber(addon.GetDB("floatingQuestItemOffsetX", -12)) or -12
            local oy = tonumber(addon.GetDB("floatingQuestItemOffsetY", 0)) or 0
            if anchor == "LEFT" then
                floatingQuestItemBtn:SetPoint("RIGHT", addon.HS, "LEFT", ox, oy)
            elseif anchor == "RIGHT" then
                floatingQuestItemBtn:SetPoint("LEFT", addon.HS, "RIGHT", ox, oy)
            elseif anchor == "TOP" then
                floatingQuestItemBtn:SetPoint("BOTTOM", addon.HS, "TOP", ox, oy)
            else
                floatingQuestItemBtn:SetPoint("TOP", addon.HS, "BOTTOM", ox, oy)
            end
        end
        if addon.focus.combat.fadeState == "in" then floatingQuestItemBtn:SetAlpha(0) end
        floatingQuestItemBtn:Show()
        addon.ApplyItemCooldown(floatingQuestItemBtn.cooldown, chosenLink)
    else
        floatingQuestItemBtn:Hide()
    end
end

addon.UpdateFloatingQuestItem = UpdateFloatingQuestItem
