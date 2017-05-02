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

-- Dejunk_Slider: contains FrameFactory functions to create and release a slider tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local Consts = DJ.Consts
local FramePooler = DJ.FramePooler

--[[
//*******************************************************************
//  					    			    Slider Functions
//*******************************************************************
--]]

-- Creates and returns a slider tailored to Dejunk.
-- @param parent - the parent frame
-- @return - a Dejunk slider
function FrameFactory:CreateSlider(parent)
  local slider = FramePooler:CreateSlider(parent)
  slider:SetWidth(Consts.SLIDER_DEFAULT_WIDTH)
  slider.FF_ObjectType = "Slider"

  slider.Texture = FramePooler:CreateTexture(slider)

  slider.Thumb = FramePooler:CreateTexture(slider)
  slider.Thumb:SetWidth(Consts.SLIDER_DEFAULT_WIDTH)
  slider.Thumb:SetHeight(Consts.THUMB_DEFAULT_HEIGHT)
  slider:SetThumbTexture(slider.Thumb)

  -- Refreshes the frame.
  function slider:Refresh()
    self.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.Slider)))
    self.Thumb:SetColorTexture(unpack(Colors:GetColor(Colors.SliderThumb)))
  end

  -- Generic scripts
  slider:SetScript("OnValueChanged", function(self, value)
    local minVal, maxVal = self:GetMinMaxValues()
    self:SetValue(Clamp(value, minVal, maxVal))
  end)
  slider:SetScript("OnMouseDown", function(self)
    self.Thumb:SetColorTexture(unpack(Colors:GetColor(Colors.SliderThumbHi))) end)
  slider:SetScript("OnMouseUp", function(self)
    self.Thumb:SetColorTexture(unpack(Colors:GetColor(Colors.SliderThumb))) end)

  slider:Refresh()

  -- Pre-hook Release function
  local release = slider.Release

  function slider:Release()
    -- Objects
    self.Texture:Release()
    self.Texture = nil

    --self:SetThumbTexture(nil)
    self.Thumb:Release()
    self.Thumb = nil

    -- Variables
    self.FF_ObjectType = nil

    -- Functions
    self.Refresh = nil

    release(self)
  end

  return slider
end

--[[
-- Releases a slider created by FrameFactory.
-- @param slider - the slider to release
function FrameFactory:ReleaseSlider(slider)
  -- Objects
  FramePooler:ReleaseTexture(slider.Texture)
  slider.Texture = nil

  FramePooler:ReleaseTexture(slider.Thumb)
  slider.Thumb = nil
  slider:SetThumbTexture(nil)

  -- Variables
  slider.FF_ObjectType = nil

  -- Functions
  slider.Refresh = nil

  FramePooler:ReleaseSlider(slider)
end
--]]
