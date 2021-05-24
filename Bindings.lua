local AddonName, Addon = ...
local Chat = Addon.Chat
local Colors = Addon.Colors
local Commands = Addon.Commands
local DCL = Addon.Libs.DCL
local L = Addon.Libs.L
local Lists = Addon.Lists
local Utils = Addon.Utils

-- Variables
local currentItemID = nil

-- ============================================================================
-- Binding Strings
-- ============================================================================

-- Category.
_G.BINDING_CATEGORY_DEJUNK = DCL:ColorString(AddonName, Colors.Primary)

-- Headers.
for i=1, 3 do _G["BINDING_HEADER_DEJUNK_HEADER_BLANK"..i] = "" end
_G.BINDING_HEADER_DEJUNK_HEADER_GENERAL = L.GENERAL_TEXT
_G.BINDING_HEADER_DEJUNK_HEADER_SELL = L.SELL_TEXT
_G.BINDING_HEADER_DEJUNK_HEADER_DESTROY = L.DESTROY_TEXT
_G.BINDING_HEADER_DEJUNK_HEADER_LISTS = L.LISTS_TEXT

-- General.
_G.BINDING_NAME_DEJUNK_TOGGLE_OPTIONS_FRAME = L.TOGGLE_OPTIONS_FRAME
_G.BINDING_NAME_DEJUNK_TOGGLE_SELL_FRAME = L.TOGGLE_SELL_FRAME
_G.BINDING_NAME_DEJUNK_TOGGLE_DESTROY_FRAME = L.TOGGLE_DESTROY_FRAME
_G.BINDING_NAME_DEJUNK_OPEN_LOOTABLES = L.OPEN_LOOTABLES

-- Sell.
_G.BINDING_NAME_DEJUNK_START_SELLING = L.START_SELLING_BUTTON_TEXT
_G.BINDING_NAME_DEJUNK_SELL_NEXT_ITEM = L.SELL_NEXT_ITEM
_G.BINDING_NAME_DEJUNK_ADD_INCLUSIONS =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.sell.inclusions.profile.locale)
_G.BINDING_NAME_DEJUNK_REM_INCLUSIONS =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.sell.inclusions.profile.locale)
_G.BINDING_NAME_DEJUNK_ADD_EXCLUSIONS =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.sell.exclusions.profile.locale)
_G.BINDING_NAME_DEJUNK_REM_EXCLUSIONS =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.sell.exclusions.profile.locale)
_G.BINDING_NAME_DEJUNK_ADD_INCLUSIONS_GLOBAL =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.sell.inclusions.global.locale)
_G.BINDING_NAME_DEJUNK_REM_INCLUSIONS_GLOBAL =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.sell.inclusions.global.locale)
_G.BINDING_NAME_DEJUNK_ADD_EXCLUSIONS_GLOBAL =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.sell.exclusions.global.locale)
_G.BINDING_NAME_DEJUNK_REM_EXCLUSIONS_GLOBAL =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.sell.exclusions.global.locale)

-- Destroy.
_G.BINDING_NAME_DEJUNK_START_DESTROYING = L.START_DESTROYING
_G.BINDING_NAME_DEJUNK_DESTROY_NEXT_ITEM = L.DESTROY_NEXT_ITEM
_G.BINDING_NAME_DEJUNK_ADD_DESTROYABLES =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.destroy.inclusions.profile.locale)
_G.BINDING_NAME_DEJUNK_REM_DESTROYABLES =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.destroy.inclusions.profile.locale)
_G.BINDING_NAME_DEJUNK_ADD_UNDESTROYABLES =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.destroy.exclusions.profile.locale)
_G.BINDING_NAME_DEJUNK_REM_UNDESTROYABLES =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.destroy.exclusions.profile.locale)
_G.BINDING_NAME_DEJUNK_ADD_DESTROYABLES_GLOBAL =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.destroy.inclusions.global.locale)
_G.BINDING_NAME_DEJUNK_REM_DESTROYABLES_GLOBAL =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.destroy.inclusions.global.locale)
_G.BINDING_NAME_DEJUNK_ADD_UNDESTROYABLES_GLOBAL =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.destroy.exclusions.global.locale)
_G.BINDING_NAME_DEJUNK_REM_UNDESTROYABLES_GLOBAL =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.destroy.exclusions.global.locale)

-- ============================================================================
-- Binding Functions
-- ============================================================================

-- General.
DejunkBindings_ToggleOptionsFrame = Commands.toggle
DejunkBindings_ToggleSellFrame = Commands.sell
DejunkBindings_ToggleDestroyFrame = Commands.destroy
DejunkBindings_OpenLootables = Commands.open

-- Sell.
DejunkBindings_StartSelling = Commands.sell.subcommands.start
DejunkBindings_SellNextItem = Commands.sell.subcommands.next

-- Destroy.
DejunkBindings_StartDestroying = Commands.destroy.subcommands.start
DejunkBindings_DestroyNextItem = Commands.destroy.subcommands.next

function DejunkBindings_AddToList(groupName, listName, listType)
  if not currentItemID then return end
  Lists[groupName][listName][listType]:Add(currentItemID)
end

function DejunkBindings_RemoveFromList(groupName, listName, listType)
  if not currentItemID then return end
  Lists[groupName][listName][listType]:Remove(currentItemID, true)
end

-- ============================================================================
-- Item Tooltip Hook
-- ============================================================================

_G.GameTooltip:HookScript("OnTooltipSetItem", function(self, ...)
  currentItemID = Utils:GetItemIDFromLink(select(2, self:GetItem()))
end)

_G.GameTooltip:HookScript("OnTooltipCleared", function(self, ...)
  currentItemID = nil
end)

