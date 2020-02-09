-- Dejunker: handles the process of selling junk items to merchants.

local _, Addon = ...
local assert = assert
local BagHelper = Addon.BagHelper
local Confirmer = Addon.Confirmer
local Consts = Addon.Consts
local Core = Addon.Core
local DB = Addon.DB
local Dejunker = Addon.Dejunker
local E = Addon.Events
local ERR_INTERNAL_BAG_ERROR = _G.ERR_INTERNAL_BAG_ERROR
local ERR_VENDOR_DOESNT_BUY = _G.ERR_VENDOR_DOESNT_BUY
local EventManager = Addon.EventManager
local Filters = Addon.Filters
local L = Addon.Libs.L
local STATICPOPUP_NUMDIALOGS = _G.STATICPOPUP_NUMDIALOGS
local tremove = table.remove
local UIErrorsFrame = _G.UIErrorsFrame
local UseContainerItem = _G.UseContainerItem

-- Variables
local states = {
  None = 0,
  Dejunking = 1,
  Selling = 2
}
local currentState = states.None

local itemsToSell = {}

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.MerchantShow, function()
  if DB.Profile.AutoSell then Dejunker:StartDejunking(true) end
end)

EventManager:On(E.Wow.MerchantClosed, function()
  if Dejunker:IsSelling() then Dejunker:StopSelling() end
end)

EventManager:On(E.Wow.UIErrorMessage, function(...)
  local _, msg = ...

  if Dejunker:IsDejunking() then
    if (msg == ERR_INTERNAL_BAG_ERROR) then
      UIErrorsFrame:Clear()
    elseif (msg == ERR_VENDOR_DOESNT_BUY) then
      UIErrorsFrame:Clear()
      Core:Print(L.VENDOR_DOESNT_BUY)
      Dejunker:StopDejunking()
    end
  end
end)

-- ============================================================================
-- Dejunking Functions
-- ============================================================================

do
  -- Starts the Dejunking process.
  -- @param auto - if the process was started automatically
  function Dejunker:StartDejunking(auto)
    local canDejunk, msg = Core:CanDejunk()
    if not canDejunk then
      if not auto then Core:Print(msg) end
      return
    end

    Confirmer:Start("Dejunker")
    currentState = states.Dejunking

    -- Get junk items
    Filters:GetItems(self, itemsToSell)

    -- Stop if no items
    if (#itemsToSell == 0) then
      if not auto then
        Core:Print(
          itemsToSell.allCached and
          L.NO_JUNK_ITEMS or
          L.NO_CACHED_JUNK_ITEMS
        )
      end

      return self:StopDejunking()
    end

    -- If some items fail to be retrieved, we'll only have items that are cached
    if not itemsToSell.allCached then
      Core:Print(L.ONLY_SELLING_CACHED)
    end

    -- SafeMode: remove items and print message as necessary
    if DB.Profile.SafeMode then
      while #itemsToSell > Consts.SAFE_MODE_MAX do
        tremove(itemsToSell)
      end

      if #itemsToSell == Consts.SAFE_MODE_MAX then
        Core:Print(L.SAFE_MODE_MESSAGE:format(Consts.SAFE_MODE_MAX))
      end
    end

    self:StartSelling()
  end

  -- Cancels the Dejunking process.
  function Dejunker:StopDejunking()
    assert(currentState ~= states.None)
    self.OnUpdate = nil
    Confirmer:Stop("Dejunker")
    currentState = states.None
  end

  -- Checks whether or not the Dejunker is active.
  -- @return - boolean
  function Dejunker:IsDejunking()
    return (currentState ~= states.None)
  end

  -- Returns true if the Dejunker is active or items are being confirmed.
  function Dejunker:IsBusy()
    return self:IsDejunking() or Confirmer:IsConfirming("Dejunker")
  end
end

-- ============================================================================
-- Selling Functions
-- ============================================================================

do
  local interval = 0

  -- Identifies and handles the StaticPopup shown when attempting to vendor a
  -- tradeable item.
  local function handleStaticPopup()
    local popup
    for i=1, STATICPOPUP_NUMDIALOGS do
      popup = _G["StaticPopup"..i]
      if
        popup and
        popup:IsShown() and
        popup.which == "CONFIRM_MERCHANT_TRADE_TIMER_REMOVAL"
      then
        popup.button1:Click()
        return
      end
    end
  end

  -- Selling update function
  local function sellItems_OnUpdate(self, elapsed)
    interval = interval + elapsed
    if (interval >= Core.MinDelay) then
      interval = 0

      -- Get next item
      local item = tremove(itemsToSell)
      -- Stop if there are no more items
      if not item then Dejunker:StopSelling() return end
      -- Otherwise, verify that the item in the bag slot has not been changed
      -- before selling
      if not BagHelper:StillInBags(item) or BagHelper:IsLocked(item) then return end
      -- Sell item
      UseContainerItem(item.Bag, item.Slot)
      -- Handle StaticPopup
      if Addon.IS_RETAIL then handleStaticPopup() end
      -- Notify confirmer
      Confirmer:Queue("Dejunker", item)
    end
  end

  -- Starts the selling process.
  function Dejunker:StartSelling()
    assert(currentState == states.Dejunking)
    assert(#itemsToSell > 0)
    currentState = states.Selling
    interval = 0
    self.OnUpdate = sellItems_OnUpdate
  end

  -- Cancels the selling process and stops dejunking.
  function Dejunker:StopSelling()
    assert(currentState == states.Selling)
    self.OnUpdate = nil
    self:StopDejunking()
  end

  -- Checks whether or not the Dejunker is actively selling items.
  -- @return - boolean
  function Dejunker:IsSelling()
    return (currentState == states.Selling)
  end
end
