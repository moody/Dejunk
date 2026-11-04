--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local TestGame = require("test/test-game")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `Items` and a test game, from a new context.
--- @return Items Items
--- @return TestGameInstance Game
local function setupContext()
  local Context = Harness:NewContext()
  local Game = TestGame:New(Context)

  Context:SetGlobal("C_Item", {})
  Context:SetGlobal("ItemLocation", { CreateEmpty = function() return {} end })
  Context:Load("src/items/items.lua")

  return Context:GetModule("Items"), Game
end

-- ============================================================================
-- Tests - Items:IsItemRefundable()
-- ============================================================================

-- Test: returns true when the game reports seconds left to refund.
do
  local Items, Game = setupContext()
  Game.refundSeconds = 30
  assert(Items:IsItemRefundable({ bag = 0, slot = 1 }) == true)
end

-- Test: returns false when the game reports no refund window.
do
  local Items, Game = setupContext()
  Game.refundSeconds = nil
  assert(Items:IsItemRefundable({ bag = 0, slot = 1 }) == false)
end

-- Test: returns false when no seconds are left to refund.
do
  local Items, Game = setupContext()
  Game.refundSeconds = 0
  assert(Items:IsItemRefundable({ bag = 0, slot = 1 }) == false)
end

-- Test: stops asking the game once the item is found refundable.
do
  local Items, Game = setupContext()
  local item = { bag = 0, slot = 1 }
  Game.refundSeconds = 30
  Items:IsItemRefundable(item)

  Game.refundSeconds = nil

  assert(Items:IsItemRefundable(item) == true)
end

-- Test: keeps asking the game until the item is refundable, so a late refund time is found.
do
  local Items, Game = setupContext()
  local item = { bag = 0, slot = 1 }
  Game.refundSeconds = nil
  assert(Items:IsItemRefundable(item) == false)

  Game.refundSeconds = 30

  assert(Items:IsItemRefundable(item) == true)
end

-- Test: asks the game again once the remembered refund window has ended.
do
  local Items, Game = setupContext()
  local item = { bag = 0, slot = 1 }
  Game.refundSeconds = 30
  Items:IsItemRefundable(item)

  Game.refundSeconds = nil
  Game.time = Game.time + 31

  assert(Items:IsItemRefundable(item) == false)
end

print("All assertions passed.")
