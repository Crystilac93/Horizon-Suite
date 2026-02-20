--[[
    Horizon Suite - Presence - Slash Commands
    Slash command dispatch for /horizon presence [cmd]. Test playback for all notification types.
]]

local addon = _G.HorizonSuite
if not addon or not addon.Presence then return end

local HSPrint = addon.HSPrint or function(msg) print("|cFF00CCFFHorizon Suite:|r " .. tostring(msg or "")) end

--- Handle /horizon presence [cmd] subcommands. Returns true if handled, false to pass to parent handler.
--- @param msg string Subcommand (zone, subzone, discover, level, boss, ach, quest, wq, wqaccept, accept, update, scenario, all, debug, debuglive, help)
--- @return boolean
local function HandlePresenceSlash(msg)
    local cmd = strtrim(msg or ""):lower()

    -- Debug is read-only; allow during combat
    if cmd == "debug" then
        if addon.Presence.DumpDebug then addon.Presence.DumpDebug() end
        return true
    end

    if cmd == "debuglive" then
        local on = addon.Presence.ToggleDebugLive and addon.Presence.ToggleDebugLive()
        HSPrint("Presence live debug: " .. (on and "on" or "off"))
        return true
    end

    if cmd == "level" then
        addon.Presence.QueueOrPlay("LEVEL_UP", "LEVEL UP", "You have reached level 80")
    elseif cmd == "boss" then
        addon.Presence.QueueOrPlay("BOSS_EMOTE", "Ragnaros", "BY FIRE BE PURGED!")
    elseif cmd == "ach" then
        addon.Presence.QueueOrPlay("ACHIEVEMENT", "ACHIEVEMENT EARNED", "Exploring the Midnight Isles")
    elseif cmd == "quest" then
        addon.Presence.QueueOrPlay("QUEST_COMPLETE", "QUEST COMPLETE", "Objective Secured")
    elseif cmd == "wq" then
        addon.Presence.QueueOrPlay("WORLD_QUEST", "WORLD QUEST", "Azerite Mining")
    elseif cmd == "wqaccept" then
        addon.Presence.QueueOrPlay("WORLD_QUEST_ACCEPT", "WORLD QUEST ACCEPTED", "Azerite Mining")
    elseif cmd == "accept" then
        addon.Presence.QueueOrPlay("QUEST_ACCEPT", "QUEST ACCEPTED", "The Fate of the Horde")
    elseif cmd == "update" then
        addon.Presence.QueueOrPlay("QUEST_UPDATE", "QUEST UPDATE", "Boar Pelts: 7/10")
    elseif cmd == "scenario" then
        if addon.GetScenarioDisplayInfo and addon.IsScenarioActive and addon.IsScenarioActive() then
            local title, subtitle, category = addon.GetScenarioDisplayInfo()
            addon.Presence.QueueOrPlay("SCENARIO_START", title or "Scenario", subtitle or "", { category = category })
        else
            addon.Presence.QueueOrPlay("SCENARIO_START", "Cinderbrew Meadery", "Defend the tavern from attackers", { category = "SCENARIO" })
        end
    elseif cmd == "zone" then
        addon.Presence.QueueOrPlay("ZONE_CHANGE", GetZoneText() or "Unknown Zone", GetSubZoneText() or "")
    elseif cmd == "subzone" then
        addon.Presence.QueueOrPlay("SUBZONE_CHANGE", GetZoneText() or "Unknown Zone", GetSubZoneText() or "Subzone")
    elseif cmd == "discover" then
        addon.Presence.SetPendingDiscovery()
        addon.Presence.QueueOrPlay("ZONE_CHANGE", "The Waking Shores", "Obsidian Citadel")
    elseif cmd == "all" then
        HSPrint("Presence: Playing demo reel (all notification types)...")
        local demos = {
            { "ZONE_CHANGE",         "Valdrakken",           "Thaldraszus"               },
            { "SUBZONE_CHANGE",      "Valdrakken",           "The Seat of Aspects"       },
            { "ZONE_CHANGE",         "The Waking Shores",    "Obsidian Citadel",  true   },
            { "QUEST_ACCEPT",        "QUEST ACCEPTED",       "The Fate of the Horde"     },
            { "WORLD_QUEST_ACCEPT",  "WORLD QUEST ACCEPTED", "Azerite Mining"            },
            { "QUEST_UPDATE",        "QUEST UPDATE",         "Dragon Glyphs: 3/5"        },
            { "QUEST_COMPLETE",      "QUEST COMPLETE",       "Aiding the Accord"         },
            { "WORLD_QUEST",         "WORLD QUEST",          "Azerite Mining"            },
            { "SCENARIO_START",      "Cinderbrew Meadery",   "Defend the tavern", { category = "SCENARIO" } },
            { "ACHIEVEMENT",         "ACHIEVEMENT EARNED",   "Exploring Khaz Algar"      },
            { "BOSS_EMOTE",          "Ragnaros",             "BY FIRE BE PURGED!"        },
            { "LEVEL_UP",            "LEVEL UP",             "You have reached level 80" },
        }
        for i, d in ipairs(demos) do
            C_Timer.After((i - 1) * 3, function()
                if d[4] == true then addon.Presence.SetPendingDiscovery() end
                addon.Presence.QueueOrPlay(d[1], d[2], d[3], type(d[4]) == "table" and d[4] or nil)
            end)
        end
    elseif cmd == "" or cmd == "help" then
        HSPrint("Presence test commands:")
        HSPrint("  /horizon presence         - Show help + test current zone")
        HSPrint("  /horizon presence zone     - Test Zone Change")
        HSPrint("  /horizon presence subzone  - Test Subzone Change")
        HSPrint("  /horizon presence discover - Test Zone Discovery")
        HSPrint("  /horizon presence level    - Test Level Up")
        HSPrint("  /horizon presence boss     - Test Boss Emote")
        HSPrint("  /horizon presence ach      - Test Achievement")
        HSPrint("  /horizon presence accept   - Test Quest Accepted")
        HSPrint("  /horizon presence wqaccept - Test World Quest Accepted")
        HSPrint("  /horizon presence scenario - Test Scenario Start")
        HSPrint("  /horizon presence quest    - Test Quest Complete")
        HSPrint("  /horizon presence wq       - Test World Quest")
        HSPrint("  /horizon presence update   - Test Quest Update")
        HSPrint("  /horizon presence all      - Demo reel (all types)")
        HSPrint("  /horizon presence debug    - Dump state to chat")
        HSPrint("  /horizon presence debuglive - Toggle live debug panel (log as events happen)")
        addon.Presence.QueueOrPlay("ZONE_CHANGE", GetZoneText() or "Unknown Zone", GetSubZoneText() or "")
    else
        return false
    end

    return true
end

-- Wrap the existing /horizon handler to add presence subcommands
local oldHandler = SlashCmdList["MODERNQUESTTRACKER"]
SlashCmdList["MODERNQUESTTRACKER"] = function(msg)
    local cmd = strtrim(msg or ""):lower()
    if cmd == "presence" or cmd:match("^presence ") then
        local sub = cmd == "presence" and "" or strtrim(cmd:sub(10))
        if HandlePresenceSlash(sub) then return end
    end
    if oldHandler then oldHandler(msg) end
end

-- ============================================================================
-- Exports
-- ============================================================================

addon.Presence.HandlePresenceSlash = HandlePresenceSlash
