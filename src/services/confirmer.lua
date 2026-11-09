local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local TickerManager = Addon:GetModule("TickerManager")

--- @class Confirmer
local Confirmer = Addon:GetModule("Confirmer")

local profit = 0
local profitReady = false
local numSold = 0

--- The sell attempts that are not confirmed yet.
--- @type table<SellAttempt, boolean>
local sellAttempts = {}

--- The destroy attempts that are not confirmed yet.
--- @type table<DestroyAttempt, boolean>
local destroyAttempts = {}

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

EventManager:On(E.AttemptedToSellItem, function(attempt)
  sellAttempts[attempt] = true

  -- If not confirmed after 5 seconds, item may not have been sold.
  TickerManager:After(5, function()
    if sellAttempts[attempt] then
      sellAttempts[attempt] = nil
      Addon:Print(L.MAY_NOT_HAVE_SOLD_ITEM:format(attempt.item.link))
      EventManager:Fire(E.MayNotHaveSoldItem, attempt)
    end
  end)
end)

EventManager:On(E.AttemptedToDestroyItem, function(attempt)
  destroyAttempts[attempt] = true

  -- If not confirmed after 5 seconds, item may not have been destroyed.
  TickerManager:After(5, function()
    if destroyAttempts[attempt] then
      destroyAttempts[attempt] = nil
      Addon:Print(L.MAY_NOT_HAVE_DESTROYED_ITEM:format(attempt.item.link))
      EventManager:Fire(E.MayNotHaveDestroyedItem, attempt)
    end
  end)
end)

-- If an item becomes unlocked after an attempt, then the operation failed.
EventManager:On(E.Wow.ItemUnlocked, function(bag, slot)
  for attempt in pairs(sellAttempts) do
    local item = attempt.item
    if item.bag == bag and item.slot == slot then
      sellAttempts[attempt] = nil
      Addon:Print(L.FAILED_TO_SELL_ITEM:format(item.link))
      EventManager:Fire(E.FailedToSellItem, attempt)
    end
  end

  for attempt in pairs(destroyAttempts) do
    local item = attempt.item
    if item.bag == bag and item.slot == slot then
      destroyAttempts[attempt] = nil
      Addon:Print(L.FAILED_TO_DESTROY_ITEM:format(item.link))
      EventManager:Fire(E.FailedToDestroyItem, attempt)
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
  for attempt in pairs(sellAttempts) do
    local item = attempt.item
    if not Items:IsItemStillInBags(item) then
      sellAttempts[attempt] = nil
      profit = profit + item.price * item.quantity

      -- Items sold in a run are summarized. Any other sale is always printed.
      if attempt.type == "RUN" then
        numSold = numSold + 1
        Addon:PrintVerbose(L.SOLD_ITEM:format(getLink(item)))
      else
        Addon:Print(L.SOLD_ITEM:format(getLink(item)))
      end

      EventManager:Fire(E.ConfirmedItemSold, attempt)
    end
  end

  -- Print the summary.
  if profitReady and next(sellAttempts) == nil then
    profitReady = false
    if numSold > 0 then
      local itemsSoldText = Colors.Yellow(L.ITEMS_SOLD:format(Colors.White(numSold)))
      local profitText = Colors.Yellow(L.PROFIT:format(Colors.White(GetCoinTextureString(profit))))
      Addon:Print(itemsSoldText .. Colors.Grey(" | ") .. profitText)
    end
  end

  -- Confirm destroyed items.
  for attempt in pairs(destroyAttempts) do
    local item = attempt.item
    if not Items:IsItemStillInBags(item) then
      destroyAttempts[attempt] = nil
      Addon:Print(L.DESTROYED_ITEM:format(getLink(item)))
      EventManager:Fire(E.ConfirmedItemDestroyed, attempt)
    end
  end
end)

function Confirmer:IsBusy()
  return next(sellAttempts) ~= nil or next(destroyAttempts) ~= nil
end
