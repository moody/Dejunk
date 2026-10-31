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

--- Sells the item and fires `AttemptedToSellItem`, unless it is gone from the bags or locked.
local function handleItem(item)
  if not Items:IsItemStillInBags(item) then return end
  if Items:IsItemLocked(item) then return end

  C_Container.UseContainerItem(item.bag, item.slot)
  handleStaticPopup()

  EventManager:Fire(E.AttemptedToSellItem, item)
end

-- ============================================================================
-- Run State
-- ============================================================================

--- The phases of a run.
--- @enum SellerRunPhase
local RunPhases = {
  --- No run is in progress.
  IDLE = "IDLE",

  --- `Start()` is waiting for the bag items cache to settle.
  WAITING = "WAITING",

  --- Items are being sold, one per tick.
  SELLING = "SELLING"
}

--- The state of the current run, from `Start()` to `Stop()`. Only its methods change it.
--- @class SellerRunState
local RunState = {
  --- @type SellerRunPhase
  phase = RunPhases.IDLE,

  --- Changes each time a run begins or ends. A wait keeps the id it began with, so it can tell the run was stopped.
  --- @type integer
  runId = 0,

  --- The items left to sell. Every `Sell()` refills the same table.
  --- @type BagItem[]
  items = {},

  --- Runs one sale per tick, while selling.
  --- @type Ticker?
  ticker = nil
}

--- Returns whether a run is waiting or selling.
--- @return boolean
function RunState:IsBusy()
  return self.phase ~= RunPhases.IDLE
end

--- Begins the wait for the bag items cache. Returns the run's id, which `IsCurrent()` checks.
--- @return integer runId
function RunState:Wait()
  self.runId = self.runId + 1
  self.phase = RunPhases.WAITING
  return self.runId
end

--- Returns whether `runId` belongs to the run in progress, not one that was stopped.
--- @param runId integer
--- @return boolean
function RunState:IsCurrent(runId)
  return self.runId == runId
end

--- Begins selling the sellable junk items, highest price first, up to the Safe Sell limit when it is on. Returns
--- whether there were any.
--- @return boolean hasItems
function RunState:Sell()
  local limit = StateManager:GetGlobalState().safeSell and Seller.SAFE_SELL_LIMIT or nil
  self.items = JunkFilter:GetSellableJunkItems(self.items, limit)

  if #self.items > 0 then
    self.phase = RunPhases.SELLING
    self.ticker = TickerManager:NewTicker(Addon:GetLatency(), function()
      local item = Addon:IsAtMerchant() and table.remove(self.items)
      if not item then return Seller:Stop() end
      handleItem(item)
    end)
    return true
  end

  return false
end

--- Ends the run and cancels its ticker. Returns whether it was selling.
--- @return boolean wasSelling
function RunState:Reset()
  local wasSelling = self.phase == RunPhases.SELLING
  if wasSelling then self.ticker:Cancel() end

  self.runId = self.runId + 1
  self.phase = RunPhases.IDLE
  self.ticker = nil

  return wasSelling
end

-- ============================================================================
-- Seller
-- ============================================================================

--- Called when the wait for the cache ends, settled or timed out. Starts selling unless the merchant window is closed or
--- there are no items.
--- @param auto? boolean Whether Auto Sell started the run.
local function onWaitEnded(auto)
  -- End the wait. Every exit below leaves the Seller idle.
  RunState:Reset()

  -- Do not start if the merchant closed while waiting.
  if not Addon:IsAtMerchant() then return end

  -- Start selling, or return if no items.
  if not RunState:Sell() then
    if not auto then Addon:Print(L.NO_JUNK_ITEMS_TO_SELL) end
    return
  end

  EventManager:Fire(E.SellerStarted)
end

--- Waits for the bag items cache to settle, then sells the junk items, highest price first.
--- @param auto? boolean If `true`, no message is printed when there are no items to sell.
function Seller:Start(auto)
  -- Do not start if busy.
  if Addon:IsBusy() then return end
  -- Do not start without merchant.
  if not Addon:IsAtMerchant() then
    return Addon:Print(L.CANNOT_SELL_WITHOUT_MERCHANT)
  end

  -- Wait for the bag items cache to settle.
  local runId = RunState:Wait()
  BagItemsCache:WhenSettled(Seller.MAX_SETTLE_SECONDS, function()
    if RunState:IsCurrent(runId) then onWaitEnded(auto) end
  end)
end

--- Ends the run, whether it is waiting or selling. Fires `SellerStopped` only if it was selling.
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

--- Returns whether a run is waiting for the cache or selling.
--- @return boolean
function Seller:IsBusy()
  return RunState:IsBusy()
end
