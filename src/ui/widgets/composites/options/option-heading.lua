local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionHeadingWidgetOptions : FrameWidgetOptions
--- @field headingText string
--- @field headingColor? Color
--- @field headingJustify? "LEFT" | "RIGHT" | "CENTER"
--- @field headingTemplate? string

-- =============================================================================
-- Widgets - Option Heading
-- =============================================================================

--- Creates a heading for grouping options.
--- @param options OptionHeadingWidgetOptions
--- @return OptionHeadingWidget frame
function Widgets:OptionHeading(options)
  --- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("OptionHeading"))
  options.headingColor = Addon:IfNil(options.headingColor, Colors.Blue)
  options.headingJustify = Addon:IfNil(options.headingJustify, "LEFT")
  options.headingTemplate = Addon:IfNil(options.headingTemplate, "GameFontNormal")

  --- @class OptionHeadingWidget : FrameWidget
  local frame = Widgets:Frame(options)
  frame:SetBackdrop(nil)

  -- Text.
  frame.text = frame:CreateFontString("$parent_Text", "ARTWORK", options.headingTemplate)
  frame.text:SetText(options.headingColor(options.headingText))
  frame.text:SetJustifyH(options.headingJustify)
  frame.text:SetPoint("LEFT")
  frame.text:SetPoint("RIGHT")

  -- Set height.
  frame:SetHeight(frame.text:GetStringHeight() + Widgets:Padding())

  return frame
end
