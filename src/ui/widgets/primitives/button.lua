local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ButtonWidgetOptions : FrameWidgetOptions
--- @field labelText string
--- @field labelColor? Color
--- @field onClick? fun(self: ButtonWidget, button: string)

-- =============================================================================
-- Widgets - Button
-- =============================================================================

--- Creates a basic button.
--- @param options ButtonWidgetOptions
--- @return ButtonWidget frame
function Widgets:Button(options)
  -- Defaults.
  options.name = options.name or Widgets:GetUniqueName("Button")
  options.frameType = "Button"
  options.labelColor = options.labelColor or Colors.Gold

  ---@class ButtonWidget : FrameWidget, Button
  local frame = self:Frame(options)
  frame.onClick = options.onClick

  -- Background texture.
  frame.background = frame:CreateTexture("$parent_Background", "BACKGROUND", nil, -8)
  frame.background:SetColorTexture(Colors.Backdrop:GetRGBA(1))
  frame.background:SetAllPoints()

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(options.labelText)
  frame.label:SetPoint("LEFT", frame, self:Padding(0.5), 0)
  frame.label:SetPoint("RIGHT", frame, -self:Padding(0.5), 0)
  frame.label:SetWordWrap(false)
  frame:SetFontString(frame.label)
  frame:SetHeight(frame.label:GetHeight() + Widgets:Padding(2))

  -- Scripts.
  frame:SetScript("OnClick", function(self, button)
    if self.onClick then self.onClick(self, button) end
  end)

  --- Colors the button as disabled, highlighted while hovered or focused, or normal.
  local function refresh()
    if not frame:GetEventValue("ENABLED") then
      frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
      frame:SetBackdropBorderColor(Colors.Black:GetRGBA(1))
      frame.label:SetTextColor(Colors.Grey:GetRGBA(0.75))
    elseif frame:GetEventValue("HOVERED") or frame:GetEventValue("FOCUSED") then
      frame:SetBackdropColor(options.labelColor:GetRGBA(0.25))
      frame:SetBackdropBorderColor(options.labelColor:GetRGBA(1))
      frame.label:SetTextColor(Colors.White:GetRGBA(1))
    else
      frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.75))
      frame:SetBackdropBorderColor(Colors.Black:GetRGBA(1))
      frame.label:SetTextColor(options.labelColor:GetRGBA(1))
    end
  end
  frame:OnEvent("HOVERED", refresh)
  frame:OnEvent("ENABLED", refresh)

  local originalColor = options.labelColor
  frame:OnEvent("FOCUSED", function(isFocused)
    options.labelColor = isFocused and Colors.Yellow or originalColor
    refresh()
  end)

  return frame
end
