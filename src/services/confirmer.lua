local _, Addon = ...
local Bags = Addon.Bags
local C_Timer = _G.C_Timer
local Confirmer = Addon.Confirmer
local Core = Addon.Core
local DB = Addon.DB
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local GetCoinTextureString = _G.GetCoinTextureString
local L = Addon.Libs.L
local pairs = pairs

local TIMEOUT_DELAY = 5 -- seconds

Confirmer.destroyedItems = {}
Confirmer.destroyCount = 0
Confirmer.printDestroyCount = false

Confirmer.soldItems = {}
Confirmer.soldTotal = 0
Confirmer.printSoldTotal = false

-- ============================================================================
-- General
-- ============================================================================

function Confirmer:IsConfirming(moduleName)
  if moduleName == "Dejunker" then
    return (
      next(self.soldItems) ~= nil or
      Dejunker:IsDejunking()
    )
  end

  if moduleName == "Destroyer" then
    return (
      next(self.destroyedItems) ~= nil or
      Destroyer:IsDestroying()
    )
  end

  return (
    self:IsConfirming("Dejunker") or
    self:IsConfirming("Destroyer")
  )
end


-- Game update function called via `Addon.Core:OnUpdate()`.
function Confirmer:OnUpdate()
  -- Final sell message
  if self.printSoldTotal and not Dejunker:IsDejunking() then
    self.printSoldTotal = false

    if self.soldTotal > 0 then
      Core:Print(
        L.SOLD_YOUR_JUNK:format(GetCoinTextureString(self.soldTotal))
      )
    end
  end

  -- Final destroy message
  if self.printDestroyCount and not Destroyer:IsDestroying() then
    self.printDestroyCount = false

    if not DB.Profile.VerboseMode and self.destroyCount > 0 then
      Core:Print(
        self.destroyCount == 1 and
        L.DESTROYED_ITEM or
        L.DESTROYED_ITEMS:format(self.destroyCount)
      )
    end
  end
end


function Confirmer:_AddSold(item)
  if self.soldItems[item] then return end
  self.soldItems[item] = true
  self.printSoldTotal = false

  C_Timer.After(TIMEOUT_DELAY, function()
    if self.soldItems[item] then
      self:_RemoveSold(item)
      Core:Print(L.MAY_NOT_HAVE_SOLD_ITEM:format(item.ItemLink))
    end
  end)
end


function Confirmer:_RemoveSold(item)
  self.soldItems[item] = nil
  if not next(self.soldItems) then
    self.printSoldTotal = true
  end
end


function Confirmer:_RemoveUnlockedSold(bag, slot)
  for item in pairs(self.soldItems) do
    if item.Bag == bag and item.Slot == slot then
      self:_RemoveSold(item)
      Core:Print(L.COULD_NOT_SELL_ITEM:format(item.ItemLink))
      return
    end
  end
end


function Confirmer:_ConfirmSoldItems(bag)
  for item in pairs(self.soldItems) do
    if item.Bag == bag and Bags:IsEmpty(item.Bag, item.Slot) then
      self.soldTotal = self.soldTotal + (item.Price * item.Quantity)

      Core:PrintVerbose(
        item.Quantity == 1 and
        L.SOLD_ITEM_VERBOSE:format(item.ItemLink) or
        L.SOLD_ITEMS_VERBOSE:format(item.ItemLink, item.Quantity)
      )

      self:_RemoveSold(item)
    end
  end
end


function Confirmer:_AddDestroyed(item)
  if self.destroyedItems[item] then return end
  self.destroyedItems[item] = true
  self.printDestroyCount = false

  -- Fail if the item hasn't been confirmed after a short delay
  _G.C_Timer.After(TIMEOUT_DELAY, function()
    if self.destroyedItems[item] then
      self:_RemoveDestroyed(item)
      Core:Print(L.MAY_NOT_HAVE_DESTROYED_ITEM:format(item.ItemLink))
    end
  end)
end


function Confirmer:_RemoveDestroyed(item)
  self.destroyedItems[item] = nil
  if not next(self.destroyedItems) then
    self.printDestroyCount = true
  end
end


function Confirmer:_RemoveUnlockedDestroyed(bag, slot)
  for item in pairs(self.destroyedItems) do
    if item.Bag == bag and item.Slot == slot then
      self:_RemoveDestroyed(item)
      Core:Print(L.COULD_NOT_DESTROY_ITEM:format(item.ItemLink))
      return
    end
  end
end


function Confirmer:_ConfirmDestroyedItems(bag)
  for item in pairs(self.destroyedItems) do
    if item.Bag == bag and Bags:IsEmpty(item.Bag, item.Slot) then
      self.destroyCount = self.destroyCount + 1

      Core:PrintVerbose(
        item.Quantity == 1 and
        L.DESTROYED_ITEM_VERBOSE:format(item.ItemLink) or
        L.DESTROYED_ITEMS_VERBOSE:format(item.ItemLink, item.Quantity)
      )

      self:_RemoveDestroyed(item)
    end
  end
end

-- ============================================================================
-- Dejunker Events
-- ============================================================================

EventManager:On(E.DejunkerStart, function()
  for k in pairs(Confirmer.soldItems) do
    Confirmer.soldItems[k] = nil
  end

  Confirmer.soldTotal = 0
  Confirmer.printSoldTotal = false
end)


EventManager:On(E.DejunkerAttemptToSell, function(item)
  Confirmer:_AddSold(item)
end)

-- ============================================================================
-- Destroyer Events
-- ============================================================================

EventManager:On(E.DestroyerStart, function()
  for k in pairs(Confirmer.destroyedItems) do
    Confirmer.destroyedItems[k] = nil
  end

  Confirmer.destroyCount = 0
  Confirmer.printDestroyCount = true
end)


EventManager:On(E.DestroyerAttemptToDestroy, function(item)
  Confirmer:_AddDestroyed(item)
end)

-- ============================================================================
-- Shared Events
-- ============================================================================

-- If an item becomes unlocked, then it was not sold or destroyed.
EventManager:On(E.Wow.ItemUnlocked, function(bag, slot)
  Confirmer:_RemoveUnlockedSold(bag, slot)
  Confirmer:_RemoveUnlockedDestroyed(bag, slot)
end)


-- Whenever bags update, check if any Confirmer items were sold or destroyed.
EventManager:On(E.Wow.BagUpdate, function(bag)
  Confirmer:_ConfirmSoldItems(bag)
  Confirmer:_ConfirmDestroyedItems(bag)
end)
