local _, Addon = ...
local E = Addon.Events
local EventManager = Addon.EventManager
local Items = Addon.Items
local JunkFilter = Addon.JunkFilter
local L = Addon.Locale
local Lists = Addon.Lists
local SavedVariables = Addon.SavedVariables
local Seller = Addon.Seller
local Sounds = Addon.Sounds

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.MerchantShow, function()
  C_Timer.After(0.1, function()
    local savedVariables = SavedVariables:Get()

    -- Auto repair.
    if savedVariables.autoRepair then
      local repairCost, canRepair = GetRepairAllCost()
      if canRepair and GetMoney() >= repairCost then
        Sounds.Repair()
        RepairAllItems()
        Addon:Print(L.REPAIRED_ALL_ITEMS:format(GetCoinTextureString(repairCost)))
      end
    end

    -- Auto sell.
    if savedVariables.autoSell then
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

local function handleStaticPopup()
  if not Addon.IS_RETAIL then return end

  local popup
  for i = 1, STATICPOPUP_NUMDIALOGS do
    popup = _G["StaticPopup" .. i]
    if popup and
        popup:IsShown() and
        popup.which == "CONFIRM_MERCHANT_TRADE_TIMER_REMOVAL"
    then
      popup.button1:Click()
      return
    end
  end
end

local function handleNextItem()
  local item = table.remove(Seller.items)
  if not item then return Seller:Stop() end

  if not Items:IsItemStillInBags(item) then return end
  if Items:IsItemLocked(item) then return end

  UseContainerItem(item.bag, item.slot)
  handleStaticPopup()

  EventManager:Fire(E.AttemptedToSellItem, item)
end

local function canStartSelling()
  if not (MerchantFrame and MerchantFrame:IsShown()) then
    return false, L.CANNOT_SELL_WITHOUT_MERCHANT
  end

  if Seller:IsBusy() then
    return false, L.SELLING_ALREADY_IN_PROGRESS
  end

  if Lists:IsBusy() then
    return false, L.CANNOT_SELL_WHILE_LISTS_UPDATING
  end

  return true
end

-- ============================================================================
-- Seller
-- ============================================================================

function Seller:Start(auto)
  local canStart, reason = canStartSelling()
  if not canStart then
    if not auto then Addon:Print(reason) end
    return
  end

  -- Get filtered items.
  self.items = JunkFilter:GetSellableJunkItems()

  -- Return if no items.
  if #self.items == 0 then
    if not auto then Addon:Print(L.NO_JUNK_ITEMS_TO_SELL) end
    return
  end

  -- Safe mode.
  if SavedVariables:Get().safeMode then
    while #self.items > 12 do table.remove(self.items) end
  end

  -- Start ticker.
  local home, world = select(3, GetNetStats())
  local latency = max(max(home, world) * 0.001, 0.2)
  self.ticker = C_Timer.NewTicker(latency, handleNextItem)
  EventManager:Fire(E.SellerStarted)
end

function Seller:Stop()
  if self:IsBusy() then
    self.ticker:Cancel()
    EventManager:Fire(E.SellerStopped)
  end
end

function Seller:IsBusy()
  return self.ticker and not self.ticker:IsCancelled()
end
