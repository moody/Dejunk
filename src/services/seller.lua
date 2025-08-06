local Addon = select(2, ...) ---@type Addon
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

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.MerchantShow, function()
  TickerManager:After(0.1, function()
    local currentState = StateManager:GetCurrentState()

    -- Auto repair.
    if currentState.autoRepair then
      local repairCost, canRepair = GetRepairAllCost()
      if canRepair and GetMoney() >= repairCost then
        RepairAllItems()
        PlaySound(SOUNDKIT.ITEM_REPAIR)
        Addon:Print(L.REPAIRED_ALL_ITEMS:format(GetCoinTextureString(repairCost)))
      end
    end

    -- Auto sell.
    if currentState.autoSell then
      Seller:Start(true)
    end
  end)
end)

EventManager:On(E.Wow.MerchantClosed, function()
  Seller:Stop()
end)

EventManager:On(E.Wow.UIErrorMessage, function(_, msg)
  if msg == ERR_VENDOR_DOESNT_BUY then
    Seller:Stop()
  end
end)

-- ============================================================================
-- Local Functions
-- ============================================================================

local function handlePopup(popup)
  if popup and popup:IsShown() and popup.which == "CONFIRM_MERCHANT_TRADE_TIMER_REMOVAL" then
    local button = popup.GetButton1 and popup:GetButton1() or popup.button1
    button:Click()
  end
end

local function handleStaticPopup()
  if Addon.IS_VANILLA then return end

  if type(StaticPopup_ForEachShownDialog) == "function" then
    StaticPopup_ForEachShownDialog(handlePopup)
  else
    for i = 1, STATICPOPUP_NUMDIALOGS do
      local popup = _G["StaticPopup" .. i]
      handlePopup(popup)
    end
  end
end

local function handleItem(item)
  if not Items:IsItemStillInBags(item) then return end
  if Items:IsItemLocked(item) then return end

  C_Container.UseContainerItem(item.bag, item.slot)
  handleStaticPopup()

  EventManager:Fire(E.AttemptedToSellItem, item)
end

local function tickerCallback()
  local item = table.remove(Seller.items)
  if not item then return Seller:Stop() end
  handleItem(item)
end

-- ============================================================================
-- Seller
-- ============================================================================

function Seller:Start(auto)
  -- Don't start if busy.
  if Addon:IsBusy() then return end
  -- Don't start without merchant.
  if not Addon:IsAtMerchant() then
    return Addon:Print(L.CANNOT_SELL_WITHOUT_MERCHANT)
  end

  -- Get filtered items.
  self.items = JunkFilter:GetSellableJunkItems()

  -- Return if no items.
  if #self.items == 0 then
    if not auto then Addon:Print(L.NO_JUNK_ITEMS_TO_SELL) end
    return
  end

  -- Safe mode.
  if StateManager:GetCurrentState().safeMode then
    while #self.items > 12 do table.remove(self.items) end
  end

  -- Start ticker.
  self.ticker = TickerManager:NewTicker(Addon:GetLatency(), tickerCallback)
  EventManager:Fire(E.SellerStarted)
end

function Seller:Stop()
  if self:IsBusy() then
    self.ticker:Cancel()
    EventManager:Fire(E.SellerStopped)
  end
end

function Seller:HandleItem(item)
  if Addon:IsBusy() then return end

  if not Addon:IsAtMerchant() then
    return Addon:Print(L.CANNOT_SELL_WITHOUT_MERCHANT)
  end

  handleItem(item)
end

function Seller:IsBusy()
  return self.ticker and not self.ticker:IsCancelled()
end
