--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk_ListFrame: contains FrameFactory functions to create and release a frame for displaying list data.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Core = DJ.Core
local Colors = DJ.Colors
local Consts = DJ.Consts
local ListManager = DJ.ListManager
local Tools = DJ.Tools

--[[
//*******************************************************************
//  					    			  List Frame Functions
//*******************************************************************
--]]

-- Creates and returns a list frame for displaying data from a list of items.
-- @param parent - the parent frame
-- @param listName - the name of a list defined in ListManager
-- @param buttonCount - the number of buttons (items) to display
-- @param title - the title of the list frame
-- @param titleColor - the color of the title
-- @param titleColorHi - the color of the title when highlighted
-- @param tooltip - the tooltip to display when highlighting the title
-- @return - a Dejunk list frame
function FrameFactory:CreateListFrame(parent, listName, buttonCount, title, titleColor, titleColorHi, tooltip)
  assert(ListManager[listName] ~= nil)

  local listFrame = self:CreateFrame(parent)
  listFrame.FF_ObjectType = "ListFrame"
  listFrame.ItemList = ListManager.Lists[listName]

  local buttonFrame = self:CreateFrame(listFrame, Colors.Area)
  listFrame.ButtonFrame = buttonFrame

  local slider = self:CreateSlider(listFrame)
  listFrame.Slider = slider

  local titleButton = self:CreateButton(listFrame, "GameFontNormalHuge", title,
    Colors.None, Colors.None, titleColor, titleColorHi)
  listFrame.TitleButton = titleButton

  local importButton = self:CreateButton(listFrame, "GameFontNormalSmall", L.IMPORT_TEXT)
  listFrame.ImportButton = importButton
  local exportButton = self:CreateButton(listFrame, "GameFontNormalSmall", L.EXPORT_TEXT)
  listFrame.ExportButton = exportButton

  -- Initialize points
  titleButton:SetPoint("TOP", listFrame)

  importButton:SetPoint("BOTTOMLEFT", listFrame)
  importButton:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOM", -Tools:Padding(0.25), 0)

  exportButton:SetPoint("BOTTOMRIGHT", listFrame)
  exportButton:SetPoint("BOTTOMLEFT", listFrame, "BOTTOM", Tools:Padding(0.25), 0)

  slider:SetPoint("BOTTOMRIGHT", exportButton, "TOPRIGHT", 0, Tools:Padding(0.5))
  buttonFrame:SetPoint("BOTTOMLEFT", importButton, "TOPLEFT", 0, Tools:Padding(0.5))
  buttonFrame:SetPoint("BOTTOMRIGHT", slider, "BOTTOMLEFT", -Tools:Padding(0.5), 0)

  -- Title button
  titleButton:RegisterForClicks("RightButtonUp")
  titleButton:SetScript("OnClick", function(self, button, down)
    if ((button == "RightButton") and IsShiftKeyDown() and IsAltKeyDown()) then
      ListManager:DestroyList(listName) end
  end)
  titleButton:HookScript("OnEnter", function(self)
    Tools:ShowTooltip(self, "ANCHOR_TOP", self.Text:GetText(), tooltip) end)
  titleButton:HookScript("OnLeave", function(self)
    Tools:HideTooltip() end)

  -- Import/Export buttons
  importButton:SetScript("OnClick", function(self, button, down)
    Core:ShowTransportChild(listName, DJ.DejunkFrames.TransportChildFrame.Import) end)
  exportButton:SetScript("OnClick", function(self, button, down)
    Core:ShowTransportChild(listName, DJ.DejunkFrames.TransportChildFrame.Export) end)

  -- Slider
  slider:SetMinMaxValues(0, 0)
  slider:SetValueStep(1)
  slider:SetValue(0)

  slider:HookScript("OnValueChanged", function(self, value)
    buttonFrame.Offset = floor(self:GetValue() + 0.5)
  end)

  -- Button frame
  buttonFrame.Offset = 0
  buttonFrame.Buttons = {}
  for i = 1, buttonCount do
    local button = self:CreateListButton(buttonFrame, listName)
    button:SetHeight(Consts.LIST_BUTTON_HEIGHT)

    if i == 1 then
      button:SetPoint("TOPLEFT", Tools:Padding(0.5), -Tools:Padding(0.5))
      button:SetPoint("TOPRIGHT", -Tools:Padding(0.5), -Tools:Padding(0.5))
    else
      button:SetPoint("TOPLEFT", buttonFrame.Buttons[i-1], "BOTTOMLEFT", 0, -Tools:Padding(0.5))
      button:SetPoint("TOPRIGHT", buttonFrame.Buttons[i-1], "BOTTOMRIGHT", 0, -Tools:Padding(0.5))
    end

    buttonFrame.Buttons[i] = button
  end

  -- Drops the item on the cursor into the scroll frame.
  function buttonFrame:DropItem()
    if CursorHasItem() then
      local infoType, itemID = GetCursorInfo()

      if infoType == "item" then
        ListManager:AddToList(listName, itemID)
      end

      ClearCursor()
    end
  end

  buttonFrame:SetScript("OnMouseUp", buttonFrame.DropItem)

  -- Displays the slider.
  function listFrame:ShowSlider()
    buttonFrame:SetPoint("BOTTOMRIGHT", slider, "BOTTOMLEFT", -Tools:Padding(0.5), 0)
    slider:Show()
  end

  -- Hides the slider.
  function listFrame:HideSlider()
    buttonFrame:SetPoint("BOTTOMRIGHT", exportButton, "TOPRIGHT", 0, Tools:Padding(0.5))
    slider:Hide()
  end

  -- Updates the buttons in the scroll frame.
  function listFrame:Update()
    if (#self.ItemList > 0) and (not ListManager:IsParsing(listName)) then
      exportButton:SetEnabled(true)
    else
      exportButton:SetEnabled(false)
    end

    -- Update buttons
    for i, button in ipairs(buttonFrame.Buttons) do
      local index = (i + buttonFrame.Offset)
      local item = self.ItemList[index]

      if item then
        button:Show()
        button:SetItem(item)
      else
        button:Hide()
      end
    end

    -- Update slider max value
    local maxVal = (#self.ItemList - #buttonFrame.Buttons)
    if maxVal > 0 then
      self:ShowSlider()
      slider:SetMinMaxValues(0, maxVal)
    else
      self:HideSlider()
      slider:SetMinMaxValues(0, 0)
    end
  end

  -- Resizes the frame to its minimum required size.
  function listFrame:Resize()
    titleButton:Resize()
    importButton:Resize()
    exportButton:Resize()

    local bfHeight = ((#buttonFrame.Buttons * Consts.LIST_BUTTON_HEIGHT) +
      ((#buttonFrame.Buttons + 1) * Tools:Padding(0.5)))
    buttonFrame:SetHeight(bfHeight)
    slider:SetHeight(bfHeight)

    self:SetWidth(self:GetMinWidth())
    self:SetHeight(self:GetMinHeight())
  end

  -- Gets the minimum width required by the frame to fit its contents.
  function listFrame:GetMinWidth()
    local titleWidth = (self.TitleButton:GetWidth() + Tools:Padding(2))

    local transportWidth = max(importButton:GetMinWidth(), exportButton:GetMinWidth())
    transportWidth = ((transportWidth * 2) + Tools:Padding(0.5))

    local width = max(titleWidth, transportWidth)

    return max(width, Consts.LIST_FRAME_MIN_WIDTH)
  end

  -- Gets the minimum height required by the frame to fit its contents.
  function listFrame:GetMinHeight()
    local bfHeight = ((#buttonFrame.Buttons * Consts.LIST_BUTTON_HEIGHT) +
                     ((#buttonFrame.Buttons + 1) * Tools:Padding(0.5)))

    local transportHeight = (max(importButton:GetMinHeight(),
      exportButton:GetMinHeight()) + Tools:Padding(0.5))

    return (titleButton:GetHeight() + bfHeight + transportHeight)
  end

  -- Refreshes the frame
  function listFrame:Refresh()
    titleButton:Refresh()
    importButton:Refresh()
    exportButton:Refresh()
    buttonFrame:Refresh()
    slider:Refresh()

    for i, button in ipairs(buttonFrame.Buttons) do
      button:Refresh()
    end
  end

  -- Scripts
  listFrame:SetScript("OnUpdate", listFrame.Update)
  listFrame:SetScript("OnMouseWheel", function(self, delta)
    slider:SetValue(slider:GetValue() - delta) end)

  listFrame:Refresh()
  listFrame:Update()

  -- Pre-hook Release function
  local release = listFrame.Release

  function listFrame:Release()
    -- Objects
    self.TitleButton:Release()
    self.TitleButton = nil

    self.ImportButton:Release()
    self.ImportButton = nil

    self.ExportButton:Release()
    self.ExportButton = nil

    for i, button in pairs(self.ButtonFrame.Buttons) do button:Release() end
    self.ButtonFrame.Buttons = nil

    self.ButtonFrame:Release()
    self.ButtonFrame.DropItem = nil
    self.ButtonFrame = nil

    self.Slider:Release()
    self.Slider = nil

    -- Variables
    self.FF_ObjectType = nil
    self.ItemList = nil

    -- Functions
    self.ShowSlider = nil
    self.HideSlider = nil
    self.Update = nil
    self.GetMinWidth = nil
    self.GetMinHeight = nil
    self.Resize = nil
    self.Refresh = nil

    release(self)
  end

  return listFrame
end

-- Enables a list frame created by FrameFactory.
-- @param listFrame - the list frame to be enabled
function FrameFactory:EnableListFrame(listFrame)
  listFrame:SetScript("OnUpdate", listFrame.Update)

  listFrame.TitleButton:SetEnabled(true)
  listFrame.ImportButton:SetEnabled(true)
  listFrame.ExportButton:SetEnabled(true)

  for i, button in pairs(listFrame.ButtonFrame.Buttons) do
    button:SetEnabled(true) end
end

-- Disables a list frame created by FrameFactory.
-- @param listFrame - the list frame to be disabled
function FrameFactory:DisableListFrame(listFrame)
  listFrame:SetScript("OnUpdate", nil)

  listFrame.TitleButton:SetEnabled(false)
  listFrame.ImportButton:SetEnabled(false)
  listFrame.ExportButton:SetEnabled(false)

  for i, button in pairs(listFrame.ButtonFrame.Buttons) do
    button:SetEnabled(false) end
end
