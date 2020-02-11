local AddonName, Addon = ...
local E = Addon.Events

-- ============================================================================
-- Addon Events
-- ============================================================================

local events = {
  -- DB
  "DatabaseReady",
  "ProfileChanged",

  -- Lists
  "ListItemAdded",
  "ListItemRemoved",
  "ListRemovedAll",

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
  BagUpdateDelayed = "BAG_UPDATE_DELAYED",
  PlayerLogin = "PLAYER_LOGIN",
  MerchantShow = "MERCHANT_SHOW",
  MerchantClosed = "MERCHANT_CLOSED",
  UIErrorMessage = "UI_ERROR_MESSAGE"
}
