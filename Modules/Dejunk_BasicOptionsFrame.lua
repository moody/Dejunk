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

-- Dejunk_BasicOptionsFrame: displays a simple options menu.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local BasicOptionsFrame = DJ.BasicOptionsFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local DejunkDB = DJ.DejunkDB
local FrameFactory = DJ.FrameFactory
local BaseFrame = DJ.BaseFrame

-- Variables
BasicOptionsFrame.Initialized = false
BasicOptionsFrame.UI = {}

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- Initializes the frame.
function BasicOptionsFrame:Initialize()
  if self.Initialized then return end

  self.UI.Frame = FrameFactory:CreateFrame()

  self:CreateOptions()

  self.Initialized = true
end

-- Deinitializes the frame.
function BasicOptionsFrame:Deinitialize()
  if not self.Initialized then return end

  FrameFactory:ReleaseUI(self.UI)

  self.Initialized = false
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- Displays the frame.
function BasicOptionsFrame:Show()
  if not self.UI.Frame:IsVisible() then
    self.UI.Frame:Show() end
end

-- Hides the frame.
function BasicOptionsFrame:Hide()
  self.UI.Frame:Hide()
end

-- Enables the frame.
function BasicOptionsFrame:Enable()
  for k, v in pairs(self.UI) do
    if v.SetEnabled then
      v:SetEnabled(true) end
  end
end

-- Disables the frame.
function BasicOptionsFrame:Disable()
  for k, v in pairs(self.UI) do
    if v.SetEnabled then
      v:SetEnabled(false) end
  end
end

-- Refreshes the frame.
function BasicOptionsFrame:Refresh()
  FrameFactory:RefreshUI(self.UI)
end

-- Resizes the frame.
function BasicOptionsFrame:Resize()
  local ui = self.UI

  -- Sell all
  local sellAllWidth, sellAllHeight = Tools:Measure(ui.Frame,
    ui.SellAllFontString, ui.SellEpicCheckButton.Text)
  ui.SellAllPositioner:SetWidth(sellAllWidth)
  ui.SellAllPositioner:SetHeight(sellAllHeight)

  -- Row 2
  local row2Width, row2Height = Tools:Measure(ui.Frame,
    ui.AutoSellCheckButton, ui.SilentModeCheckButton.Text)
  ui.Row2Positioner:SetWidth(row2Width)
  ui.Row2Positioner:SetHeight(row2Height)

  -- Calculate newWidth
  -- The widest child plus 4 times padding for outside and inside margins
  local newWidth = max(sellAllWidth, row2Width)
  newWidth = (newWidth + Tools:Padding(4))

  -- Calculate newHeight
  -- The height from the top of the first child to the bottom of the last child
  -- plus 2 times padding for top and bottom margins
  local _, newHeight = Tools:Measure(ui.Frame,
    ui.SellAllPositioner, ui.Row2Positioner, "TOP", "BOTTOM")
  newHeight = (newHeight + Tools:Padding(2))

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

-- Gets the width of the frame.
-- @return - the width of the frame
function BasicOptionsFrame:GetWidth()
  return self.UI.Frame:GetWidth()
end

-- Sets the width of the frame.
-- @param width - the new width
function BasicOptionsFrame:SetWidth(width)
  self.UI.Frame:SetWidth(width)

  -- Set widths of separators
  local oldSeparatorWidth = (self.UI.OptionsAreaTexture:GetWidth() - Tools:Padding())
  local separatorWidth = (width - Tools:Padding(3))

  self.UI.SellAllSeparator:SetWidth(separatorWidth)
end

-- Gets the height of the frame.
-- @return - the height of the frame
function BasicOptionsFrame:GetHeight()
  return self.UI.Frame:GetHeight()
end

-- Sets the height of the frame.
-- @param height - the new height
function BasicOptionsFrame:SetHeight(height)
  self.UI.Frame:SetHeight(height)
end

-- Sets the parent of the frame.
-- @param parent - the new parent
function BasicOptionsFrame:SetParent(parent)
  self.UI.Frame:SetParent(parent)
end

-- Sets the point of the frame.
-- @param point - the new point
function BasicOptionsFrame:SetPoint(point)
  self.UI.Frame:ClearAllPoints()
  self.UI.Frame:SetPoint(unpack(point))
end

--[[
//*******************************************************************
//                       UI Creation Functions
//*******************************************************************
--]]

