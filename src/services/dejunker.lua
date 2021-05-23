local _, Addon = ...
local Bags = Addon.Bags
local C_Timer = _G.C_Timer
local Chat = Addon.Chat
local Consts = Addon.Consts
local Core = Addon.Core
local DB = Addon.DB
local Dejunker = Addon.Dejunker
local E = Addon.Events
local ERR_VENDOR_DOESNT_BUY = _G.ERR_VENDOR_DOESNT_BUY
local EventManager = Addon.EventManager
local Filters = Addon.Filters
local ItemFrames = Addon.ItemFrames
local L = Addon.Libs.L
local Lists = Addon.Lists
local STATICPOPUP_NUMDIALOGS = _G.STATICPOPUP_NUMDIALOGS
local tremove = table.remove
local tsort = table.sort
local UI = Addon.UI
local UseContainerItem = _G.UseContainerItem

Dejunker.items = {}
Dejunker.isDejunking = false
Dejunker.timer = 0

-- ============================================================================
-- Events
-- ============================================================================

do -- E.Wow.MerchantShow
  local function autoStart()
    Dejunker:Start(true)
  end

  EventManager:On(E.Wow.MerchantShow, function()
    -- Auto Sell.
    if DB.Profile.sell.auto then C_Timer.After(0.1, autoStart) end
    -- Auto Open.
    if DB.Profile.sell.autoOpen then ItemFrames.Sell:Show() end
  end)
end

EventManager:On(E.Wow.MerchantClosed, function()
  -- Stop.
  if Dejunker:IsDejunking() then Dejunker:Stop() end
  -- Auto Open.
  if DB.Profile.sell.autoOpen then ItemFrames.Sell:Hide() end
end)

EventManager:On(E.Wow.UIErrorMessage, function(_, msg)
  if Dejunker:IsDejunking() and msg == ERR_VENDOR_DOESNT_BUY then
    Dejunker:Stop()
  end
end)

do -- Flag for refresh.
  local function flagForRefresh()
    Dejunker.needsRefresh = true
  end

  for _, e in ipairs({
    E.BagsUpdated,
    E.ListItemAdded,
    E.ListItemRemoved,
    E.ListRemovedAll,
    E.MainUIClosed,
    E.ProfileChanged,
    E.Wow.ItemUnlocked,
  }) do
    EventManager:On(e, flagForRefresh)
  end
end

-- ============================================================================
-- Local Functions
-- ============================================================================

-- Identifies and handles the StaticPopup shown when attempting to vendor a
-- tradeable item.
local function handleStaticPopup()
  -- Stop if not retail.
  if not Addon.IS_RETAIL then return end

  -- Handle popup.
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


local function handleItem(index)
  local item = tremove(Dejunker.items, index)
  if not item then return end

  -- Verify that the item can be sold.
  if not Bags:StillInBags(item) or Bags:IsLocked(item) then return end

  -- Sell item.
  UseContainerItem(item.Bag, item.Slot)

  -- Handle popup.
  handleStaticPopup()

  -- Fire event.
  EventManager:Fire(E.DejunkerAttemptToSell, item)
end

-- ============================================================================
-- Functions
-- ============================================================================

function Dejunker:GetItems()
  return self.items
end


function Dejunker:GetLists()
  return Lists.sell
end


function Dejunker:RefreshItems()
  -- Stop if selling is in progress.
  if self.isDejunking then return end

  -- Stop if not necessary.
  if not (self.needsRefresh or UI:IsShown()) then return end
  self.needsRefresh = false

  Filters:GetItems(self, self.items)

  -- Sort by quality.
  tsort(self.items, function(a, b)
    return (
      a.Quality == b.Quality and
      a.Name < b.Name or
      a.Quality < b.Quality
    )
  end)
end


function Dejunker:HandleNextItem(item)
  -- Stop if unsafe.
  local canDejunk, msg = Core:CanDejunk()
  if not canDejunk then
    return Chat:Print(msg)
  end

  -- Refresh items.
  self:RefreshItems()

  -- Stop if no items.
  if #self.items == 0 then
    return Chat:Print(L.NO_JUNK_ITEMS)
  end

  -- Get item index.
  local index = 1
  if item then
    -- Get index of specified item.
    index = nil
    for i, v in pairs(self.items) do
      if v == item then index = i end
    end
    -- Stop if the item was not found.
    if index == nil then return end
  end

  -- Handle item.
  handleItem(index)
end


-- Starts the dejunking process.
-- @param {boolean} auto
function Dejunker:Start(auto)
  -- Stop if unsafe.
  local canDejunk, msg = Core:CanDejunk()
  if not canDejunk then
    if not auto then Chat:Print(msg) end
    return
  end

  -- Refresh items.
  self:RefreshItems()

  -- Stop if no items.
  if #self.items == 0 then
    if not auto then
      Chat:Print(
        self.items.allCached and
        L.NO_JUNK_ITEMS or
        L.NO_CACHED_JUNK_ITEMS
      )
    end

    return
  end

  -- If some items fail to be retrieved, we'll only have items that are cached.
  if not self.items.allCached then
    Chat:Print(L.ONLY_SELLING_CACHED)
  end

  -- Safe Mode: remove items and print message as necessary.
  if DB.Profile.sell.safeMode then
    while #self.items > Consts.SAFE_MODE_MAX do
      tremove(self.items)
    end

    if #self.items == Consts.SAFE_MODE_MAX then
      Chat:Print(L.SAFE_MODE_MESSAGE:format(Consts.SAFE_MODE_MAX))
    end
  end

  -- Start.
  self.isDejunking = true
  self.timer = 0
  EventManager:Fire(E.DejunkerStart)
end


-- Stops the dejunking process.
function Dejunker:Stop()
  self.isDejunking = false
  EventManager:Fire(E.DejunkerStop)
end


-- Returns true if the Dejunker is active.
-- @return {boolean}
function Dejunker:IsDejunking()
  return self.isDejunking
end


-- Game update function called via `Addon.Core:OnUpdate()`.
-- @param {number} elapsed - time since last frame
function Dejunker:OnUpdate(elapsed)
  if not self.isDejunking then return end

  self.timer = self.timer + elapsed

  if self.timer >= Core.MinDelay then
    self.timer = 0

    -- Stop if there are no more items.
    if #self.items == 0 then
      return self:Stop()
    end

    -- Handle next item.
    handleItem()
  end
end
