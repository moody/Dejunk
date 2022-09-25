local _, Addon = ...
local Widgets = Addon.UserInterface.Widgets
local Colors = Addon.Colors

--[[
  Creates a basic button.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    labelText = string,
    labelColor? = Color,
    onClick? = function(self, button) -> nil
  }
]]
function Widgets:Button(options)
  -- Defaults.
  options.frameType = "Button"
  options.labelColor = options.labelColor or Colors.Gold

  -- Base frame.
  local frame = self:Frame(options)
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.75))
  frame:SetBackdropBorderColor(0, 0, 0, 1)

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(options.labelText)
  frame.label:SetTextColor(options.labelColor:GetRGB())
  frame.label:SetPoint("LEFT", frame, self:Padding(0.5), 0)
  frame.label:SetPoint("RIGHT", frame, -self:Padding(0.5), 0)
  frame.label:SetWordWrap(false)
  frame:SetFontString(frame.label)

  frame:SetScript("OnClick", options.onClick)

  frame:SetScript("OnEnter", function(self)
    self:SetBackdropColor(options.labelColor:GetRGBA(0.25))
    self:SetBackdropBorderColor(options.labelColor:GetRGB())
    self.label:SetTextColor(Colors.White:GetRGB())
  end)

  frame:SetScript("OnLeave", function(self)
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.75))
    self:SetBackdropBorderColor(0, 0, 0, 1)
    self.label:SetTextColor(options.labelColor:GetRGB())
  end)

  frame:SetScript("OnUpdate", function(self)
    self:SetHeight(self.label:GetHeight() + Widgets:Padding(2))
    self:SetAlpha(self:IsEnabled() and 1 or 0.5)
  end)

  return frame
end