-- Creates the components that make up the options frame.
function BasicOptionsFrame:CreateOptions()
  local ui = self.UI

  -- Creates and positions a check button horizontally
  local quickCheckButton = function(name, relativeFrame, size, text, textColor, tooltip, svKey)
      ui[name]	= FrameFactory:CreateCheckButton(ui.Frame, size, text, textColor, tooltip, svKey)
      ui[name]:SetPoint("LEFT", relativeFrame, "RIGHT", 8, 0)
  end

  -- Options area texture
  ui.OptionsAreaTexture = FrameFactory:CreateTexture(ui.Frame, "BACKGROUND", Colors.Area)
  ui.OptionsAreaTexture:ClearAllPoints()
  ui.OptionsAreaTexture:SetPoint("TOPLEFT", ui.Frame, "TOPLEFT", Tools:Padding(), 0)
  ui.OptionsAreaTexture:SetPoint("BOTTOMRIGHT", ui.Frame, "BOTTOMRIGHT", -Tools:Padding(), 0)

  -- Sell All
  ui.SellAllPositioner = FrameFactory:CreateTexture(ui.Frame)
  ui.SellAllPositioner:ClearAllPoints()
  ui.SellAllPositioner:SetPoint("TOP", ui.OptionsAreaTexture, "TOP", 0, -Tools:Padding())

  ui.SellAllFontString = FrameFactory:CreateFontString(ui.Frame, "OVERLAY",
    "GameFontNormalHuge", Colors.LabelText)
  ui.SellAllFontString:SetPoint("LEFT", ui.SellAllPositioner, "LEFT", 0, 0)
  ui.SellAllFontString:SetText(L.SELL_ALL_TEXT)

  -- Sell All check buttons
  --quickCheckButton(name, relativeFrame, size, text, textColor, tooltip, svKey)
  quickCheckButton("SellPoorCheckButton", ui.SellAllFontString, "Huge",
    L.POOR_TEXT, Colors.Poor, L.SELL_ALL_TOOLTIP, DejunkDB.SellPoor)
  quickCheckButton("SellCommonCheckButton", ui.SellPoorCheckButton.Text, "Huge",
    L.COMMON_TEXT, Colors.Common, L.SELL_ALL_TOOLTIP, DejunkDB.SellCommon)
  quickCheckButton("SellUncommonCheckButton", ui.SellCommonCheckButton.Text, "Huge",
    L.UNCOMMON_TEXT, Colors.Uncommon, L.SELL_ALL_TOOLTIP, DejunkDB.SellUncommon)
  quickCheckButton("SellRareCheckButton", ui.SellUncommonCheckButton.Text, "Huge",
    L.RARE_TEXT, Colors.Rare, L.SELL_ALL_TOOLTIP, DejunkDB.SellRare)
  quickCheckButton("SellEpicCheckButton", ui.SellRareCheckButton.Text, "Huge",
    L.EPIC_TEXT, Colors.Epic, L.SELL_ALL_TOOLTIP, DejunkDB.SellEpic)

  -- Separator
  ui.SellAllSeparator = FrameFactory:CreateTexture(ui.Frame, "OVERLAY", Colors.Separator)
  ui.SellAllSeparator:ClearAllPoints()
  ui.SellAllSeparator:SetPoint("TOP", ui.SellAllPositioner, "BOTTOM", 0, -Tools:Padding(0.5))
  ui.SellAllSeparator:SetHeight(1)

  -- Row 2 options
  ui.Row2Positioner = FrameFactory:CreateTexture(ui.Frame)
  ui.Row2Positioner:ClearAllPoints()
  ui.Row2Positioner:SetPoint("TOP", ui.SellAllSeparator, "BOTTOM", 0, -Tools:Padding(0.5))

  -- Row 2 check buttons
  quickCheckButton("AutoSellCheckButton", ui.SellAllFontString, "Normal",
    L.AUTO_SELL_TEXT, Colors.LabelText, L.AUTO_SELL_TOOLTIP, DejunkDB.AutoSell)

  ui.AutoSellCheckButton:ClearAllPoints()
  ui.AutoSellCheckButton:SetPoint("TOPLEFT", ui.Row2Positioner)

  quickCheckButton("AutoRepairCheckButton", ui.AutoSellCheckButton.Text, "Normal",
    L.AUTO_REPAIR_TEXT, Colors.LabelText, L.AUTO_REPAIR_TOOLTIP, DejunkDB.AutoRepair)
  quickCheckButton("SafeModeCheckButton", ui.AutoRepairCheckButton.Text, "Normal",
    L.SAFE_MODE_TEXT, Colors.LabelText, L.SAFE_MODE_TOOLTIP, DejunkDB.SafeMode)
  quickCheckButton("SilentModeCheckButton", ui.SafeModeCheckButton.Text, "Normal",
    L.SILENT_MODE_TEXT, Colors.LabelText, L.SILENT_MODE_TOOLTIP, DejunkDB.SilentMode)
end
