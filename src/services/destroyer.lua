local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local JunkItemsCache = Addon:GetModule("JunkItemsCache")
local L = Addon:GetModule("Locale")
local Popup = Addon:GetModule("Popup")
local StateManager = Addon:GetModule("StateManager")

--- @class Destroyer
local Destroyer = Addon:GetModule("Destroyer")

--- How an attempt to destroy started: with the next junk item, or on a single item.
--- @alias DestroyAttemptType "NEXT" | "MANUAL"

--- An attempt to destroy an item. `AttemptedToDestroyItem` and the events that report its outcome carry it.
--- @class DestroyAttempt
--- @field item BagItem
--- @field type DestroyAttemptType
--- @field reason string? Why the junk filter called the item junk, or `nil` if it did not.

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Attempts to destroy `item` and fires `AttemptedToDestroyItem` with a `DestroyAttempt`.
--- @param item BagItem
--- @param attemptType DestroyAttemptType
local function attemptDestroy(item, attemptType)
  local isJunk, reason = JunkFilter:IsJunkItem(item, "DESTROY")

  ClearCursor()
  C_Container.PickupContainerItem(item.bag, item.slot)
  DeleteCursorItem()

  --- @type DestroyAttempt
  local attempt = { item = item, type = attemptType, reason = isJunk and reason or nil }
  EventManager:Fire(E.AttemptedToDestroyItem, attempt)
end

--- Attempts to destroy `item`, confirming first if Safe Destroy is enabled.
--- Does nothing if `item` is no longer in the bags or is locked.
--- @param item BagItem
--- @param attemptType DestroyAttemptType
local function handleItem(item, attemptType)
  if not Items:IsItemStillInBags(item) then return end
  if Items:IsItemLocked(item) then return end

  if not StateManager:GetGlobalState().safeDestroy then
    attemptDestroy(item, attemptType)
    return
  end

  local link = item.quantity > 1 and (item.link .. "x" .. item.quantity) or item.link
  local price = item.noValue and 0 or (item.price * item.quantity)
  link = link .. " " .. Colors.Grey("(%s)"):format(Colors.White(GetCoinTextureString(price)))
  Popup:Confirm({
    text = L.DESTROY_ITEM_POPUP_HELP:format(link),
    alert = true,
    onAccept = function() attemptDestroy(item, attemptType) end
  })
end

-- ============================================================================
-- Destroyer
-- ============================================================================

function Destroyer:Start()
  -- Don't start if busy.
  if Addon:IsBusy() then return end

  -- Get item.
  local item = JunkItemsCache:GetNextDestroyableJunkItem()
  if not item then return Addon:Print(L.NO_JUNK_ITEMS_TO_DESTROY) end

  -- Handle item.
  handleItem(item, "NEXT")
end

function Destroyer:HandleItem(item)
  if not Addon:IsBusy() then handleItem(item, "MANUAL") end
end
