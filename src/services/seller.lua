local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local BagItemsCache = Addon:GetModule("BagItemsCache")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")

--- @class Seller
local Seller = Addon:GetModule("Seller")

--- The most items Safe Sell sells in one run.
--- @type integer
Seller.SAFE_SELL_LIMIT = 12

--- The seconds after the merchant window opens before Auto Repair and Auto Sell run.
--- @type number
Seller.ON_MERCHANT_SHOW_DELAY = 0.1

--- The maximum seconds `Start()` waits for the bag items cache to settle.
--- @type number
Seller.MAX_SETTLE_SECONDS = 0.4

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.MerchantShow, function()
  TickerManager:After(Seller.ON_MERCHANT_SHOW_DELAY, function()
    local profileSettings = StateManager:GetProfileState().settings

    -- Auto repair.
    if profileSettings.autoRepair then
      local repairCost, canRepair = GetRepairAllCost()
      if canRepair and GetMoney() >= repairCost then
        RepairAllItems()
        PlaySound(SOUNDKIT.ITEM_REPAIR)
        Addon:Print(L.REPAIRED_ALL_ITEMS:format(GetCoinTextureString(repairCost)))
      end
    end

    -- Auto sell.
    if profileSettings.autoSell then
      Seller:Start(true)
    end
  end)
end)

EventManager:On(E.Wow.MerchantClosed, function()
  Seller:Stop()
end)

EventManager:On(E.Wow.UIErrorMessage, function(_, msg)
  if msg == B.Strings.VENDOR_DOESNT_BUY_ERROR_TEXT then
    Seller:Stop()
  end
end)

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Confirms `popup` if it asks to remove an item's trade timer.
local function handlePopup(popup)
  if popup and popup:IsShown() and popup.which == "CONFIRM_MERCHANT_TRADE_TIMER_REMOVAL" then
    local button = popup.GetButton1 and popup:GetButton1() or popup.button1
    button:Click()
  end
end

--- Confirms a shown popup that asks to remove an item's trade timer. Does nothing on Classic Era and TBC.
local function handleStaticPopup()
  if (Addon.IS_VANILLA or Addon.IS_TBC) then return end

  if type(StaticPopup_ForEachShownDialog) == "function" then
    StaticPopup_ForEachShownDialog(handlePopup)
  else
    for i = 1, STATICPOPUP_NUMDIALOGS do
      local popup = _G["StaticPopup" .. i]
      handlePopup(popup)
    end
  end
end

--- Sells the item and fires `AttemptedToSellItem`, unless it is gone from the bags or locked. Returns `true` if a sale
--- was attempted.
--- @param item BagItem
--- @return boolean wasAttempted
local function handleItem(item)
  if Items:IsItemStillInBags(item) and not Items:IsItemLocked(item) then
    C_Container.UseContainerItem(item.bag, item.slot)
    handleStaticPopup()

    EventManager:Fire(E.AttemptedToSellItem, item)
    return true
  end

  return false
end

-- ============================================================================
-- Run State
-- ============================================================================

--- The phases of a run.
--- @enum SellerRunPhase
local RunPhases = {
  --- No run is in progress.
  IDLE = "IDLE",

  --- Waiting for the bag items cache to settle, before the first batch or between batches.
  WAITING = "WAITING",

  --- Items are being sold, one per tick.
  SELLING = "SELLING"
}

--- The state of the current run, from `Start()` to `Stop()`. Only its methods change it.
--- @class SellerRunState
local RunState = {
  --- @type SellerRunPhase
  phase = RunPhases.IDLE,

  --- Changes each time a run begins, waits, or ends, so a pending wait can tell it is out of date.
  --- @type integer
  runId = 0,

  --- Set when `Sell()` first finds items, which is when `SellerStarted` fires.
  hasStarted = false,

  --- The items left to sell.
  --- @type BagItem[]
  items = {},

  --- The item ID of each attempted sale this run, by slot key.
  --- @type table<integer, integer>
  attempted = {},

  --- The calls to `UseContainerItem` this run, which count against the Safe Sell limit.
  numAttempted = 0,

  --- The calls to `UseContainerItem` since the last fetch. A batch with none ends the run.
  numBatchAttempts = 0,

  --- Runs one sale per tick, while selling.
  --- @type Ticker?
  ticker = nil
}

--- Returns `true` if a run is waiting or selling.
--- @return boolean
function RunState:IsBusy()
  return self.phase ~= RunPhases.IDLE
end

--- Returns `true` if the run has started selling.
--- @return boolean
function RunState:HasStarted()
  return self.hasStarted
end

--- Returns `true` if Safe Sell is on and the run has attempted its limit.
--- @return boolean
function RunState:IsSafeSellLimitReached()
  return (StateManager:GetGlobalState().safeSell and self.numAttempted >= Seller.SAFE_SELL_LIMIT) or false
end

--- Waits for the bag items cache to settle, then calls `callback`. The call is dropped if the run ends first.
--- @param callback fun()
function RunState:Wait(callback)
  if self.ticker then
    self.ticker:Cancel()
    self.ticker = nil
  end

  self.runId = self.runId + 1
  self.phase = RunPhases.WAITING

  local runId = self.runId
  BagItemsCache:WhenSettled(Seller.MAX_SETTLE_SECONDS, function()
    if self.runId == runId then callback() end
  end)
