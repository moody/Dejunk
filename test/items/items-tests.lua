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

-- ============================================================================
-- Tests - Items:GetStackPrice()
-- ============================================================================

-- Test: returns the price of the whole stack.
do
  local Items = setupContext()
  assert(Items:GetStackPrice({ price = 5, quantity = 3 }) == 15)
end

-- Test: returns 0 for an item with no sell price.
do
  local Items = setupContext()
  assert(Items:GetStackPrice({ noValue = true, price = 5, quantity = 3 }) == 0)
end

-- ============================================================================
-- Tests - Items.compareByStackPrice()
-- ============================================================================

-- Test: puts the lower stack price first.
do
  local Items = setupContext()
  local cheaper = { price = 5, quantity = 1 }
  local pricier = { price = 2, quantity = 4 }

  assert(Items.compareByStackPrice(cheaper, pricier) == true)
  assert(Items.compareByStackPrice(pricier, cheaper) == false)
end

-- Test: puts an item with no sell price before one with a price.
do
  local Items = setupContext()
  local noPrice = { noValue = true, price = 9, quantity = 1 }
  local priced = { price = 1, quantity = 1 }

  assert(Items.compareByStackPrice(noPrice, priced) == true)
  assert(Items.compareByStackPrice(priced, noPrice) == false)
end

-- Test: puts the lower quality first when the stack prices match.
do
  local Items = setupContext()
  local lower = { price = 5, quantity = 1, quality = 1 }
  local higher = { price = 5, quantity = 1, quality = 3 }

  assert(Items.compareByStackPrice(lower, higher) == true)
  assert(Items.compareByStackPrice(higher, lower) == false)
end

-- Test: orders by name when the stack prices and qualities match.
do
  local Items = setupContext()
  local first = { name = "a", price = 5, quantity = 1, quality = 1 }
  local second = { name = "b", price = 5, quantity = 1, quality = 1 }

  assert(Items.compareByStackPrice(first, second) == true)
  assert(Items.compareByStackPrice(second, first) == false)
end

-- Test: puts the lower quantity first when the stack prices, qualities, and names match.
do
  local Items = setupContext()
  local smaller = { name = "a", price = 4, quantity = 1, quality = 1 }
  local larger = { name = "a", price = 2, quantity = 2, quality = 1 }

  assert(Items.compareByStackPrice(smaller, larger) == true)
  assert(Items.compareByStackPrice(larger, smaller) == false)
end

-- Test: orders by bag when everything else matches.
do
  local Items = setupContext()
  local first = { name = "a", price = 5, quantity = 1, quality = 1, bag = 0, slot = 3 }
  local second = { name = "a", price = 5, quantity = 1, quality = 1, bag = 1, slot = 1 }

  assert(Items.compareByStackPrice(first, second) == true)
  assert(Items.compareByStackPrice(second, first) == false)
end

-- Test: orders by slot when everything else, including the bag, matches.
do
  local Items = setupContext()
  local first = { name = "a", price = 5, quantity = 1, quality = 1, bag = 0, slot = 1 }
  local second = { name = "a", price = 5, quantity = 1, quality = 1, bag = 0, slot = 2 }

  assert(Items.compareByStackPrice(first, second) == true)
  assert(Items.compareByStackPrice(second, first) == false)
end

-- Test: returns false when given the same item twice.
do
  local Items = setupContext()
  local item = { name = "a", price = 5, quantity = 1, quality = 1, bag = 0, slot = 1 }

  assert(Items.compareByStackPrice(item, item) == false)
end

print("All assertions passed.")
