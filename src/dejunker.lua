-- Dejunker: handles the process of selling junk items to merchants.

local _, Addon = ...
local assert = assert
local Confirmer = Addon.Confirmer
local Consts = Addon.Consts
local Core = Addon.Core
local DB = Addon.DB
local DBL = Addon.Libs.DBL
local Dejunker = Addon.Dejunker
local ERR_INTERNAL_BAG_ERROR = _G.ERR_INTERNAL_BAG_ERROR
local ERR_VENDOR_DOESNT_BUY = _G.ERR_VENDOR_DOESNT_BUY
local Filters = Addon.Filters
local format = string.format
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

-- Event handler.
function Dejunker:OnEvent(event, ...)
  if (event == "MERCHANT_SHOW") then
    if DB.Profile.AutoSell then self:StartDejunking(true) end
  elseif (event == "MERCHANT_CLOSED") then
    if self:IsSelling() then self:StopSelling() end
  elseif (event == "UI_ERROR_MESSAGE") then
    local _, msg = ...

    if self:IsDejunking() then
      if (msg == ERR_INTERNAL_BAG_ERROR) then
        UIErrorsFrame:Clear()
      elseif (msg == ERR_VENDOR_DOESNT_BUY) then
        UIErrorsFrame:Clear()
        Core:Print(L.VENDOR_DOESNT_BUY)
        self:StopDejunking()
      end
    end
  end
end

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
    local maxItems = DB.Profile.SafeMode and Consts.SAFE_MODE_MAX
    Filters:GetItems(self, itemsToSell, maxItems)

    -- Stop if no items
    if (#itemsToSell == 0) then
      if not auto then
        Core:Print(
          DBL:IsUpToDate() and L.NO_JUNK_ITEMS or L.NO_CACHED_JUNK_ITEMS
        )
      end
      self:StopDejunking()
      return
    end

    -- If DBL isn't up to date, we'll only have items that are cached
    if not DBL:IsUpToDate() then Core:Print(L.ONLY_SELLING_CACHED) end

    -- Print safe mode message if necessary
    if DB.Profile.SafeMode and (#itemsToSell == Consts.SAFE_MODE_MAX) then
      Core:Print(format(L.SAFE_MODE_MESSAGE, Consts.SAFE_MODE_MAX))
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
      if not DBL:StillInBags(item) or item:IsLocked() then return end
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
