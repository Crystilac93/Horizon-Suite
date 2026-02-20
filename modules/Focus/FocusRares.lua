--[[
    Horizon Suite - Focus - Rare Bosses
    RARES_BY_MAP, vignette detection, GetRaresOnMap.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- RARE BOSSES BY ZONE AND VIGNETTE DETECTION
-- ============================================================================

local RARES_BY_MAP = {
    [2112] = {
        { 193136, "Researcher Sneakwing" },
        { 193166, "Sparkspitter Vrak" },
        { 193173, "Territorial Coastling" },
    },
    [2133] = {
        { 193157, "Dragonhunter Gorund" },
        { 193168, "Breezebiter" },
        { 193209, "Tenek" },
    },
    [2198] = {
        { 212557, "Bonesifter" },
        { 212558, "Captain Dailis" },
    },
}

local function IsNpcVignetteAtlas(atlasName)
    if not atlasName or atlasName == "" then return false end
    local lower = atlasName:lower()
    if lower:find("loot") or lower:find("treasure") or lower:find("container") or lower:find("chest") or lower:find("object") then
        return false
    end
    if lower:find("rare") or lower:find("elite") or lower:find("npc") or lower:find("vignettekill") then
        return true
    end
    return false
end

local function GetRaresOnMap()
    local out = {}
    local rareColor = addon.GetQuestColor("RARE")

    if C_VignetteInfo and C_VignetteInfo.GetVignettes and C_VignetteInfo.GetVignetteInfo then
        local vignettes = C_VignetteInfo.GetVignettes()
        if vignettes then
            for _, vignetteGUID in ipairs(vignettes) do
                local vi = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
                if vi and vi.onWorldMap and (vi.name and vi.name ~= "") then
                    if IsNpcVignetteAtlas(vi.atlasName) then
                        local creatureID = vi.npcID or vi.creatureID
                        if not creatureID and vi.objectGUID then
                            local _, _, _, _, _, id, _ = strsplit("-", vi.objectGUID)
                            creatureID = tonumber(id)
                        end
                        if creatureID then
                            out[#out + 1] = {
                                entryKey    = "vignette:" .. tostring(vignetteGUID),
                                questID     = nil,
                                title       = vi.name or "Unknown",
                                objectives  = {},
                                color       = rareColor,
                                category    = "RARE",
                                isComplete  = false,
                                isSuperTracked = false,
                                isNearby    = true,
                                zoneName    = nil,
                                itemLink    = nil,
                                itemTexture = nil,
                                isRare      = true,
                                creatureID  = creatureID,
                            }
                        end
                    end
                end
            end
        end
        if #out > 0 then
            return out
        end
    end

    if not C_Map or not C_Map.GetBestMapForUnit then return out end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return out end

    local rares = RARES_BY_MAP[mapID]
    if not rares and C_Map.GetMapInfo then
        local current = mapID
        for _ = 1, 20 do
            local parentInfo = C_Map.GetMapInfo(current)
            if not parentInfo or not parentInfo.parentMapID then break end
            current = parentInfo.parentMapID
            rares = RARES_BY_MAP[current]
            if rares then break end
        end
    end
    if not rares then return out end

    local zoneName = (C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)) and C_Map.GetMapInfo(mapID).name or nil
    for _, t in ipairs(rares) do
        local creatureID, name = t[1], t[2]
        if creatureID and name then
            out[#out + 1] = {
                entryKey   = "rare:" .. tostring(creatureID),
                questID    = nil,
                title      = name,
                objectives = {},
                color      = rareColor,
                category   = "RARE",
                isComplete = false,
                isSuperTracked = false,
                isNearby   = true,
                zoneName   = zoneName,
                itemLink   = nil,
                itemTexture = nil,
                isRare     = true,
                creatureID = creatureID,
            }
        end
    end
    return out
end

addon.GetRaresOnMap = GetRaresOnMap
