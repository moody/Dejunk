local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionButtonWidgetOptions : FrameWidgetOptions
--- @field labelText string
--- @field tooltipText? string
--- @field get fun(): boolean
--- @field set fun(value: boolean)

-- =============================================================================
-- Widgets - Option Button
-- =============================================================================

--- Creates a toggleable option button.
--- @param options OptionButtonWidgetOptions
--- @return OptionButtonWidget frame
function Widgets:OptionButton(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("OptionButton"))
  options.frameType = "Button"

  if options.tooltipText then
    options.onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(options.labelText)
      tooltip:AddLine(options.tooltipText)
    end
  end

  --- @class OptionButtonWidget : FrameWidget, Button
  local frame = self:Frame(options)
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
