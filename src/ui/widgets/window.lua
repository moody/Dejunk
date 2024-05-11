local _, Addon = ...
local Colors = Addon:GetModule("Colors") ---@type Colors
local TickerManager = Addon:GetModule("TickerManager") ---@type TickerManager
local Widgets = Addon:GetModule("Widgets") ---@class Widgets

-- ============================================================================
-- Local Functions
-- ============================================================================

local setFrameLevel
do
  local prevLevel = 0
  setFrameLevel = function(frame)
    local level = prevLevel + 1
    prevLevel = level
    -- Delay to avoid overwrites from existing values in `{character}/layout-local.txt`.
    TickerManager:After(1, function() frame:SetFrameLevel(level) end)
  end
end

-- ============================================================================
-- Window
-- ============================================================================

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
  options.points = Addon:IfNil(options.points, { { "CENTER" } })
  options.width = Addon:IfNil(options.width, 675)
  options.height = Addon:IfNil(options.height, 500)
  options.onUpdateTooltip = nil
  options.titleTemplate = "GameFontNormalLarge"
  options.titleJustify = "LEFT"

  -- Base frame.
  local frame = self:TitleFrame(options)
  frame.titleButton:SetBackdrop(nil)
  frame.titleButton:EnableMouse(false)
  setFrameLevel(frame)

  -- Add as special frame to be hidden on certain events.
  table.insert(UISpecialFrames, frame:GetName())

  -- Make frame moveable.
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

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
