--[[
    Horizon Suite - Presence - Blizzard Suppression
    Hide default zone text, level-up, boss emotes, achievements, event toasts.
    Restore all when Presence is disabled.
    Frames: ZoneTextFrame, SubZoneTextFrame, RaidBossEmoteFrame, LevelUpDisplay,
    BossBanner, ObjectiveTrackerBonusBannerFrame, ObjectiveTrackerTopBannerFrame,
    EventToastManagerFrame, WorldQuestCompleteBannerFrame.
]]

local addon = _G.HorizonSuite
if not addon or not addon.Presence then return end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local suppressedFrames = {}
local originalParents = {}
local originalPoints = {}
local originalAlphas = {}
local ZONE_TEXT_EVENTS = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" }

-- ============================================================================
-- Private helpers
-- ============================================================================

-- pcall: frame methods can throw on protected or invalid frames.
local function KillBlizzardFrame(frame)
    if not frame then return end
    local ok1, err1 = pcall(function()
        frame:UnregisterAllEvents()
        suppressedFrames[frame] = true
        originalParents[frame] = frame:GetParent()
        local p, r, rp, x, y = frame:GetPoint(1)
        originalPoints[frame] = p and { p, r, rp, x, y } or nil
        originalAlphas[frame] = frame:GetAlpha()
        frame:SetParent(hiddenParent)
        frame:Hide()
        frame:SetAlpha(0)
    end)
    if not ok1 and addon.HSPrint then addon.HSPrint("Presence KillBlizzardFrame hide failed: " .. tostring(err1)) end
    local ok2, err2 = pcall(function()
        frame:SetScript("OnShow", function(self) self:Hide() end)
    end)
    if not ok2 and addon.HSPrint then addon.HSPrint("Presence KillBlizzardFrame OnShow hook failed: " .. tostring(err2)) end
end

-- pcall: frame methods can throw on protected or invalid frames.
local function RestoreBlizzardFrame(frame)
    if not frame or not suppressedFrames[frame] then return end
    local ok, err = pcall(function()
        frame:SetScript("OnShow", nil)
        frame:SetParent(originalParents[frame] or UIParent)
        frame:SetAlpha(originalAlphas[frame] or 1)
        local pt = originalPoints[frame]
        frame:ClearAllPoints()
        if pt and pt[1] then
            frame:SetPoint(pt[1], pt[2] or UIParent, pt[3] or "CENTER", pt[4] or 0, pt[5] or 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        local isZoneTextFrame = (frame == ZoneTextFrame) or (frame == SubZoneTextFrame)
        if isZoneTextFrame then
            if frame == ZoneTextFrame then
                for _, ev in ipairs(ZONE_TEXT_EVENTS) do frame:RegisterEvent(ev) end
            end
        end
        frame:Hide()
    end)
    if not ok and addon.HSPrint then addon.HSPrint("Presence RestoreBlizzardFrame failed: " .. tostring(err)) end
    suppressedFrames[frame] = nil
    originalParents[frame] = nil
    originalPoints[frame] = nil
    originalAlphas[frame] = nil
end

-- ============================================================================
-- Public functions
-- ============================================================================

--- Suppress Blizzard zone text, level-up, boss emotes, achievement toasts, and related frames when Presence is enabled.
--- Idempotent; safe to call multiple times.
--- @return nil
local function SuppressBlizzard()
    KillBlizzardFrame(ZoneTextFrame)
    KillBlizzardFrame(SubZoneTextFrame)
    KillBlizzardFrame(RaidBossEmoteFrame)
    KillBlizzardFrame(LevelUpDisplay)
    KillBlizzardFrame(BossBanner)
    KillBlizzardFrame(ObjectiveTrackerBonusBannerFrame)
    local topBannerFrame = ObjectiveTrackerTopBannerFrame or _G["ObjectiveTrackerTopBannerFrame"]
    if topBannerFrame then
        KillBlizzardFrame(topBannerFrame)
    end
    KillBlizzardFrame(EventToastManagerFrame)

    local wqFrame = WorldQuestCompleteBannerFrame or _G["WorldQuestCompleteBannerFrame"]
    if wqFrame then
        KillBlizzardFrame(wqFrame)
    end
end

--- Restore all suppressed Blizzard frames when Presence is disabled.
--- @return nil
local function RestoreBlizzard()
    RestoreBlizzardFrame(ZoneTextFrame)
    RestoreBlizzardFrame(SubZoneTextFrame)
    RestoreBlizzardFrame(RaidBossEmoteFrame)
    RestoreBlizzardFrame(LevelUpDisplay)
    RestoreBlizzardFrame(BossBanner)
    RestoreBlizzardFrame(ObjectiveTrackerBonusBannerFrame)
    local topBannerFrame = ObjectiveTrackerTopBannerFrame or _G["ObjectiveTrackerTopBannerFrame"]
    if topBannerFrame then RestoreBlizzardFrame(topBannerFrame) end
    local wqFrame = WorldQuestCompleteBannerFrame or _G["WorldQuestCompleteBannerFrame"]
    if wqFrame then RestoreBlizzardFrame(wqFrame) end
end

--- Suppress WorldQuestCompleteBannerFrame (called on ADDON_LOADED for Blizzard_WorldQuestComplete).
--- @return nil
local function KillWorldQuestBanner()
    local frame = WorldQuestCompleteBannerFrame or _G["WorldQuestCompleteBannerFrame"]
    if frame then
        KillBlizzardFrame(frame)
    end
end

-- ============================================================================
-- Exports
-- ============================================================================

addon.Presence.SuppressBlizzard     = SuppressBlizzard
addon.Presence.RestoreBlizzard      = RestoreBlizzard
addon.Presence.KillWorldQuestBanner = KillWorldQuestBanner
