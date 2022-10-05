local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates a basic frame with title text.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string,
    titleTemplate? = string,
    titleJustify? = "LEFT" | "RIGHT" | "CENTER",
    tooltipText? = string,
    onClick? = function(self, button) -> nil
  }
]]
function Widgets:TitleFrame(options)
  -- Defaults.
  options.frameType = "Frame"
  options.titleText = options.titleText or ADDON_NAME
  options.titleJustify = options.titleJustify or "CENTER"
  options.titleTemplate = options.titleTemplate or "GameFontNormal"

  -- Base frame.
  local frame = self:Frame(options)

  -- Title button.
  frame.titleButton = self:Frame({
    name = "$parent_TitleBackground",
    frameType = "Button",
    parent = frame,
    points = { { "TOPLEFT" }, { "TOPRIGHT" } }
  })
  frame.titleButton:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.75))
  frame.titleButton:RegisterForClicks("RightButtonUp")
  frame.titleButton:SetScript("OnClick", options.onClick)
  frame.titleButton:EnableMouse(options.tooltipText ~= nil or options.onClick ~= nil)

  -- Title text.
  frame.title = frame.titleButton:CreateFontString("$parent_Title", "ARTWORK", options.titleTemplate)
  frame.title:SetText(Colors.White(options.titleText))
  frame.title:SetPoint("LEFT", self:Padding(), 0)
  frame.title:SetPoint("RIGHT", -self:Padding(), 0)
  frame.title:SetJustifyH(options.titleJustify)

  frame.titleButton:SetFontString(frame.title)
  frame.titleButton:SetHeight(frame.title:GetStringHeight() + self:Padding(2))

  -- Tooltip text.
  if options.tooltipText then
    function frame.titleButton:UpdateTooltip()
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(options.titleText)
      GameTooltip:AddLine(options.tooltipText, 1, 0.82, 0, true)
      GameTooltip:Show()
    end

    frame.titleButton:SetScript("OnEnter", function(self)
      self:UpdateTooltip()
    end)

    frame.titleButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  return frame
end
