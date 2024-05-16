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

--- @class OptionHeadingWidgetOptions : FrameWidgetOptions
--- @field text string

-- =============================================================================
-- Widgets - Options Frame
-- =============================================================================

--- Creates a ScrollableTitleFrame with the ability to add boolean options.
--- @param options OptionsFrameWidgetOptions
--- @return OptionsFrameWidget frame
function Widgets:OptionsFrame(options)
  local CHILD_SPACING = Widgets:Padding()

  -- Defaults.
  options.onUpdateTooltip = nil
  options.titleTemplate = nil
  options.titleJustify = "CENTER"

  --- @class OptionsFrameWidget : ScrollableTitleFrameWidget
  local frame = self:ScrollableTitleFrame(options)
  frame.titleButton:EnableMouse(false)
  frame.children = {}
  frame.childCounts = {
    optionButton = 0,
    optionHeading = 0
  }

  -- Scroll child.
  frame.scrollChild = self:Frame({ name = "$parent_ScrollChild", parent = frame.scrollFrame })
  frame.scrollChild:SetBackdrop(nil)
  frame.scrollFrame:SetScrollChild(frame.scrollChild)

  --- Adds an option button to the frame.
  --- @param options OptionButtonWidgetOptions
  function frame:AddOptionButton(options)
    -- Increment count.
    self.childCounts.optionButton = self.childCounts.optionButton + 1

    -- Defaults.
    options.name = "$parent_OptionButton" .. self.childCounts.optionButton
    options.parent = self.scrollChild

    -- Add button.
    self.children[#self.children + 1] = Widgets:OptionButton(options)
  end

  --- Adds an option heading to the frame.
  --- @param options OptionHeadingWidgetOptions
  function frame:AddOptionHeading(options)
    -- Increment count.
    self.childCounts.optionHeading = self.childCounts.optionHeading + 1

    -- Defaults.
    options.name = "$parent_OptionHeading" .. self.childCounts.optionHeading
    options.parent = self.scrollChild

    -- Add button.
    self.children[#self.children + 1] = Widgets:OptionHeading(options)
  end

  -- Hook `OnUpdate` script.
  frame:HookScript("OnUpdate", function(self)
    -- Calculate total height of children.
    local childrenHeight = 0
    for _, child in ipairs(self.children) do
      childrenHeight = childrenHeight + child:GetHeight()
    end

    -- Calculate total spacing between children.
    local childrenSpacing = (#self.children - 1) * CHILD_SPACING

    -- Update scroll child height.
    frame.scrollChild:SetHeight(childrenHeight + childrenSpacing)

    -- Update child points.
    for i, child in ipairs(self.children) do
      child:ClearAllPoints()
      if i == 1 then
        child:SetPoint("TOPLEFT", frame.scrollChild)
        child:SetPoint("TOPRIGHT", frame.scrollChild)
      else
        child:SetPoint("TOPLEFT", self.children[i - 1], "BOTTOMLEFT", 0, -CHILD_SPACING)
        child:SetPoint("TOPRIGHT", self.children[i - 1], "BOTTOMRIGHT", 0, -CHILD_SPACING)
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
  frame.checkBox = frame:CreateTexture("$parent_CheckBox")
  frame.checkBox:SetPoint("RIGHT", -Widgets:Padding(), 0)

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(Colors.White(options.labelText))
  frame.label:SetPoint("LEFT", frame, Widgets:Padding(), 0)
  frame.label:SetPoint("RIGHT", frame.checkBox, "LEFT", -Widgets:Padding(0.5), 0)
  frame.label:SetWordWrap(false)
  frame.label:SetJustifyH("LEFT")

  -- Set frame height and check box size.
  local labelHeight = frame.label:GetStringHeight()
  frame:SetHeight(labelHeight + Widgets:Padding(2))
  frame.checkBox:SetSize(labelHeight, labelHeight)

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
    if options.get() then
      self:SetAlpha(1)
      self.checkBox:SetColorTexture(Colors.Blue:GetRGBA(0.75))
    else
      self:SetAlpha(0.5)
      self.checkBox:SetColorTexture(Colors.White:GetRGBA(0.25))
    end
  end)

  return frame
end

-- =============================================================================
-- Widgets - Option Heading
-- =============================================================================

--- Creates a heading for grouping options.
--- @param options OptionHeadingWidgetOptions
--- @return OptionHeadingWidget frame
function Widgets:OptionHeading(options)
  --- @class OptionHeadingWidget : FrameWidget
  local frame = Widgets:Frame(options)
  frame:SetBackdrop(nil)

  -- Text.
  frame.text = frame:CreateFontString("$parent_Text", "ARTWORK", "GameFontNormal")
  frame.text:SetText(Colors.Grey(options.text))
  frame.text:SetPoint("LEFT")
  frame.text:SetPoint("RIGHT")
  frame.text:SetJustifyH("LEFT")

  -- Set height.
  frame:SetHeight(frame.text:GetStringHeight() + Widgets:Padding())

  return frame
end
