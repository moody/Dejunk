local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class SliderWidgetOptions : FrameWidgetOptions
--- @field orientation? "VERTICAL" | "HORIZONTAL"
--- @field valueStep? number

-- =============================================================================
-- Widgets - Slider
-- =============================================================================

--- Creates a basic slider.
--- @param options SliderWidgetOptions
--- @return SliderWidget frame
function Widgets:Slider(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("Slider"))
  options.frameType = "Slider"
  options.onUpdateTooltip = nil
  options.width = Addon:IfNil(options.width, 12)
  options.orientation = Addon:IfNil(options.orientation, "VERTICAL")
  options.valueStep = Addon:IfNil(options.valueStep, 1)

  --- @class SliderWidget : FrameWidget, Slider
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
