local ADDON_NAME, Addon = ...
local E = Addon.Events

-- ============================================================================
-- Addon Events
-- ============================================================================

local events = {
  -- DB
  "ProfileChanged",

  -- Lists
  "ListItemAdded"
}

for _, event in pairs(events) do
  assert(E[event] == nil)
  E[event] = ("%s_%s"):format(ADDON_NAME, event)
end

-- ============================================================================
-- WoW Events
-- ============================================================================

E.Wow = {
  PlayerLogin = "PLAYER_LOGIN",
  MerchantShow = "MERCHANT_SHOW",
  MerchantClosed = "MERCHANT_CLOSED",
  UIErrorMessage = "UI_ERROR_MESSAGE"
}
