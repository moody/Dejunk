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

-- Dejunk_ScrollFrame: contains FrameFactory functions to create and release a scroll frame tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local Tools = DJ.Tools
local FramePooler = DJ.FramePooler

--[[
//*******************************************************************
//  					    			Scroll Frame Functions
//*******************************************************************
--]]

-- Creates and returns a scroll frame tailored to Dejunk.
-- @param parent - the parent frame
-- @return - a Dejunk scroll frame
function FrameFactory:CreateScrollFrame(parent)
  local scrollFrame = FramePooler:CreateScrollFrame(parent)
  scrollFrame.FF_ObjectType = "ScrollFrame"
  scrollFrame.UI = {}

  scrollFrame.MinWidth = 0
  scrollFrame.MinHeight = DJ.Consts.SCROLL_FRAME_MIN_HEIGHT

  scrollFrame.Texture = FramePooler:CreateTexture(scrollFrame)

  local scrollChild = FramePooler:CreateFrame(scrollFrame)
  scrollFrame.ScrollChild = scrollChild
  scrollFrame:SetScrollChild(scrollChild)

  local slider = self:CreateSlider(parent)
  scrollFrame.Slider = slider

  -- Slider
  slider:SetMinMaxValues(0, 0)
  slider:SetValueStep(1)
  slider:SetValue(0)

  slider:SetScript("OnValueChanged", function(self, value)
    scrollFrame:SetVerticalScroll(value) end)

  -- Adds an object to the scroll frame's UI.
  function scrollFrame:AddObject(object)
    assert(type(object.FF_ObjectType) == "string")

    object:SetParent(scrollChild)

    local lastObject = self.UI[#self.UI]
    if lastObject then
      object:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, -Tools:Padding(0.5))
    else
      object:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", Tools:Padding(0.5), -Tools:Padding(0.5))
    end

    self.UI[#self.UI+1] = object
  end

  -- Checks whether or not the slider should be displayed.
  function scrollFrame:IsSliderRequired()
    return (scrollChild:GetHeight() > self:GetHeight())
  end

  -- Gets the minimum width of the frame.
  function scrollFrame:GetMinWidth()
    return self.MinWidth
  end

  -- Gets the minimum height of the frame.
  function scrollFrame:GetMinHeight()
    return self.MinHeight
  end

  -- Resizes the scroll frame.
  function scrollFrame:Resize()
    local newWidth = 0 -- Widest object in UI + horizontal padding
    local newHeight = 0 -- Sum of heights of UI objects + vertical padding

    for i, v in ipairs(self.UI) do
      if v.Resize then v:Resize() end
      local w = (v.GetMinWidth and v:GetMinWidth()) or v:GetWidth();
      local h = (v.GetMinHeight and v:GetMinHeight()) or v:GetHeight();
      newWidth = max(newWidth, w)
      newHeight = newHeight + h + Tools:Padding(0.5);
    end

    newWidth = (newWidth + Tools:Padding())
    scrollChild:SetWidth(newWidth)
    self.MinWidth = newWidth

    newHeight = (newHeight + Tools:Padding(0.5))
    scrollChild:SetHeight(newHeight)

    slider:SetMinMaxValues(0, max(newHeight - self.MinHeight, 0))
    slider:SetHeight(self.MinHeight)

    self:SetWidth(newWidth)
    self:SetHeight(self.MinHeight)
  end

  -- Refreshes the scroll frame.
  function scrollFrame:Refresh()
    self.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.ScrollFrame)))
    self.Slider:Refresh()
    FrameFactory:RefreshUI(self.UI)
  end

  scrollFrame:Refresh()

  -- Pre-hook Release function
  local release = scrollFrame.Release

  function scrollFrame:Release()
    -- Objects
    self.Texture:Release()
    self.Texture = nil

    self.ScrollChild:Release()
    self.ScrollChild = nil

    self.Slider:Release()
    self.Slider = nil

    FrameFactory:ReleaseUI(self.UI)
    self.UI = nil

    -- Variables
    self.FF_ObjectType = nil

    -- Functions
    self.AddObject = nil
    self.Resize = nil
    self.Refresh = nil

    release(self)
  end

  return scrollFrame
end

-- Enables the functionality of a scroll frame created by FrameFactory.
-- @param scrollFrame - the scroll frame to be enabled
function FrameFactory:EnableScrollFrame(scrollFrame)
  self:EnableUI(scrollFrame.UI)
end

-- Disables the functionality of a scroll frame created by FrameFactory.
-- @param scrollFrame - the scroll frame to be disabled
function FrameFactory:DisableScrollFrame(scrollFrame)
  self:DisableUI(scrollFrame.UI)
end

--[[
-- Releases a scroll frame created by FrameFactory.
-- @param scrollFrame - the scroll frame to release
function FrameFactory:ReleaseScrollFrame(scrollFrame)
  -- Objects
  FramePooler:ReleaseTexture(scrollFrame.Texture)
  scrollFrame.Texture = nil

  FramePooler:ReleaseFrame(scrollFrame.ScrollChild)
  scrollFrame.ScrollChild = nil

  self:ReleaseSlider(scrollFrame.Slider)
  scrollFrame.Slider = nil

  self:ReleaseUI(scrollFrame.UI)
  scrollFrame.UI = nil

  -- Variables
  scrollFrame.FF_ObjectType = nil

  -- Functions
  scrollFrame.AddObject = nil
  scrollFrame.Resize = nil
  scrollFrame.Refresh = nil

  FramePooler:ReleaseScrollFrame(scrollFrame)
end
--]]
