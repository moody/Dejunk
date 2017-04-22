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

-- Dejunk_TitleFrame: displays a menu title, character specific settings button, and close button.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local TitleFrame = DJ.TitleFrame

local Colors = DJ.Colors
local Consts = DJ.Consts
local Tools = DJ.Tools
local DejunkDB = DJ.DejunkDB
local FrameFactory = DJ.FrameFactory
local BaseFrame = DJ.BaseFrame

-- variables
TitleFrame.Initialized = false
TitleFrame.UI = {}

local Scales = {1, 0.75, 0.5}
local scaleIndex = 1

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- Initializes the frame.
function TitleFrame:Initialize()
  if self.Initialized then return end

  local ui = self.UI

  ui.Frame = FrameFactory:CreateFrame()

  -- Character Specific Settings check button
  ui.CharSpecCheckButton = FrameFactory:CreateCheckButton(ui.Frame,
    "Small", L.CHARACTER_SPECIFIC_TEXT, nil, L.CHARACTER_SPECIFIC_TOOLTIP)
  ui.CharSpecCheckButton:SetPoint("TOPLEFT", ui.Frame, "TOPLEFT", Tools:Padding(), -Tools:Padding())
  ui.CharSpecCheckButton:SetChecked(not DejunkPerChar.UseGlobal)
  ui.CharSpecCheckButton:SetScript("OnClick", function(self)
    DJ.Core:ToggleCharacterSpecificSettings() end)
  ui.CharSpecCheckButton:SetScript("OnUpdate", function(self)
    local enabled = (not DJ.Dejunker:IsDejunking() and not DJ.ListManager:IsParsing())
    self:SetEnabled(enabled)
  end)

  -- Title
  ui.TitleFontString = FrameFactory:CreateFontString(ui.Frame,
    "OVERLAY", "NumberFontNormalHuge", Colors.BaseFrameTitle,
    {2, -1.5}, Colors.BaseFrameTitleShadow)
  ui.TitleFontString:SetPoint("TOP", 0, -Tools:Padding())
  ui.TitleFontString:SetText(L.DEJUNK_OPTIONS_TEXT)

  -- Close Button
  ui.CloseButton = FrameFactory:CreateButton(ui.Frame, "GameFontNormal", "X")
  ui.CloseButton:SetPoint("TOPRIGHT", ui.Frame, "TOPRIGHT", -1, -1)
	ui.CloseButton:SetScript("OnClick", function(self) BaseFrame:Hide() end)

  -- Scale button
  ui.ScaleButton = FrameFactory:CreateButton(ui.Frame, "GameFontNormal", L.SCALE_TEXT)
  ui.ScaleButton:SetPoint("TOPRIGHT", ui.CloseButton, "TOPLEFT", -Tools:Padding(0.25), 0)
  ui.ScaleButton:SetScript("OnClick", function(self, button, down)
    scaleIndex = ((scaleIndex + 1) % (#Scales + 1))
    if scaleIndex == 0 then scaleIndex = 1 end
    BaseFrame.UI.Frame:SetScale(Scales[scaleIndex])
    BaseFrame:Resize()
  end)

  self.Initialized = true
end

-- Deinitializes the frame.
function TitleFrame:Deinitialize()
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
function TitleFrame:Show()
  if not self.UI.Frame:IsVisible() then
    self.UI.Frame:Show() end
end

-- Hides the frame.
function TitleFrame:Hide()
  self.UI.Frame:Hide()
end

-- Enables the frame.
function TitleFrame:Enable()
  -- Nothing to do
end

-- Disables the frame.
function TitleFrame:Disable()
  -- Nothing to do
end

-- Refreshes the frame.
function TitleFrame:Refresh()
  FrameFactory:RefreshUI(self.UI)
end

-- Resizes the frame.
function TitleFrame:Resize()
  local ui = self.UI

  local titleWidth = ui.TitleFontString:GetStringWidth()
  local titleHeight = ui.TitleFontString:GetStringHeight()

  local charSpecWidth = (ui.CharSpecCheckButton:GetMinWidth() + Tools:Padding())
  --local charSpecHeight = ui.CharSpecCheckButton:GetMinHeight()

  ui.CloseButton:Resize()
  local closeButtonWidth = (ui.CloseButton:GetWidth() + 1)
  --local closeButtonHeight = ui.CloseButton:GetHeight()

  ui.ScaleButton:Resize()
  local scaleButtonWidth = (ui.ScaleButton:GetWidth() + Tools:Padding(0.25))
  --local scaleButtonHeight = ui.ScaleButton:GetHeight()

  -- Width
  local leftSideWidth = charSpecWidth
  local rightSideWith = (closeButtonWidth + scaleButtonWidth)

  local newWidth = (max(leftSideWidth, rightSideWith) * 2)
  newWidth = ((newWidth + titleWidth) + Tools:Padding(2))

  -- Height
  local newHeight = (titleHeight + Tools:Padding())

  ui.Frame:SetWidth(newWidth)
  ui.Frame:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

-- Gets the width of the frame.
-- @return - the width of the frame
function TitleFrame:GetWidth()
  return self.UI.Frame:GetWidth()
end

-- Sets the width of the frame.
-- @param width - the new width
function TitleFrame:SetWidth(width)
  self.UI.Frame:SetWidth(width)
end

-- Gets the height of the frame.
-- @return - the height of the frame
function TitleFrame:GetHeight()
  return self.UI.Frame:GetHeight()
end

-- Sets the height of the frame.
-- @param height - the new height
function TitleFrame:SetHeight(height)
  self.UI.Frame:SetHeight(height)
end

-- Sets the parent of the frame.
-- @param parent - the new parent
function TitleFrame:SetParent(parent)
  self.UI.Frame:SetParent(parent)
end

-- Sets the point of the frame.
-- @param point - the new point
function TitleFrame:SetPoint(point)
  self.UI.Frame:ClearAllPoints()
  self.UI.Frame:SetPoint(unpack(point))
end
