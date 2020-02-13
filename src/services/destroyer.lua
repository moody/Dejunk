local _, Addon = ...
local assert = assert
local Bags = Addon.Bags
local CalculateTotalNumberOfFreeBagSlots = _G.CalculateTotalNumberOfFreeBagSlots
local ClearCursor = _G.ClearCursor
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
local max = math.max
local PickupContainerItem = _G.PickupContainerItem
local tremove = table.remove
local tsort = table.sort
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

local queueAutoDestroy do
  local function start()
    if DB.Profile and DB.Profile.AutoDestroy and not UI:IsShown() then
      Destroyer:Start(true)
      return true
    end

    return false
  end

  local frame = _G.CreateFrame("Frame")
  frame.timer = 0

  frame:SetScript("OnUpdate", function(self, elapsed)
    if not self.dirty then return end

    self.timer = self.timer + elapsed

    if self.timer >= 1 then
      self.timer = 0
      self.dirty = not start()
    end
  end)

  queueAutoDestroy = function()
    frame.timer = 0
    frame.dirty = true
  end
end

EventManager:On(E.Wow.BagUpdateDelayed, queueAutoDestroy)
EventManager:On(E.MainUIClosed, queueAutoDestroy)

do -- List events
  local function func(list)
    if list == Lists.Destroyables or list == Lists.Undestroyables then
      queueAutoDestroy()
    end
  end

  EventManager:On(E.ListItemAdded, func)
  EventManager:On(E.ListItemRemoved, func)
  EventManager:On(E.ListRemovedAll, func)
end

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

    return
  end

  -- Save Space
  if auto and DB.Profile.DestroySaveSpace.Enabled then
    -- Calculate number of items to destroy
    local freeSpace = CalculateTotalNumberOfFreeBagSlots()
    local maxToDestroy = DB.Profile.DestroySaveSpace.Value - freeSpace
    -- Stop if destroying is not necessary
    if maxToDestroy <= 0 then return end

    -- Sort by price
    tsort(self.items, function(a, b)
      return (a.Price * a.Quantity) < (b.Price * b.Quantity)
    end)

    -- Remove extraneous entries (most expensive first)
    local numToRemove = max(#self.items - maxToDestroy, 0)
    for _=1, numToRemove do tremove(self.items) end
  end

  -- If some items fail to be retrieved, we'll only have items that are cached
  if not self.items.allCached then
    Core:Print(L.ONLY_DESTROYING_CACHED)
  end

  -- Start
  self.state = States.Destroying
  self.timer = 0
  EventManager:Fire(E.DestroyerStart)
end


-- Stops the destroying process.
function Destroyer:Stop()
  assert(self.state ~= States.None)
  self.state = States.None
  EventManager:Fire(E.DestroyerStop)
end


-- Returns true if the Destroyer is active.
-- @return {boolean}
function Destroyer:IsDestroying()
  return self.state ~= States.None
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

    -- Fire event
    EventManager:Fire(E.DestroyerAttemptToDestroy, item)
  end
end
