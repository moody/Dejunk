-- Bindings: sets up binding data and functions.

local AddonName, Addon = ...
local _G = _G
local Colors = Addon.Colors
local DCL = Addon.Libs.DCL
local Destroyables = Addon.Lists.Destroyables
local Destroyer = Addon.Destroyer
local Exclusions = Addon.Lists.Exclusions
local Inclusions = Addon.Lists.Inclusions
local L = Addon.Libs.L
local Tools = Addon.Tools
local UI = Addon.UI

-- Variables
local currentItemID = nil

-- Category
_G["BINDING_CATEGORY_DEJUNK"] = DCL:ColorString(AddonName, Colors.Primary)

-- Blank headers
_G["BINDING_HEADER_DEJUNKBLANK1"] = ""
_G["BINDING_HEADER_DEJUNKBLANK2"] = ""
_G["BINDING_HEADER_DEJUNKBLANK3"] = ""

-- Toggle options
_G["BINDING_NAME_DEJUNK_TOGGLE_OPTIONS"] = L.BINDINGS_TOGGLE_OPTIONS_TEXT

-- Start destroying
_G["BINDING_NAME_DEJUNK_START_DESTROYING"] = L.START_DESTROYING_BUTTON_TEXT

-- Inclusions
_G["BINDING_NAME_DEJUNK_ADD_INCLUSIONS"] = L.BINDINGS_ADD_TO_LIST_TEXT:format(Inclusions.localeColored)
_G["BINDING_NAME_DEJUNK_REM_INCLUSIONS"] = L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Inclusions.localeColored)

-- Exclusions
_G["BINDING_NAME_DEJUNK_ADD_EXCLUSIONS"] = L.BINDINGS_ADD_TO_LIST_TEXT:format(Exclusions.localeColored)
_G["BINDING_NAME_DEJUNK_REM_EXCLUSIONS"] = L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Exclusions.localeColored)

-- Destroyables
_G["BINDING_NAME_DEJUNK_ADD_DESTROYABLES"] = L.BINDINGS_ADD_TO_LIST_TEXT:format(Destroyables.localeColored)
_G["BINDING_NAME_DEJUNK_REM_DESTROYABLES"] = L.BINDINGS_REMOVE_FROM_LIST_TEXT:format(Destroyables.localeColored)

-- ============================================================================
-- General Bindings
-- ============================================================================

function DejunkBindings_ToggleOptions()
  UI:Toggle()
end

function DejunkBindings_StartDestroying()
  Destroyer:StartDestroying()
end

-- ============================================================================
-- List Bindings
-- ============================================================================

-- Inclusions
function DejunkBindings_AddToInclusions()
  if not currentItemID then return end
  Inclusions:Add(currentItemID)
end

function DejunkBindings_RemoveFromInclusions()
  if not currentItemID then return end
  Inclusions:Remove(currentItemID, true)
end

-- Exclusions
function DejunkBindings_AddToExclusions()
  if not currentItemID then return end
  Exclusions:Add(currentItemID)
end

function DejunkBindings_RemoveFromExclusions()
  if not currentItemID then return end
  Exclusions:Remove(currentItemID, true)
end

-- Destroyables
function DejunkBindings_AddToDestroyables()
  if not currentItemID then return end
  Destroyables:Add(currentItemID)
end

function DejunkBindings_RemoveFromDestroyables()
  if not currentItemID then return end
  Destroyables:Remove(currentItemID, true)
end

-- ============================================================================
-- Item Tooltip Hook
-- ============================================================================

local function OnTooltipSetItem(self, ...)
  currentItemID = Tools:GetItemIDFromLink(select(2, self:GetItem()))
end

local function OnTooltipCleared(self, ...)
  currentItemID = nil
end

_G.GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
_G.GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
