local _, Addon = ...
local Colors = Addon:GetModule("Colors") ---@type Colors
local Widgets = Addon:GetModule("Widgets") ---@class Widgets

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionsFrameWidgetOptions : ScrollableTitleFrameWidgetOptions

--- @class OptionButtonWidgetOptions : FrameWidgetOptions
--- @field labelText string
--- @field tooltipText? string
--- @field get fun(): boolean
--- @field set fun(value: boolean)

-- =============================================================================
-- Widgets - Options Frame
-- =============================================================================

--- Creates a ScrollableTitleFrame with the ability to add boolean options.
--- @param options OptionsFrameWidgetOptions
--- @return OptionsFrameWidget frame
function Widgets:OptionsFrame(options)
  local SPACING = Widgets:Padding()

  -- Defaults.
  options.onUpdateTooltip = nil
  options.titleTemplate = nil
  options.titleJustify = "CENTER"

  -- Base frame.
  local frame = self:ScrollableTitleFrame(options) ---@class OptionsFrameWidget : ScrollableTitleFrameWidget
  frame.titleButton:EnableMouse(false)
  frame.buttons = {}
  frame.buttonHeight = frame.title:GetStringHeight() + (SPACING * 2)

  -- Scroll child.
  frame.scrollChild = self:Frame({ name = "$parent_ScrollChild", parent = frame.scrollFrame })
  frame.scrollFrame:SetScrollChild(frame.scrollChild)

  --- Adds an option button to the frame.
  --- @param options OptionButtonWidgetOptions
  function frame:AddOption(options)
    -- Defaults.
    options.name = "$parent_CheckButton" .. #self.buttons + 1
    options.parent = self.scrollChild
    options.height = self.buttonHeight

    -- Add button.
    self.buttons[#self.buttons + 1] = Widgets:OptionButton(options)
  end

  frame:HookScript("OnUpdate", function(self)
    local scrollChildHeight = (#self.buttons * self.buttonHeight) + (SPACING * (#self.buttons - 1))
    frame.scrollChild:SetHeight(scrollChildHeight)

    -- Update button points.
    for i, button in ipairs(self.buttons) do
      button:ClearAllPoints()
      if i == 1 then
        button:SetPoint("TOPLEFT", frame.scrollChild, SPACING, 0)
        button:SetPoint("TOPRIGHT", frame.scrollChild, -SPACING, 0)
      else
        local prevButton = self.buttons[i - 1]
        button:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, -SPACING)
        button:SetPoint("TOPRIGHT", prevButton, "BOTTOMRIGHT", 0, -SPACING)
      end
    end
  end)

  return frame
end

-- =============================================================================
-- Widgets - Option Button
-- =============================================================================

--- Creates a toggleable option button.
--- @param options OptionButtonWidgetOptions
--- @return OptionButtonWidget frame
function Widgets:OptionButton(options)
  -- Defaults.
  options.frameType = "Button"

  if options.tooltipText then
    options.onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(options.labelText)
      tooltip:AddLine(options.tooltipText)
    end
  end

  -- Base frame.
  local frame = self:Frame(options) ---@class OptionButtonWidget : FrameWidget
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
  frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))

  -- Check box.
  frame.checkBox = self:Frame({
    name = "$parent_CheckBox",
    parent = frame
  })

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(Colors.White(options.labelText))
  frame.label:SetPoint("LEFT", frame, self:Padding(), 0)
  frame.label:SetPoint("RIGHT", frame.checkBox, "LEFT", -self:Padding(0.5), 0)
  frame.label:SetWordWrap(false)
  frame.label:SetJustifyH("LEFT")

  frame:HookScript("OnEnter", function(self)
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
    self:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
  end)

  frame:HookScript("OnLeave", function(self)
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
    self:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
  end)

  frame:SetScript("OnClick", function(self)
    options.set(not options.get())
  end)

  frame:SetScript("OnUpdate", function(self)
    -- Check box.
    local size = self.label:GetStringHeight()
    self.checkBox:SetSize(size, size)
    self.checkBox:SetPoint("RIGHT", -Widgets:Padding(), 0)

    if options.get() then
      self.checkBox:SetBackdropColor(Colors.Yellow:GetRGBA(0.5))
      self.checkBox:SetBackdropBorderColor(Colors.Yellow:GetRGB())
    else
      self.checkBox:SetBackdropColor(0, 0, 0, 0)
      self.checkBox:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
    end
  end)

  return frame
end
