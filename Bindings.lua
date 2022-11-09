local ADDON_NAME, Addon = ...
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")

-- ============================================================================
-- Binding Strings
-- ============================================================================

-- Category.
BINDING_CATEGORY_DEJUNK = Colors.Blue(ADDON_NAME)

-- Headers.
BINDING_HEADER_DEJUNK_HEADER_GENERAL = L.GENERAL
BINDING_HEADER_DEJUNK_HEADER_LISTS = L.LISTS

-- General.
BINDING_NAME_DEJUNK_TOGGLE_OPTIONS_FRAME = L.TOGGLE_OPTIONS_FRAME
BINDING_NAME_DEJUNK_TOGGLE_JUNK_FRAME = L.TOGGLE_JUNK_FRAME
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
DejunkBindings_ToggleOptionsFrame = Commands.options
DejunkBindings_ToggleJunkFrame = Commands.junk
DejunkBindings_StartSelling = Commands.sell
DejunkBindings_DestroyNextItem = Commands.destroy
DejunkBindings_OpenLootables = Commands.loot

function DejunkBindings_AddToList(listKey)
  local name, link = GameTooltip:GetItem()
  if name and link then
    local id = GetItemInfoFromHyperlink(link)
    Lists[listKey]:Add(id)
  end
end

function DejunkBindings_RemoveFromList(listKey)
  local name, link = GameTooltip:GetItem()
  if name and link then
    local id = GetItemInfoFromHyperlink(link)
    Lists[listKey]:Remove(id)
  end
end
