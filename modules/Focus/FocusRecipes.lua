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
                -- Key includes isRecraft so the same recipe can appear as both normal and recraft
                local seenKey = tostring(id) .. (isRecraft and ":r" or "")
                if type(id) == "number" and id > 0 and not seen[seenKey] then
                    seen[seenKey] = true
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
        local key = r.name or (r.currencyID and ("currency:" .. tostring(r.currencyID))) or ("item:" .. tostring(r.itemID))
        if not byName[key] then
            byName[key] = { name = r.name, itemID = r.itemID, currencyID = r.currencyID, link = r.link, owned = 0, qtyRequired = r.qtyRequired, itemQuality = r.itemQuality }
            order[#order + 1] = key
        end
        byName[key].owned = byName[key].owned + r.owned
        if r.itemID and r.itemID > (byName[key].itemID or 0) then
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
            currencyID   = agg.currencyID,
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

    -- Derives the choice slot header text from all deduplicated variant names.
    -- Uses longest common prefix if >=4 chars, otherwise falls back to first name.
    local function deriveChoiceBaseName(dedupedVariants)
        if #dedupedVariants == 0 then return "Item (any)" end
        if #dedupedVariants == 1 then return deriveBaseName(dedupedVariants[1].text) end
        local prefix = dedupedVariants[1].text or ""
        for i = 2, #dedupedVariants do
            local name = dedupedVariants[i].text or ""
            local newLen = 0
            for j = 1, math.min(#prefix, #name) do
                if prefix:sub(j, j) == name:sub(j, j) then newLen = j else break end
            end
            prefix = prefix:sub(1, newLen)
        end
        prefix = prefix:gsub("[^%a]+$", ""):match("^%s*(.-)%s*$") or ""
        if #prefix >= 4 then return prefix .. " (any)" end
        return (dedupedVariants[1].text or "Item") .. " (any)"
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
                        -- If item data wasn't cached, request a background load so next refresh shows the real name
                        if (not name or name:sub(1, 5) == "Item ") and C_Item and C_Item.RequestLoadItemDataByID then
                            C_Item.RequestLoadItemDataByID(itemID)
                        end
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
                -- Deduplicate by display name: quality-tier variants share a name but have distinct itemIDs.
                -- Merge same-named entries: sum owned counts; prefer highest-quality itemID for display.
                if #variants > 1 then
                    local byName, nameOrder = {}, {}
                    for _, v in ipairs(variants) do
                        local key = v.text
                        if not byName[key] then
                            byName[key] = { text = v.text, itemID = v.itemID, itemLink = v.itemLink,
                                            numFulfilled = v.numFulfilled, numRequired = v.numRequired,
                                            itemQuality = v.itemQuality, finished = false }
                            nameOrder[#nameOrder + 1] = key
                        else
                            local agg = byName[key]
                            agg.numFulfilled = agg.numFulfilled + v.numFulfilled
                            local vQ = v.itemQuality or -1
                            local aQ = agg.itemQuality or -1
                            if vQ > aQ then
                                agg.itemID, agg.itemLink, agg.itemQuality = v.itemID, v.itemLink, v.itemQuality
                            end
                        end
                    end
                    variants = {}
                    for _, key in ipairs(nameOrder) do
                        local agg = byName[key]
                        agg.finished = (agg.numFulfilled >= 1)
                        variants[#variants + 1] = agg
                    end
                end
                -- Recalculate totalOwned from deduped list
                totalOwned = 0
                for _, v in ipairs(variants) do totalOwned = totalOwned + v.numFulfilled end
                if #variants > 0 then
                    choiceSlots[#choiceSlots + 1] = {
                        choiceSlotKey = "recipe:" .. tostring(recipeID) .. ":slot:" .. tostring(slotIdx),
                        baseName = deriveChoiceBaseName(variants),
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
                        elseif type(reagent and reagent.currencyID) == "number" and reagent.currencyID > 0 then
                            local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(reagent.currencyID)
                            if info then
                                local owned = info.quantity or 0
                                target[#target + 1] = { name = info.name, itemID = nil, currencyID = reagent.currencyID, link = nil, owned = owned, qtyRequired = qtyRequired }
                            end
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

--- Build unmet crafting station requirements for a recipe as objectives.
-- Only called when showRecipeRequirements is enabled. Returns unmet requirements only.
-- @param recipeID number Recipe spell ID
-- @return table Array of { text, isRequirement = true, finished = false }
local function BuildRecipeRequirements(recipeID)
    local out = {}
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeRequirements then return out end
    local ok, reqs = pcall(C_TradeSkillUI.GetRecipeRequirements, recipeID)
    if not ok or type(reqs) ~= "table" then return out end
    for _, req in ipairs(reqs) do
        if req and req.met == false and type(req.name) == "string" and req.name ~= "" then
            out[#out + 1] = {
                text         = "Requires: " .. req.name,
                isRequirement = true,
                finished     = false,
                numFulfilled = 0,
                numRequired  = 1,
            }
        end
    end
    return out
end

--- Get recipe output item quality for rarity coloring.
-- Tries GetRecipeQualityItemIDs, GetRecipeOutputItemData, GetFactionSpecificOutputItem, then schematic output.
-- @param recipeID number Recipe spell ID
-- @param isRecraft boolean|nil If true, use recraft schematic
-- @return number|nil Item quality (0-7) or nil if unavailable
local function GetRecipeOutputQuality(recipeID, isRecraft)
    if not C_TradeSkillUI then return nil end

    -- 0. Direct schematic fields (fastest path)
    if C_TradeSkillUI.GetRecipeSchematic then
        local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, isRecraft or false, nil)
        if ok and schematic and type(schematic) == "table" then
            -- 0a. schematic.productQuality is the direct crafting quality number
            if type(schematic.productQuality) == "number" and schematic.productQuality > 0 then
                return schematic.productQuality
            end
            -- 0b. schematic.outputItemID -> item quality via GetItemInfo
            if type(schematic.outputItemID) == "number" and schematic.outputItemID > 0 then
                local _, _, itemQuality = GetItemInfo(schematic.outputItemID)
                if type(itemQuality) == "number" then return itemQuality end
            end
        end
    end

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
-- @return string name, number|string icon, boolean supportsQualities, number maxQuality, boolean firstCraft
local function GetRecipeDisplayInfo(recipeID)
    -- C_TradeSkillUI.GetRecipeInfo(recipeSpellID, recipeLevel) - recipeID often equals recipeSpellID
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, recipeInfo = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and recipeInfo and type(recipeInfo) == "table" then
            local name = recipeInfo.name
            if name and name ~= "" then
                local icon = recipeInfo.icon
                local supportsQualities = recipeInfo.supportsQualities == true
                local maxQuality = type(recipeInfo.maxQuality) == "number" and recipeInfo.maxQuality or nil
                local firstCraft = recipeInfo.firstCraft == true
                return name, icon, supportsQualities, maxQuality, firstCraft
            end
        end
    end
    -- Fallback: profession name + recipe ID
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoByRecipeID then
        local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoByRecipeID, recipeID)
        if ok and info and type(info) == "table" and info.professionName then
            return info.professionName .. " — Recipe #" .. tostring(recipeID), nil, false, nil, false
        end
    end
    return "Recipe " .. tostring(recipeID), nil, false, nil, false
end

--- Build synthetic objectives for the recipe debug example (all sections: required, choice slots, optional, finishing).
-- @return table Array of objective tables
local function BuildExampleRecipeObjectives()
    local optionalHeader = (addon.L and addon.L["Optional reagents"]) or "Optional reagents"
    local finishingHeader = (addon.L and addon.L["Finishing reagents"]) or "Finishing reagents"
    local showOptional = addon.GetDB("showOptionalReagents", true)
    local showFinishing = addon.GetDB("showFinishingReagents", true)
    local showChoiceSlots = addon.GetDB("showChoiceSlots", true)
    local showRequirements = addon.GetDB("showRecipeRequirements", false)
    local showCraftableCount = addon.GetDB("showCraftableCount", false)
    local showQualityInfo = addon.GetDB("showRecipeQualityInfo", false)
    local choiceSlotKey = "recipe:0:slot:1"
    local obj = {}
    -- Unmet requirements (if enabled)
    if showRequirements then
        obj[#obj + 1] = { text = "Requires: Forge", isRequirement = true, finished = false, numFulfilled = 0, numRequired = 1 }
    end
    -- Craftable count (if enabled)
    if showCraftableCount then
        obj[#obj + 1] = { text = "Can craft: 2", isCraftableCount = true, finished = true, numFulfilled = 1, numRequired = 1 }
    end
    -- Quality tier indicator (if enabled)
    if showQualityInfo then
        obj[#obj + 1] = { text = "Quality: ★ ★ ★ (1–3)", isQualityInfo = true, finished = true, numFulfilled = 1, numRequired = 1 }
    end
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

    local showRequirements = addon.GetDB("showRecipeRequirements", false)
    local showCraftableCount = addon.GetDB("showCraftableCount", false)
    local showQualityInfo = addon.GetDB("showRecipeQualityInfo", false)

    for _, item in ipairs(idList) do
        local recipeID = (type(item) == "table" and item.recipeID) or item
        local isRecraft = (type(item) == "table" and item.isRecraft == true) or false
        if type(recipeID) == "number" and recipeID > 0 then
            local name, icon, supportsQualities, maxQuality, firstCraft = GetRecipeDisplayInfo(recipeID)
            local recipeIcon = (icon and (type(icon) == "number" or (type(icon) == "string" and icon ~= ""))) and icon or nil
            local objectives = BuildRecipeObjectives(recipeID, isRecraft)
            local outputQuality = GetRecipeOutputQuality(recipeID, isRecraft)

            -- Prepend unmet requirements (if enabled)
            if showRequirements then
                local reqs = BuildRecipeRequirements(recipeID)
                if #reqs > 0 then
                    local merged = {}
                    for _, r in ipairs(reqs) do merged[#merged + 1] = r end
                    for _, o in ipairs(objectives) do merged[#merged + 1] = o end
                    objectives = merged
                end
            end

            -- Craftable count (if enabled)
            local craftableCount = nil
            if showCraftableCount and C_TradeSkillUI and C_TradeSkillUI.GetCraftableCount then
                local ok, count = pcall(C_TradeSkillUI.GetCraftableCount, recipeID)
                if ok and type(count) == "number" then
                    craftableCount = count
                    table.insert(objectives, 1, {
                        text = "Can craft: " .. tostring(count),
                        isCraftableCount = true,
                        finished = true,
                        numFulfilled = 1,
                        numRequired = 1,
                    })
                end
            end

            -- Quality tier indicator (if enabled and recipe supports qualities)
            if showQualityInfo and supportsQualities and maxQuality and maxQuality > 0 then
                local stars = string.rep("★ ", maxQuality):gsub(" $", "")
                table.insert(objectives, 1, {
                    text = "Quality: " .. stars .. " (1–" .. tostring(maxQuality) .. ")",
                    isQualityInfo = true,
                    finished = true,
                    numFulfilled = 1,
                    numRequired = 1,
                })
            end

            out[#out + 1] = {
                -- Include recraft suffix so normal and recraft can coexist without key collision
                entryKey           = "recipe:" .. tostring(recipeID) .. (isRecraft and ":recraft" or ""),
                recipeID           = recipeID,
                recipeIsRecraft    = isRecraft,
                questID            = nil,
                title              = name or ("Recipe " .. tostring(recipeID)),
                objectives         = objectives,
                color              = recipeColor,
                outputQuality      = outputQuality,
                category           = "RECIPE",
                isComplete         = false,
                isSuperTracked     = false,
                isNearby           = false,
                zoneName           = nil,
                itemLink           = nil,
                itemTexture        = nil,
                isRecipe           = true,
                isTracked          = true,
                recipeIcon         = recipeIcon,
                supportsQualities  = supportsQualities,
                maxQuality         = maxQuality,
                firstCraft         = firstCraft,
                craftableCount     = craftableCount,
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
    local showRequirements = addon.GetDB("showRecipeRequirements", false)
    local showCraftableCount = addon.GetDB("showCraftableCount", false)
    local showQualityInfo = addon.GetDB("showRecipeQualityInfo", false)
    HSPrint("--- Recipe Reagent Debug ---")
    HSPrint("Options: showOptional=" .. tostring(showOptional) .. " showFinishing=" .. tostring(showFinishing) .. " showChoiceSlots=" .. tostring(showChoiceSlots))
    HSPrint("         showRequirements=" .. tostring(showRequirements) .. " showCraftableCount=" .. tostring(showCraftableCount) .. " showQualityInfo=" .. tostring(showQualityInfo))
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
                    local rawCount = #reagents
                    local namesSeen, uniqueNames, nameToIDs = {}, {}, {}
                    for _, r in ipairs(reagents) do
                        if r and type(r.itemID) == "number" and r.itemID > 0 then
                            local n = GetItemInfo(r.itemID) or ("item:" .. r.itemID)
                            if not namesSeen[n] then namesSeen[n] = true; uniqueNames[#uniqueNames + 1] = n; nameToIDs[n] = {} end
                            nameToIDs[n][#nameToIDs[n] + 1] = r.itemID
                        end
                    end
                    local firstName = uniqueNames[1] or "?"
                    local dedupNote = (rawCount ~= #uniqueNames)
                        and ("[DEDUP: " .. rawCount .. " raw -> " .. #uniqueNames .. " unique]")
                        or ("[" .. rawCount .. " variants, all unique]")
                    choiceSlots[#choiceSlots + 1] = firstName .. " " .. dedupNote
                    for _, uName in ipairs(uniqueNames) do
                        local ids = {}
                        for _, id in ipairs(nameToIDs[uName]) do ids[#ids + 1] = tostring(id) end
                        choiceSlots[#choiceSlots + 1] = "  " .. uName .. " [" .. table.concat(ids, ",") .. "]"
                    end
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
            if o.isRequirement then flags[#flags + 1] = "requirement" end
            if o.isCraftableCount then flags[#flags + 1] = "craftableCount" end
            if o.isQualityInfo then flags[#flags + 1] = "qualityInfo" end
            if o.currencyID then flags[#flags + 1] = "currency:" .. tostring(o.currencyID) end
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
