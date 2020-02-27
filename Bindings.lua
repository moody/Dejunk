local AddonName, Addon = ...
local Colors = Addon.Colors
local Core = Addon.Core
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local Destroyables = Addon.Lists.Destroyables
local Destroyer = Addon.Destroyer
local Exclusions = Addon.Lists.Exclusions
local Inclusions = Addon.Lists.Inclusions
local L = Addon.Libs.L
local Lists = Addon.Lists
local MerchantFrame = _G.MerchantFrame
local UI = Addon.UI
local Undestroyables = Addon.Lists.Undestroyables
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

-- Inclusions
_G.BINDING_NAME_DEJUNK_ADD_INCLUSIONS = L.BINDINGS_ADD_TO_LIST_TEXT:format(Inclusions.localeColored)
_G.BINDING_NAME_DEJUNK_REM_INCLUSIONS = L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Inclusions.localeColored)

-- Exclusions
_G.BINDING_NAME_DEJUNK_ADD_EXCLUSIONS = L.BINDINGS_ADD_TO_LIST_TEXT:format(Exclusions.localeColored)
_G.BINDING_NAME_DEJUNK_REM_EXCLUSIONS = L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Exclusions.localeColored)

-- Destroyables
_G.BINDING_NAME_DEJUNK_ADD_DESTROYABLES = L.BINDINGS_ADD_TO_LIST_TEXT:format(Destroyables.localeColored)
_G.BINDING_NAME_DEJUNK_REM_DESTROYABLES = L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Destroyables.localeColored)

-- Undestroyables
_G.BINDING_NAME_DEJUNK_ADD_UNDESTROYABLES = L.BINDINGS_ADD_TO_LIST_TEXT:format(Undestroyables.localeColored)
_G.BINDING_NAME_DEJUNK_REM_UNDESTROYABLES = L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Undestroyables.localeColored)

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

function DejunkBindings_AddToList(listName)
  if not currentItemID then return end
  Lists[listName]:Add(currentItemID)
end

function DejunkBindings_RemoveFromList(listName)
  if not currentItemID then return end
  Lists[listName]:Remove(currentItemID, true)
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
