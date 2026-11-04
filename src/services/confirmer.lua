local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local TickerManager = Addon:GetModule("TickerManager")

--- @class Confirmer
local Confirmer = Addon:GetModule("Confirmer")

--- How an attempt to sell started: as part of a run, or on a single item. `AttemptedToSellItem` carries it.
--- @alias SellAttemptType "RUN" | "MANUAL"

local profit = 0
local profitReady = false
local numSold = 0

--- The items attempted to sell that are not confirmed yet, by how the attempt started.
--- @type table<BagItem, SellAttemptType>
local soldItems = {}

local destroyedItems = {}

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.SellerStarted, function()
  profit = 0
  numSold = 0
  profitReady = false
end)

EventManager:On(E.SellerStopped, function()
  profitReady = true
end)

EventManager:On(E.AttemptedToSellItem, function(item, attemptType)
  soldItems[item] = attemptType

  -- If not confirmed after 5 seconds, item may not have been sold.
  TickerManager:After(5, function()
    if soldItems[item] then
      soldItems[item] = nil
      Addon:Print(L.MAY_NOT_HAVE_SOLD_ITEM:format(item.link))
    end
  end)
end)

EventManager:On(E.AttemptedToDestroyItem, function(item)
  destroyedItems[item] = true

  -- If not confirmed after 5 seconds, item may not have been destroyed.
  TickerManager:After(5, function()
    if destroyedItems[item] then
      destroyedItems[item] = nil
      Addon:Print(L.MAY_NOT_HAVE_DESTROYED_ITEM:format(item.link))
    end
  end)
end)

-- If an item becomes unlocked after an attempt, then the operation failed.
EventManager:On(E.Wow.ItemUnlocked, function(bag, slot)
  for item in pairs(soldItems) do
    if item.bag == bag and item.slot == slot then
      soldItems[item] = nil
      Addon:Print(L.FAILED_TO_SELL_ITEM:format(item.link))
    end
  end

  for item in pairs(destroyedItems) do
    if item.bag == bag and item.slot == slot then
      destroyedItems[item] = nil
      Addon:Print(L.FAILED_TO_DESTROY_ITEM:format(item.link))
    end
  end
end)

-- ============================================================================
-- Confirmer
-- ============================================================================

local function getLink(item)
  return item.quantity > 1 and (item.link .. "x" .. item.quantity) or item.link
end

TickerManager:NewTicker(0, function()
  -- Confirm sold items.
  for item, attemptType in pairs(soldItems) do
    if not Items:IsItemStillInBags(item) then
      soldItems[item] = nil
      profit = profit + item.price * item.quantity

      -- Items sold in a run are summarized. Any other sale is always printed.
      if attemptType == "RUN" then
        numSold = numSold + 1
        Addon:PrintVerbose(L.SOLD_ITEM:format(getLink(item)))
      else
        Addon:Print(L.SOLD_ITEM:format(getLink(item)))
      end
    end
  end

  -- Print the summary.
  if profitReady and next(soldItems) == nil then
    profitReady = false
    if numSold > 0 then Addon:Print(L.ITEMS_SOLD:format(numSold)) end
    if profit > 0 then Addon:Print(L.PROFIT:format(GetCoinTextureString(profit))) end
  end

  -- Confirm destroyed items.
  for item in pairs(destroyedItems) do
    if not Items:IsItemStillInBags(item) then
      destroyedItems[item] = nil
      Addon:Print(L.DESTROYED_ITEM:format(getLink(item)))
    end
  end
end)

function Confirmer:IsBusy()
  return next(soldItems) ~= nil or next(destroyedItems) ~= nil
end
