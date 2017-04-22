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

-- Dejunk_BasicChildFrame: displays the BasicOptionsFrame and BasicListsFrame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local BasicChildFrame = DJ.BasicChildFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local FrameFactory = DJ.FrameFactory
local BasicOptionsFrame = DJ.BasicOptionsFrame
local BasicListsFrame = DJ.BasicListsFrame

-- Variables
BasicChildFrame.Initialized = false
BasicChildFrame.UI = {}

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- Initializes the frame.
function BasicChildFrame:Initialize()
  if self.Initialized then return end

  local ui = self.UI

  ui.Frame = FrameFactory:CreateFrame()

  BasicOptionsFrame:Initialize()
  BasicOptionsFrame:SetParent(ui.Frame)
  BasicOptionsFrame:SetPoint({"TOPLEFT", ui.Frame})

  BasicListsFrame:Initialize()
  BasicListsFrame:SetParent(ui.Frame)
  BasicListsFrame:SetPoint({"TOPLEFT", BasicOptionsFrame.UI.Frame, "BOTTOMLEFT", 0, -Tools:Padding()})

  self.Initialized = true
end

-- Deinitializes the frame.
function BasicChildFrame:Deinitialize()
  if not self.Initialized then return end

  BasicOptionsFrame:Deinitialize()
  BasicListsFrame:Deinitialize()

  FrameFactory:ReleaseUI(self.UI)

  self.Initialized = false
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- Displays the frame.
function BasicChildFrame:Show()
  BasicOptionsFrame:Show()
  BasicListsFrame:Show()

  if not self.UI.Frame:IsVisible() then
    self.UI.Frame:Show() end
end

-- Hides the frame.
function BasicChildFrame:Hide()
  BasicOptionsFrame:Hide()
  BasicListsFrame:Hide()

  self.UI.Frame:Hide()
end

-- Enables the frame.
function BasicChildFrame:Enable()
  BasicOptionsFrame:Enable()
  BasicListsFrame:Enable()

  for k, v in pairs(self.UI) do
    if v.SetEnabled then
      v:SetEnabled(true) end
  end
end

-- Disables the frame.
function BasicChildFrame:Disable()
  BasicOptionsFrame:Disable()
  BasicListsFrame:Disable()

  for k, v in pairs(self.UI) do
    if v.SetEnabled then
      v:SetEnabled(false) end
  end
end

-- Refreshes the frame.
function BasicChildFrame:Refresh()
  BasicOptionsFrame:Refresh()
  BasicListsFrame:Refresh()

  FrameFactory:RefreshUI(self.UI)
end

-- Resizes the frame.
function BasicChildFrame:Resize()
  BasicOptionsFrame:Resize()
  BasicListsFrame:Resize()

  local newWidth = max(BasicOptionsFrame:GetWidth(), BasicListsFrame:GetWidth())
  local _, newHeight = Tools:Measure(self.UI.Frame,
    BasicOptionsFrame.UI.Frame, BasicListsFrame.UI.Frame, "TOPLEFT", "BOTTOMLEFT")

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
function BasicChildFrame:GetWidth()
  return self.UI.Frame:GetWidth()
end

-- Sets the width of the frame.
-- @param width - the new width
function BasicChildFrame:SetWidth(width)
  BasicOptionsFrame:SetWidth(width)
  BasicListsFrame:SetWidth(width)

  self.UI.Frame:SetWidth(width)
end

-- Gets the height of the frame.
-- @return - the height of the frame
function BasicChildFrame:GetHeight()
  return self.UI.Frame:GetHeight()
end

-- Sets the height of the frame.
-- @param height - the new height
function BasicChildFrame:SetHeight(height)
  self.UI.Frame:SetHeight(height)
end

-- Sets the parent of the frame.
-- @param parent - the new parent
function BasicChildFrame:SetParent(parent)
  self.UI.Frame:SetParent(parent)
end

-- Sets the point of the frame.
-- @param point - the new point
function BasicChildFrame:SetPoint(point)
  self.UI.Frame:ClearAllPoints()
  self.UI.Frame:SetPoint(unpack(point))
end
