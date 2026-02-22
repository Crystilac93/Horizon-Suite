--[[
    Horizon Suite - Focus - Recipe Tracking
    C_TradeSkillUI data provider for tracked profession recipes.
    When the player tracks a recipe in the profession UI, it appears in the tracker.
]]

local addon = _G.HorizonSuite

-- ============================================================================
-- QUALITY COLOR HELPER
-- ============================================================================

--- Returns r, g, b for item quality, or nil if unavailable.
-- @param quality number Item quality (0-7)
-- @return number|nil r, number|nil g, number|nil b
function addon.GetQualityColorRGB(quality)
    if type(quality) ~= "number" then return nil end
    if GetItemQualityColor then
        local r, g, b = GetItemQualityColor(quality)
        if r and g and b then return r, g, b end
    end
    if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local c = ITEM_QUALITY_COLORS[quality]
        return c.r, c.g, c.b
    end
    return nil
end

-- ============================================================================
-- RECIPE DATA PROVIDER
-- ============================================================================

--- Resolve tracked recipe IDs with isRecraft flag from C_TradeSkillUI.GetRecipesTracked.
-- @return table Array of { recipeID = number, isRecraft = boolean }
local function GetTrackedRecipeIDs()
    local idList = {}
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipesTracked then return idList end

    local seen = {}
    for _, isRecraft in ipairs({ false, true }) do
        local ok, ids = pcall(C_TradeSkillUI.GetRecipesTracked, isRecraft)
        if ok and ids and type(ids) == "table" then
            for _, id in ipairs(ids) do
                if type(id) == "number" and id > 0 and not seen[id] then
                    seen[id] = true
                    idList[#idList + 1] = { recipeID = id, isRecraft = isRecraft }
                end
            end
        end
    end
    return idList
end

-- Enum.CraftingReagentType: Modifying=0, Basic=1, Finishing=2, Automatic=3
local REAGENT_TYPE_MODIFYING = (Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Modifying) or 0
local REAGENT_TYPE_BASIC     = (Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic) or 1
local REAGENT_TYPE_FINISHING = (Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Finishing) or 2

--- Deduplicate reagents by name (quality-tier variants) and append to objectives.
-- @param raw table Array of { name, itemID, link, owned, qtyRequired }
-- @param objectives table Array to append to
-- @param sectionHeader string|nil If set, insert this as a collapsible header line before the reagents
-- @param sectionType string|nil "finishing" | "optional" | nil. When set, header and reagents get isFinishingHeader/isFinishingReagent or isOptionalHeader/isOptionalReagent.
local function DedupeAndAppend(raw, objectives, sectionHeader, sectionType)
    if #raw == 0 then return end
    if sectionHeader and sectionType then
        objectives[#objectives + 1] = {
            text             = sectionHeader,
            isSectionHeader  = true,
            isFinishingHeader = (sectionType == "finishing"),
            isOptionalHeader  = (sectionType == "optional"),
            isCollapsible    = true,
        }
    end
    local byName, order = {}, {}
    for _, r in ipairs(raw) do
        local key = r.name or ("item:" .. tostring(r.itemID))
        if not byName[key] then
            byName[key] = { name = r.name, itemID = r.itemID, link = r.link, owned = 0, qtyRequired = r.qtyRequired, itemQuality = r.itemQuality }
            order[#order + 1] = key
        end
        byName[key].owned = byName[key].owned + r.owned
        if r.itemID > (byName[key].itemID or 0) then
            byName[key].itemID = r.itemID
            byName[key].link = r.link
            byName[key].itemQuality = r.itemQuality
        end
        if r.qtyRequired > (byName[key].qtyRequired or 0) then
            byName[key].qtyRequired = r.qtyRequired
        end
    end
    for _, key in ipairs(order) do
        local agg = byName[key]
        local obj = {
            text         = agg.name,
            numFulfilled = agg.owned,
            numRequired  = agg.qtyRequired,
            itemID       = agg.itemID,
            itemLink     = agg.link,
            itemQuality  = agg.itemQuality,
            finished     = (agg.owned >= (agg.qtyRequired or 1)),
        }
        if sectionType == "finishing" then obj.isFinishingReagent = true end
        if sectionType == "optional" then obj.isOptionalReagent = true end
        objectives[#objectives + 1] = obj
    end
end

--- Build reagent objectives for a recipe (shopping list: owned vs required from bags, bank, warband bank).
-- Basic reagents shown first; Finishing reagents in a separate section. Quality-tier variants deduplicated.
-- @param recipeID number Recipe spell ID
-- @param isRecraft boolean
-- @return table Array of { text, numFulfilled, numRequired, itemID, itemLink, finished } or { text, isSectionHeader }
local function BuildRecipeObjectives(recipeID, isRecraft)
    local objectives = {}
    if not addon.GetDB("showRecipeReagents", true) then return objectives end
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeSchematic then return objectives end

    local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, isRecraft, nil)
    if not ok or not schematic or type(schematic) ~= "table" or not schematic.reagentSlotSchematics then
        return objectives
    end

    local getItemCount = (C_Item and C_Item.GetItemCount)
    local optionalHeader = (addon.L and addon.L["Optional reagents"]) or "Optional reagents"
    local finishingHeader = (addon.L and addon.L["Finishing reagents"]) or "Finishing reagents"
    local showOptional = addon.GetDB("showOptionalReagents", true)
    local showFinishing = addon.GetDB("showFinishingReagents", true)
    local showChoiceSlots = addon.GetDB("showChoiceSlots", true)

    -- Choice slot: qtyRequired==1 and multiple reagents (e.g. "Algari Missive" variants) — show as collapsible "1 of any"
    local function isChoiceSlot(slot)
        local reagents = slot and slot.reagents
        local qty = slot and (slot.quantityRequired or 1)
        return reagents and type(reagents) == "table" and #reagents > 1 and qty == 1
    end

    local function deriveBaseName(firstName)
        if not firstName or firstName == "" then return "Item (any)" end
        local base = firstName:gsub(" of the .+$", "")
        return (base ~= firstName) and (base .. " (any)") or (firstName .. " (any)")
    end

    -- Collect raw reagents; choice slots go to a separate list for collapsible treatment
    -- Basic = required; Modifying = optional; Finishing = finishing
    local requiredRaw, optionalRaw, finishingRaw, choiceSlots = {}, {}, {}, {}
    for slotIdx, slot in ipairs(schematic.reagentSlotSchematics) do
        local reagentType = slot.reagentType
        local reagents = slot.reagents
        local qtyRequired = slot.quantityRequired or 1
        if reagents and type(reagents) == "table" then
            if isChoiceSlot(slot) then
                local variants, totalOwned = {}, 0
                for _, reagent in ipairs(reagents) do
                    local itemID = reagent and reagent.itemID
                    if type(itemID) == "number" and itemID > 0 then
                        local name, link, itemQuality = GetItemInfo(itemID)
                        if not link and Item and Item.CreateFromItemID then
                            local item = Item:CreateFromItemID(itemID)
                            if item and item.GetItemLink then link = item:GetItemLink() end
                        end
                        name = name or (link and link:match("%[(.-)%]")) or ("Item " .. tostring(itemID))
                        link = link or ("item:" .. tostring(itemID))
                        local owned = 0
                        if getItemCount then
                            local countOk, count = pcall(getItemCount, itemID, true, false, true, true)
                            if countOk and type(count) == "number" then owned = count end
                        end
                        totalOwned = totalOwned + owned
                        variants[#variants + 1] = { text = name, itemID = itemID, itemLink = link, numFulfilled = owned, numRequired = 1, itemQuality = itemQuality, finished = (owned >= 1) }
                    end
                end
                if #variants > 0 then
                    local first = variants[1]
                    choiceSlots[#choiceSlots + 1] = {
                        choiceSlotKey = "recipe:" .. tostring(recipeID) .. ":slot:" .. tostring(slotIdx),
                        baseName = deriveBaseName(first.text),
                        numFulfilled = totalOwned,
                        numRequired = 1,
                        finished = (totalOwned >= 1),
                        variants = variants,
                    }
                end
            else
                local target
                if reagentType == REAGENT_TYPE_FINISHING then
                    target = finishingRaw
                elseif reagentType == REAGENT_TYPE_MODIFYING then
                    target = optionalRaw
                else
                    target = requiredRaw  -- Basic
                end
                if reagentType == REAGENT_TYPE_BASIC or reagentType == REAGENT_TYPE_MODIFYING or reagentType == REAGENT_TYPE_FINISHING then
                    for _, reagent in ipairs(reagents) do
                        local itemID = reagent and reagent.itemID
                        if type(itemID) == "number" and itemID > 0 then
                            local name, link, itemQuality = GetItemInfo(itemID)
                            if not link and Item and Item.CreateFromItemID then
                                local item = Item:CreateFromItemID(itemID)
                                if item and item.GetItemLink then link = item:GetItemLink() end
                            end
                            name = name or (link and link:match("%[(.-)%]")) or ("Item " .. tostring(itemID))
                            link = link or ("item:" .. tostring(itemID))
                            local owned = 0
                            if getItemCount then
                                local countOk, count = pcall(getItemCount, itemID, true, false, true, true)
                                if countOk and type(count) == "number" then owned = count end
                            end
                            target[#target + 1] = { name = name, itemID = itemID, link = link, owned = owned, qtyRequired = qtyRequired, itemQuality = itemQuality }
                        end
                    end
                end
            end
        end
    end

    DedupeAndAppend(requiredRaw, objectives, nil, nil)
    -- Choice slots: collapsible (header + variants) or flat list of variants
    for _, cs in ipairs(choiceSlots) do
        if showChoiceSlots then
            objectives[#objectives + 1] = {
                isChoiceHeader = true,
                isCollapsible = true,
                choiceSlotKey = cs.choiceSlotKey,
                text = cs.baseName,
                numFulfilled = cs.numFulfilled,
                numRequired = cs.numRequired,
                finished = cs.finished,
                variants = cs.variants,
            }
            for _, v in ipairs(cs.variants) do
                objectives[#objectives + 1] = {
                    isChoiceVariant = true,
                    choiceSlotKey = cs.choiceSlotKey,
                    text = v.text,
                    numFulfilled = v.numFulfilled,
                    numRequired = v.numRequired,
                    itemID = v.itemID,
                    itemLink = v.itemLink,
                    itemQuality = v.itemQuality,
                    finished = v.finished,
                }
            end
        else
            -- Flat list: add each variant as a normal reagent
            for _, v in ipairs(cs.variants) do
                objectives[#objectives + 1] = {
                    text = v.text,
                    numFulfilled = v.numFulfilled,
                    numRequired = v.numRequired,
                    itemID = v.itemID,
                    itemLink = v.itemLink,
                    itemQuality = v.itemQuality,
                    finished = v.finished,
                }
            end
        end
    end
    if showOptional and #optionalRaw > 0 then
        DedupeAndAppend(optionalRaw, objectives, optionalHeader, "optional")
    end
    if showFinishing and #finishingRaw > 0 then
        DedupeAndAppend(finishingRaw, objectives, finishingHeader, "finishing")
    end

    return objectives
end

--- Get recipe output item quality for rarity coloring.
-- Tries GetRecipeQualityItemIDs, GetRecipeOutputItemData, GetFactionSpecificOutputItem, then schematic output.
-- @param recipeID number Recipe spell ID
-- @param isRecraft boolean|nil If true, use recraft schematic
-- @return number|nil Item quality (0-7) or nil if unavailable
local function GetRecipeOutputQuality(recipeID, isRecraft)
    if not C_TradeSkillUI then return nil end

    -- 1. GetRecipeQualityItemIDs: table of itemIDs per quality tier (may be sparse)
    if C_TradeSkillUI.GetRecipeQualityItemIDs then
        local ok, qualityItemIDs = pcall(C_TradeSkillUI.GetRecipeQualityItemIDs, recipeID)
        if ok and qualityItemIDs and type(qualityItemIDs) == "table" then
            for i = 1, 8 do
                local itemID = qualityItemIDs[i]
                if type(itemID) == "number" and itemID > 0 then
                    local _, _, itemQuality = GetItemInfo(itemID)
                    if type(itemQuality) == "number" then return itemQuality end
                end
            end
            -- Sparse table: try pairs in case keys are non-sequential
            for _, itemID in pairs(qualityItemIDs) do
                if type(itemID) == "number" and itemID > 0 then
                    local _, _, itemQuality = GetItemInfo(itemID)
                    if type(itemQuality) == "number" then return itemQuality end
                end
            end
        end
    end

    -- 2. GetRecipeOutputItemData: outputInfo has itemID or itemLink for default output
    if C_TradeSkillUI.GetRecipeOutputItemData then
        local ok, outputInfo = pcall(C_TradeSkillUI.GetRecipeOutputItemData, recipeID, nil, nil, nil, nil)
        if ok and outputInfo and type(outputInfo) == "table" then
            for _, key in ipairs({ "itemID", "outputItemID", "item" }) do
                local v = outputInfo[key]
                if type(v) == "number" and v > 0 then
                    local _, _, itemQuality = GetItemInfo(v)
                    if type(itemQuality) == "number" then return itemQuality end
                end
            end
            local link = outputInfo.itemLink or outputInfo.link
            if link and type(link) == "string" then
                local itemID = link:match("item:(%d+)")
                if itemID then
                    local _, _, itemQuality = GetItemInfo(tonumber(itemID))
                    if type(itemQuality) == "number" then return itemQuality end
                end
                local _, _, itemQuality = GetItemInfo(link)
                if type(itemQuality) == "number" then return itemQuality end
            end
        end
    end

    -- 3. GetFactionSpecificOutputItem: single output item for faction-specific recipes
    if C_TradeSkillUI.GetFactionSpecificOutputItem then
        local ok, itemID = pcall(C_TradeSkillUI.GetFactionSpecificOutputItem, recipeID)
        if ok and type(itemID) == "number" and itemID > 0 then
            local _, _, itemQuality = GetItemInfo(itemID)
            if type(itemQuality) == "number" then return itemQuality end
        end
    end

    -- 4. GetRecipeSchematic: schematic may have outputSlotSchematic with itemID
    if C_TradeSkillUI.GetRecipeSchematic then
        for _, isRecraft in ipairs({ false, true }) do
            local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, isRecraft, nil)
            if ok and schematic and type(schematic) == "table" then
                local outputSlot = schematic.outputSlotSchematic or schematic.outputSlot
                if outputSlot and type(outputSlot) == "table" then
                    local itemID = outputSlot.itemID or (outputSlot.reagents and outputSlot.reagents[1] and outputSlot.reagents[1].itemID)
                    if type(itemID) == "number" and itemID > 0 then
                        local _, _, itemQuality = GetItemInfo(itemID)
                        if type(itemQuality) == "number" then return itemQuality end
                    end
                end
            end
        end
    end

    return nil
end

--- Get recipe display info. Uses C_TradeSkillUI.GetRecipeInfo or GetProfessionInfoByRecipeID fallback.
-- @param recipeID number
-- @return string name, number|string icon
local function GetRecipeDisplayInfo(recipeID)
    -- C_TradeSkillUI.GetRecipeInfo(recipeSpellID, recipeLevel) - recipeID often equals recipeSpellID
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, recipeInfo = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and recipeInfo and type(recipeInfo) == "table" then
            local name = recipeInfo.name
            if name and name ~= "" then
                local icon = recipeInfo.icon
                return name, icon
            end
        end
    end
    -- Fallback: profession name + recipe ID
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoByRecipeID then
        local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoByRecipeID, recipeID)
        if ok and info and type(info) == "table" and info.professionName then
            return info.professionName .. " — Recipe #" .. tostring(recipeID), nil
        end
    end
    return "Recipe " .. tostring(recipeID), nil
end

--- Build synthetic objectives for the recipe debug example (all sections: required, choice slots, optional, finishing).
-- @return table Array of objective tables
local function BuildExampleRecipeObjectives()
    local optionalHeader = (addon.L and addon.L["Optional reagents"]) or "Optional reagents"
    local finishingHeader = (addon.L and addon.L["Finishing reagents"]) or "Finishing reagents"
    local showOptional = addon.GetDB("showOptionalReagents", true)
    local showFinishing = addon.GetDB("showFinishingReagents", true)
    local showChoiceSlots = addon.GetDB("showChoiceSlots", true)
    local choiceSlotKey = "recipe:0:slot:1"
    local obj = {}
    -- Required
    obj[#obj + 1] = { text = "Sanctified Alloy", numFulfilled = 0, numRequired = 6, finished = false }
    obj[#obj + 1] = { text = "Ironclaw Alloy", numFulfilled = 0, numRequired = 12, finished = false }
    -- Choice slot
    if showChoiceSlots then
        obj[#obj + 1] = { isChoiceHeader = true, isCollapsible = true, choiceSlotKey = choiceSlotKey, text = "Forged Framework (any)", numFulfilled = 0, numRequired = 1, finished = false }
        obj[#obj + 1] = { isChoiceVariant = true, choiceSlotKey = choiceSlotKey, text = "Forged Framework", numFulfilled = 0, numRequired = 1, finished = false }
        obj[#obj + 1] = { isChoiceVariant = true, choiceSlotKey = choiceSlotKey, text = "Tempered Framework", numFulfilled = 0, numRequired = 1, finished = false }
        obj[#obj + 1] = { isChoiceVariant = true, choiceSlotKey = choiceSlotKey, text = "Adjustable Framework", numFulfilled = 0, numRequired = 1, finished = false }
    else
        obj[#obj + 1] = { text = "Forged Framework", numFulfilled = 0, numRequired = 1, finished = false }
        obj[#obj + 1] = { text = "Tempered Framework", numFulfilled = 0, numRequired = 1, finished = false }
        obj[#obj + 1] = { text = "Adjustable Framework", numFulfilled = 0, numRequired = 1, finished = false }
    end
    -- Optional
    if showOptional then
        obj[#obj + 1] = { text = optionalHeader, isSectionHeader = true, isOptionalHeader = true, isCollapsible = true }
        obj[#obj + 1] = { text = "Quality Missive", numFulfilled = 0, numRequired = 1, isOptionalReagent = true, finished = false }
    end
    -- Finishing
    if showFinishing then
        obj[#obj + 1] = { text = finishingHeader, isSectionHeader = true, isFinishingHeader = true, isCollapsible = true }
        obj[#obj + 1] = { text = "Primal Flux", numFulfilled = 0, numRequired = 5, isFinishingReagent = true, finished = false }
        obj[#obj + 1] = { text = "Optional Finishing Reagent", numFulfilled = 0, numRequired = 1, isFinishingReagent = true, finished = false }
    end
    return obj
end

--- Build tracker rows from WoW tracked profession recipes.
-- @return table Array of normalized entry tables for the tracker
local function ReadTrackedRecipes()
    local out = {}
    if not addon.GetDB("showRecipes", true) then return out end

    -- Debug: inject example recipe with all sections into the tracker
    if addon.testRecipeExample then
        local recipeColor = (addon.GetQuestColor and addon.GetQuestColor("RECIPE")) or (addon.QUEST_COLORS and addon.QUEST_COLORS.RECIPE) or { 0.55, 0.75, 0.45 }
        out[#out + 1] = {
            entryKey        = "recipe:debug-example",
            recipeID        = 0,
            recipeIsRecraft = false,
            questID         = nil,
            title           = "[Debug] Example: All Reagent Sections",
            objectives      = BuildExampleRecipeObjectives(),
            color           = recipeColor,
            outputQuality   = 3,
            category        = "RECIPE",
            isComplete      = false,
            isSuperTracked  = false,
            isNearby        = false,
            zoneName        = nil,
            itemLink        = nil,
            itemTexture     = nil,
            isRecipe        = true,
            isTracked       = true,
            recipeIcon      = "Interface\\Icons\\inv_misc_questionmark",
        }
    end

    local idList = GetTrackedRecipeIDs()
    if #idList == 0 then return out end

    local recipeColor = (addon.GetQuestColor and addon.GetQuestColor("RECIPE")) or (addon.QUEST_COLORS and addon.QUEST_COLORS.RECIPE) or { 0.55, 0.75, 0.45 }

    for _, item in ipairs(idList) do
        local recipeID = (type(item) == "table" and item.recipeID) or item
        local isRecraft = (type(item) == "table" and item.isRecraft == true) or false
        if type(recipeID) == "number" and recipeID > 0 then
            local name, icon = GetRecipeDisplayInfo(recipeID)
            local recipeIcon = (icon and (type(icon) == "number" or (type(icon) == "string" and icon ~= ""))) and icon or nil
            local objectives = BuildRecipeObjectives(recipeID, isRecraft)
            local outputQuality = GetRecipeOutputQuality(recipeID, isRecraft)
            out[#out + 1] = {
                entryKey        = "recipe:" .. tostring(recipeID),
                recipeID        = recipeID,
                recipeIsRecraft = isRecraft,
                questID        = nil,
                title          = name or ("Recipe " .. tostring(recipeID)),
                objectives     = objectives,
                color          = recipeColor,
                outputQuality  = outputQuality,
                category       = "RECIPE",
                isComplete     = false,
                isSuperTracked = false,
                isNearby       = false,
                zoneName       = nil,
                itemLink       = nil,
                itemTexture    = nil,
                isRecipe       = true,
                isTracked      = true,
                recipeIcon     = recipeIcon,
            }
        end
    end

    return out
end

--- Debug: dump recipe reagent structure to chat. Use /horizon recipedebug [recipeID]
-- When recipeID given, dumps that recipe. Otherwise dumps all tracked recipes.
-- Shows raw counts (required, optional, choice slots, finishing) and built objectives with flags.
-- @param recipeID number|nil Optional specific recipe spell ID
local function DebugRecipeReagents(recipeID)
    local HSPrint = _G.HSPrint or print
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeSchematic then
        HSPrint("C_TradeSkillUI.GetRecipeSchematic not available.")
        return
    end
    local targets = {}
    if recipeID and type(recipeID) == "number" and recipeID > 0 then
        targets[#targets + 1] = { recipeID = recipeID, isRecraft = false }
    else
        targets = GetTrackedRecipeIDs()
    end
    if #targets == 0 then
        HSPrint("No tracked recipes. Track some in the profession UI, or use: /horizon recipedebug 12345")
        HSPrint("")
        HSPrint("Example recipe with ALL sections (required, optional, choice slots, finishing):")
        HSPrint("  Raw: required=2 optional=1 choiceSlots=1 finishing=2")
        HSPrint("    required: Sanctified Alloy, Ironclaw Alloy")
        HSPrint("    optional: Quality Missive")
        HSPrint("    choiceSlot 1: Forged Framework (4 variants)")
        HSPrint("    finishing: Primal Flux, Optional Finishing Reagent")
        HSPrint("  Built objectives (with showOptional/showFinishing/showChoiceSlots on):")
        HSPrint("    1: Sanctified Alloy [required]")
        HSPrint("    2: Ironclaw Alloy [required]")
        HSPrint("    3: Forged Framework (any) [choiceHeader]")
        HSPrint("    4-7: Forged Framework, Tempered Framework... [choiceVariant]")
        HSPrint("    8: Optional reagents [optionalHeader]")
        HSPrint("    9: Quality Missive [optionalReagent]")
        HSPrint("   10: Finishing reagents [finishingHeader]")
        HSPrint("   11-12: Primal Flux, Optional Finishing [finishingReagent]")
        return
    end
    local showOptional = addon.GetDB("showOptionalReagents", true)
    local showFinishing = addon.GetDB("showFinishingReagents", true)
    local showChoiceSlots = addon.GetDB("showChoiceSlots", true)
    HSPrint("--- Recipe Reagent Debug ---")
    HSPrint("Options: showOptional=" .. tostring(showOptional) .. " showFinishing=" .. tostring(showFinishing) .. " showChoiceSlots=" .. tostring(showChoiceSlots))
    for _, item in ipairs(targets) do
        local rid = item.recipeID
        local isRecraft = item.isRecraft
        local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, rid, isRecraft, nil)
        if not ok or not schematic or type(schematic) ~= "table" or not schematic.reagentSlotSchematics then
            HSPrint("  Recipe " .. rid .. (isRecraft and " (recraft)" or "") .. ": no schematic")
        else
        local name = GetRecipeDisplayInfo(rid)
        HSPrint("  Recipe " .. rid .. (isRecraft and " (recraft)" or "") .. ": " .. tostring(name))
        local requiredRaw, optionalRaw, finishingRaw, choiceSlots = {}, {}, {}, {}
        local function isChoiceSlot(slot)
            local reagents = slot and slot.reagents
            local qty = slot and (slot.quantityRequired or 1)
            return reagents and type(reagents) == "table" and #reagents > 1 and qty == 1
        end
        for slotIdx, slot in ipairs(schematic.reagentSlotSchematics) do
            local reagentType = slot and slot.reagentType
            local reagents = slot and slot.reagents
            local qtyRequired = slot and (slot.quantityRequired or 1) or 1
            if reagents and type(reagents) == "table" then
                if isChoiceSlot(slot) then
                    local first = reagents[1] and type(reagents[1].itemID) == "number" and GetItemInfo(reagents[1].itemID)
                    local name = first or ("item:" .. tostring(reagents[1] and reagents[1].itemID))
                    choiceSlots[#choiceSlots + 1] = name .. " (" .. #reagents .. " variants)"
                else
                    local target
                    if reagentType == REAGENT_TYPE_FINISHING then target = finishingRaw
                    elseif reagentType == REAGENT_TYPE_MODIFYING then target = optionalRaw
                    else target = requiredRaw end
                    for _, r in ipairs(reagents) do
                        if r and type(r.itemID) == "number" and r.itemID > 0 then
                            local n = (GetItemInfo(r.itemID))
                            target[#target + 1] = n or ("item:" .. r.itemID)
                        end
                    end
                end
            end
        end
        HSPrint("    Raw: required=" .. #requiredRaw .. " optional=" .. #optionalRaw .. " choiceSlots=" .. #choiceSlots .. " finishing=" .. #finishingRaw)
        if #choiceSlots > 0 then
            for i, cs in ipairs(choiceSlots) do
                HSPrint("      choiceSlot " .. i .. ": " .. tostring(cs))
            end
        end
        if #requiredRaw > 0 then
            local names = {}
            for i = 1, math.min(3, #requiredRaw) do names[i] = tostring(requiredRaw[i]) end
            HSPrint("      required: " .. table.concat(names, ", ") .. (#requiredRaw > 3 and " ..." or ""))
        end
        if #optionalRaw > 0 then
            local names = {}
            for i = 1, math.min(3, #optionalRaw) do names[i] = tostring(optionalRaw[i]) end
            HSPrint("      optional: " .. table.concat(names, ", ") .. (#optionalRaw > 3 and " ..." or ""))
        end
        if #finishingRaw > 0 then
            local names = {}
            for i = 1, math.min(3, #finishingRaw) do names[i] = tostring(finishingRaw[i]) end
            HSPrint("      finishing: " .. table.concat(names, ", ") .. (#finishingRaw > 3 and " ..." or ""))
        end
        local objectives = BuildRecipeObjectives(rid, isRecraft)
        HSPrint("    Built objectives: " .. #objectives)
        for i, o in ipairs(objectives) do
            local flags = {}
            if o.isChoiceHeader then flags[#flags + 1] = "choiceHeader" end
            if o.isChoiceVariant then flags[#flags + 1] = "choiceVariant" end
            if o.isOptionalHeader then flags[#flags + 1] = "optionalHeader" end
            if o.isOptionalReagent then flags[#flags + 1] = "optionalReagent" end
            if o.isFinishingHeader then flags[#flags + 1] = "finishingHeader" end
            if o.isFinishingReagent then flags[#flags + 1] = "finishingReagent" end
            local flagStr = #flags > 0 and (" [" .. table.concat(flags, ",") .. "]") or ""
            HSPrint("      " .. i .. ": " .. tostring(o.text or "(no text)") .. flagStr)
        end
        end
    end
    HSPrint("--- End Recipe Reagent Debug ---")
end

addon.GetTrackedRecipeIDs = GetTrackedRecipeIDs
addon.ReadTrackedRecipes = ReadTrackedRecipes
addon.DebugRecipeReagents = DebugRecipeReagents
