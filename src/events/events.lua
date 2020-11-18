local AddonName, Addon = ...
local E = Addon.Events

-- ============================================================================
-- Addon Events
-- ============================================================================

local events = {
  -- Bags
  "BagsUpdated",

  -- DB
  "DatabaseReady",
  "ProfileChanged",

  -- Lists
  "ListItemAdded",
  "ListItemRemoved",
  "ListRemovedAll",

  -- Services
  "DejunkerStart",
  "DejunkerStop",
  "DejunkerAttemptToSell",

  "DestroyerAttemptToDestroy",

  -- UI
  "MainUIClosed",
}

for _, event in pairs(events) do
  assert(E[event] == nil)
  E[event] = ("%s_%s"):format(AddonName, event)
end

-- ============================================================================
-- WoW Events
-- ============================================================================

E.Wow = {
  BagUpdate = "BAG_UPDATE",
  BagUpdateDelayed = "BAG_UPDATE_DELAYED",
  ItemUnlocked = "ITEM_UNLOCKED",
  MerchantClosed = "MERCHANT_CLOSED",
  MerchantShow = "MERCHANT_SHOW",
  PlayerLogin = "PLAYER_LOGIN",
  UIErrorMessage = "UI_ERROR_MESSAGE"
}
