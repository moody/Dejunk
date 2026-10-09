local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local TickerManager = Addon:GetModule("TickerManager")

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

  -- Checkbox.
  frame.checkbox = self:Checkbox({
    parent = frame,
    name = "$parent_Checkbox",
    points = { { "TOPRIGHT", -Widgets:Padding(), -Widgets:Padding() } },
    color = Colors.White
  })

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(Colors.White(options.labelText))
  frame.label:SetPoint("TOPLEFT", frame, Widgets:Padding(), -Widgets:Padding())
  frame.label:SetPoint("RIGHT", frame.checkbox, "LEFT", -Widgets:Padding(0.5), 0)
  frame.label:SetWordWrap(false)
  frame.label:SetJustifyH("LEFT")

  local CHECKBOX_SIZE = math.floor(frame.label:GetStringHeight())
  frame.checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
  frame:SetHeight(CHECKBOX_SIZE + Widgets:Padding(2))

  frame:HookScript("OnEnter", function()
    frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
    frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
    frame.checkbox:FireEvent("HOVERED", true)
  end)

  frame:HookScript("OnLeave", function()
    frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
    frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
    frame.checkbox:FireEvent("HOVERED", false)
  end)

  frame:SetScript("OnClick", function()
    options.set(not options.get())
  end)

  frame:SetScript("OnUpdate", function()
    frame:SetAlpha(options.get() and 1 or 0.5)
  end)

  -- Keep the checkbox in step with the option.
  TickerManager:NewTicker(1 / 30, function()
    frame.checkbox:SetChecked(options.get())
  end):BindFrame(frame)

  return frame
end
