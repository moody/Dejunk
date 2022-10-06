local _, Addon = ...
local Colors = Addon.Colors
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates a basic slider.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    orientation? = "VERTICAL" | "HORIZONTAL",
    valueStep? = number
  }
]]
function Widgets:Slider(options)
  -- Defaults.
  options.frameType = "Slider"
  options.width = options.width or 12
  options.orientation = options.orientation or "VERTICAL"
  options.valueStep = options.valueStep or 1

  -- Base frame.
  local frame = self:Frame(options)
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
  frame:SetBackdropBorderColor(Colors.DarkGrey:GetRGBA(0.5))

  frame:SetObeyStepOnDrag(true)
  frame:SetOrientation(options.orientation)
  frame:SetValueStep(options.valueStep)
  frame:SetMinMaxValues(0, 0)
  frame:SetValue(0)

  -- Thumb texture.
  frame.texture = frame:CreateTexture("$parent_Texture", "ARTWORK")
  frame.texture:SetColorTexture(Colors.White:GetRGBA(0.25))
  frame.texture:SetSize(frame:GetWidth(), frame:GetWidth() * 2)
  frame:SetThumbTexture(frame.texture)

  return frame
end
