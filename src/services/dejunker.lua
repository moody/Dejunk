local _, Addon = ...
local assert = assert
local Bags = Addon.Bags
local Consts = Addon.Consts
local Core = Addon.Core
local DB = Addon.DB
local Dejunker = Addon.Dejunker
local E = Addon.Events
local ERR_VENDOR_DOESNT_BUY = _G.ERR_VENDOR_DOESNT_BUY
local EventManager = Addon.EventManager
local Filters = Addon.Filters
local L = Addon.Libs.L
local STATICPOPUP_NUMDIALOGS = _G.STATICPOPUP_NUMDIALOGS
local tremove = table.remove
local UseContainerItem = _G.UseContainerItem

local States = {
  None = 0,
  Dejunking = 1
}

Dejunker.state = States.None
Dejunker.items = {}
Dejunker.timer = 0

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.MerchantShow, function()
  if DB.Profile.AutoSell then Dejunker:Start(true) end
end)

EventManager:On(E.Wow.MerchantClosed, function()
  if Dejunker:IsDejunking() then Dejunker:Stop() end
end)

EventManager:On(E.Wow.UIErrorMessage, function(_, msg)
  if Dejunker:IsDejunking() and msg == ERR_VENDOR_DOESNT_BUY then
    Dejunker:Stop()
  end
end)

-- ============================================================================
-- Functions
-- ============================================================================

-- Starts the dejunking process.
-- @param {boolean} auto
function Dejunker:Start(auto)
  local canDejunk, msg = Core:CanDejunk()
  if not canDejunk then
    if not auto then Core:Print(msg) end
    return
  end

  -- Get junk items
  Filters:GetItems(self, self.items)

  -- Stop if no items
  if #self.items == 0 then
    if not auto then
      Core:Print(
        self.items.allCached and
        L.NO_JUNK_ITEMS or
        L.NO_CACHED_JUNK_ITEMS
      )
    end

    return
  end

  -- If some items fail to be retrieved, we'll only have items that are cached
  if not self.items.allCached then
    Core:Print(L.ONLY_SELLING_CACHED)
  end

  -- SafeMode: remove items and print message as necessary
  if DB.Profile.SafeMode then
    while #self.items > Consts.SAFE_MODE_MAX do
      tremove(self.items)
    end

    if #self.items == Consts.SAFE_MODE_MAX then
      Core:Print(L.SAFE_MODE_MESSAGE:format(Consts.SAFE_MODE_MAX))
    end
  end

  -- Start
  self.state = States.Dejunking
  self.timer = 0
  EventManager:Fire(E.DejunkerStart)
end


-- Stops the dejunking process.
function Dejunker:Stop()
  assert(self.state ~= States.None)
  self.state = States.None
  EventManager:Fire(E.DejunkerStop)
end


-- Returns true if the Dejunker is active.
-- @return {boolean}
function Dejunker:IsDejunking()
  return self.state ~= States.None
end


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


-- Game update function called via `Addon.Core:OnUpdate()`.
-- @param {number} elapsed - time since last frame
function Dejunker:OnUpdate(elapsed)
  if self.state ~= States.Dejunking then return end

  self.timer = self.timer + elapsed

  if self.timer >= Core.MinDelay then
    self.timer = 0

    -- Get next item
    local item = tremove(self.items)

    -- Stop if there are no more items
    if not item then
      return self:Stop()
    end

    -- Otherwise, verify that the item in the bag slot has not been changed
    if not Bags:StillInBags(item) or Bags:IsLocked(item) then
      return
    end

    -- Sell item
    UseContainerItem(item.Bag, item.Slot)

    -- Handle StaticPopup
    if Addon.IS_RETAIL then handleStaticPopup() end

    -- Fire event
    EventManager:Fire(E.DejunkerAttemptToSell, item)
  end
end
