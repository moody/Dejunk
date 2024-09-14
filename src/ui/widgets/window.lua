local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class WindowWidgetOptions : TitleFrameWidgetOptions

-- ============================================================================
-- Window
-- ============================================================================

--- Creates a moveable frame with title text and a close button.
--- @param options WindowWidgetOptions
--- @return WindowWidget frame
function Widgets:Window(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("Window"))
  options.points = Addon:IfNil(options.points, { { "CENTER" } })
  options.width = Addon:IfNil(options.width, 675)
  options.height = Addon:IfNil(options.height, 500)
  options.enableDragging = true
  options.titleTemplate = "GameFontNormalLarge"
  options.titleJustify = "LEFT"

  --- @class WindowWidget : TitleFrameWidget
  local frame = self:TitleFrame(options)
  frame.titleButton:SetBackdrop(nil)
  frame.titleButton:EnableMouse(false)

  -- Add as special frame to be hidden on certain events.
  table.insert(UISpecialFrames, frame:GetName())

  -- Close button.
  frame.closeButton = self:TitleFrameIconButton({
    name = "$parent_CloseButton",
    parent = frame.titleButton,
    points = { { "TOPRIGHT" }, { "BOTTOMRIGHT" } },
    texture = Addon:GetAsset("x-icon"),
    textureSize = frame.title:GetStringHeight() - Widgets:Padding(0.25),
    highlightColor = Colors.Red,
    onClick = function() frame:Hide() end
  })

  return frame
end
