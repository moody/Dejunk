local _, Addon = ...
local E = Addon:GetModule("Events") ---@class Events

-- ============================================================================
-- Dejunk Events
-- ============================================================================

E.AttemptedToDestroyItem = "Dejunk_AttemptedToDestroyItem"
E.AttemptedToSellItem = "Dejunk_AttemptedToSellItem"
E.BagsUpdated = "Dejunk_BagsUpdated"
E.ListItemCannotBeParsed = "Dejunk_ListItemCannotBeParsed"
E.ListItemFailedToParse = "Dejunk_ListItemFailedToParse"
E.ListItemParsed = "Dejunk_ListItemParsed"
E.SellerStarted = "Dejunk_SellerStarted"
E.SellerStopped = "Dejunk_SellerStopped"
E.StateUpdated = "Dejunk_StateUpdated"
E.StoreCreated = "Dejunk_StoreCreated"

-- ============================================================================
-- WoW Events
-- ============================================================================

E.Wow = {
  BagUpdate = "BAG_UPDATE",
  BagUpdateDelayed = "BAG_UPDATE_DELAYED",
  EquipmentSetsChanged = "EQUIPMENT_SETS_CHANGED",
  InventorySearchUpdate = "INVENTORY_SEARCH_UPDATE",
  ItemLocked = "ITEM_LOCKED",
  ItemUnlocked = "ITEM_UNLOCKED",
  MerchantClosed = "MERCHANT_CLOSED",
  MerchantShow = "MERCHANT_SHOW",
  PlayerLevelUp = "PLAYER_LEVEL_UP",
  PlayerLogin = "PLAYER_LOGIN",
  UIErrorMessage = "UI_ERROR_MESSAGE"
}
