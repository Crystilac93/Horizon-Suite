--[[
    Horizon Suite - Presence Module
    Cinematic zone text and notifications. Zone/subzone changes, discoveries,
    level up, boss emotes, achievements, quest accept/complete/update, world quests.
]]

local addon = _G.HorizonSuite
if not addon or not addon.RegisterModule then return end

addon:RegisterModule("presence", {
    title       = "Presence",
    description = "Cinematic zone text and notifications (zone changes, level up, boss emotes, achievements, quest updates).",
    order       = 20,

    OnInit = function()
        if addon.Presence and addon.Presence.Init then
            addon.Presence.Init()
        end
    end,

    OnEnable = function()
        if addon.Presence then
            if addon.Presence.EnableEvents then addon.Presence.EnableEvents() end
            if addon.Presence.SuppressBlizzard then addon.Presence.SuppressBlizzard() end
            if addon.Presence.MuteAlerts then addon.Presence.MuteAlerts() end
            if addon.Presence.HookUIErrorsFrame then addon.Presence.HookUIErrorsFrame() end
        end
    end,

    OnDisable = function()
        if addon.Presence then
            if addon.Presence.DisableEvents then addon.Presence.DisableEvents() end
            if addon.Presence.RestoreBlizzard then addon.Presence.RestoreBlizzard() end
            if addon.Presence.RestoreAlerts then addon.Presence.RestoreAlerts() end
            if addon.Presence.HideAndClear then addon.Presence.HideAndClear() end
        end
        ReloadUI()
    end,
})
