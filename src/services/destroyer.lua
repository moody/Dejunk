local _, Addon = ...
local assert = assert
local Bags = Addon.Bags
local ClearCursor = _G.ClearCursor
local Confirmer = Addon.Confirmer
local Core = Addon.Core
local DB = Addon.DB
local DeleteCursorItem = _G.DeleteCursorItem
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local Filters = Addon.Filters
local GetCursorInfo = _G.GetCursorInfo
local L = Addon.Libs.L
local Lists = Addon.Lists
local PickupContainerItem = _G.PickupContainerItem
local tremove = table.remove
local UI = Addon.UI

local States = {
  None = 0,
  Destroying = 1
}

Destroyer.items = {}
Destroyer.state = States.None
Destroyer.timer = 0

-- ============================================================================
-- Events
-- ============================================================================

-- Attempts to start the destroying process if "Auto Destroy" is enabled.
local function startAutoDestroy()
  if DB.Profile and DB.Profile.AutoDestroy and not UI:IsShown() then
    Destroyer:Start(true)
  end
end

EventManager:On(E.BagUpdateDelayedSafe, startAutoDestroy)

EventManager:On(E.MainUIClosed, startAutoDestroy)

EventManager:On(E.ListItemsUpdated, function(list)
  if
    list == Lists.Destroyables or
    list == Lists.Undestroyables
  then
    startAutoDestroy()
  end
end)

-- ============================================================================
-- Functions
-- ============================================================================

-- Starts the destroying process.
-- @param {boolean} auto
function Destroyer:Start(auto)
  local canDestroy, msg = Core:CanDestroy()
  if not canDestroy then
    if not auto then Core:Print(msg) end
    return
  end

  Confirmer:Start("Destroyer")
  self.state = States.Destroying
  self.timer = 0

  -- Get items
  Filters:GetItems(self, self.items)

  -- Stop if no items
  if #self.items == 0 then
    if not auto then
      Core:Print(
        self.items.allCached and
        L.NO_DESTROYABLE_ITEMS or
        L.NO_CACHED_DESTROYABLE_ITEMS
      )
    end

    return self:Stop()
  end

  -- If some items fail to be retrieved, we'll only have items that are cached
  if not self.items.allCached then
    Core:Print(L.ONLY_DESTROYING_CACHED)
  end
end


-- Stops the destroying process.
function Destroyer:Stop()
  assert(self.state ~= States.None)
  Confirmer:Stop("Destroyer")
  self.state = States.None
end


-- Returns true if the Destroyer is active.
-- @return {boolean}
function Destroyer:IsDestroying()
  return self.state ~= States.None
end


-- Returns true if the Destroyer is active or items are being confirmed.
function Destroyer:IsBusy()
  return self:IsDestroying() or Confirmer:IsConfirming("Destroyer")
end


-- Game update function called via `Addon.Core:OnUpdate()`.
-- @param {number} elapsed - time since last frame
function Destroyer:OnUpdate(elapsed)
  if self.state ~= States.Destroying then return end

  self.timer = self.timer + elapsed

  if self.timer >= Core.MinDelay then
    self.timer = 0

    -- Don't run if the cursor has an item, spell, etc.
    if GetCursorInfo() then return end

    -- Get next item
    local item = tremove(self.items)

    -- Stop if there are no more items
    if not item then
      return self:Stop()
    end

    -- Otherwise, verify that the item in the bag slot has not been changed
    if not Bags:StillInBags(item) or Bags:IsLocked(item) then
      return
    end

    -- Destroy item
    PickupContainerItem(item.Bag, item.Slot)
    DeleteCursorItem()
    ClearCursor() -- Clear cursor in case any issues occurred

    -- Notify confirmer
    Confirmer:Queue("Destroyer", item)
  end
end
