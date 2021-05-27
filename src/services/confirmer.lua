local _, Addon = ...
local Bags = Addon.Bags
local C_Timer = _G.C_Timer
local Chat = Addon.Chat
local Confirmer = Addon.Confirmer
local Dejunker = Addon.Dejunker
local E = Addon.Events
local EventManager = Addon.EventManager
local GetCoinTextureString = _G.GetCoinTextureString
local L = Addon.Libs.L
local pairs = pairs

local TIMEOUT_DELAY = 5 -- seconds

Confirmer.destroyedItems = {}

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
    return next(self.destroyedItems) ~= nil
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
      Chat:Sell(
        L.PROFIT_MESSAGE:format(GetCoinTextureString(self.soldTotal))
      )
      self.soldTotal = 0
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
      Chat:Sell(L.MAY_NOT_HAVE_SOLD_ITEM:format(item.ItemLink))
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
      Chat:Sell(L.COULD_NOT_SELL_ITEM:format(item.ItemLink))
      return
    end
  end
end


function Confirmer:_ConfirmSoldItems(bag)
  for item in pairs(self.soldItems) do
    if item.Bag == bag and not Bags:StillInBags(item) then
      self.soldTotal = self.soldTotal + (item.Price * item.Quantity)

      Chat:SellVerbose(
        item.Quantity == 1 and
        L.SOLD_ITEM_VERBOSE:format(item.ItemLink) or
        L.SOLD_ITEMS_VERBOSE:format(item.ItemLink, item.Quantity)
      )
      Chat:SellReason(item.Reason)

      self:_RemoveSold(item)
    end
  end
end


function Confirmer:_AddDestroyed(item)
  if self.destroyedItems[item] then return end
  self.destroyedItems[item] = true

  -- Fail if the item hasn't been confirmed after a short delay
  _G.C_Timer.After(TIMEOUT_DELAY, function()
    if self.destroyedItems[item] then
      self:_RemoveDestroyed(item)
      Chat:Destroy(L.MAY_NOT_HAVE_DESTROYED_ITEM:format(item.ItemLink))
    end
  end)
end


function Confirmer:_RemoveDestroyed(item)
  self.destroyedItems[item] = nil
end


function Confirmer:_RemoveUnlockedDestroyed(bag, slot)
  for item in pairs(self.destroyedItems) do
    if item.Bag == bag and item.Slot == slot then
      self:_RemoveDestroyed(item)
      Chat:Destroy(L.COULD_NOT_DESTROY_ITEM:format(item.ItemLink))
      return
    end
  end
end


function Confirmer:_ConfirmDestroyedItems(bag)
  for item in pairs(self.destroyedItems) do
    if item.Bag == bag and not Bags:StillInBags(item) then
      Chat:Destroy(
        item.Quantity == 1 and
        L.DESTROYED_ITEM_VERBOSE:format(item.ItemLink) or
        L.DESTROYED_ITEMS_VERBOSE:format(item.ItemLink, item.Quantity)
      )
      Chat:DestroyReason(item.Reason)

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
