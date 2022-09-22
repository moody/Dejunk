local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local Commands = Addon.Commands
local L = Addon.Locale
local Lists = Addon.Lists

local currentItemId = nil

-- ============================================================================
-- Binding Strings
-- ============================================================================

-- Category.
BINDING_CATEGORY_DEJUNK = Colors.Blue(ADDON_NAME)

-- Headers.
BINDING_HEADER_DEJUNK_HEADER_GENERAL = L.GENERAL
BINDING_HEADER_DEJUNK_HEADER_LISTS = L.LISTS

-- General.
BINDING_NAME_DEJUNK_TOGGLE_OPTIONS_FRAME = L.TOGGLE_USER_INTERFACE
BINDING_NAME_DEJUNK_START_SELLING = L.START_SELLING
BINDING_NAME_DEJUNK_DESTROY_NEXT_ITEM = L.DESTROY_NEXT_ITEM
BINDING_NAME_DEJUNK_OPEN_LOOTABLES = L.OPEN_LOOTABLE_ITEMS

-- Lists.
BINDING_NAME_DEJUNK_ADD_INCLUSIONS = L.BINDINGS_ADD_TO_LIST:format(Lists.Inclusions.name)
BINDING_NAME_DEJUNK_REM_INCLUSIONS = L.BINDINGS_REMOVE_FROM_LIST:format(Lists.Inclusions.name)
BINDING_NAME_DEJUNK_ADD_EXCLUSIONS = L.BINDINGS_ADD_TO_LIST:format(Lists.Exclusions.name)
BINDING_NAME_DEJUNK_REM_EXCLUSIONS = L.BINDINGS_REMOVE_FROM_LIST:format(Lists.Exclusions.name)

-- ============================================================================
-- Binding Functions
-- ============================================================================

-- General.
DejunkBindings_ToggleOptionsFrame = Commands.toggle
DejunkBindings_StartSelling = Commands.sell
DejunkBindings_DestroyNextItem = Commands.destroy
DejunkBindings_OpenLootables = Commands.loot

function DejunkBindings_AddToList(listKey)
  if not currentItemId then return end
  Lists[listKey]:Add(currentItemId)
end

function DejunkBindings_RemoveFromList(listKey)
  if not currentItemId then return end
  local list = Lists[listKey]
  list:Remove(currentItemId)
end

-- ============================================================================
-- Item Tooltip Hook
-- ============================================================================

GameTooltip:HookScript("OnTooltipSetItem", function(self)
  local link = select(2, self:GetItem())
  if not link then return end
  currentItemId = GetItemInfoFromHyperlink(link)
end)

GameTooltip:HookScript("OnTooltipCleared", function(self)
  currentItemId = nil
end)
