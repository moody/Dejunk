-- ListFrame: a customized DFL faux scroll frame for visually displaying list data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Upvalues
local IsAltKeyDown, IsShiftKeyDown = IsAltKeyDown, IsShiftKeyDown

-- Addon
local ListFrame = Addon.Objects.ListFrame
ListFrame.Scripts = {}

local ListManager = Addon.ListManager

-- ============================================================================
-- Local Functions
-- ============================================================================

-- Returns the localized text and tooltip for the list.
local function getListStrings(listName)
  if (listName == ListManager.Inclusions) then
    return L.INCLUSIONS_TEXT, L.INCLUSIONS_TOOLTIP
  elseif (listName == ListManager.Exclusions) then
    return L.EXCLUSIONS_TEXT, L.EXCLUSIONS_TOOLTIP
  elseif (listName == ListManager.Destroyables) then
    return L.DESTROYABLES_TEXT, L.DESTROYABLES_TOOLTIP
  else
    error(listName.." is not a valid list name.")
  end
end

local function createTitleButton(parent, listName, text, tooltip)
  local titleButton = DFL.Button:Create(parent, text, DFL.Fonts.Huge)
  titleButton:RegisterForClicks("RightButtonUp")
  titleButton:SetColors(DFL.Colors.None, DFL.Colors.None)--, Colors[listName], Colors[listName.."Hi"])
  titleButton._listName = listName
  titleButton._tooltip = tooltip

  -- Scripts
  titleButton:SetScript("OnClick", function(self, button, down)
    if ((button == "RightButton") and IsShiftKeyDown() and IsAltKeyDown()) then
      ListManager:DestroyList(self._listName)
    end
  end)

  titleButton:SetScript("OnEnter", function(self)
    DFL.Button.Scripts.OnEnter(self)
    DFL:ShowTooltip(self, DFL.Anchors.TOP, self._label:GetText(), self._tooltip)
  end)

  titleButton:SetScript("OnLeave", function(self)
    DFL.Button.Scripts.OnLeave(self)
    DFL:HideTooltip()
  end)

  return titleButton
end

local function createListButton(parent)
  return Addon.Objects.ListButton:Create(parent)
end

local function createTransportButtons(parent, listName)
  local frame = DFL.Frame:Create(parent)
  frame:SetSpacing(DFL:Padding(0.25))

  local importButton = DFL.Button:Create(parent, L.IMPORT_TEXT, DFL.Fonts.Small)
  importButton:SetScript("OnClick", function(self, button, down)
    Addon.Core:ShowTransportChild(listName, Addon.Frames.TransportChildFrame.Import)
  end)
  frame._importButton = importButton
  frame:Add(importButton)

  local exportButton = DFL.Button:Create(parent, L.EXPORT_TEXT, DFL.Fonts.Small)
  exportButton:SetScript("OnClick", function(self, button, down)
    Addon.Core:ShowTransportChild(listName, Addon.Frames.TransportChildFrame.Export)
  end)
  frame._exportButton = exportButton
  frame:Add(exportButton)

  return frame
end

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame.
-- @param parent - the parent frame
-- @param listName - the name of a ListManager list
function ListFrame:Create(parent, listName)  
  local title, tooltip = getListStrings(listName)

  local frame = DFL.Frame:Create(parent, DFL.Alignments.TOP, DFL.Directions.DOWN)
  frame:SetSpacing(DFL:Padding(0.5))
  -- Title button
  local titleButton = createTitleButton(frame, listName, title, tooltip)
  frame._titleButton = titleButton
  frame:Add(titleButton)
  -- FauxScrollFrame
  local fsFrame = DFL.FauxScrollFrame:Create(frame, ListManager.Lists[listName], createListButton, 6)
  frame._fsFrame = fsFrame
  frame:Add(fsFrame)
  -- Transport buttons
  local transportButtons = createTransportButtons(frame, listName)
  frame._transportButtons = transportButtons
  frame:Add(transportButtons)

  -- Mixins
  DFL:AddMixins(frame, self.Functions)

  frame:SetColors()
  frame:Refresh()

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = ListFrame.Functions

  function Functions:SetColors()
  end
end
