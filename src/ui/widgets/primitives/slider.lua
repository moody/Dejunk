local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class SliderWidgetOptions : FrameWidgetOptions
--- @field orientation? "VERTICAL" | "HORIZONTAL"
--- @field minValue? number
--- @field maxValue? number
--- @field valueStep? number
--- @field set? fun(value: number)

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
  options.width = Addon:IfNil(options.width, 12)
  options.height = Addon:IfNil(options.height, 12)
  options.orientation = Addon:IfNil(options.orientation, "VERTICAL")
  options.minValue = Addon:IfNil(options.minValue, 0)
  options.maxValue = Addon:IfNil(options.maxValue, 1)
  options.valueStep = Addon:IfNil(options.valueStep, 1)

  --- @class SliderWidget : FrameWidget, Slider
  local frame = self:Frame(options)
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
  frame:SetBackdropBorderColor(Colors.DarkGrey:GetRGBA(0.5))

  frame:SetObeyStepOnDrag(true)
  frame:SetOrientation(options.orientation)
  frame:SetValueStep(options.valueStep)
  frame:SetMinMaxValues(options.minValue, options.maxValue)
  frame:SetValue(options.minValue)

  -- Thumb texture.
  frame.texture = frame:CreateTexture("$parent_Texture", "ARTWORK")
  frame.texture:SetColorTexture(Colors.White:GetRGBA(0.25))
  frame:SetThumbTexture(frame.texture)

  -- Set texture size.
  if options.orientation == "VERTICAL" then
    local size = frame:GetWidth()
    frame.texture:SetSize(size, size * 2)
  else
    local size = frame:GetHeight()
    frame.texture:SetSize(size * 1.25, size)
  end

  frame:SetScript("OnMouseDown", function()
    frame.texture:SetColorTexture(Colors.White:GetRGBA(0.5))
  end)

  frame:SetScript("OnMouseUp", function()
    frame.texture:SetColorTexture(Colors.White:GetRGBA(0.25))
    if options.set then options.set(frame:GetValue()) end
  end)

  return frame
end
