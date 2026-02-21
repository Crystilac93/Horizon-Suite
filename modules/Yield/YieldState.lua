--[[
    Horizon Suite - Yield - State
    Runtime state and DB accessors for loot toasts. Blizzard: CHAT_MSG_LOOT, C_CurrencyInfo.
]]

local addon = _G.HorizonSuite
if not addon then return end

addon.Yield = addon.Yield or {}
addon.yield = addon.yield or {}

local Y = addon.Yield
local y = addon.yield

-- ============================================================================
-- CONSTANTS
-- ============================================================================

Y.FONT_PATH       = "Fonts\\FRIZQT__.TTF"
Y.FONT_SIZE       = 16
Y.ICON_SIZE       = 34
Y.BORDER_PAD      = 1
Y.ENTRY_HEIGHT    = 38
Y.TEXT_WIDTH      = 300
Y.ICON_GAP        = 10
Y.TOTAL_WIDTH     = (Y.ICON_SIZE + Y.BORDER_PAD * 2) + Y.ICON_GAP + Y.TEXT_WIDTH
Y.LINE_SPACING    = 5
Y.LINE_HEIGHT     = Y.ENTRY_HEIGHT + Y.LINE_SPACING
Y.POOL_SIZE       = 15

Y.DEFAULT_ANCHOR  = "BOTTOMRIGHT"
Y.DEFAULT_X       = -30
Y.DEFAULT_Y       = 250

Y.ENTRANCE_DUR    = 0.3
Y.EXIT_DUR        = 0.5
Y.SLIDE_DIST      = 20
Y.EXIT_DRIFT      = 10
Y.NUDGE_SPEED     = 10

Y.HOLD_ITEM       = 5.0
Y.HOLD_EPIC       = 6.5
Y.HOLD_LEGENDARY  = 8.0
Y.HOLD_MONEY      = 2.5
Y.HOLD_CURRENCY   = 3.0
Y.HOLD_REP        = 3.5

Y.ENTRANCE_DUR_EPIC      = 0.45
Y.ENTRANCE_DUR_LEGENDARY = 0.6
Y.POP_SCALE_START        = 0.75
Y.POP_SCALE_PEAK_EPIC    = 1.12
Y.POP_SCALE_PEAK_LEGEND  = 1.18
Y.POP_SETTLE_FRAC        = 0.35
Y.BORDER_PULSE_SPEED     = 2.2
Y.BORDER_PULSE_ALPHA     = 0.45
Y.FLASH_DUR              = 0.15

Y.SOUND_EPIC      = (SOUNDKIT and SOUNDKIT.UI_CHALLENGES_NEW_RECORD) or 33338
Y.SOUND_LEGENDARY = (SOUNDKIT and SOUNDKIT.UI_LEGENDARY_LOOT_TOAST) or 63971

Y.QUALITY_COLORS = {
    [0] = {0.62, 0.62, 0.62},
    [1] = {1.00, 1.00, 1.00},
    [2] = {0.12, 1.00, 0.00},
    [3] = {0.00, 0.44, 0.87},
    [4] = {0.64, 0.21, 0.93},
    [5] = {1.00, 0.50, 0.00},
    [6] = {0.90, 0.80, 0.50},
    [7] = {0.00, 0.80, 1.00},
    [8] = {0.00, 0.80, 1.00},
}

Y.MONEY_COLOR     = {1.00, 0.84, 0.00}
Y.CURRENCY_COLOR  = {0.40, 0.80, 1.00}
Y.REP_GAIN_COLOR  = {0.00, 0.80, 0.40}
Y.REP_LOSS_COLOR  = {0.80, 0.20, 0.20}

Y.MONEY_ICON      = "Interface\\Icons\\INV_Misc_Coin_02"
Y.REP_ICON        = "Interface\\Icons\\Achievement_Reputation_01"
Y.UNKNOWN_ICON    = "Interface\\Icons\\INV_Misc_QuestionMark"

-- ============================================================================
-- RUNTIME STATE (addon.yield)
-- ============================================================================

y.pool        = y.pool or {}
y.activeCount = y.activeCount or 0
y.patternsOK  = y.patternsOK or false
y.playerGUID  = y.playerGUID
y.debugMode   = y.debugMode or false
y.editMode    = y.editMode or false

-- ============================================================================
-- DB ACCESSORS
-- ============================================================================

--- Get position from HorizonDB.modules.yield (or defaults).
--- @return point string|nil, relPoint string|nil, x number|nil, y number|nil
function Y.GetPosition()
    if not HorizonDB or not HorizonDB.modules or not HorizonDB.modules.yield then
        return nil, nil, Y.DEFAULT_X, Y.DEFAULT_Y
    end
    local db = HorizonDB.modules.yield
    return db.point, db.relPoint, db.x or Y.DEFAULT_X, db.y or Y.DEFAULT_Y
end

--- Save frame position to HorizonDB.modules.yield.
--- @param point string
--- @param relPoint string
--- @param x number
--- @param y number
--- @return nil
function Y.SavePosition(point, relPoint, x, y)
    if not HorizonDB then HorizonDB = {} end
    if not HorizonDB.modules then HorizonDB.modules = {} end
    if not HorizonDB.modules.yield then HorizonDB.modules.yield = {} end
    local db = HorizonDB.modules.yield
    db.point    = point
    db.relPoint = relPoint
    db.x        = x
    db.y        = y
end

--- Clear saved position.
--- @return nil
function Y.ClearPosition()
    if HorizonDB and HorizonDB.modules and HorizonDB.modules.yield then
        local db = HorizonDB.modules.yield
        db.point    = nil
        db.relPoint = nil
        db.x        = nil
        db.y        = nil
    end
end
