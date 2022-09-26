local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local Sounds = Addon.Sounds
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates a moveable frame with title text and a close button.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string
  }
]]
function Widgets:Window(options)
  -- Defaults.
  options.points = options.points or { { "CENTER" } }
  options.width = options.width or 675
  options.height = options.height or 500
  options.titleText = options.titleText or ADDON_NAME
  options.titleTemplate = "GameFontNormalLarge"
  options.titleJustify = "LEFT"

  -- Base frame.
  local frame = self:TitleFrame(options)
  frame.titleBackground:Hide()

  -- Add as special frame to be hidden on certain events.
  table.insert(UISpecialFrames, frame:GetName())

  -- Make frame moveable.
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  -- Close button.
  frame.closeButton = self:Frame({
    name = "$parent_CloseButton",
    frameType = "Button",
    parent = frame
  })
  frame.closeButton:SetBackdropColor(0, 0, 0, 0)
  frame.closeButton:SetBackdropBorderColor(0, 0, 0, 0)
  frame.closeButton:SetPoint("TOPRIGHT", frame.titleBackground)
  frame.closeButton:SetPoint("BOTTOMRIGHT", frame.titleBackground)

  frame.closeButton.text = frame.closeButton:CreateFontString("$parent_Text", "ARTWORK", "GameFontNormalLarge")
  frame.closeButton.text:SetText(Colors.White("X"))
  frame.closeButton:SetFontString(frame.closeButton.text)
  frame.closeButton:SetWidth(frame.closeButton.text:GetWidth() + self:Padding(4))

  frame.closeButton:SetScript("OnEnter", function(self)
    self:SetBackdropColor(Colors.Red:GetRGBA(0.75))
  end)

  frame.closeButton:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0, 0, 0, 0)
  end)

  frame.closeButton:SetScript("OnClick", function() frame:Hide() end)

  frame:SetScript("OnShow", Sounds.WindowOpened)
  frame:SetScript("OnHide", Sounds.WindowClosed)

  return frame
end
