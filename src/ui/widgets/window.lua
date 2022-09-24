local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
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
  frame.objectsToHideWhenBusy = {}

  -- Make frame moveable.
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  -- Close button.
  frame.closeButton = CreateFrame("Button", "$parent_CloseButton", frame)
  frame.closeButton.text = frame.closeButton:CreateFontString("$parent_Text", "ARTWORK", "GameFontNormalLarge")
  frame.closeButton.text:SetText(Colors.White("X"))
  frame.closeButton:SetFontString(frame.closeButton.text)
  frame.closeButton:SetSize(frame.closeButton.text:GetWidth(), frame.closeButton.text:GetHeight())
  frame.closeButton:SetPoint("TOPRIGHT", -self:Padding(), -self:Padding())
  frame.closeButton:SetScript("OnEnter", function(self) self.text:SetText(Colors.Red("X")) end)
  frame.closeButton:SetScript("OnLeave", function(self) self.text:SetText(Colors.White("X")) end)
  frame.closeButton:SetScript("OnClick", function() frame:Hide() end)

  -- Busy text.
  frame.busyText = frame:CreateFontString("$parent_BusyText", "ARTWORK", "GameFont_Gigantic")
  frame.busyText:SetPoint("LEFT", Widgets:Padding(), 0)
  frame.busyText:SetPoint("RIGHT", -Widgets:Padding(), 0)
  frame.busyText:SetAlpha(0.5)
  frame.busyText:Hide()

  function frame:HideWhenBusy(object)
    self.objectsToHideWhenBusy[object] = true
  end

  frame:SetScript("OnUpdate", function(self)
    local isBusy, reason = Addon:IsBusy()
    if isBusy then
      self.busyText:SetText(Colors.White(reason))
      self.busyText:Show()
      -- Hide objects.
      for object in pairs(self.objectsToHideWhenBusy) do
        if object.Hide then object:Hide() end
      end
    else
      self.busyText:Hide()
      -- Show objects.
      for object in pairs(self.objectsToHideWhenBusy) do
        if object.Show then object:Show() end
      end
    end
  end)

  return frame
end
