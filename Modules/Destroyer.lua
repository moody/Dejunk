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
local Consts = Addon.Consts
local Core = Addon.Core
local DejunkDB = Addon.DejunkDB
local ListManager = Addon.ListManager
local ParentFrame = Addon.Frames.ParentFrame
local Tools = Addon.Tools

-- Variables
local states = {
  None = 0,
  Destroying = 1
}
local currentState = states.None

local itemsToDestroy = {}

function Destroyer:StartAutoDestroy()
  Core:Debug("Destroyer", "StartAutoDestroy()")
  if (currentState ~= states.None) then return end
  if not DejunkDB.SV.AutoDestroy then return end
  if ParentFrame.Frame and ParentFrame:IsVisible() then return end

  DBL:GetItemsByFilter(Destroyer.Filter, itemsToDestroy)
  if (#itemsToDestroy > 0) then
    Destroyer:StartDestroying(true)
  end
end

-- Register DBL listener
DBL:AddListener(Destroyer.StartAutoDestroy)


-- ============================================================================
-- Destroyer Frames
-- ============================================================================

-- destroyerFrame is used for destroying items
local destroyerFrame = CreateFrame("Frame", AddonName.."DejunkDestroyerFrame")

-- ============================================================================
-- Destroying Functions
-- ============================================================================

do
  -- Starts the Destroying process.
  -- @param auto - if the process was started automatically
  function Destroyer:StartDestroying(auto)
    local canDestroy, msg = Core:CanDestroy()
    if not canDestroy then
      if not auto then Core:Print(msg) end
      return
    end

    Confirmer:OnDestroyerStart()
    currentState = states.Destroying

    -- Update items if manually started
    if not auto then DBL:GetItemsByFilter(Destroyer.Filter, itemsToDestroy) end
    local upToDate = DBL:IsUpToDate()

    -- Stop if no items
    if (#itemsToDestroy == 0) then
      if not auto then
        Core:Print(upToDate and L.NO_DESTROYABLE_ITEMS or L.NO_CACHED_DESTROYABLE_ITEMS)
      end
      self:StopDestroying()
      return
    end

    -- If DBL isn't up to date, we'll only have items that are cached
    if not upToDate then Core:Print(L.ONLY_DESTROYING_CACHED) end

    self:StartDestroyingItems()
  end

  -- Cancels the Destroying process.
  function Destroyer:StopDestroying()
    assert(currentState ~= states.None)

    destroyerFrame:SetScript("OnUpdate", nil)

    Confirmer:OnDestroyerEnd()
    currentState = states.None
  end

  -- Checks whether or not the Destroyer is active.
  -- @return - boolean
  function Destroyer:IsDestroying()
    return (currentState ~= states.None) or Confirmer:IsConfirmingDestroyedItems()
  end
end

-- ============================================================================
-- Destroy Item Functions
-- ============================================================================

do
  local DESTROY_DELAY = 0.25
  local destroyInterval = 0

  -- Destroying update function
  local function destroyItems_OnUpdate(self, elapsed)
    destroyInterval = (destroyInterval + elapsed)
    if (destroyInterval >= DESTROY_DELAY) then
      destroyInterval = 0

      -- Don't run if the cursor has an item, spell, etc.
      if GetCursorInfo() then return end
      -- Get item
      local item = remove(itemsToDestroy)
      -- Verify that the item in the bag slot has not been changed before destroying
      if not item or not DBL:StillInBags(item) or item:IsLocked() then return end
      
      -- Destroy item
      PickupContainerItem(item.Bag, item.Slot)
      DeleteCursorItem()
      ClearCursor() -- Clear cursor in case any issues occurred
      
      -- Notify confirmer
      Confirmer:OnItemDestroyed(item)

      -- If no more items, stop destroying
      if (#itemsToDestroy <= 0) then
        Destroyer:StopDestroyingItems()
      end
    end
  end

  -- Starts the destroying items process.
  function Destroyer:StartDestroyingItems()
    assert(currentState == states.Destroying)
    destroyInterval = 0
    destroyerFrame:SetScript("OnUpdate", destroyItems_OnUpdate)
  end

  -- Cancels the destroying items process.
  function Destroyer:StopDestroyingItems()
    assert(currentState == states.Destroying)
    destroyerFrame:SetScript("OnUpdate", nil)
    self:StopDestroying()
  end
end

-- ============================================================================
-- Filter Functions
-- ============================================================================

do
  -- Returns true if the specified item is destroyable.
  -- @param item - the item to run through the filter
  Destroyer.Filter = function(item)
    if item:IsLocked() then return false end
    if not Tools:ItemCanBeDestroyed(item) then return false end
    if not Destroyer:IsDestroyableItem(item) then return false end
    return true
  end

  -- Checks if an item is a junk item based on Dejunk's settings.
  -- @param item - a DethsBagLib item
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
end
