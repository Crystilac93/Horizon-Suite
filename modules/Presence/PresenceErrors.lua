--[[
    Horizon Suite - Presence - Error Frame & Alert Interception
    UIErrorsFrame hook for "Discovered" and quest text. AlertFrame muting.
]]

local addon = _G.HorizonSuite
if not addon or not addon.Presence then return end

-- ============================================================================
-- UIERRORSFRAME HOOK
-- ============================================================================

local uiErrorsHooked = false
local originalAddMessage = nil

local function OnUIErrorsAddMessage(self, msg)
    if msg and msg:find("Discovered") then
        addon.Presence.SetPendingDiscovery()
        local phase = addon.Presence.animPhase and addon.Presence.animPhase()
        if addon:IsModuleEnabled("presence") and phase and (phase == "entrance" or phase == "hold" or phase == "crossfade") then
            addon.Presence.ShowDiscoveryLine()
            addon.Presence.pendingDiscovery = nil
        end
        if self.Clear then self:Clear() end
        return
    end
    if addon.Presence.IsQuestText and addon.Presence.IsQuestText(msg) then
        if self.Clear then self:Clear() end
    end
end

local function HookUIErrorsFrame()
    if uiErrorsHooked or not UIErrorsFrame then return end
    if hooksecurefunc then
        hooksecurefunc(UIErrorsFrame, "AddMessage", function(self, msg)
            if not addon:IsModuleEnabled("presence") then return end
            OnUIErrorsAddMessage(self, msg)
        end)
        uiErrorsHooked = true
    end
end

local function UnhookUIErrorsFrame()
    -- hooksecurefunc cannot be undone; we simply stop acting in the callback when Presence is disabled
    -- The callback will remain but will no-op when addon:IsModuleEnabled("presence") is false
    uiErrorsHooked = false
end

-- ============================================================================
-- ALERT FRAME MUTING
-- ============================================================================

local alertsMuted = false
local alertEventsUnregistered = {}

local function MuteAlerts()
    if alertsMuted then return end
    pcall(function()
        if AlertFrame and AlertFrame.UnregisterEvent then
            AlertFrame:UnregisterEvent("ACHIEVEMENT_EARNED")
            alertEventsUnregistered["ACHIEVEMENT_EARNED"] = true
            AlertFrame:UnregisterEvent("QUEST_TURNED_IN")
            alertEventsUnregistered["QUEST_TURNED_IN"] = true
        end
    end)
    alertsMuted = true
end

local function RestoreAlerts()
    if not alertsMuted then return end
    pcall(function()
        if AlertFrame and AlertFrame.RegisterEvent then
            if alertEventsUnregistered["ACHIEVEMENT_EARNED"] then
                AlertFrame:RegisterEvent("ACHIEVEMENT_EARNED")
                alertEventsUnregistered["ACHIEVEMENT_EARNED"] = nil
            end
            if alertEventsUnregistered["QUEST_TURNED_IN"] then
                AlertFrame:RegisterEvent("QUEST_TURNED_IN")
                alertEventsUnregistered["QUEST_TURNED_IN"] = nil
            end
        end
    end)
    alertsMuted = false
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

addon.Presence.HookUIErrorsFrame = HookUIErrorsFrame
addon.Presence.UnhookUIErrorsFrame = UnhookUIErrorsFrame
addon.Presence.MuteAlerts = MuteAlerts
addon.Presence.RestoreAlerts = RestoreAlerts
