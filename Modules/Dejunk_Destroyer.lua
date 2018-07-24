-- Dejunk_Destroyer: handles the process of destroying items in the player's bags.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DBL = Addon.Libs.DBL

-- Upvalues
local assert, remove = assert, table.remove

local GetCursorInfo, PickupContainerItem, DeleteCursorItem, ClearCursor =
      GetCursorInfo, PickupContainerItem, DeleteCursorItem, ClearCursor

-- Modules
local Destroyer = Addon.Destroyer
local Confirmer = Addon.Confirmer

local Core = Addon.Core
local Consts = Addon.Consts
local DejunkDB = Addon.DejunkDB
local ListManager = Addon.ListManager
local Tools = Addon.Tools

-- Variables
local DestroyerState = {
  None = 0,
  Destroying = 1
}

local currentState = DestroyerState.None

local ItemsToDestroy = {}

-- Register DBL listener
DBL:AddListener(function()
  if (currentState == DestroyerState.None) then
    Addon.Core:Debug("Destroyer", "DBL update")
    DBL:GetItemsByFilter(Destroyer.Filter, ItemsToDestroy)
    if DejunkDB.SV.AutoDestroy and (#ItemsToDestroy > 0) and Core:CanDestroy() then
      Destroyer:StartDestroying()
    end
  end
end)

-- ============================================================================
--                              Destroyer Frames
-- ============================================================================

-- destroyerFrame is used for destroying items
local destroyerFrame = CreateFrame("Frame", AddonName.."DejunkDestroyerFrame")

-- ============================================================================
--                             Destroying Functions
-- ============================================================================

-- Starts the Destroying process.
function Destroyer:StartDestroying()
  local canDestroy, msg = Core:CanDestroy()
  if not canDestroy then
    Core:Print(msg)
    return
  end

  Confirmer:OnDestroyerStart()
  currentState = DestroyerState.Destroying

  if not DBL:IsUpToDate() then
    if (#ItemsToDestroy > 0) then
      Core:Print(L.ONLY_DESTROYING_CACHED)
    else
      Core:Print(L.NO_CACHED_DESTROYABLE_ITEMS)
      self:StopDestroying()
      return
    end
  end

  self:StartDestroyingItems()
end

-- Cancels the Destroying process.
function Destroyer:StopDestroying()
  assert(currentState ~= DestroyerState.None)

  destroyerFrame:SetScript("OnUpdate", nil)

  Confirmer:OnDestroyerEnd()
  currentState = DestroyerState.None

  DBL:GetItemsByFilter(Destroyer.Filter, ItemsToDestroy)
end

-- Checks whether or not the Destroyer is active.
-- @return - boolean
function Destroyer:IsDestroying()
  return (currentState ~= DestroyerState.None) or Confirmer:IsConfirmingDestroyedItems()
end

-- ============================================================================
--                            Destroy Item Functions
-- ============================================================================

local DESTROY_DELAY = 0.25
local destroyInterval = 0

-- Starts the destroying items process.
function Destroyer:StartDestroyingItems()
  assert(currentState == DestroyerState.Destroying)

  if (#ItemsToDestroy <= 0) then
		Core:Print(L.NO_DESTROYABLE_ITEMS)
		self:StopDestroying()
		return
	end

  destroyInterval = 0

  destroyerFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:DestroyItems(frame, elapsed)
  end)
end

-- Cancels the destroying items process.
function Destroyer:StopDestroyingItems()
  destroyerFrame:SetScript("OnUpdate", nil)
  self:StopDestroying()
end

-- Set as the OnUpdate function during the destroying items process.
function Destroyer:DestroyItems(frame, elapsed)
	destroyInterval = (destroyInterval + elapsed)

	if (destroyInterval >= DESTROY_DELAY) then
		destroyInterval = 0

		self:DestroyNextItem()

		if (#ItemsToDestroy <= 0) then self:StopDestroyingItems() end
	end
end

-- Destroys the next item in the ItemsToDestroy table.
function Destroyer:DestroyNextItem()
  -- Don't run if the cursor has an item, spell, etc.
  if GetCursorInfo() then return end

  local item = remove(ItemsToDestroy)
  -- Verify that the item in the bag slot has not been changed before destroying
  if not item or not DBL:StillInBags(item) or item:IsLocked() then return end

	PickupContainerItem(item.Bag, item.Slot)
  DeleteCursorItem()
  ClearCursor() -- Clear cursor in case any issues occurred

  Confirmer:OnItemDestroyed(item)
end

-- ============================================================================
--                              Filter Functions
-- ============================================================================

-- Returns true if the specified item is destroyable.
-- @param item - the item to run through the filter
Destroyer.Filter = function(item)
  if item:IsLocked() then return nil end
  if not Tools:ItemCanBeDestroyed(item) then return nil end
  if not Destroyer:IsDestroyableItem(item) then return nil end
  return true
end

-- Checks if an item is a junk item based on Dejunk's settings.
-- @param item - an item retrieved using Tools:GetItemFromBag
-- @return - true if the item is considered junk, and false otherwise
function Destroyer:IsDestroyableItem(item)
  --[[ Priority
  1. Are we ignoring Exclusions?
  2. Are we destroying Poor items?
    2.1 Threshold?
  3. Are we destroying Inclusions?
    3.1 Threshold?
  4. Is it on the Destroyables list?
    4.1 Threshold?
  5. Custom
  ]]

  -- 1
  if DejunkDB.SV.DestroyIgnoreExclusions and
    ListManager:IsOnList(ListManager.Exclusions, item.ItemID) then
    return false, L.REASON_DESTROY_IGNORE_EXCLUSIONS_TEXT
  end

  -- 2
  if DejunkDB.SV.DestroyPoor and (item.Quality == LE_ITEM_QUALITY_POOR) then
    local destroy, reason = self:ItemPriceBelowThreshold(item)
    return destroy, reason or L.REASON_DESTROY_BY_QUALITY_TEXT
  end

  -- 3
  if DejunkDB.SV.DestroyInclusions and
    ListManager:IsOnList(ListManager.Inclusions, item.ItemID) then
    local destroy, reason = self:ItemPriceBelowThreshold(item)
    return destroy, reason or L.REASON_DESTROY_INCLUSIONS_TEXT
  end

  -- 4
  if ListManager:IsOnList(ListManager.Destroyables, item.ItemID) then
    local destroy, reason = self:ItemPriceBelowThreshold(item)
    return destroy, reason or format(L.REASON_ITEM_ON_LIST_TEXT, L.DESTROYABLES_TEXT)
  end

  -- 5
  if self:IsDestroyPetsAlreadyCollected(item) then
    return true, L.REASON_DESTROY_PETS_ALREADY_COLLECTED_TEXT end
  if self:IsDestroyToysAlreadyCollectedItem(item) then
    return true, L.REASON_DESTROY_TOYS_ALREADY_COLLECTED_TEXT end

  -- Default
  return false, L.REASON_ITEM_NOT_FILTERED_TEXT
end

-- Returns true if the item's price is less than the set price threshold.
function Destroyer:ItemPriceBelowThreshold(item)
  if DejunkDB.SV.DestroyUsePriceThreshold and Tools:ItemCanBeSold(item) then
    local threshold = DejunkDB.SV.DestroyPriceThreshold
    local thresholdCopperPrice = (threshold.Gold * 10000) +
      (threshold.Silver * 100) + threshold.Copper

    if ((item.Price * item.Quantity) >= thresholdCopperPrice) then
      return false, format(L.REASON_DESTROY_THRESHOLD_MET_TEXT, GetCoinTextureString(thresholdCopperPrice))
    else
      return true, format(L.REASON_DESTROY_THRESHOLD_NOT_MET_TEXT, GetCoinTextureString(thresholdCopperPrice))
    end
  end

  return true
end

function Destroyer:IsDestroyPetsAlreadyCollected(item)
  if not DejunkDB.SV.DestroyPetsAlreadyCollected or not item.NoValue then return false end
  if not (item.SubClass == Consts.COMPANION_SUBCLASS) then return false end
  return Tools:BagItemTooltipHasText(item.Bag, item.Slot, ITEM_SOULBOUND, COLLECTED)
end

function Destroyer:IsDestroyToysAlreadyCollectedItem(item)
  if not DejunkDB.SV.DestroyToysAlreadyCollected or not item.NoValue then return false end
  if not PlayerHasToy(item.ItemID) then return false end
  return Tools:BagItemTooltipHasText(item.Bag, item.Slot, ITEM_SOULBOUND)
end