end

--- Records that a sale of `item` was attempted. Later fetches leave out its slot while it holds the same item.
--- @param item BagItem
function RunState:AddAttempt(item)
  self.attempted[BagItemsCache:GetSlotKey(item.bag, item.slot)] = item.id
  self.numAttempted = self.numAttempted + 1
  self.numBatchAttempts = self.numBatchAttempts + 1
end

--- Begins selling the junk items that were not attempted this run, highest price first, up to what is left of the Safe
--- Sell limit when it is on. Returns `true` if there were any.
--- @param onWaitEnded fun() Called when the batch is sold and the cache has settled again.
--- @return boolean hasItems
function RunState:Sell(onWaitEnded)
  local safeSell = StateManager:GetGlobalState().safeSell

  -- Ask for the full limit, since attempted items may still be in the bags.
  local items = JunkFilter:GetSellableJunkItems(nil, safeSell and Seller.SAFE_SELL_LIMIT or nil)
  local maxKept = safeSell and Seller.SAFE_SELL_LIMIT - self.numAttempted or #items

  -- Leave out attempted slots, and items past what is left of the Safe Sell limit.
  local numKept = 0
  for i = 1, #items do
    local item = items[i]
    local attemptedId = self.attempted[BagItemsCache:GetSlotKey(item.bag, item.slot)]
    if numKept < maxKept and (attemptedId == nil or attemptedId ~= item.id) then
      numKept = numKept + 1
      items[numKept] = item
    end
  end
  for i = #items, numKept + 1, -1 do items[i] = nil end
  self.items = items

  if #items > 0 then
    self.hasStarted = true
    self.phase = RunPhases.SELLING
    self.numBatchAttempts = 0
    self.ticker = TickerManager:NewTicker(Addon:GetLatency(), function()
      if not Addon:IsAtMerchant() or self:IsSafeSellLimitReached() then
        return Seller:Stop()
      end

      local item = table.remove(self.items)
      if not item then
        -- Fetch again once the cache settles, unless the batch made no attempts.
        if self.numBatchAttempts > 0 then
          return self:Wait(onWaitEnded)
        else
          return Seller:Stop()
        end
      end

      -- Skip an item that stopped being junk since the fetch.
      if JunkFilter:IsSellableJunkItem(item) and handleItem(item) then
        self:AddAttempt(item)
      end
    end)
    return true
  end

  return false
end

--- Ends the run and cancels its ticker. Returns `true` if the run had started selling.
--- @return boolean hasStarted
function RunState:Reset()
  local hasStarted = self.hasStarted
  if self.ticker then self.ticker:Cancel() end

  self.runId = self.runId + 1
  self.phase = RunPhases.IDLE
  self.hasStarted = false
  self.numAttempted = 0
  self.numBatchAttempts = 0
  self.ticker = nil
  for slotKey in pairs(self.attempted) do self.attempted[slotKey] = nil end

  return hasStarted
end

-- ============================================================================
-- Seller
-- ============================================================================

--- Called when the wait for the cache ends, settled or timed out. Sells the next batch, or ends the run if the
--- merchant window is closed or there are no items.
--- @param auto? boolean Whether Auto Sell started the run.
local function onWaitEnded(auto)
  -- End the run if the merchant closed while waiting.
  if not Addon:IsAtMerchant() then return Seller:Stop() end

  local hasStarted = RunState:HasStarted()
  if RunState:Sell(onWaitEnded) then
    if not hasStarted then EventManager:Fire(E.SellerStarted) end
  else
    if not hasStarted and not auto then Addon:Print(L.NO_JUNK_ITEMS_TO_SELL) end
    Seller:Stop()
  end
end

--- Waits for the bag items cache to settle, then sells the junk items, highest price first, until none are left or the
--- Safe Sell limit is reached.
--- @param auto? boolean If `true`, no message is printed when there are no items to sell.
function Seller:Start(auto)
  -- Do not start if busy.
  if Addon:IsBusy() then return end
  -- Do not start without merchant.
  if not Addon:IsAtMerchant() then
    return Addon:Print(L.CANNOT_SELL_WITHOUT_MERCHANT)
  end

  -- Wait for the bag items cache to settle.
  RunState:Wait(function() onWaitEnded(auto) end)
end

--- Ends the run, whether it is waiting or selling. Fires `SellerStopped` only if `SellerStarted` fired.
function Seller:Stop()
  if RunState:Reset() then
    EventManager:Fire(E.SellerStopped)
  end
end

--- Sells one item at once, without starting a run. Does nothing while busy.
--- @param item BagItem
function Seller:HandleItem(item)
  if Addon:IsBusy() then return end

  if not Addon:IsAtMerchant() then
    return Addon:Print(L.CANNOT_SELL_WITHOUT_MERCHANT)
  end

  handleItem(item)
end

--- Returns `true` if a run is waiting for the cache or selling.
--- @return boolean
function Seller:IsBusy()
  return RunState:IsBusy()
end
