local AddonName, Addon = ...
local Colors = Addon.Colors
local Core = Addon.Core
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local L = Addon.Libs.L
local Lists = Addon.Lists
local MerchantFrame = _G.MerchantFrame
local UI = Addon.UI
local Utils = Addon.Utils

-- Variables
local currentItemID = nil

-- ============================================================================
-- Binding Strings
-- ============================================================================

-- Category
_G.BINDING_CATEGORY_DEJUNK = DCL:ColorString(AddonName, Colors.Primary)

-- General
_G.BINDING_NAME_DEJUNK_TOGGLE_OPTIONS = L.BINDINGS_TOGGLE_OPTIONS_TEXT
_G.BINDING_NAME_DEJUNK_START_SELLING = L.START_SELLING_BUTTON_TEXT
_G.BINDING_NAME_DEJUNK_START_DESTROYING = L.START_DESTROYING_BUTTON_TEXT

-- Sell Inclusions
_G.BINDING_NAME_DEJUNK_ADD_SELL_INCLUSIONS =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.sell.inclusions.localeColored)
_G.BINDING_NAME_DEJUNK_REM_SELL_INCLUSIONS =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.sell.inclusions.localeColored)

-- Sell Exclusions
_G.BINDING_NAME_DEJUNK_ADD_SELL_EXCLUSIONS =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.sell.exclusions.localeColored)
_G.BINDING_NAME_DEJUNK_REM_SELL_EXCLUSIONS =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.sell.exclusions.localeColored)

-- Destroy Inclusions
_G.BINDING_NAME_DEJUNK_ADD_DESTROY_INCLUSIONS =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.destroy.inclusions.localeColored)
_G.BINDING_NAME_DEJUNK_REM_DESTROY_INCLUSIONS =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.destroy.inclusions.localeColored)

-- Destroy Exclusions
_G.BINDING_NAME_DEJUNK_ADD_DESTROY_EXCLUSIONS =
  L.BINDINGS_ADD_TO_LIST_TEXT:format(Lists.destroy.exclusions.localeColored)
_G.BINDING_NAME_DEJUNK_REM_DESTROY_EXCLUSIONS =
  L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Lists.destroy.exclusions.localeColored)

-- ============================================================================
-- Binding Functions
-- ============================================================================

function DejunkBindings_ToggleOptions()
  UI:Toggle()
end

function DejunkBindings_StartSelling()
  if MerchantFrame:IsShown() then
    Dejunker:Start()
  else
    Core:Print(L.CANNOT_SELL_WITHOUT_MERCHANT)
  end
end

function DejunkBindings_StartDestroying()
  Destroyer:Start()
end

function DejunkBindings_AddToList(groupName, listName)
  if not currentItemID then return end
  Lists[groupName][listName]:Add(currentItemID)
end

function DejunkBindings_RemoveFromList(groupName, listName)
  if not currentItemID then return end
  Lists[groupName][listName]:Remove(currentItemID, true)
end

-- ============================================================================
-- Item Tooltip Hook
-- ============================================================================

local function OnTooltipSetItem(self, ...)
  currentItemID = Utils:GetItemIDFromLink(select(2, self:GetItem()))
end

local function OnTooltipCleared(self, ...)
  currentItemID = nil
end

_G.GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
_G.GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
