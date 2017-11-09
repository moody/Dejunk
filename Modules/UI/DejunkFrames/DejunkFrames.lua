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

-- DejunkFrames: provides Dejunk frames with default functionality.

local AddonName, DJ = ...

local DejunkFrames = DJ.DejunkFrames -- See Modules.lua
local FrameFactory = DJ.FrameFactory

local DejunkFrameMixin = {
  Initialized = false
}

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- Initializes the frame.
function DejunkFrameMixin:Initialize()
  if self.Initialized then return end
  self.Initialized = true

  if not self.UI then
    self.UI = {}
  end

  self.Frame = FrameFactory:CreateFrame()

  self:OnInitialize()
end

-- Additional initialize logic. Override when necessary.
function DejunkFrameMixin:OnInitialize() end

-- -- Deinitializes the frame.
-- function DejunkFrameMixin:Deinitialize()
--   if not self.Initialized then return end
--   self.Initialized = false
--
--   self:OnDeinitialize()
--
--   FrameFactory:ReleaseUI(self.UI)
--
--   self.Frame:Release()
--   self.Frame = nil
-- end
--
-- -- Additional deinitialize logic. Override when necessary.
-- function DejunkFrameMixin:OnDeinitialize() end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- Displays the frame.
function DejunkFrameMixin:Show()
  self.Frame:Show()
end

-- Hides the frame.
function DejunkFrameMixin:Hide()
  self.Frame:Hide()
end

-- Toggles the frame.
function DejunkFrameMixin:Toggle()
  if not self.Frame:IsVisible() then
    self:Show()
  else
    self:Hide()
  end
end

-- Enables the frame.
function DejunkFrameMixin:Enable()
  FrameFactory:EnableUI(self.UI)
end

-- Disables the frame.
function DejunkFrameMixin:Disable()
  FrameFactory:DisableUI(self.UI)
end

-- Refreshes the frame.
function DejunkFrameMixin:Refresh()
  FrameFactory:RefreshUI(self.UI)
end

-- Resizes the frame. Override when necessary.
function DejunkFrameMixin:Resize() end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

-- Gets the width of the frame.
-- @return - the width of the frame
function DejunkFrameMixin:GetWidth()
  return self.Frame:GetWidth()
end

-- Sets the width of the frame.
-- @param width - the new width
function DejunkFrameMixin:SetWidth(width)
  self.Frame:SetWidth(width)
end

-- Gets the height of the frame.
-- @return - the height of the frame
function DejunkFrameMixin:GetHeight()
  return self.Frame:GetHeight()
end

-- Sets the height of the frame.
-- @param height - the new height
function DejunkFrameMixin:SetHeight(height)
  self.Frame:SetHeight(height)
end

-- Sets the parent of the frame.
-- @param parent - the new parent
function DejunkFrameMixin:SetParent(parent)
  self.Frame:SetParent(parent)
end

-- Sets the point of the frame.
-- @param point - the new point
function DejunkFrameMixin:SetPoint(...)
  self.Frame:ClearAllPoints()
  self.Frame:SetPoint(unpack(...))
end

-- Perform mixins
for i, frame in pairs(DejunkFrames) do
  for k, v in pairs(DejunkFrameMixin) do
    frame[k] = v
  end
end
