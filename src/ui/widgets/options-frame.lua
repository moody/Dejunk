local _, Addon = ...
local Colors = Addon.Colors
local GameTooltip = GameTooltip
local Sounds = Addon.Sounds
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates a TitleFrame with the ability to add boolean options.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string
  }
]]
function Widgets:OptionsFrame(options)
  local BUTTONS_PER_ROW = 4
  local SPACING = Widgets:Padding()

  -- Defaults.
  options.titleTemplate = nil
  options.titleJustify = "CENTER"

  -- Base frame.
  local frame = self:TitleFrame(options)
  frame.buttons = {}

  --[[
    -- Adds an option button to the frame.

    options = {
      labelText = string,
      tooltipText = string,
      get = function() -> boolean,
      set = function(value: boolean) -> nil
    }
  ]]
  function frame:AddOption(options)
    -- Defaults.
    options.name = "$parent_CheckButton" .. #self.buttons + 1
    options.parent = self

    -- Set `points` based on `#self.buttons` and `BUTTONS_PER_ROW`.
    if #self.buttons == 0 then
      options.points = { { "TOPLEFT", self.titleBackground, "BOTTOMLEFT", SPACING, -SPACING } }
    else
      local row = #self.buttons / BUTTONS_PER_ROW
      if math.floor(row) == row then
        local firstIndexOfPreviousRow = #self.buttons - (BUTTONS_PER_ROW - 1)
        options.points = { { "TOPLEFT", self.buttons[firstIndexOfPreviousRow], "BOTTOMLEFT", 0, -SPACING } }
      else
        options.points = { { "TOPLEFT", self.buttons[#self.buttons], "TOPRIGHT", SPACING, 0 } }
      end
    end

    -- Add button.
    self.buttons[#self.buttons + 1] = Widgets:OptionButton(options)
  end

  frame:SetScript("OnUpdate", function(self)
    -- Resize buttons.
    local numColumns = math.ceil(#self.buttons / BUTTONS_PER_ROW)
    local buttonAreaWidth = self:GetWidth() - (SPACING * 2)
    local buttonAreaHeight = self:GetHeight() - self.titleBackground:GetHeight() - (SPACING * 2)
    local buttonSpacingHorizontal = (BUTTONS_PER_ROW - 1) * SPACING
    local buttonSpacingVertical = (numColumns - 1) * SPACING

    local buttonWidth = (buttonAreaWidth - buttonSpacingHorizontal) / BUTTONS_PER_ROW
    local buttonHeight = (buttonAreaHeight - buttonSpacingVertical) / numColumns

    for _, button in ipairs(self.buttons) do
      button:SetSize(buttonWidth, buttonHeight)
    end
  end)

  return frame
end

--[[
  Creates a toggleable option button.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height = number,
    labelText = string,
    tooltipText = string,
    get = function() -> boolean,
    set = function(value: boolean) -> nil
  }
]]
function Widgets:OptionButton(options)
  -- Defaults.
  options.frameType = "Button"

  -- Base frame.
  local frame = self:Frame(options)
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
  frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(Colors.White(options.labelText))
  frame.label:SetPoint("LEFT", frame, self:Padding(), 0)
  frame.label:SetPoint("RIGHT", frame, -self:Padding(), 0)
  frame.label:SetWordWrap(false)

  function frame:UpdateTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(options.labelText, 1, 1, 1)
    GameTooltip:AddLine(options.tooltipText, 1, 0.82, 0, true)
    GameTooltip:Show()
  end

  frame:SetScript("OnEnter", function(self)
    -- Add highlight.
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
    self:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
    -- Show tooltip.
    self:UpdateTooltip()
  end)

  frame:SetScript("OnLeave", function(self)
    -- Remove highlight.
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
    self:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
    -- Hide tooltip.
    GameTooltip:Hide()
  end)

  frame:SetScript("OnClick", function(self)
    Sounds.Click()
    options.set(not options.get())
  end)

  frame:SetScript("OnUpdate", function(self)
    self:SetAlpha(options.get() and 1 or 0.3)
  end)

  return frame
end
