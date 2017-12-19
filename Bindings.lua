-- Bindings: sets up binding data and functions.

local AddonName, DJ = ...
local _G = _G

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Core = DJ.Core
local Colors = DJ.Colors
local Destroyer = DJ.Destroyer
local ListManager = DJ.ListManager
local Tools = DJ.Tools

-- Variables
local currentItemID = nil

-- Hack to avoid errors when Colors:GetColor() is called before Dejunk has been
-- initialized. Called in Core:Initialize().
function Core:InitializeBindingStrings()
  -- Category
  _G["BINDING_CATEGORY_DEJUNK"] = Tools:GetColorString(AddonName, Colors.DefaultColors.LabelText)

  -- Blank headers
  _G["BINDING_HEADER_DEJUNKBLANK1"] = ""
  _G["BINDING_HEADER_DEJUNKBLANK2"] = ""
  _G["BINDING_HEADER_DEJUNKBLANK3"] = ""

  -- Inclusions
  _G["BINDING_NAME_DEJUNK_ADD_INCLUSIONS"] = format(L.BINDINGS_ADD_TO_LIST_TEXT, Tools:GetInclusionsString())
  _G["BINDING_NAME_DEJUNK_REM_INCLUSIONS"] = format(L.BINDINGS_REMOVE_FROM_LIST_TEXT, Tools:GetInclusionsString())

  -- Exclusions
  _G["BINDING_NAME_DEJUNK_ADD_EXCLUSIONS"] = format(L.BINDINGS_ADD_TO_LIST_TEXT, Tools:GetExclusionsString())
  _G["BINDING_NAME_DEJUNK_REM_EXCLUSIONS"] = format(L.BINDINGS_REMOVE_FROM_LIST_TEXT, Tools:GetExclusionsString())

  -- Destroyables
  _G["BINDING_NAME_DEJUNK_ADD_DESTROYABLES"] = format(L.BINDINGS_ADD_TO_LIST_TEXT, Tools:GetDestroyablesString())
  _G["BINDING_NAME_DEJUNK_REM_DESTROYABLES"] = format(L.BINDINGS_REMOVE_FROM_LIST_TEXT, Tools:GetDestroyablesString())

  -- Start destroying
  _G["BINDING_NAME_DEJUNK_START_DESTROY"] = L.START_DESTROYING_BUTTON_TEXT
end

-- ============================================================================
--                                List Bindings
-- ============================================================================

-- Inclusions
function DejunkBindings_AddToInclusions()
  if not currentItemID then return end
  ListManager:AddToList(ListManager.Inclusions, currentItemID)
end

function DejunkBindings_RemoveFromInclusions()
  if not currentItemID then return end
  ListManager:RemoveFromList(ListManager.Inclusions, currentItemID)
end

-- Exclusions
function DejunkBindings_AddToExclusions()
  if not currentItemID then return end
  ListManager:AddToList(ListManager.Exclusions, currentItemID)
end

function DejunkBindings_RemoveFromExclusions()
  if not currentItemID then return end
  ListManager:RemoveFromList(ListManager.Exclusions, currentItemID)
end

-- Destroyables
function DejunkBindings_AddToDestroyables()
  if not currentItemID then return end
  ListManager:AddToList(ListManager.Destroyables, currentItemID)
end

function DejunkBindings_RemoveFromDestroyables()
  if not currentItemID then return end
  ListManager:RemoveFromList(ListManager.Destroyables, currentItemID)
end

-- ============================================================================
--                              Non-List Bindings
-- ============================================================================

function DejunkBindings_StartDestroying()
  Destroyer:StartDestroying()
end

-- ============================================================================
--                             Item Tooltip Hook
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
