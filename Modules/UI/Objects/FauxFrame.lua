-- FauxFrame: a customized DFL faux scroll frame for visually displaying list data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Upvalues
local IsAltKeyDown, IsShiftKeyDown = IsAltKeyDown, IsShiftKeyDown

-- Addon
local FauxFrame = Addon.Objects.FauxFrame
local Colors = Addon.Colors

-- ============================================================================
-- Local Functions
-- ============================================================================

local function createTitleButton(parent)
  local titleButton = DFL.Button:Create(parent, "", DFL.Fonts.Huge)
  titleButton:RegisterForClicks("RightButtonUp")
  titleButton:SetColors(Colors.None, Colors.None, Colors.LabelText, Colors.LabelText)

  -- Scripts
  titleButton:SetScript("OnEnter", function(self)
    DFL.Button.Scripts.OnEnter(self)
    DFL:ShowTooltip(self, DFL.Anchors.TOP, self._label:GetText(), self.Tooltip)
  end)

  titleButton:SetScript("OnLeave", function(self)
    DFL.Button.Scripts.OnLeave(self)
    DFL:HideTooltip()
  end)

  return titleButton
end

-- ============================================================================
-- Transport Button Functions
-- ============================================================================

local transportButtonData = {
  {
    key = "ImportButton",
    text = L.IMPORT_TEXT,
    type = "IMPORT"
  },
  {
    key = "ExportButton",
    text = L.EXPORT_TEXT,
    type = "EXPORT"
  }
}

local function transportButton_OnClick(self)
  Addon.Frames.ParentFrame:SetContent(Addon.Frames.TransportChildFrame)
  Addon.Frames.TransportChildFrame:SetData(self.ListName, self.TransportType)
end

local function createTransportButtons(parent, listName)
  local frame = DFL.Frame:Create(parent)
  frame:SetLayout(DFL.Layouts.FILL)
  frame:SetSpacing(DFL:Padding(0.25))

  for _, v in ipairs(transportButtonData) do
    local button = DFL.Button:Create(frame, v.text, DFL.Fonts.Small)
    button:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
    button:SetScript("OnClick", transportButton_OnClick)
    button.ListName = listName
    button.TransportType = v.type
    frame[v.key] = button
    frame:Add(button)
  end

  return frame
end

-- ============================================================================
-- FauxScrollFrame Functions
-- ============================================================================

local function fsFrame_OnUpdate(self, elapsed)
  self.ExportButton:SetEnabled(self:IsEnabled() and (#self._data > 0))
  
  if (#self._data == 0) then -- No items
    self.NoItemsFS:Show()
  else
    self.NoItemsFS:Hide()
  end
end

-- ============================================================================
-- Creation Function
-- ============================================================================

local BLANK_TABLE = {}

-- Creates and returns a Dejunk list frame.
-- @param parent - the parent frame
-- @param listName - the name of a ListManager list, or "Profiles"
function FauxFrame:Create(parent, listName, buttonFunc, numObjects)  
  local frame = DFL.Frame:Create(parent, DFL.Alignments.TOP, DFL.Directions.DOWN)
  frame:SetSpacing(DFL:Padding(0.25))

  -- Title button
  local titleButton = createTitleButton(frame)
  frame.TitleButton = titleButton
  frame:Add(titleButton)

  -- FauxScrollFrame
  local fsFrame = DFL.FauxScrollFrame:Create(frame, BLANK_TABLE, buttonFunc, numObjects)
  fsFrame:SetColors(Colors.ScrollFrame, Colors.SliderColors)
  fsFrame.OnUpdate = fsFrame_OnUpdate
  frame.FSFrame = fsFrame
  frame:Add(fsFrame)

  -- No items font string
  fsFrame.NoItemsFS = DFL.FontString:Create(fsFrame._objFrame, L.NO_ITEMS_TEXT)
  fsFrame.NoItemsFS:SetColors(Colors.LabelText)
  fsFrame.NoItemsFS:SetPoint(DFL.Points.LEFT, DFL:Padding(0.5), 0)
  fsFrame.NoItemsFS:SetPoint(DFL.Points.RIGHT, -DFL:Padding(0.5), 0)
  fsFrame.NoItemsFS:SetJustifyH("CENTER")
  fsFrame.NoItemsFS:SetAlpha(0.5)

  -- Transport buttons
  local transportButtons = createTransportButtons(frame, listName)
  fsFrame.ExportButton = transportButtons.ExportButton
  frame.TransportButtons = transportButtons
  frame:Add(transportButtons)

  -- Mixins
  DFL:AddMixins(frame, self.Functions)

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = FauxFrame.Functions

  Functions.SetColors = nop

  function Functions:Refresh()
    DFL.Frame.Functions.Refresh(self)
    self.FSFrame.NoItemsFS:Refresh()
  end
end
