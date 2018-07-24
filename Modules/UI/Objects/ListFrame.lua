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

local Colors = Addon.Colors
local ListManager = Addon.ListManager

-- ============================================================================
-- Local Functions
-- ============================================================================

-- Returns the localized text and tooltip for the list.
local function getListStrings(listName)
  -- NOTE: Holy fuck. Just change this to a single tooltip using [=[]=] string
  local baseTooltip = format("%s|n|n%s|n|n%s", L.LIST_FRAME_ADD_TOOLTIP,
    L.LIST_FRAME_REM_TOOLTIP, L.LIST_FRAME_REM_ALL_TOOLTIP)
    
  if (listName == ListManager.Inclusions) then
    local tooltip = format("%s|n|n%s", L.INCLUSIONS_TOOLTIP, baseTooltip)
    return L.INCLUSIONS_TEXT, tooltip
  elseif (listName == ListManager.Exclusions) then
    local tooltip = format("%s|n|n%s", L.EXCLUSIONS_TOOLTIP, baseTooltip)
    return L.EXCLUSIONS_TEXT, tooltip
  elseif (listName == ListManager.Destroyables) then
    local tooltip = format("%s|n|n%s", L.DESTROYABLES_TOOLTIP, baseTooltip)
    return L.DESTROYABLES_TEXT, tooltip
  else
    error(listName.." is not a valid list name.")
  end
end

local function createTitleButton(parent, listName, text, tooltip)
  local titleButton = DFL.Button:Create(parent, text, DFL.Fonts.Huge)
  titleButton:RegisterForClicks("RightButtonUp")
  titleButton:SetColors(Colors.None, Colors.None, Colors[listName], Colors[listName.."Hi"])
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
  frame:SetLayout(DFL.Layouts.FILL)
  frame:SetSpacing(DFL:Padding(0.25))

  local importButton = DFL.Button:Create(frame, L.IMPORT_TEXT, DFL.Fonts.Small)
  importButton:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
  importButton:SetScript("OnClick", function(self, button, down)
    Addon.ParentFrame:SetContent(Addon.TransportChildFrame)
    Addon.TransportChildFrame:SetData(listName, "IMPORT")
  end)
  frame._importButton = importButton
  frame:Add(importButton)

  local exportButton = DFL.Button:Create(frame, L.EXPORT_TEXT, DFL.Fonts.Small)
  exportButton:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
  exportButton:SetScript("OnClick", function(self, button, down)
    Addon.ParentFrame:SetContent(Addon.TransportChildFrame)
    Addon.TransportChildFrame:SetData(listName, "EXPORT")
  end)
  frame._exportButton = exportButton
  frame:Add(exportButton)

  return frame
end

-- ============================================================================
-- FauxScrollFrame._objFrame Functions
-- ============================================================================

-- Adds the item currently on the cursor to list.
local function addCursorItem(self)
  if self:IsEnabled() and CursorHasItem() then
    local infoType, itemID = GetCursorInfo()

    if (infoType == "item") then
      ListManager:AddToList(self._listName, itemID)
    end
    
    ClearCursor()
  end
end

-- Removes the item from the list by id.
local function removeItem(self, itemID)
  if self:IsEnabled() then
    ListManager:RemoveFromList(self._listName, itemID)
  end
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
  frame:SetSpacing(DFL:Padding(0.25))

  -- Title button
  local titleButton = createTitleButton(frame, listName, title, tooltip)
  frame._titleButton = titleButton
  frame:Add(titleButton)

  -- FauxScrollFrame
  local fsFrame = DFL.FauxScrollFrame:Create(frame, ListManager.Lists[listName], createListButton, 6)
  fsFrame:SetColors(Colors.ScrollFrame, {
    Colors.Slider,
    Colors.SliderThumb,
    Colors.SliderThumbHi
  })
  fsFrame._objFrame:SetScript("OnMouseUp", addCursorItem)
  fsFrame._objFrame.AddCursorItem = addCursorItem
  fsFrame._objFrame.RemoveItem = removeItem
  fsFrame._objFrame._listName = listName
  frame._fsFrame = fsFrame
  frame:Add(fsFrame)

  -- No items font string
  fsFrame._noItemsFS = DFL.FontString:Create(fsFrame._objFrame, L.NO_ITEMS_TEXT)
  fsFrame._noItemsFS:SetColors(Colors.LabelText)
  fsFrame._noItemsFS:SetPoint(DFL.Points.LEFT, DFL:Padding(0.5), 0)
  fsFrame._noItemsFS:SetPoint(DFL.Points.RIGHT, -DFL:Padding(0.5), 0)
  fsFrame._noItemsFS:SetJustifyH("CENTER")
  fsFrame._noItemsFS:SetAlpha(0.5)

  function fsFrame:OnUpdate(elapsed)
    if not self._objFrame:GetChildren()[1]:IsVisible() then
      self._noItemsFS:Show()
    else
      self._noItemsFS:Hide()
    end
  end

  -- Transport buttons
  local transportButtons = createTransportButtons(frame, listName)
  frame._transportButtons = transportButtons
  frame:Add(transportButtons)

  -- Mixins
  DFL:AddMixins(frame, self.Functions)

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = ListFrame.Functions

  Functions.SetColors = nop

  function Functions:Refresh()
    DFL.Frame.Functions.Refresh(self)
    self._fsFrame._noItemsFS:Refresh()
  end
end