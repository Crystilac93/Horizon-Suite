--[[
    Horizon Suite - Focus - Achievement Tracking
    Direct provider: C_ContentTracking.GetTrackedIDs(Achievement) / GetTrackedAchievements + GetAchievementInfo.
    Returns normalized entry tables for the tracker.
    Step-by-step flow notes: notes/FocusAchievements.md
]]

local addon = _G.HorizonSuite

local TRACKING_TYPE_ACHIEVEMENT = (Enum and Enum.ContentTrackingType and Enum.ContentTrackingType.Achievement) or 2
local DEFAULT_ACHIEVEMENT_COLOR = { 0.78, 0.48, 0.22 }
local MAX_LEGACY_TRACKED_ACHIEVEMENTS = 10

-- ============================================================================
-- Private helpers
-- ============================================================================

-- Turns one achievement's criteria into objective rows; respects "only missing" option. Uses pcall for APIs that can throw on invalid ID.
local function GetAchievementCriteria(achievementID)
    local objectives = {}
    local criteriaDone, criteriaTotal = 0, 0
    local onlyMissing = addon.GetDB and addon.GetDB("achievementOnlyMissingRequirements", false)
    if not GetAchievementCriteriaInfo then return objectives, criteriaDone, criteriaTotal end
    -- pcall: GetAchievementNumCriteria and GetAchievementCriteriaInfo can throw on invalid ID.
    local numCriteria = 0
    if GetAchievementNumCriteria then
        local nOk, n = pcall(GetAchievementNumCriteria, achievementID)
        if nOk and type(n) == "number" then numCriteria = n end
    end
    for criteriaIndex = 1, math.max(numCriteria, 1) do
        local cOk, criteriaString, criteriaType, completedCrit, quantity, reqQuantity = pcall(GetAchievementCriteriaInfo, achievementID, criteriaIndex)
        if cOk and criteriaString and criteriaString ~= "" then
            local finished = (completedCrit == true) or (completedCrit == 1)
            criteriaTotal = criteriaTotal + 1
            if finished then criteriaDone = criteriaDone + 1 end
            local include = not onlyMissing or not finished
            if include then
                local percent = nil
                local numFulfilled, numRequired = nil, nil
                if quantity and reqQuantity and reqQuantity > 0 then
                    percent = math.floor(100 * math.min(quantity, reqQuantity) / reqQuantity)
                    numFulfilled = quantity
                    numRequired = reqQuantity
                end
                objectives[#objectives + 1] = {
                    text = criteriaString,
                    finished = finished,
                    percent = percent,
                    numFulfilled = numFulfilled,
                    numRequired = numRequired,
                }
            end
        end
    end
    return objectives, criteriaDone, criteriaTotal
end

-- ============================================================================
-- Public functions
-- ============================================================================

--- Build tracker rows from WoW tracked achievements.
--- @return table Array of normalized entry tables (see entry shape in FocusState.lua)
local function ReadTrackedAchievements()
    local out = {}
    local idList = {}

    if C_ContentTracking and C_ContentTracking.GetTrackedIDs then
        local ids = C_ContentTracking.GetTrackedIDs(TRACKING_TYPE_ACHIEVEMENT)
        if ids and type(ids) == "table" then
            for _, id in ipairs(ids) do
                if type(id) == "number" and id > 0 then
                    idList[#idList + 1] = id
                end
        end
    end
    elseif GetTrackedAchievements then
        for i = 1, MAX_LEGACY_TRACKED_ACHIEVEMENTS do
            local id = select(i, GetTrackedAchievements())
            if type(id) == "number" and id > 0 then
                idList[#idList + 1] = id
            end
        end
    end

    local achievementColor = (addon.GetQuestColor and addon.GetQuestColor("ACHIEVEMENT")) or (addon.QUEST_COLORS and addon.QUEST_COLORS.ACHIEVEMENT) or DEFAULT_ACHIEVEMENT_COLOR

    for _, achievementID in ipairs(idList) do
        if type(achievementID) ~= "number" or achievementID <= 0 then
            -- skip invalid ID
        else
            -- pcall: GetAchievementInfo can throw on invalid ID.
            local aOk, id, name, points, completed, month, day, year, description, flags, icon = pcall(GetAchievementInfo, achievementID)
            if not aOk or not name or name == "" then
                name = "Achievement " .. tostring(achievementID)
            end
            local isComplete = (completed == true) or (completed == 1)
            local showCompleted = addon.GetDB and addon.GetDB("showCompletedAchievements", false)
            if not (isComplete and not showCompleted) then
                local achievementIcon = (icon and (type(icon) == "number" or (type(icon) == "string" and icon ~= ""))) and icon or nil
                local objectives, criteriaDone, criteriaTotal = GetAchievementCriteria(achievementID)
                local numericQuantity, numericRequired = nil, nil
                if #objectives == 1 then
                    local o = objectives[1]
                    if o.numFulfilled ~= nil and o.numRequired ~= nil and type(o.numRequired) == "number" and o.numRequired > 1 then
                        numericQuantity = o.numFulfilled
                        numericRequired = o.numRequired
                    end
                end
                out[#out + 1] = {
                    entryKey        = "ach:" .. tostring(achievementID),
                    achievementID   = achievementID,
                    questID         = nil,
                    title           = name or ("Achievement " .. tostring(achievementID)),
                    objectives      = objectives,
                    criteriaDone    = criteriaTotal > 0 and criteriaDone or nil,
                    criteriaTotal   = criteriaTotal > 0 and criteriaTotal or nil,
                    numericQuantity = numericQuantity,
                    numericRequired = numericRequired,
                    color           = achievementColor,
                    category        = "ACHIEVEMENT",
                    isComplete      = isComplete,
                    isSuperTracked  = false,
                    isNearby        = false,
                    zoneName        = nil,
                    itemLink        = nil,
                    itemTexture     = nil,
                    isAchievement   = true,
                    isTracked       = true,
                    achievementIcon = achievementIcon,
                }
            end
        end
    end

    return out
end

addon.ReadTrackedAchievements = ReadTrackedAchievements
