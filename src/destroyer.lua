local _, Addon = ...
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local JunkFilter = Addon.JunkFilter
local L = Addon.Locale
local Lists = Addon.Lists
local Seller = Addon.Seller

-- ============================================================================
-- Local Functions
-- ============================================================================

local function canStartDestroying()
  if Seller:IsBusy() then
    return false, L.CANNOT_DESTROY_WHILE_SELLING
  end

  if Lists:IsBusy() then
    return false, L.CANNOT_DESTROY_WHILE_LISTS_UPDATING
  end

  return true
end

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
  local canStart, reason = canStartDestroying()
  if not canStart then return Addon:Print(reason) end

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
