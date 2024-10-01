local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local L = Addon:GetModule("Locale")

--- @class Destroyer
local Destroyer = Addon:GetModule("Destroyer")

-- ============================================================================
-- Local Functions
-- ============================================================================

local function handleItem(item)
  if not Items:IsItemStillInBags(item) then return end
  if Items:IsItemLocked(item) then return end

  ClearCursor()
  C_Container.PickupContainerItem(item.bag, item.slot)
  DeleteCursorItem()

  EventManager:Fire(E.AttemptedToDestroyItem, item)
end

-- ============================================================================
-- Destroyer
-- ============================================================================

function Destroyer:Start()
  -- Don't start if busy.
  if Addon:IsBusy() then return end

  -- Get item.
  local item = JunkFilter:GetNextDestroyableJunkItem()
  if not item then return Addon:Print(L.NO_JUNK_ITEMS_TO_DESTROY) end

  -- Handle item.
  handleItem(item)
end

function Destroyer:HandleItem(item)
  if not Addon:IsBusy() then handleItem(item) end
end
