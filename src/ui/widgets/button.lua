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
    onClick? = function(self, button) -> nil
  }
]]
function Widgets:Button(options)
  -- Defaults.
  options.frameType = "Button"

  -- Base frame.
  local frame = self:Frame(options)
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
  frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(Colors.White(options.labelText))
  frame.label:SetPoint("LEFT", frame, self:Padding(0.5), 0)
  frame.label:SetPoint("RIGHT", frame, -self:Padding(0.5), 0)
  frame.label:SetWordWrap(false)

  frame:SetHeight(max(frame.label:GetHeight(), frame.label:GetStringHeight()) + self:Padding(2))

  frame:SetScript("OnClick", options.onClick)

  frame:SetScript("OnUpdate", function(self)
    if GetMouseFocus() == self then
      if IsMouseButtonDown("LeftButton") then
        self:SetBackdropColor(Colors.DarkGrey:GetRGB())
        self:SetBackdropBorderColor(Colors.White:GetRGB())
      else
        self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
        self:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
      end
    else
      self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
      self:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
    end
  end)

  return frame
end
