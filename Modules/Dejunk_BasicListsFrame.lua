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

-- Dejunk_BasicListsFrame: displays the Inclusions and Exclusions lists.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local BasicListsFrame = DJ.BasicListsFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local ListManager = DJ.ListManager
local FrameFactory = DJ.FrameFactory

-- Variables
BasicListsFrame.Initialized = false
BasicListsFrame.UI = {}

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- Initializes the frame.
function BasicListsFrame:Initialize()
  if self.Initialized then return end

  self.UI.Frame = FrameFactory:CreateFrame()

  self:CreateListFrames()

  self.Initialized = true
end

-- Deinitializes the frame.
function BasicListsFrame:Deinitialize()
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
function BasicListsFrame:Show()
  if not self.UI.Frame:IsVisible() then
    self.UI.Frame:Show() end
end

-- Hides the frame.
function BasicListsFrame:Hide()
  self.UI.Frame:Hide()
end

-- Enables the frame.
function BasicListsFrame:Enable()
  -- Nothing to do
end

-- Disables the frame.
function BasicListsFrame:Disable()
  -- Nothing to do
end

-- Refreshes the frame.
function BasicListsFrame:Refresh()
  FrameFactory:RefreshUI(self.UI)
end

-- Resizes the frame.
function BasicListsFrame:Resize()
  local ui = self.UI

  ui.InclusionsFrame:Resize()
  ui.ExclusionsFrame:Resize()

  local newWidth = max(ui.InclusionsFrame:GetMinWidth(), ui.ExclusionsFrame:GetMinWidth())
  newWidth = ((newWidth * 2) + Tools:Padding())

  local newHeight = max(ui.InclusionsFrame:GetHeight(), ui.InclusionsFrame:GetHeight())

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
function BasicListsFrame:GetWidth()
  return self.UI.Frame:GetWidth()
end

-- Sets the width of the frame.
-- @param width - the new width
function BasicListsFrame:SetWidth(width)
  self.UI.Frame:SetWidth(width)
end

-- Gets the height of the frame.
-- @return - the height of the frame
function BasicListsFrame:GetHeight()
  return self.UI.Frame:GetHeight()
end

-- Sets the height of the frame.
-- @param height - the new height
function BasicListsFrame:SetHeight(height)
  self.UI.Frame:SetHeight(height)
end

-- Sets the parent of the frame.
-- @param parent - the new parent
function BasicListsFrame:SetParent(parent)
  self.UI.Frame:SetParent(parent)
end

-- Sets the point of the frame.
-- @param point - the new point
function BasicListsFrame:SetPoint(point)
  self.UI.Frame:ClearAllPoints()
  self.UI.Frame:SetPoint(unpack(point))
end

--[[
//*******************************************************************
//                       UI Creation Functions
//*******************************************************************
--]]

-- Creates the Inclusions and Exclusions list frames.
function BasicListsFrame:CreateListFrames()
  local ui = self.UI
  local buttonCount = 6
  local listName = nil
  local tooltip = nil

  local baseTooltip = format("%s|n|n%s|n|n%s", L.LIST_FRAME_ADD_TOOLTIP,
    L.LIST_FRAME_REM_TOOLTIP, L.LIST_FRAME_REM_ALL_TOOLTIP)

  -- Inclusions
  listName = ListManager.Inclusions
  tooltip = format("%s|n|n%s", L.INCLUSIONS_TOOLTIP, baseTooltip)

  ui.InclusionsFrame = FrameFactory:CreateListFrame(ui.Frame, listName,
    buttonCount, L.INCLUSIONS_TEXT, Colors.Inclusions, Colors.InclusionsHi, tooltip)
  ui.InclusionsFrame:SetPoint("TOPLEFT", Tools:Padding(), 0)
  ui.InclusionsFrame:SetPoint("TOPRIGHT", ui.Frame, "TOP", -Tools:Padding(0.5), 0)

  -- Exclusions
  listName = ListManager.Exclusions
  tooltip = format("%s|n|n%s", L.EXCLUSIONS_TOOLTIP, baseTooltip)

  ui.ExclusionsFrame = FrameFactory:CreateListFrame(ui.Frame, listName,
    buttonCount, L.EXCLUSIONS_TEXT, Colors.Exclusions, Colors.ExclusionsHi, tooltip)
  ui.ExclusionsFrame:SetPoint("TOPRIGHT", -Tools:Padding(), 0)
  ui.ExclusionsFrame:SetPoint("TOPLEFT", ui.Frame, "TOP", Tools:Padding(0.5), 0)
end
