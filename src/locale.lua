local Addon = select(2, ...) ---@type Addon

--- @class Locale
local L = Addon:GetModule("Locale")

setmetatable(L, {
  __index = function(t, k)
    return rawget(t, k) or k
  end
})

-- ============================================================================
-- English
-- ============================================================================

L["ADD_ALL_TO_LIST"] = "Add All to %s"
L["ADD_TO_LIST"] = "Add to %s"
L["ALL_ITEMS_REMOVED_FROM_LIST"] = "Removed all items from %s."
L["ALT_KEY"] = "Alt"
L["AUTO_JUNK_FRAME_TEXT"] = "Auto Junk Frame"
L["AUTO_JUNK_FRAME_TOOLTIP"] = "Automatically toggle the Junk frame upon interacting with a merchant."
L["AUTO_REPAIR_TEXT"] = "Auto Repair"
L["AUTO_REPAIR_TOOLTIP"] = "Automatically repair upon interacting with a merchant."
L["AUTO_SELL_TEXT"] = "Auto Sell"
L["AUTO_SELL_TOOLTIP"] = "Automatically sell items upon interacting with a merchant."
L["BAG_ITEM_ICONS_TEXT"] = "Bag Item Icons"
L["BAG_ITEM_ICONS_TOOLTIP"] = "Overlay an icon on junk items in your bags."
L["BAG_ITEM_TOOLTIPS_TEXT"] = "Bag Item Tooltips"
L["BAG_ITEM_TOOLTIPS_TOOLTIP"] = "Add Dejunk information to the tooltips of items in your bags."
L["CANNOT_OPEN_LOOTABLE_ITEMS"] = "Cannot open lootable items right now."
L["CANNOT_SELL_OR_DESTROY_ITEM"] = "Cannot sell or destroy %s."
L["CANNOT_SELL_WITHOUT_MERCHANT"] = "Cannot sell items without a merchant."
L["CHANGE_VALUE"] = "Change Value"
L["CHARACTER_SPECIFIC_SETTINGS_TEXT"] = "Character Specific Settings"
L["CHARACTER_SPECIFIC_SETTINGS_TOOLTIP"] = "Enable settings specific to this character."
L["CHARACTER"] = "Character"
L["CHAT_MESSAGES_TEXT"] = "Chat Messages"
L["CHAT_MESSAGES_TOOLTIP"] = "Enable chat messages."
L["CLEAR_SEARCH"] = "Clear Search"
L["CLEAR"] = "Clear"
L["COMMAND_DESCRIPTION_DESTROY"] = "Destroy the next junk item."
L["COMMAND_DESCRIPTION_HELP"] = "Display a list of commands."
L["COMMAND_DESCRIPTION_JUNK"] = "Toggle the junk frame."
L["COMMAND_DESCRIPTION_KEYBINDS"] = "Open the key binding frame."
L["COMMAND_DESCRIPTION_LOOT"] = "Open lootable items."
L["COMMAND_DESCRIPTION_OPTIONS"] = "Toggle the options frame."
L["COMMAND_DESCRIPTION_SELL"] = "Start selling junk items."
L["COMMAND_DESCRIPTION_TRANSPORT"] = "Toggle the transport frame."
L["COMMANDS"] = "Commands"
L["COMMON"] = "Common"
L["CONTROL_KEY"] = "Ctrl"
L["DESTROY_NEXT_ITEM"] = "Destroy Next Item"
L["DESTROY"] = "Destroy"
L["DESTROYED_ITEM"] = "Destroyed: %s."
L["EPIC"] = "Epic"
L["EXCLUDE_EQUIPMENT_SETS_TEXT"] = "Exclude Equipment Sets"
L["EXCLUDE_EQUIPMENT_SETS_TOOLTIP"] = "Exclude equipment that is saved to an equipment set."
L["EXCLUDE_UNBOUND_EQUIPMENT_TEXT"] = "Exclude Unbound Equipment"
L["EXCLUDE_UNBOUND_EQUIPMENT_TOOLTIP"] = "Exclude equipment that is not bound."
L["EXCLUDE_WARBAND_EQUIPMENT_TEXT"] = "Exclude Warband Equipment"
L["EXCLUDE_WARBAND_EQUIPMENT_TOOLTIP"] = "Exclude equipment that can be placed in the warband bank."
L["EXCLUDE"] = "Exclude"
L["EXCLUSIONS_DESCRIPTION_GLOBAL"] = "Items on this list will not be considered junk unless included by %s."
L["EXCLUSIONS_DESCRIPTION_PERCHAR"] = "Items on this list will never be considered junk."
L["EXCLUSIONS_TEXT"] = "Exclusions"
L["EXPORT"] = "Export"
L["FAILED_TO_DESTROY_ITEM"] = "Failed to destroy %s."
L["FAILED_TO_SELL_ITEM"] = "Failed to sell %s."
L["GENERAL"] = "General"
L["GLOBAL"] = "Global"
L["IMPORT"] = "Import"
L["INCLUDE_ARTIFACT_RELICS_TEXT"] = "Include Artifact Relics"
L["INCLUDE_ARTIFACT_RELICS_TOOLTIP"] = "Include artifact relic gems."
L["INCLUDE_BELOW_ITEM_LEVEL_POPUP_HELP"] = "Enter an item level:"
L["INCLUDE_BELOW_ITEM_LEVEL_TEXT"] = "Include Below Item Level"
L["INCLUDE_BELOW_ITEM_LEVEL_TOOLTIP"] = "Include equipment with an item level below a set value (%s).|n|nDoes not apply to generic items, cosmetic items, or fishing poles."
L["INCLUDE_BY_QUALITY_TEXT"] = "Include By Quality"
L["INCLUDE_BY_QUALITY_TOOLTIP"] = "Include items based on quality."
L["INCLUDE_UNSUITABLE_EQUIPMENT_TEXT"] = "Include Unsuitable Equipment"
L["INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP"] = "Include equipment with an armor or weapon type that is unsuitable for your class.|n|nDoes not apply to generic items, cosmetic items, or fishing poles."
L["INCLUDE"] = "Include"
L["INCLUSIONS_DESCRIPTION_GLOBAL"] = "Items on this list will be considered junk unless excluded by %s."
L["INCLUSIONS_DESCRIPTION_PERCHAR"] = "Items on this list will always be considered junk."
L["INCLUSIONS_TEXT"] = "Inclusions"
L["IS_BUSY_CONFIRMING_ITEMS"] = "Confirming items..."
L["IS_BUSY_SELLING_ITEMS"] = "Selling items..."
L["ITEM_ADDED_TO_LIST"] = "%s added to %s."
L["ITEM_ALREADY_ON_LIST"] = "%s is already on %s."
L["ITEM_ID_DOES_NOT_EXIST"] = "Item with ID %s does not exist."
L["ITEM_ID_FAILED_TO_PARSE"] = "Item with ID %s failed to parse and may not exist."
L["ITEM_IDS"] = "Item IDs"
L["ITEM_IS_JUNK"] = "This item is junk."
L["ITEM_IS_LOCKED"] = "Item is locked."
L["ITEM_IS_NOT_JUNK"] = "This item is not junk."
L["ITEM_IS_REFUNDABLE"] = "Item is refundable."
L["ITEM_NOT_ON_LIST"] = "%s is not on %s."
L["ITEM_QUALITY_CHECK_BOX_TOOLTIP"] = "Apply to items of this quality."
L["ITEM_REMOVED_FROM_LIST"] = "%s removed from %s."
L["JUNK_FRAME_TOOLTIP"] = "Junk items you currently possess will be listed in this frame.|n|nTo add an item to %s, drop it into the frame below.|n|nTo add an item to %s, hold %s and drop it into the frame below."
L["JUNK_ITEMS"] = "Junk Items"
L["KEYBINDS"] = "Keybinds"
L["LEFT_CLICK"] = "Left-Click"
L["LIST_FRAME_TOOLTIP"] = "To add an item, drop it into the frame below."
L["LIST_FRAME_TRANSPORT_BUTTON_TOOLTIP"] = "Toggle the Transport frame for this list."
L["LISTS"] = "Lists"
L["LOADING"] = "Loading"
L["MAY_NOT_HAVE_DESTROYED_ITEM"] = "May not have destroyed %s."
L["MAY_NOT_HAVE_SOLD_ITEM"] = "May not have sold %s."
L["MERCHANT_BUTTON_TEXT"] = "Merchant Button"
L["MERCHANT_BUTTON_TOOLTIP"] = "Enable a button on the merchant frame."
L["MINIMAP_ICON_TEXT"] = "Minimap Icon"
L["MINIMAP_ICON_TOOLTIP"] = "Enable an icon on the minimap."
L["NO_FILTERS_MATCHED"] = "No filters matched."
L["NO_ITEMS"] = "No items."
L["NO_JUNK_ITEMS_TO_DESTROY"] = "No junk items to destroy."
L["NO_JUNK_ITEMS_TO_SELL"] = "No junk items to sell."
L["NO_LOOTABLE_ITEMS_TO_OPEN"] = "No lootable items to open."
L["OPEN_LOOTABLE_ITEMS"] = "Open Lootable Items"
L["OPTIONS_TEXT"] = "Options"
L["POOR"] = "Poor"
L["PROFIT"] = "Profit: %s"
L["RARE"] = "Rare"
L["REMOVE_ALL_ITEMS"] = "Remove All Items"
L["REMOVE_FROM_LIST"] = "Remove from %s"
L["REMOVE"] = "Remove"
L["REPAIRED_ALL_ITEMS"] = "Repaired all items for %s."
L["RESET_POSITION"] = "Reset Position"
L["RIGHT_CLICK"] = "Right-Click"
L["SAFE_MODE_TEXT"] = "Safe Mode"
L["SAFE_MODE_TOOLTIP"] = "Only sell up to 12 items at a time."
L["SEARCH_LISTS"] = "Search Lists"
L["SELECT_ALL"] = "Select All"
L["SELL"] = "Sell"
L["SHIFT_KEY"] = "Shift"
L["SOLD_ITEM"] = "Sold: %s."
L["START_SELLING"] = "Start Selling"
L["TOGGLE_JUNK_FRAME"] = "Toggle Junk Frame"
L["TOGGLE_OPTIONS_FRAME"] = "Toggle Options Frame"
L["TRANSPORT_FRAME_TOOLTIP"] = "Use this frame to transport item IDs into or out of the target list.|n|nWhen importing, item IDs must be separated by a non-numeric character (e.g. 4983,58907,67410)."
L["TRANSPORT"] = "Transport"
L["UNCOMMON"] = "Uncommon"

-- ============================================================================
-- Others
-- ============================================================================

if GetLocale() == "deDE" then
  --@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "esES" then
  --@localization(locale="esES", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "esMX" then
  --@localization(locale="esMX", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "frFR" then
  --@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "itIT" then
  --@localization(locale="itIT", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "koKR" then
  --@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "ptBR" then
  --@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "ruRU" then
  --@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "zhCN" then
  --@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="ignore")@
end

if GetLocale() == "zhTW" then
  --@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="ignore")@
end
