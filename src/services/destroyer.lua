local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local L = Addon:GetModule("Locale")
local Popup = Addon:GetModule("Popup")
local StateManager = Addon:GetModule("StateManager")

--- @class Destroyer
local Destroyer = Addon:GetModule("Destroyer")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Attempts to destroy `item`.
--- @param item BagItem
local function attemptDestroy(item)
  ClearCursor()
  C_Container.PickupContainerItem(item.bag, item.slot)
  DeleteCursorItem()
  EventManager:Fire(E.AttemptedToDestroyItem, item)
end

--- Attempts to destroy `item`, confirming first if Safe Destroy is enabled.
--- Does nothing if `item` is no longer in the bags or is locked.
--- @param item BagItem
local function handleItem(item)
  if not Items:IsItemStillInBags(item) then return end
  if Items:IsItemLocked(item) then return end

  if not StateManager:GetGlobalState().safeDestroy then
    attemptDestroy(item)
    return
  end

  local link = item.quantity > 1 and (item.link .. "x" .. item.quantity) or item.link
  local price = item.noValue and 0 or (item.price * item.quantity)
  link = link .. " " .. Colors.Grey("(%s)"):format(Colors.White(GetCoinTextureString(price)))
  Popup:Confirm({
    text = L.DESTROY_ITEM_POPUP_HELP:format(link),
    alert = true,
    onAccept = function() attemptDestroy(item) end
  })
end

-- ============================================================================
-- Destroyer
-- ============================================================================

function Destroyer:Start()
  -- Don't start if busy.
  if Addon:IsBusy() then return end

  -- Get item.
  local item = JunkFilter:GetNextDestroyableJunkItem()
  if not item then return Addon:Print(L.NO_JUNK_ITEMS_TO_DESTROY) end

  -- Handle item.
  handleItem(item)
end

function Destroyer:HandleItem(item)
  if not Addon:IsBusy() then handleItem(item) end
end
