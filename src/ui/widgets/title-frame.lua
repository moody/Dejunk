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
    titleJustify? = "LEFT" | "RIGHT" | "CENTER"
  }
]]
function Widgets:TitleFrame(options)
  -- Defaults.
  options.frameType = "Frame"

  -- Base frame.
  local frame = self:Frame(options)

  -- Title text.
  frame.title = frame:CreateFontString("$parent_Title", "ARTWORK", options.titleTemplate or "GameFontNormal")
  frame.title:SetText(Colors.White(options.titleText or ADDON_NAME))

  if options.titleJustify == "LEFT" then
    frame.title:SetPoint("TOPLEFT", self:Padding(), -self:Padding())
  elseif options.titleJustify == "RIGHT" then
    frame.title:SetPoint("TOPRIGHT", -self:Padding(), -self:Padding())
  else
    frame.title:SetPoint("TOP", 0, -self:Padding())
  end

  -- Title background.
  local titleHeight = max(frame.title:GetHeight(), frame.title:GetStringHeight()) + self:Padding(2)
  frame.titleBackground = frame:CreateTexture("$parent_TitleBackground", "BACKGROUND", nil, 7)
  frame.titleBackground:SetColorTexture(Colors.DarkGrey:GetRGBA(0.75))
  frame.titleBackground:SetPoint("TOPLEFT")
  frame.titleBackground:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -titleHeight)

  return frame
end
