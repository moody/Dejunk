local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class TitleFrameWidgetOptions : FrameWidgetOptions
--- @field titleText? string
--- @field titleTemplate? string
--- @field titleJustify? "LEFT" | "RIGHT" | "CENTER"

--- @class TitleFrameIconButtonWidgetOptions : FrameWidgetOptions
--- @field texture string
--- @field textureSize number
--- @field highlightColor Color
--- @field onClick? fun(self: TitleFrameIconButtonWidget, button: string)

-- =============================================================================
-- Widgets - Title Frame
-- =============================================================================

--- Creates a basic frame with title text.
--- @param options TitleFrameWidgetOptions
--- @return TitleFrameWidget frame
function Widgets:TitleFrame(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("TitleFrame"))
  options.frameType = "Frame"
  options.titleText = Addon:IfNil(options.titleText, ADDON_NAME)
  options.titleTemplate = Addon:IfNil(options.titleTemplate, "GameFontNormal")
  options.titleJustify = Addon:IfNil(options.titleJustify, "CENTER")

  local onUpdateTooltip = options.onUpdateTooltip
  options.onUpdateTooltip = nil

  --- @class TitleFrameWidget : FrameWidget
  local frame = self:Frame(options)

  -- Title button.
  frame.titleButton = self:Frame({
    name = "$parent_TitleBackground",
    frameType = "Button",
    parent = frame,
    points = { { "TOPLEFT" }, { "TOPRIGHT" } },
    onUpdateTooltip = onUpdateTooltip
  })
  frame.titleButton:SetBackdropColor(Colors.DarkGrey:GetRGB())
  frame.titleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  -- Title text.
  frame.title = frame.titleButton:CreateFontString("$parent_Title", "ARTWORK", options.titleTemplate)
  frame.title:SetText(Colors.White(options.titleText))
  frame.title:SetPoint("LEFT", self:Padding(), 0)
  frame.title:SetPoint("RIGHT", -self:Padding(), 0)
  frame.title:SetJustifyH(options.titleJustify)
  frame.title:SetWordWrap(false)

  frame.titleButton:SetFontString(frame.title)
  frame.titleButton:SetHeight(frame.title:GetStringHeight() + self:Padding(2))

  return frame
end

-- =============================================================================
-- Widgets - Title Frame Icon Button
-- =============================================================================

--- Creates a button Frame with an icon.
--- @param options TitleFrameIconButtonWidgetOptions
--- @return TitleFrameIconButtonWidget frame
function Widgets:TitleFrameIconButton(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("TitleFrameIconButton"))
  options.frameType = "Button"

  --- @class TitleFrameIconButtonWidget : FrameWidget, Button
  local frame = self:Frame(options)
  frame:SetBackdropColor(0, 0, 0, 0)
  frame:SetBackdropBorderColor(0, 0, 0, 0)
  frame:SetWidth(options.textureSize + self:Padding(4))

  -- Texture.
  frame.texture = frame:CreateTexture("$parent_Texture", "ARTWORK")
  frame.texture:SetTexture(options.texture)
  frame.texture:SetSize(options.textureSize, options.textureSize)
  frame.texture:SetPoint("CENTER")

  frame:HookScript("OnEnter", function(self) self:SetBackdropColor(options.highlightColor:GetRGBA(0.75)) end)
  frame:HookScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
  frame:SetScript("OnClick", options.onClick)

  return frame
end
