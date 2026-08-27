local Addon = select(2, ...) ---@type Addon
local Commands = Addon:GetModule("Commands")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")

-- ============================================================================
-- Binding Strings
-- ============================================================================

-- Category.
BINDING_CATEGORY_DEJUNK = "|cFF4FAFE3Dejunk|r"

-- Headers.
BINDING_HEADER_DEJUNK_HEADER_BLANK1 = ""
BINDING_HEADER_DEJUNK_HEADER_BLANK2 = ""

-- General.
BINDING_NAME_DEJUNK_TOGGLE_OPTIONS_FRAME = L.TOGGLE_OPTIONS_FRAME
BINDING_NAME_DEJUNK_TOGGLE_JUNK_FRAME = L.TOGGLE_JUNK_FRAME
BINDING_NAME_DEJUNK_START_SELLING = L.START_SELLING
BINDING_NAME_DEJUNK_DESTROY_NEXT_ITEM = L.DESTROY_NEXT_ITEM
BINDING_NAME_DEJUNK_OPEN_LOOTABLES = L.OPEN_LOOTABLE_ITEMS

-- Lists.
BINDING_NAME_DEJUNK_ADD_GLOBAL_INCLUSIONS = L.ADD_TO_LIST:format(Lists.GlobalInclusions.name)
BINDING_NAME_DEJUNK_REM_GLOBAL_INCLUSIONS = L.REMOVE_FROM_LIST:format(Lists.GlobalInclusions.name)
BINDING_NAME_DEJUNK_ADD_PROFILE_INCLUSIONS = L.ADD_TO_LIST:format(Lists.ProfileInclusions.name)
BINDING_NAME_DEJUNK_REM_PROFILE_INCLUSIONS = L.REMOVE_FROM_LIST:format(Lists.ProfileInclusions.name)
BINDING_NAME_DEJUNK_ADD_GLOBAL_EXCLUSIONS = L.ADD_TO_LIST:format(Lists.GlobalExclusions.name)
BINDING_NAME_DEJUNK_REM_GLOBAL_EXCLUSIONS = L.REMOVE_FROM_LIST:format(Lists.GlobalExclusions.name)
BINDING_NAME_DEJUNK_ADD_PROFILE_EXCLUSIONS = L.ADD_TO_LIST:format(Lists.ProfileExclusions.name)
BINDING_NAME_DEJUNK_REM_PROFILE_EXCLUSIONS = L.REMOVE_FROM_LIST:format(Lists.ProfileExclusions.name)

-- ============================================================================
-- Binding Functions
-- ============================================================================

-- General.
DejunkBindings_ToggleOptionsFrame = Commands.options
DejunkBindings_ToggleJunkFrame = Commands.junk
DejunkBindings_StartSelling = Commands.sell
DejunkBindings_DestroyNextItem = Commands.destroy
DejunkBindings_OpenLootables = Commands.loot

--- Adds an item to a list. If `itemId` is not given, then
--- an attempt will be made to retrieve it from the `GameTooltip`.
--- @param listKey ListKey
--- @param itemId? string|number
function DejunkBindings_AddToList(listKey, itemId)
  if not itemId then
    local name, link = GameTooltip:GetItem()
    if name and link then itemId = GetItemInfoFromHyperlink(link) end
  end

  if itemId then Lists[listKey]:Add(itemId) end
end

--- Removes an item from a list. If `itemId` is not given, then
--- an attempt will be made to retrieve it from the `GameTooltip`.
--- @param listKey ListKey
--- @param itemId? string|number
function DejunkBindings_RemoveFromList(listKey, itemId)
  if not itemId then
    local name, link = GameTooltip:GetItem()
    if name and link then itemId = GetItemInfoFromHyperlink(link) end
  end

  if itemId then Lists[listKey]:Remove(itemId) end
end
