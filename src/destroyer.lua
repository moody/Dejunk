local _, Addon = ...
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local JunkFilter = Addon.JunkFilter
local L = Addon.Locale

-- ============================================================================
-- Local Functions
-- ============================================================================

-- Sorts items by most expensive to least expensive.
local function sortByTotalPrice(a, b)
  local aTotalPrice = (a.price * a.quantity)
  local bTotalPrice = (b.price * b.quantity)
  return aTotalPrice == bTotalPrice and a.quality > b.quality or aTotalPrice > bTotalPrice
end

-- ============================================================================
-- Destroyer
-- ============================================================================

function Destroyer:Start()
  -- Don't start if busy.
  if Addon:IsBusy() then return end

  -- Get items.
  local items = JunkFilter:GetDestroyableJunkItems()
  if #items == 0 then return Addon:Print(L.NO_JUNK_ITEMS_TO_DESTROY) end

  -- Sort, and get least expensive item.
  table.sort(items, sortByTotalPrice)
  local item = table.remove(items)

  -- Delete item.
  ClearCursor()
  PickupContainerItem(item.bag, item.slot)
  DeleteCursorItem()

  EventManager:Fire(E.AttemptedToDestroyItem, item)
end
