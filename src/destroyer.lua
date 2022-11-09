local _, Addon = ...
local Container = Addon.Container
local Destroyer = Addon.Destroyer
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon.Items
local JunkFilter = Addon.JunkFilter
local L = Addon:GetModule("Locale")

-- ============================================================================
-- Local Functions
-- ============================================================================

-- Sorts items by most expensive to least expensive.
local function sortByTotalPrice(a, b)
  local aTotalPrice = (a.price * a.quantity)
  local bTotalPrice = (b.price * b.quantity)
  return aTotalPrice == bTotalPrice and a.quality > b.quality or aTotalPrice > bTotalPrice
end

local function handleItem(item)
  if not Items:IsItemStillInBags(item) then return end
  if Items:IsItemLocked(item) then return end

  ClearCursor()
  Container.PickupContainerItem(item.bag, item.slot)
  DeleteCursorItem()

  EventManager:Fire(E.AttemptedToDestroyItem, item)
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

  -- Handle item.
  handleItem(item)
end

function Destroyer:HandleItem(item)
  if not Addon:IsBusy() then handleItem(item) end
end
