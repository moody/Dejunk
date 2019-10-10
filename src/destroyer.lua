-- Destroyer: handles the process of destroying items in the player's bags.

local _, Addon = ...
local assert = assert
local ClearCursor = _G.ClearCursor
local Confirmer = Addon.Confirmer
local Core = Addon.Core
local DB = Addon.DB
local DBL = Addon.Libs.DBL
local DeleteCursorItem = _G.DeleteCursorItem
local Destroyer = Addon.Destroyer
local Filters = Addon.Filters
local GetCursorInfo = _G.GetCursorInfo
local L = Addon.Libs.L
local PickupContainerItem = _G.PickupContainerItem
local tremove = table.remove
local UI = Addon.UI

-- Variables
local states = {
  None = 0,
  Destroying = 1
}
local currentState = states.None

local itemsToDestroy = {}

-- ============================================================================
-- Destroying Functions
-- ============================================================================

-- Attempts to start the Destroying process if Auto Destroy is enabled.
-- NOTE: We use this function as a listener for DBL: `self` cannot be used.
function Destroyer:StartAutoDestroy()
  if
    currentState ~= states.None or
    not DB.Profile.AutoDestroy or
    UI:IsShown()
  then
    return
  end

  Filters:GetItems(Destroyer, itemsToDestroy)
  if (#itemsToDestroy > 0) then Destroyer:StartDestroying(true) end
end
-- Register DBL listener
DBL:AddListener(Destroyer.StartAutoDestroy)

-- Starts the Destroying process.
-- @param auto - if the process was started automatically
function Destroyer:StartDestroying(auto)
  local canDestroy, msg = Core:CanDestroy()
  if not canDestroy then
    if not auto then Core:Print(msg) end
    return
  end

  Confirmer:Start("Destroyer")
  currentState = states.Destroying

  -- Get items if manually started
  if not auto then Filters:GetItems(self, itemsToDestroy) end

  -- Stop if no items
  if (#itemsToDestroy == 0) then
    if not auto then
      Core:Print(
        DBL:IsUpToDate() and
        L.NO_DESTROYABLE_ITEMS or
        L.NO_CACHED_DESTROYABLE_ITEMS
      )
    end
    self:StopDestroying()
    return
  end

  -- If DBL isn't up to date, we'll only have items that are cached
  if not DBL:IsUpToDate() then Core:Print(L.ONLY_DESTROYING_CACHED) end

  self:StartDestroyingItems()
end

-- Cancels the Destroying process.
function Destroyer:StopDestroying()
  assert(currentState ~= states.None)
  self.OnUpdate = nil
  Confirmer:Stop("Destroyer")
  currentState = states.None
end

-- Checks whether or not the Destroyer is active.
-- @return - boolean
function Destroyer:IsDestroying()
  return currentState ~= states.None
end

-- Returns true if the Destroyer is active or items are being confirmed.
function Destroyer:IsBusy()
  return self:IsDestroying() or Confirmer:IsConfirming("Destroyer")
end

-- ============================================================================
-- Destroy Item Functions
-- ============================================================================

do
  local interval = 0

  -- Destroying update function
  local function destroyItems_OnUpdate(self, elapsed)
    interval = interval + elapsed
    if (interval >= Core.MinDelay) then
      interval = 0

      -- Don't run if the cursor has an item, spell, etc.
      if GetCursorInfo() then return end
      -- Get next item
      local item = tremove(itemsToDestroy)
      -- Stop if there are no more items
      if not item then Destroyer:StopDestroyingItems() return end
      -- Otherwise, verify that the item in the bag slot has not been changed
      -- before destroying
      if not DBL:StillInBags(item) or item:IsLocked() then return end

      -- Destroy item
      PickupContainerItem(item.Bag, item.Slot)
      DeleteCursorItem()
      ClearCursor() -- Clear cursor in case any issues occurred

      -- Notify confirmer
      Confirmer:Queue("Destroyer", item)
    end
  end

  -- Starts the destroying items process.
  function Destroyer:StartDestroyingItems()
    assert(currentState == states.Destroying)
    interval = 0
    self.OnUpdate = destroyItems_OnUpdate
  end

  -- Cancels the destroying items process.
  function Destroyer:StopDestroyingItems()
    assert(currentState == states.Destroying)
    self.OnUpdate = nil
    self:StopDestroying()
  end
end
