-- Dejunk_Slider: contains FrameFactory functions to create a slider tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local Consts = DJ.Consts
local FrameCreator = DJ.FrameCreator

-- ============================================================================
--                             Creation Function
-- ============================================================================

-- Creates and returns a slider tailored to Dejunk.
-- @param parent - the parent frame
-- @return - a Dejunk slider
function FrameFactory:CreateSlider(parent)
  local slider = FrameCreator:CreateSlider(parent)
  slider:SetWidth(Consts.SLIDER_DEFAULT_WIDTH)
  slider.FF_ObjectType = "Slider"

  slider.Texture = FrameCreator:CreateTexture(slider)

  slider.Thumb = FrameCreator:CreateTexture(slider)
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

  return slider
end
