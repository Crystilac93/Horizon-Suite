--[[
    Horizon Suite - Focus - Recipe Tracking
    C_TradeSkillUI data provider for tracked profession recipes.
    When the player tracks a recipe in the profession UI, it appears in the tracker.
]]

local addon = _G.HorizonSuite

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

--- Build reagent objectives for a recipe (shopping list: owned vs required from bags, bank, warband bank).
-- Quality-tier variants (same item name, different itemIDs) are deduplicated: one line per unique name,
-- with owned = sum across all quality tiers, and copy link = highest-quality itemID.
-- @param recipeID number Recipe spell ID
-- @param isRecraft boolean
-- @return table Array of { text, numFulfilled, numRequired, itemID, itemLink, finished }
local function BuildRecipeObjectives(recipeID, isRecraft)
    local objectives = {}
    if not addon.GetDB("showRecipeReagents", true) then return objectives end
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeSchematic then return objectives end

    local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, isRecraft, nil)
    if not ok or not schematic or type(schematic) ~= "table" or not schematic.reagentSlotSchematics then
        return objectives
    end

    local getItemCount = (C_Item and C_Item.GetItemCount)

    -- Collect raw reagents: { name, itemID, link, owned, qtyRequired } per reagent
    local raw = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics) do
        local reagents = slot.reagents
        local qtyRequired = slot.quantityRequired or 1
        if reagents and type(reagents) == "table" then
            for _, reagent in ipairs(reagents) do
                local itemID = reagent and reagent.itemID
                if type(itemID) == "number" and itemID > 0 then
                    local name, link = GetItemInfo(itemID)
                    if not link and Item and Item.CreateFromItemID then
                        local item = Item:CreateFromItemID(itemID)
                        if item and item.GetItemLink then
                            link = item:GetItemLink()
                        end
                    end
                    name = name or (link and link:match("%[(.-)%]")) or ("Item " .. tostring(itemID))
                    link = link or ("item:" .. tostring(itemID))

                    local owned = 0
                    if getItemCount then
                        local countOk, count = pcall(getItemCount, itemID, true, false, true, true)
                        if countOk and type(count) == "number" then owned = count end
                    end

                    raw[#raw + 1] = { name = name, itemID = itemID, link = link, owned = owned, qtyRequired = qtyRequired }
                end
            end
        end
    end

    -- Deduplicate by name: group quality-tier variants (same name, different itemIDs).
    -- For each group: sum owned, use max qtyRequired, pick highest itemID for copy link.
    -- Preserve order of first appearance in schematic.
    local byName = {}
    local order = {}
    for _, r in ipairs(raw) do
        local key = r.name or ("item:" .. tostring(r.itemID))
        if not byName[key] then
            byName[key] = { name = r.name, itemID = r.itemID, link = r.link, owned = 0, qtyRequired = r.qtyRequired }
            order[#order + 1] = key
        end
        byName[key].owned = byName[key].owned + r.owned
        if r.itemID > (byName[key].itemID or 0) then
            byName[key].itemID = r.itemID
            byName[key].link = r.link
        end
        if r.qtyRequired > (byName[key].qtyRequired or 0) then
            byName[key].qtyRequired = r.qtyRequired
        end
    end

    for _, key in ipairs(order) do
        local agg = byName[key]
        local finished = (agg.owned >= (agg.qtyRequired or 1))
        objectives[#objectives + 1] = {
            text         = agg.name,
            numFulfilled = agg.owned,
            numRequired  = agg.qtyRequired,
            itemID       = agg.itemID,
            itemLink     = agg.link,
            finished     = finished,
        }
    end

    return objectives
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

--- Build tracker rows from WoW tracked profession recipes.
-- @return table Array of normalized entry tables for the tracker
local function ReadTrackedRecipes()
    local out = {}
    if not addon.GetDB("showRecipes", true) then return out end

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
            out[#out + 1] = {
                entryKey        = "recipe:" .. tostring(recipeID),
                recipeID        = recipeID,
                recipeIsRecraft = isRecraft,
                questID        = nil,
                title          = name or ("Recipe " .. tostring(recipeID)),
                objectives     = objectives,
                color          = recipeColor,
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

addon.GetTrackedRecipeIDs = GetTrackedRecipeIDs
addon.ReadTrackedRecipes = ReadTrackedRecipes
