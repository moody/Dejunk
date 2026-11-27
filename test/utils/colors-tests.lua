--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")

-- ============================================================================
-- Setup
-- ============================================================================

local Context = Harness:NewContext()

-- What `Colors` needs from the game at load. No item quality has a color.
Context:SetGlobal("C_Item", { GetItemQualityColor = function() end })
Context:SetGlobal("Enum", { ItemQuality = {} })
Context:SetGlobal("CreateColorFromHexString", function() return {} end)

Context:Load("src/utils/colors.lua")
local Colors = Context:GetModule("Colors")

-- ============================================================================
-- Tests - Colors:Strip()
-- ============================================================================

-- Test: removes the color codes from text.
assert(Colors:Strip("|cffff0000red|r and |cff00ff00green|r") == "red and green")

-- Test: returns text without color codes unchanged.
assert(Colors:Strip("plain text") == "plain text")

-- Test: returns an empty string for no text.
assert(Colors:Strip() == "")
