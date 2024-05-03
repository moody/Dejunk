local ADDON_NAME, Addon = ...
local Colors = Addon:GetModule("Colors") ---@type Colors
local Widgets = Addon:GetModule("Widgets") ---@class Widgets

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class TitleFrameWidgetOptions : FrameWidgetOptions
--- @field titleText? string
--- @field titleTemplate? string
--- @field titleJustify? "LEFT" | "RIGHT" | "CENTER"

-- =============================================================================
-- Widgets - Title Frame
-- =============================================================================

--- Creates a basic frame with title text.
--- @param options TitleFrameWidgetOptions
--- @return TitleFrameWidget frame
function Widgets:TitleFrame(options)
  -- Defaults.
  options.frameType = "Frame"
  options.titleText = Addon:IfNil(options.titleText, ADDON_NAME)
  options.titleTemplate = Addon:IfNil(options.titleTemplate, "GameFontNormal")
  options.titleJustify = Addon:IfNil(options.titleJustify, "CENTER")

  local onUpdateTooltip = options.onUpdateTooltip
  options.onUpdateTooltip = nil

  -- Base frame.
  local frame = self:Frame(options) ---@class TitleFrameWidget : FrameWidget

  -- Title button.
  frame.titleButton = self:Frame({
    name = "$parent_TitleBackground",
    frameType = "Button",
    parent = frame,
    points = { { "TOPLEFT" }, { "TOPRIGHT" } },
    onUpdateTooltip = onUpdateTooltip
  })
  frame.titleButton:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.75))
  frame.titleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  -- Title text.
  frame.title = frame.titleButton:CreateFontString("$parent_Title", "ARTWORK", options.titleTemplate)
  frame.title:SetText(Colors.White(options.titleText))
  frame.title:SetPoint("LEFT", self:Padding(), 0)
  frame.title:SetPoint("RIGHT", -self:Padding(), 0)
  frame.title:SetJustifyH(options.titleJustify)

  frame.titleButton:SetFontString(frame.title)
  frame.titleButton:SetHeight(frame.title:GetStringHeight() + self:Padding(2))

  return frame
end
