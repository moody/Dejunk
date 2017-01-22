-- Dejunk: enUS (English) localization file.

local AddonName, AddonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(AddonName, 'enUS', true)

-- Selling
L.SOLD_YOUR_JUNK = "Sold your junk for %s."
L.MAY_NOT_HAVE_SOLD_ITEM = "May not have sold %s."
L.NO_JUNK_ITEMS = "No junk items to sell."

L.ONLY_SELLING_CACHED = "Some items could not be retrieved. Only selling cached junk items."
L.NO_CACHED_JUNK_ITEMS = "No junk items were found in the cache. Try again later."

L.VENDOR_DOESNT_BUY = "Cannot sell to that merchant."

-- Add item to list messages
L.ITEM_CANNOT_BE_SOLD = "%s cannot be sold."
L.ITEM_ALREADY_ON_LIST = "%s is already on %s."
L.ADDED_ITEM_TO_LIST = "Added %s to %s."

-- Remove item from list messages
L.REMOVED_ITEM_FROM_LIST = "Removed %s from %s."

-- Dejunk Button (on merchant frame)
L.DEJUNK_BUTTON_TOOLTIP = "Right-Click to toggle options."

-- Dejunk Options
L.DEJUNK_OPTIONS_TEXT = "[DEJUNK OPTIONS]"

-- Character Specific Settings
L.CHARACTER_SPECIFIC_TEXT = "Character Specific Settings"
L.CHARACTER_SPECIFIC_TOOLTIP = "Click this to toggle between global settings and settings specific to this character."

-- Sell all
L.SELL_ALL_TEXT = "Sell All:"
L.SELL_ALL_TOOLTIP = "Sell all items of this quality."

L.POOR_TEXT = "Poor"
L.COMMON_TEXT = "Common"
L.UNCOMMON_TEXT = "Uncommon"
L.RARE_TEXT = "Rare"
L.EPIC_TEXT = "Epic"

-- Auto sell
L.AUTO_SELL_TEXT = "Auto Sell"
L.AUTO_SELL_TOOLTIP = "Automatically sell junk items upon opening a merchant window."

-- Auto Repair
L.AUTO_REPAIR_TEXT = "Auto Repair"
L.AUTO_REPAIR_TOOLTIP = "Automatically repair items upon opening a merchant window.|n|nPrioritizes guild repairs when available."
L.REPAIRED_ALL_ITEMS = "Repaired all items for %s."
L.REPAIRED_ALL_ITEMS_GUILD = "Repaired all items for %s (Guild)."
L.REPAIRED_NO_ITEMS = "Not enough money to repair."

-- Safe Mode
L.SAFE_MODE_TEXT = "Safe Mode"
L.SAFE_MODE_TOOLTIP = "Only sell up to 12 items at a time."
L.SAFE_MODE_MESSAGE = "Safe Mode is enabled: only selling 12 items."

-- Silent Mode
L.SILENT_MODE_TEXT = "Silent Mode"
L.SILENT_MODE_TOOLTIP = "Disable Dejunk chat window messages."

-- Inclusions
L.INCLUSIONS_TEXT = "Inclusions"
L.INCLUSIONS_TOOLTIP = "Items on this list will always be sold."

-- Exclusions
L.EXCLUSIONS_TEXT = "Exclusions"
L.EXCLUSIONS_TOOLTIP = "Items on this list will never be sold."

-- Scroll Frame
L.SCROLL_FRAME_ADD_TOOLTIP = "To add an item, drop it into the frame below. (Items can only be added from your bags and inventory.)"
L.SCROLL_FRAME_REM_TOOLTIP = "To remove an item, highlight an entry and Right-Click."