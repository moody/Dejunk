--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk: enUS (English) localization file.

local AddonName, AddonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(AddonName, 'enUS', true)

L["ADDED_ITEM_TO_LIST"] = "Added %s to %s."
L["AUTO_REPAIR_TEXT"] = "Auto Repair"
L["AUTO_REPAIR_TOOLTIP"] = "Automatically repair items upon opening a merchant window.|n|nPrioritizes guild repairs when available."
L["AUTO_SELL_TEXT"] = "Auto Sell"
L["AUTO_SELL_TOOLTIP"] = "Automatically sell junk items upon opening a merchant window."
L["BACK_TEXT"] = "Back"
L["CHARACTER_SPECIFIC_TEXT"] = "Character Specific Settings"
L["CHARACTER_SPECIFIC_TOOLTIP"] = "Click this to toggle between global settings and settings specific to this character."
L["COMMON_TEXT"] = "Common"
L["DEJUNK_BUTTON_TOOLTIP"] = "Right-Click to toggle options."
L["DEJUNK_OPTIONS_TEXT"] = "[DEJUNK OPTIONS]"
L["EPIC_TEXT"] = "Epic"
L["EXCLUSIONS_TEXT"] = "Exclusions"
L["EXCLUSIONS_TOOLTIP"] = "Items on this list will never be sold."
L["EXPORT_TEXT"] = "Export"
L["EXPORT_HELPER_TEXT"] = "When highlighted, use <Ctrl+C> or <Cmd+C> to copy the export string above."
L["EXPORT_LABEL_TEXT"] = "Export String"
L["EXPORT_TITLE_TEXT"] = "%s Export"
L["FAILED_TO_PARSE_ITEM_ID"] = "Item ID %s failed to parse and may not exist."
L["IMPORT_TEXT"] = "Import"
L["IMPORT_HELPER_TEXT"] = "Enter item IDs separated by a semi-colon (e.g. 4983;58907;67410)."
L["IMPORT_LABEL_TEXT"] = "Import String"
L["IMPORT_TITLE_TEXT"] = "%s Import"
L["INCLUSIONS_TEXT"] = "Inclusions"
L["INCLUSIONS_TOOLTIP"] = "Items on this list will always be sold."
L["ITEM_ALREADY_ON_LIST"] = "%s is already on %s."
L["ITEM_CANNOT_BE_SOLD"] = "%s cannot be sold."
L["MAY_NOT_HAVE_SOLD_ITEM"] = "May not have sold %s."
L["NO_CACHED_JUNK_ITEMS"] = "No junk items could be retrieved. Try again later."
L["NO_JUNK_ITEMS"] = "No junk items to sell."
L["ONLY_SELLING_CACHED"] = "Some items could not be retrieved. Only selling cached junk items."
L["POOR_TEXT"] = "Poor"
L["RARE_TEXT"] = "Rare"
L["REMOVED_ITEM_FROM_LIST"] = "Removed %s from %s."
L["REMOVED_ALL_FROM_LIST"] = "Removed all items from %s."
L["REPAIRED_ALL_ITEMS"] = "Repaired all items for %s."
L["REPAIRED_ALL_ITEMS_GUILD"] = "Repaired all items for %s (Guild)."
L["REPAIRED_NO_ITEMS"] = "Not enough money to repair."
L["SAFE_MODE_MESSAGE"] = "Safe Mode is enabled: only selling 12 items."
L["SAFE_MODE_TEXT"] = "Safe Mode"
L["SAFE_MODE_TOOLTIP"] = "Only sell up to 12 items at a time."
L["SCALE_TEXT"] = "Scale"
L["LIST_FRAME_ADD_TOOLTIP"] = "To add an item, drop it into the frame below. (Items can only be added from your bags and inventory.)"
L["LIST_FRAME_REM_TOOLTIP"] = "To remove an item, highlight an entry and Right-Click."
L["LIST_FRAME_REM_ALL_TOOLTIP"] = "To remove all items, hold <Shift+Alt> and Right-Click this title."
L["SELL_ALL_TEXT"] = "Sell All:"
L["SELL_ALL_TOOLTIP"] = "Sell all items of this quality."
L["SILENT_MODE_TEXT"] = "Silent Mode"
L["SILENT_MODE_TOOLTIP"] = "Disable Dejunk chat window messages."
L["SOLD_YOUR_JUNK"] = "Sold your junk for %s."
L["UNCOMMON_TEXT"] = "Uncommon"
L["VENDOR_DOESNT_BUY"] = "Cannot sell to that merchant."
