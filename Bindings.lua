-- Bindings: sets up binding data and functions.

local AddonName, Addon = ...
local _G = _G
local Colors = Addon.Colors
local DCL = Addon.Libs.DCL
local Destroyer = Addon.Destroyer
local L = Addon.Libs.L
local ListManager = Addon.ListManager
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
_G["BINDING_NAME_DEJUNK_ADD_INCLUSIONS"] = format(L.BINDINGS_ADD_TO_LIST_TEXT, Tools:GetInclusionsString())
_G["BINDING_NAME_DEJUNK_REM_INCLUSIONS"] = format(L.BINDINGS_REMOVE_FROM_LIST_TEXT, Tools:GetInclusionsString())

-- Exclusions
_G["BINDING_NAME_DEJUNK_ADD_EXCLUSIONS"] = format(L.BINDINGS_ADD_TO_LIST_TEXT, Tools:GetExclusionsString())
_G["BINDING_NAME_DEJUNK_REM_EXCLUSIONS"] = format(L.BINDINGS_REMOVE_FROM_LIST_TEXT, Tools:GetExclusionsString())

-- Destroyables
_G["BINDING_NAME_DEJUNK_ADD_DESTROYABLES"] = format(L.BINDINGS_ADD_TO_LIST_TEXT, Tools:GetDestroyablesString())
_G["BINDING_NAME_DEJUNK_REM_DESTROYABLES"] = format(L.BINDINGS_REMOVE_FROM_LIST_TEXT, Tools:GetDestroyablesString())

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
  ListManager:AddToList("Inclusions", currentItemID)
end

function DejunkBindings_RemoveFromInclusions()
  if not currentItemID then return end
  ListManager:RemoveFromList("Inclusions", currentItemID, true)
end

-- Exclusions
function DejunkBindings_AddToExclusions()
  if not currentItemID then return end
  ListManager:AddToList("Exclusions", currentItemID)
end

function DejunkBindings_RemoveFromExclusions()
  if not currentItemID then return end
  ListManager:RemoveFromList("Exclusions", currentItemID, true)
end

-- Destroyables
function DejunkBindings_AddToDestroyables()
  if not currentItemID then return end
  ListManager:AddToList("Destroyables", currentItemID)
end

function DejunkBindings_RemoveFromDestroyables()
  if not currentItemID then return end
  ListManager:RemoveFromList("Destroyables", currentItemID, true)
end

-- ============================================================================
-- Item Tooltip Hook
-- ============================================================================

do
  local function OnTooltipSetItem(self, ...)
    currentItemID = Tools:GetItemIDFromLink(select(2, self:GetItem()))
  end

  local function OnTooltipCleared(self, ...)
    currentItemID = nil
  end

  GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
  GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
end
