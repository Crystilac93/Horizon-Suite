--[[
    Horizon Suite - Focus - Mythic+ Block
    Cinematic banner: dungeon name, keystone level, timer/progress, affixes.
    Hover tooltip shows detailed dungeon and modifier info.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- MYTHIC+ BANNER (CINEMATIC, ALWAYS-VISIBLE ABOVE / BELOW LIST)
-- ============================================================================

local MPLUS_MIN_HEIGHT = 80
-- Parented to UIParent so it stays visible even when the main tracker
-- panel (addon.HS) is hidden by "Show in dungeon" being OFF.
local mplusBlock = CreateFrame("Frame", nil, UIParent)
mplusBlock:SetSize(addon.GetPanelWidth() - addon.PADDING * 2, MPLUS_MIN_HEIGHT)
mplusBlock:SetFrameStrata(addon.HS:GetFrameStrata())
mplusBlock:SetFrameLevel(addon.HS:GetFrameLevel() + 5)
mplusBlock:EnableMouse(false)
mplusBlock:Hide()

-- Cinematic gradient background (dark top, slightly lighter center, dark bottom).
local mplusBg = mplusBlock:CreateTexture(nil, "BACKGROUND")
mplusBg:SetAllPoints()
if mplusBg.SetGradient and CreateColor then
    -- Two-stop vertical gradient for cinematic vignette feel.
    mplusBg:SetGradient("VERTICAL", CreateColor(0.02, 0.02, 0.06, 0.88), CreateColor(0.05, 0.05, 0.12, 0.72))
else
    mplusBg:SetColorTexture(0.02, 0.02, 0.06, 0.78)
end

-- Left accent aligned with quest entry highlight bar (bar-left position).
local accent = mplusBlock:CreateTexture(nil, "BORDER")
local dungeonColor = (addon.QUEST_COLORS and addon.QUEST_COLORS.DUNGEON) or { 0.6, 0.4, 1.0 }
accent:SetColorTexture(dungeonColor[1], dungeonColor[2], dungeonColor[3], 0.65)
accent:Hide()  -- Hide the accent bar for M+ block

local contentOffsetX = 12
local iconSize = addon.QUEST_TYPE_ICON_SIZE or 16
local iconGap = addon.QUEST_TYPE_ICON_GAP or 4

-- Dungeon/keystone icon (same as DUNGEON category).
local mplusIcon = mplusBlock:CreateTexture(nil, "OVERLAY")
mplusIcon:SetSize(iconSize, iconSize)
mplusIcon:SetAtlas("questlog-questtypeicon-dungeon")
mplusIcon:Hide()  -- Hide the icon for M+ block

-- Line 1: Dungeon name + keystone level
local mplusHeroText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusHeroText:SetWordWrap(true)
mplusHeroText:SetJustifyH("LEFT")

-- Line 2: Timer (elapsed / target)
local mplusPillText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusPillText:SetJustifyH("LEFT")

-- Line 3: Progress bar (enemy forces)
local PROGRESS_BAR_HEIGHT = 16
local mplusProgressBar = CreateFrame("Frame", nil, mplusBlock)
mplusProgressBar:SetHeight(PROGRESS_BAR_HEIGHT)

local progressBarBg = mplusProgressBar:CreateTexture(nil, "BACKGROUND")
progressBarBg:SetAllPoints()
progressBarBg:SetColorTexture(0.08, 0.08, 0.12, 0.85)

local progressBarFill = mplusProgressBar:CreateTexture(nil, "ARTWORK")
progressBarFill:SetPoint("TOPLEFT")
progressBarFill:SetPoint("BOTTOMLEFT")
progressBarFill:SetWidth(1)
progressBarFill:SetColorTexture(0.20, 0.55, 0.30, 0.90)

-- Percentage label (left of center inside bar)
local progressPercentLabel = mplusProgressBar:CreateFontString(nil, "OVERLAY")
progressPercentLabel:SetJustifyH("RIGHT")

-- Count label (right of center inside bar)
local progressCountLabel = mplusProgressBar:CreateFontString(nil, "OVERLAY")
progressCountLabel:SetJustifyH("LEFT")

-- Position both labels centered together inside the bar
progressPercentLabel:SetPoint("RIGHT", mplusProgressBar, "CENTER", -3, 0)
progressCountLabel:SetPoint("LEFT", mplusProgressBar, "CENTER", 3, 0)

-- Line 4: Affixes (one per line)
local mplusAffixesText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusAffixesText:SetWordWrap(true)
mplusAffixesText:SetJustifyH("LEFT")

-- Lines 5+: Bosses (one per line)
local mplusBossesText = mplusBlock:CreateFontString(nil, "OVERLAY")
mplusBossesText:SetWordWrap(true)
mplusBossesText:SetJustifyH("LEFT")
mplusBossesText:SetJustifyV("TOP")

addon.mplusBlock            = mplusBlock
addon.mplusHeroText         = mplusHeroText
addon.mplusTimerText        = mplusPillText
addon.mplusProgressBar      = mplusProgressBar
addon.mplusAffixesText      = mplusAffixesText
addon.mplusBossesText       = mplusBossesText

-- Function to get current M+ block height (dynamic based on content)
function addon.GetMplusBlockHeight()
    if mplusBlock and mplusBlock:IsShown() then
        return mplusBlock:GetHeight() or MPLUS_MIN_HEIGHT
    end
    return MPLUS_MIN_HEIGHT
end

local function GetMplusTimer()
    -- Get world elapsed timer for active scenarios 
    local _, elapsedTime = GetWorldElapsedTime(1)
    return elapsedTime
end

local function GetMplusData()
    local data = {
        dungeonName = "",
        level = 0,
        timer = 0,
        timeLimit = 0,
        deathPenalty = 0,
        bossList = {},  -- Array of {name, completed}
        enemyForces = { current = 0, total = 0, percent = 0 },
        affixes = {}
    }

    -- Get active challenge map ID
    local mapId = C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
    if not mapId then return data end

    -- Get dungeon name from map info
    if mapId and C_ChallengeMode.GetMapUIInfo then
        local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapId)
        if name then
            data.dungeonName = name
        end
        if timeLimit then
            data.timeLimit = timeLimit
        end
    end

    -- Get keystone level and affixes
    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local level, affixes, wasEnergized = C_ChallengeMode.GetActiveKeystoneInfo()
        if level and level > 0 then
            data.level = level
        end
        
        -- Try multiple methods to get affixes
        local affixesFound = false
        
        -- Method 1: From GetActiveKeystoneInfo
        if affixes and type(affixes) == "table" and #affixes > 0 then
            for i = 1, #affixes do
                local affixID = affixes[i]
                if affixID and type(affixID) == "number" then
                    if C_ChallengeMode.GetAffixInfo then
                        local name, desc, iconFileID = C_ChallengeMode.GetAffixInfo(affixID)
                        if name and name ~= "" then
                            data.affixes[#data.affixes + 1] = { name = name, desc = desc or "" }
                            affixesFound = true
                        end
                    end
                end
            end
        end
        
        -- Method 2: Try C_MythicPlus.GetCurrentAffixes() if available
        if not affixesFound and C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
            local currentAffixes = C_MythicPlus.GetCurrentAffixes()
            if currentAffixes and type(currentAffixes) == "table" then
                for _, affixInfo in ipairs(currentAffixes) do
                    if affixInfo and affixInfo.id then
                        local name, desc, iconFileID = C_ChallengeMode.GetAffixInfo(affixInfo.id)
                        if name and name ~= "" then
                            data.affixes[#data.affixes + 1] = { name = name, desc = desc or "" }
                            affixesFound = true
                        end
                    end
                end
            end
        end
        
        -- Method 3: Get from map ID if we have one
        if not affixesFound and mapId and C_ChallengeMode.GetMapUIInfo then
            local _, _, keyLevel = C_ChallengeMode.GetMapUIInfo(mapId)
            if keyLevel and keyLevel > 0 then
                -- Affixes are typically stored on a weekly basis, try to get them
                -- This is a fallback - affixes may not be available until key is inserted
                print("HorizonSuite: Affixes not available from GetActiveKeystoneInfo, may need key insertion")
            end
        end
    end

    -- Get timer
    data.timer = GetMplusTimer() or 0

    -- Get death penalty
    if C_ChallengeMode and C_ChallengeMode.GetDeathCount then
        local numDeaths, timePenalty = C_ChallengeMode.GetDeathCount()
        if timePenalty and timePenalty > 0 then
            data.deathPenalty = timePenalty
        end
    end

    -- Get boss progress and forces from scenario criteria
    local stepCount = C_Scenario and C_Scenario.GetStepInfo and select(3, C_Scenario.GetStepInfo()) or 0
    
    -- Track seen boss criteria by index to handle multi-boss encounters
    local seenBosses = {}
    
    if stepCount and stepCount > 0 then
        for i = 1, stepCount do
            local criteriaInfo = C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo and C_ScenarioInfo.GetCriteriaInfo(i)
            if criteriaInfo then
                -- Enemy Forces are weighted progress
                if criteriaInfo.isWeightedProgress and criteriaInfo.totalQuantity and criteriaInfo.totalQuantity > 0 then
                    -- quantityString contains the current count with a % sign
                    local currentCount = criteriaInfo.quantityString and tonumber(criteriaInfo.quantityString:match("%d+")) or 0
                    data.enemyForces.current = currentCount
                    data.enemyForces.total = criteriaInfo.totalQuantity
                    data.enemyForces.percent = (currentCount / criteriaInfo.totalQuantity) * 100
                
                -- Bosses are non-weighted objectives
                elseif not criteriaInfo.isWeightedProgress then
                    -- Try to get proper encounter name, fall back to description
                    -- For multi-boss encounters, description contains individual NPC names
                    -- Use criteriaString if available as it may contain the encounter name
                    local bossName = criteriaInfo.criteriaString or criteriaInfo.description or ("Boss " .. i)
                    local completed = criteriaInfo.completed or false
                    
                    -- Avoid duplicates for multi-boss encounters (e.g., Demolition Duo)
                    if not seenBosses[bossName] then
                        seenBosses[bossName] = true
                        data.bossList[#data.bossList + 1] = { name = bossName, completed = completed }
                    end
                end
            end
        end
    end

    return data
end

-- No static ApplyMplusAlignment — all positioning is done in
-- UpdateMplusBlockDisplay so we can skip hidden elements and
-- avoid anchor-chain issues (hidden frames collapse anchors).

local function PositionMplusBlock(pos)
    local panelWidth = addon.GetPanelWidth() - addon.PADDING * 2
    mplusBlock:SetWidth(panelWidth)
    mplusBlock:ClearAllPoints()
    if pos == "bottom" then
        mplusBlock:SetPoint("BOTTOMLEFT", addon.HS, "BOTTOMLEFT", addon.PADDING, addon.PADDING)
    else
        local topOffset = addon.GetContentTop()
        mplusBlock:SetPoint("TOPLEFT", addon.HS, "TOPLEFT", addon.PADDING, topOffset)
    end
end

-- Cached block width – only grows during a dungeon run to keep the
-- progress bar from jumping around when the timer string changes width.
local cachedBlockWidth = 0

local function UpdateMplusBlockDisplay(data)
    if not data then return end

    -- Apply typography settings
    local fontPath = addon.GetDB("fontPath", addon.DEFAULT_FONT_PATH or "Fonts\\FRIZQT__.TTF")
    local fontOutline = addon.GetDB("fontOutline", "OUTLINE")

    -- Get sizes with validation (clamp between 8-32)
    local dungeonSize = math.max(8, math.min(32, tonumber(addon.GetDB("mplusDungeonSize", 14)) or 14))
    local dungeonR = addon.GetDB("mplusDungeonColorR", 0.96)
    local dungeonG = addon.GetDB("mplusDungeonColorG", 0.96)
    local dungeonB = addon.GetDB("mplusDungeonColorB", 1.0)

    local timerSize = math.max(8, math.min(32, tonumber(addon.GetDB("mplusTimerSize", 12)) or 12))
    local timerR = addon.GetDB("mplusTimerColorR", 0.6)
    local timerG = addon.GetDB("mplusTimerColorG", 0.88)
    local timerB = addon.GetDB("mplusTimerColorB", 1.0)
    local timerOvertimeR = addon.GetDB("mplusTimerOvertimeColorR", 0.9)
    local timerOvertimeG = addon.GetDB("mplusTimerOvertimeColorG", 0.25)
    local timerOvertimeB = addon.GetDB("mplusTimerOvertimeColorB", 0.2)

    local progressSize = math.max(8, math.min(32, tonumber(addon.GetDB("mplusProgressSize", 11)) or 11))
    local progressR = addon.GetDB("mplusProgressColorR", 0.72)
    local progressG = addon.GetDB("mplusProgressColorG", 0.76)
    local progressB = addon.GetDB("mplusProgressColorB", 0.88)

    local affixSize = math.max(8, math.min(32, tonumber(addon.GetDB("mplusAffixSize", 10)) or 10))
    local affixR = addon.GetDB("mplusAffixColorR", 0.85)
    local affixG = addon.GetDB("mplusAffixColorG", 0.85)
    local affixB = addon.GetDB("mplusAffixColorB", 0.95)

    local bossSize = math.max(8, math.min(32, tonumber(addon.GetDB("mplusBossSize", 11)) or 11))
    local bossR = addon.GetDB("mplusBossColorR", 0.78)
    local bossG = addon.GetDB("mplusBossColorG", 0.82)
    local bossB = addon.GetDB("mplusBossColorB", 0.92)

    -- Read progress bar fill colors
    local barNormR = addon.GetDB("mplusBarColorR", 0.20)
    local barNormG = addon.GetDB("mplusBarColorG", 0.45)
    local barNormB = addon.GetDB("mplusBarColorB", 0.60)
    local barDoneR = addon.GetDB("mplusBarDoneColorR", 0.15)
    local barDoneG = addon.GetDB("mplusBarDoneColorG", 0.65)
    local barDoneB = addon.GetDB("mplusBarDoneColorB", 0.25)

    -- Apply fonts
    mplusHeroText:SetFont(fontPath, dungeonSize, fontOutline)
    mplusHeroText:SetTextColor(dungeonR, dungeonG, dungeonB, 1)

    mplusPillText:SetFont(fontPath, timerSize, fontOutline)

    progressPercentLabel:SetFont(fontPath, progressSize, fontOutline)
    progressPercentLabel:SetTextColor(progressR, progressG, progressB, 1)
    progressCountLabel:SetFont(fontPath, progressSize, fontOutline)
    progressCountLabel:SetTextColor(progressR, progressG, progressB, 1)

    mplusAffixesText:SetFont(fontPath, affixSize, fontOutline)
    mplusAffixesText:SetTextColor(affixR, affixG, affixB, 1)

    mplusBossesText:SetFont(fontPath, bossSize, fontOutline)
    mplusBossesText:SetTextColor(bossR, bossG, bossB, 1)

    -- Line 1: Dungeon name + keystone level
    local dungeonName = data.dungeonName ~= "" and data.dungeonName or "Mythic+"
    local level = data.level > 0 and (" (+" .. data.level .. ")") or ""
    mplusHeroText:SetText(dungeonName .. level)

    -- Line 2: Timer (elapsed / target + penalty)
    local timerStr = "—"
    local isOvertime = false
    if data.timer and data.timer > 0 and data.timeLimit and data.timeLimit > 0 then
        local elapsed = data.timer
        local target = data.timeLimit
        isOvertime = elapsed >= target
        local elapsedStr = string.format("%d:%02d", math.floor(elapsed / 60), math.floor(elapsed % 60))
        local targetStr = string.format("%d:%02d", math.floor(target / 60), math.floor(target % 60))
        timerStr = elapsedStr .. " / " .. targetStr
        if data.deathPenalty and data.deathPenalty > 0 then
            local penStr = string.format("+%d:%02d", math.floor(data.deathPenalty / 60), math.floor(data.deathPenalty % 60))
            timerStr = timerStr .. "  |cffcc4444" .. penStr .. "|r"
        end
    end
    -- Switch timer color when over the time limit
    if isOvertime then
        mplusPillText:SetTextColor(timerOvertimeR, timerOvertimeG, timerOvertimeB, 1)
    else
        mplusPillText:SetTextColor(timerR, timerG, timerB, 1)
    end
    mplusPillText:SetText(timerStr)

    -- Line 3: Progress bar (enemy forces)
    if data.enemyForces.total > 0 then
        local pctStr  = string.format("%.2f%%", data.enemyForces.percent)
        local cntStr  = string.format("(%d/%d)", data.enemyForces.current, data.enemyForces.total)
        progressPercentLabel:SetText(pctStr)
        progressCountLabel:SetText(cntStr)

        -- Color: user-picked bar fill; switches to "done" color at 100%
        if data.enemyForces.percent >= 100 then
            progressBarFill:SetColorTexture(barDoneR, barDoneG, barDoneB, 0.90)
        else
            progressBarFill:SetColorTexture(barNormR, barNormG, barNormB, 0.90)
        end
        mplusProgressBar:SetHeight(math.max(PROGRESS_BAR_HEIGHT, progressSize + 6))
        mplusProgressBar:Show()
    else
        progressPercentLabel:SetText("")
        progressCountLabel:SetText("")
        mplusProgressBar:Hide()
    end

    -- Line 4: Affixes (one per line)
    local affixStr = ""
    if #data.affixes > 0 then
        local affixNames = {}
        for _, a in ipairs(data.affixes) do
            affixNames[#affixNames + 1] = a.name
        end
        affixStr = table.concat(affixNames, "\n")
    end
    mplusAffixesText:SetText(affixStr)

    -- Lines 5+: Bosses with Defeated / Active status labels
    local bossStr = ""
    if #data.bossList > 0 then
        local bossLines = {}
        for _, boss in ipairs(data.bossList) do
            if boss.completed then
                -- Green checkmark icon + "Defeated" label
                bossLines[#bossLines + 1] = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t " .. boss.name .. "  |cff44cc44Defeated|r"
            else
                -- Grey dash icon for incomplete bosses
                bossLines[#bossLines + 1] = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t " .. boss.name
            end
        end
        bossStr = table.concat(bossLines, "\n")
    end
    mplusBossesText:SetText(bossStr)

    -- ----------------------------------------------------------------
    -- Compute stable width (timer excluded – its pixel width changes
    -- each second as digits switch).  cachedBlockWidth only grows
    -- during a run so the progress bar stays rock-solid.
    -- ----------------------------------------------------------------
    local heroLeft = 4          -- small inset from block edge (no icon column needed)
    local sidePadding = heroLeft + 4  -- left + right inset

    local maxContentW = 0
    local widths = {
        mplusHeroText:GetStringWidth() or 0,
        mplusAffixesText:GetStringWidth() or 0,
        mplusBossesText:GetStringWidth() or 0,
        (progressPercentLabel:GetStringWidth() or 0) + 12 + (progressCountLabel:GetStringWidth() or 0),
    }
    for _, w in ipairs(widths) do
        if w > maxContentW then maxContentW = w end
    end

    local panelWidth = addon.GetPanelWidth() - addon.PADDING * 2
    local dividerWidth = (addon.divider and addon.divider:GetWidth()) or panelWidth
    local neededWidth = maxContentW + sidePadding
    cachedBlockWidth = math.max(cachedBlockWidth, panelWidth, dividerWidth, neededWidth)
    mplusBlock:SetWidth(cachedBlockWidth)

    -- ----------------------------------------------------------------
    -- Position every element explicitly from the top.  No anchor
    -- chains through hidden frames, no RIGHT-anchor wobble.
    -- ----------------------------------------------------------------
    local barWidth = cachedBlockWidth - sidePadding
    local barH = math.max(PROGRESS_BAR_HEIGHT, progressSize + 6)
    local y = -4

    mplusHeroText:ClearAllPoints()
    mplusHeroText:SetPoint("TOPLEFT", mplusBlock, "TOPLEFT", heroLeft, y)
    mplusHeroText:SetWidth(barWidth)
    local heroH = mplusHeroText:GetStringHeight() or dungeonSize
    y = y - heroH - 6

    mplusPillText:ClearAllPoints()
    mplusPillText:SetPoint("TOPLEFT", mplusBlock, "TOPLEFT", heroLeft, y)
    local timerH = mplusPillText:GetStringHeight() or timerSize
    y = y - timerH - 6

    if data.enemyForces.total > 0 then
        mplusProgressBar:ClearAllPoints()
        mplusProgressBar:SetPoint("TOPLEFT", mplusBlock, "TOPLEFT", heroLeft, y)
        mplusProgressBar:SetSize(math.max(1, barWidth), barH)
        local fillFrac = math.min(1, data.enemyForces.percent / 100)
        progressBarFill:SetWidth(math.max(1, barWidth * fillFrac))
        y = y - barH - 6
    end

    mplusAffixesText:ClearAllPoints()
    mplusAffixesText:SetPoint("TOPLEFT", mplusBlock, "TOPLEFT", heroLeft, y)
    mplusAffixesText:SetWidth(barWidth)
    local affixH = 0
    if affixStr ~= "" then
        affixH = mplusAffixesText:GetStringHeight() or affixSize
        y = y - affixH - 6
    end

    mplusBossesText:ClearAllPoints()
    mplusBossesText:SetPoint("TOPLEFT", mplusBlock, "TOPLEFT", heroLeft, y)
    mplusBossesText:SetWidth(barWidth)
    local bossH = 0
    if bossStr ~= "" then
        bossH = mplusBossesText:GetStringHeight() or bossSize
        y = y - bossH - 6
    end

    -- Final block height
    local heightNeeded = -y + 4  -- y is negative, add bottom padding
    local finalHeight = math.max(MPLUS_MIN_HEIGHT, heightNeeded)
    mplusBlock:SetHeight(finalHeight)
end

-- OnUpdate for timer refresh (updates every second)
local timeSinceLastUpdate = 0
mplusBlock:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() then return end
    if addon.mplusDebugPreview then return end
    
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    
    -- Update display every 1 second for smooth timer
    if timeSinceLastUpdate >= 1.0 then
        timeSinceLastUpdate = 0
        local data = GetMplusData()
        UpdateMplusBlockDisplay(data)
    end
end)

local function UpdateMplusBlock()
    local pos = addon.GetDB("mplusBlockPosition", "top") or "top"
    
    -- mplusDebugPreview: show hardcoded demo data (from /hs mplus command)
    if addon.mplusDebugPreview then
        PositionMplusBlock(pos)
        local demoData = {
            dungeonName = "Darkheart Thicket",
            level = 15,
            timer = 1112,
            timeLimit = 1800,
            deathPenalty = 15,
            bossList = {
                { name = "Boss 1", completed = true },
                { name = "Boss 2", completed = true },
                { name = "Boss 3", completed = false },
                { name = "Boss 4", completed = false },
            },
            enemyForces = { current = 340, total = 400, percent = 85.25 },
            affixes = {
                { name = "Fortified" },
                { name = "Bursting" },
                { name = "Sanguine" },
            }
        }
        UpdateMplusBlockDisplay(demoData)
        mplusBlock:Show()
        return
    end

    -- Check visibility settings
    local showInDungeon = addon.GetDB("showInDungeon", false)
    local alwaysShow = addon.GetDB("mplusAlwaysShow", false)
    local hasActiveKeystone = C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID() ~= nil

    -- "Show in dungeon" ON  → show the M+ block.
    -- "Show in dungeon" OFF → only show if "Always show M+ block" is ON.
    local shouldShow = hasActiveKeystone and (showInDungeon or alwaysShow)
    
    if not shouldShow then
        mplusBlock:Hide()
        cachedBlockWidth = 0  -- reset so next dungeon recalculates
        return
    end

    PositionMplusBlock(pos)

    -- Get real M+ data and update display (OnUpdate will handle refreshes)
    if not mplusBlock:IsShown() then
        local data = GetMplusData()
        UpdateMplusBlockDisplay(data)
    end
    mplusBlock:Show()
end

addon.UpdateMplusBlock = UpdateMplusBlock


