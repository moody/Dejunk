-- Dejunk_TransportChildFrame: displays an edit box for importing or exporting list data.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local TransportChildFrame = DJ.DejunkFrames.TransportChildFrame

local Core = DJ.Core
local Colors = DJ.Colors
local Tools = DJ.Tools
local ListManager = DJ.ListManager
local FrameFactory = DJ.FrameFactory

-- Variables
TransportChildFrame.Types =
{
  ["Import"] = true,
  ["Export"] = true,
}

-- Add type keys
for k in pairs(TransportChildFrame.Types) do
  TransportChildFrame[k] = k end

local currentList = nil
local currentType = nil

-- ============================================================================
--                          Frame Lifecycle Functions
-- ============================================================================

function TransportChildFrame:OnInitialize()
  self:CreateTransportFrame()
end

function TransportChildFrame:OnRefresh()
  if not currentList then return end

  -- Recolor the title text when the color scheme changes
  local titleText = (currentType == self.Import) and
    L.IMPORT_TITLE_TEXT or L.EXPORT_TITLE_TEXT
  local listName = Tools:GetColoredListName(currentList)

  self.UI.TitleFontString:SetText(format(titleText, listName))
end

function TransportChildFrame:OnResize()
  local ui = self.UI

  ui.TextField:Resize()
  ui.LeftButton:Resize()
  ui.BackButton:Resize()

  local newWidth = max(ui.LeftButton:GetMinWidth(), ui.BackButton:GetMinWidth())
  newWidth = ((newWidth * 2) + Tools:Padding(0.5))
  newWidth = max(newWidth, ui.TextField:GetWidth())
  newWidth = max(newWidth, ui.TitleFontString:GetWidth())

  local titleHeight = (ui.TitleFontString:GetHeight() + Tools:Padding())
  local textFieldHeight = (ui.TextField:GetHeight() + Tools:Padding(0.5))
  local buttonHeight = ui.LeftButton:GetMinHeight()

  local newHeight = (titleHeight + textFieldHeight + buttonHeight)

  self:SetWidth(1)
  self:SetHeight(newHeight)
end

-- ============================================================================
--                           Getters and Setters
-- ============================================================================

-- Sets the list and transport type for the frame.
-- @param listName - the name of the list used for transport operations
-- @param transportType - the type of transport operations to perform
function TransportChildFrame:SetData(listName, transportType)
  assert(self.Initialized)
  assert(self[transportType])
  assert(ListManager[listName] ~= nil)

  local ui = self.UI
  local editBox = ui.TextField.EditBoxFrame.EditBox

  currentList = listName
  currentType = transportType
  listName = Tools:GetColoredListName(listName)

  if (transportType == self.Import) then
    ui.TitleFontString:SetText(format(L.IMPORT_TITLE_TEXT, listName))
    ui.TextField:SetLabelText(L.IMPORT_LABEL_TEXT)
    ui.TextField:SetHelperText(L.IMPORT_HELPER_TEXT)

    editBox:SetText("")
    editBox:SetFocus()

    ui.LeftButton.Text:SetText(L.IMPORT_TEXT)
    ui.LeftButton:SetScript("OnClick", function(self, button, down)
      ListManager:ImportToList(currentList, editBox:GetText())
      editBox:ClearFocus() end)
  else -- Export
    local exportFunc = function()
      editBox:SetText(ListManager:ExportFromList(currentList))
      editBox:SetFocus()
      editBox:SetCursorPosition(0)
      editBox:HighlightText()
    end

    exportFunc()

    ui.TitleFontString:SetText(format(L.EXPORT_TITLE_TEXT, listName))
    ui.TextField:SetLabelText(L.EXPORT_LABEL_TEXT)
    ui.TextField:SetHelperText(L.EXPORT_HELPER_TEXT)

    ui.LeftButton.Text:SetText(L.EXPORT_TEXT)
    ui.LeftButton:SetScript("OnClick", function(self, button, down) exportFunc() end)
  end
end

-- ============================================================================
--                             Creation Function
-- ============================================================================

-- Creates the components that make up the transport frame.
function TransportChildFrame:CreateTransportFrame()
  local frame = self.Frame
  local ui = self.UI

  -- Title
  ui.TitleFontString = FrameFactory:CreateFontString(frame, nil, "GameFontNormalHuge", Colors.LabelText)
  ui.TitleFontString:SetPoint("TOP")

  -- Left button
  ui.LeftButton = FrameFactory:CreateButton(frame, "GameFontNormalSmall")
  ui.LeftButton:SetPoint("BOTTOMLEFT", Tools:Padding(), 0)
  ui.LeftButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -Tools:Padding(0.25), 0)

  -- Back button
  ui.BackButton = FrameFactory:CreateButton(frame, "GameFontNormalSmall", L.BACK_TEXT)
  ui.BackButton:SetPoint("BOTTOMRIGHT", -Tools:Padding(), 0)
  ui.BackButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", Tools:Padding(0.25), 0)
  ui.BackButton:SetScript("OnClick", function(self, button, down)
    Core:ShowPreviousChild()
  end)

  -- Text frame
  ui.TextField = FrameFactory:CreateTextField(frame, "GameFontNormal")
  ui.TextField:SetPoint("BOTTOMLEFT", ui.LeftButton, "TOPLEFT", 0, Tools:Padding())
  ui.TextField:SetPoint("BOTTOMRIGHT", ui.BackButton, "TOPRIGHT", 0, Tools:Padding())
end
