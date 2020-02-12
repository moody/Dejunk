local _, Addon = ...
local Bags = Addon.Bags
local C_Timer = _G.C_Timer
local Confirmer = Addon.Confirmer
local Core = Addon.Core
local DB = Addon.DB
local E = Addon.Events
local EventManager = Addon.EventManager
local GetCoinTextureString = _G.GetCoinTextureString
local L = Addon.Libs.L
local pairs = pairs

local TIMEOUT_DELAY = 5 -- seconds

Confirmer.destroyedItems = {}
Confirmer.destroyCount = 0

Confirmer.soldItems = {}
Confirmer.soldTotal = 0

-- ============================================================================
-- General
-- ============================================================================

function Confirmer:IsConfirming(moduleName)
  if moduleName == "Dejunker" then
    return next(self.soldItems) ~= nil
  end

  if moduleName == "Destroyer" then
    return next(self.destroyedItems) ~= nil
  end

  return (
    next(self.soldItems) ~= nil or
    next(self.destroyedItems) ~= nil
  )
end

-- ============================================================================
-- Dejunker Events
-- ============================================================================

EventManager:On(E.DejunkerStart, function()
  for k in pairs(Confirmer.soldItems) do
    Confirmer.soldItems[k] = nil
  end

  Confirmer.soldTotal = 0
end)


EventManager:On(E.DejunkerAttemptToSell, function(item)
  Confirmer.soldItems[item] = true

  C_Timer.After(TIMEOUT_DELAY, function()
    if Confirmer.soldItems[item] then
      Confirmer.soldItems[item] = nil
      Core:Print(L.MAY_NOT_HAVE_SOLD_ITEM:format(item))
    end
  end)
end)

-- ============================================================================
-- Destroyer Events
-- ============================================================================

EventManager:On(E.DestroyerStart, function()
  for k in pairs(Confirmer.destroyedItems) do
    Confirmer.destroyedItems[k] = nil
  end

  Confirmer.destroyCount = 0
end)


EventManager:On(E.DestroyerAttemptToDestroy, function(item)
  Confirmer.destroyedItems[item] = true

  -- Fail if the item hasn't been confirmed after a short delay
  _G.C_Timer.After(TIMEOUT_DELAY, function()
    if Confirmer.destroyedItems[item] then
      Confirmer.destroyedItems[item] = nil
      Core:Print(L.MAY_NOT_HAVE_DESTROYED_ITEM:format(item))
    end
  end)
end)

-- ============================================================================
-- Shared Events
-- ============================================================================

-- If an item becomes unlocked, then it could not be sold or destroyed.
EventManager:On(E.Wow.ItemUnlocked, function(bag, slot)
  -- Remove unsold items
  for item in pairs(Confirmer.soldItems) do
    if item.Bag == bag and item.Slot == slot then
      Confirmer.soldItems[item] = nil
      -- TODO: print a "%s could not be sold." message?
    end
  end

  -- Remove undestroyed items
  for item in pairs(Confirmer.destroyedItems) do
    if item.Bag == bag and item.Slot == slot then
      Confirmer.destroyedItems[item] = nil
      -- TODO: print a "%s could not be destroyed." message?
    end
  end
end)


-- Whenever bags update, check if any Confirmer items were sold or destroyed.
EventManager:On(E.Wow.BagUpdate, function(bag)
  -- Confirm sold items
  for item in pairs(Confirmer.soldItems) do
    if item.Bag == bag and Bags:IsEmpty(item.Bag, item.Slot) then
      Confirmer.soldItems[item] = nil
      Confirmer.soldTotal = Confirmer.soldTotal + (item.Price * item.Quantity)

      Core:PrintVerbose(
        item.Quantity == 1 and
        L.SOLD_ITEM_VERBOSE:format(item.ItemLink) or
        L.SOLD_ITEMS_VERBOSE:format(item.ItemLink, item.Quantity)
      )

      if not next(Confirmer.soldItems) then
        Core:Print(
          L.SOLD_YOUR_JUNK:format(GetCoinTextureString(Confirmer.soldTotal))
        )
      end
    end
  end

  -- Confirm destroyed items
  for item in pairs(Confirmer.destroyedItems) do
    if item.Bag == bag and Bags:IsEmpty(item.Bag, item.Slot) then
      Confirmer.destroyedItems[item] = nil
      Confirmer.destroyCount = Confirmer.destroyCount + 1

      Core:PrintVerbose(
        item.Quantity == 1 and
        L.DESTROYED_ITEM_VERBOSE:format(item.ItemLink) or
        L.DESTROYED_ITEMS_VERBOSE:format(item.ItemLink, item.Quantity)
      )

      -- Show basic message if not printing verbose
      if
        not next(Confirmer.destroyedItems) and
        not DB.Profile.VerboseMode and
        Confirmer.destroyCount > 0
      then
        Core:Print(
          Confirmer.destroyCount == 1 and
          L.DESTROYED_ITEM or
          L.DESTROYED_ITEMS:format(Confirmer.destroyCount)
        )
      end
    end
  end
end)
