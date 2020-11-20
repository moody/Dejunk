local _, Addon = ...
local Bags = Addon.Bags
local CalculateTotalNumberOfFreeBagSlots = _G.CalculateTotalNumberOfFreeBagSlots
local Chat = Addon.Chat
local ClearCursor = _G.ClearCursor
local Consts = Addon.Consts
local DB = Addon.DB
local DeleteCursorItem = _G.DeleteCursorItem
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local Filters = Addon.Filters
local GetCursorInfo = _G.GetCursorInfo
local ItemFrames = Addon.ItemFrames
local L = Addon.Libs.L
local Lists = Addon.Lists
local PickupContainerItem = _G.PickupContainerItem
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
    if (
      DB.Profile and
      DB.Profile.destroy.auto and
      not UI:IsShown()
    ) then
      Destroyer:AutoShow()
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

local function flagForRefresh()
  Destroyer.needsRefresh = true
end

for _, e in ipairs({
  E.BagsUpdated,
  E.ListItemAdded,
  E.ListItemRemoved,
  E.ListRemovedAll,
  E.MainUIClosed,
  E.ProfileChanged,
}) do
  EventManager:On(e, flagForRefresh)
  EventManager:On(e, queueAutoDestroy)
end

-- ============================================================================
-- Functions
-- ============================================================================

function Destroyer:GetItems()
  return self.items
end


function Destroyer:GetLists()
  return Lists.destroy
end


function Destroyer:RefreshItems()
  -- Stop if not necessary.
  if not self.needsRefresh then return end
  self.needsRefresh = false

  Filters:GetItems(self, self.items)

  -- Sort by price.
  tsort(self.items, function(a, b)
    return (a.Price * a.Quantity) < (b.Price * b.Quantity)
  end)
end


function Destroyer:HandleNextItem(item)
  -- Refresh items.
  self:RefreshItems()

  -- Stop if no items.
  if #self.items == 0 then
    Chat:Print(L.NO_DESTROYABLE_ITEMS)
    return
  end

  -- Don't run if the cursor has an item, spell, etc.
  if GetCursorInfo() then return end

  -- Get item.
  local index = 1
  if item then
    -- Get index of specified item.
    index = nil
    for i, v in pairs(self.items) do
      if v == item then index = i end
    end
    -- Stop if the item was not found.
    if index == nil then return end
  end
  item = self.items[index]

  -- Verify that the item can be destroyed.
  if not Bags:StillInBags(item) or Bags:IsLocked(item) then return end

  -- Destroy item.
  PickupContainerItem(item.Bag, item.Slot)
  DeleteCursorItem()
  -- Clear cursor in case any issues occurred.
  ClearCursor()

  -- Fire event.
  EventManager:Fire(E.DestroyerAttemptToDestroy, item)
end


function Destroyer:AutoShow()
  -- Refresh items.
  self:RefreshItems()

  -- Stop if no items.
  if #self.items == 0 then return end

  -- Auto slider check.
  if DB.Profile.destroy.autoSlider > Consts.DESTROY_AUTO_SLIDER_MIN then
    -- Calculate number of items to destroy.
    local freeSpace = CalculateTotalNumberOfFreeBagSlots()
    local maxToDestroy = DB.Profile.destroy.autoSlider - freeSpace
    -- Stop if destroying is not necessary.
    if maxToDestroy <= 0 then return end
  end

  ItemFrames.Destroy:Show()
end
