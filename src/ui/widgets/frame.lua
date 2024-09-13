local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Tooltip = Addon:GetModule("Tooltip")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class FrameWidgetOptions
--- @field name? string
--- @field frameType? string
--- @field parent? table
--- @field points? table[]
--- @field width? integer
--- @field height? integer
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip)
--- @field enableClickHandling? boolean

-- =============================================================================
-- Modifier (Click Handling)
-- =============================================================================

local ModifierValues = {
  SHIFT = 1,
  CONTROL = 2,
  ALT = 4
}

--- @enum (key) WidgetFrameClickModifierType
local ModifierTypes = {
  NONE = 0,
  SHIFT = ModifierValues.SHIFT,
  CONTROL = ModifierValues.CONTROL,
  ALT = ModifierValues.ALT,
  SHIFT_CONTROL = ModifierValues.SHIFT + ModifierValues.CONTROL,
  SHIFT_ALT = ModifierValues.SHIFT + ModifierValues.ALT,
  CONTROL_ALT = ModifierValues.CONTROL + ModifierValues.ALT,
  SHIFT_CONTROL_ALT = ModifierValues.SHIFT + ModifierValues.CONTROL + ModifierValues.ALT,
}

local function getCurrentModifierValue()
  local shift = IsShiftKeyDown() and ModifierValues.SHIFT or 0
  local control = IsControlKeyDown() and ModifierValues.CONTROL or 0
  local alt = IsLeftAltKeyDown() and ModifierValues.ALT or 0
  return shift + control + alt
end

-- =============================================================================
-- Widgets - Frame
-- =============================================================================

--- Creates a basic frame with a backdrop.
--- @param options FrameWidgetOptions
--- @return FrameWidget frame
function Widgets:Frame(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("Frame"))
  options.frameType = Addon:IfNil(options.frameType, "Frame")
  options.parent = Addon:IfNil(options.parent, UIParent)
  options.width = Addon:IfNil(options.width, 1)
  options.height = Addon:IfNil(options.height, 1)

  --- @class FrameWidget : Frame, BackdropTemplate
  local frame = CreateFrame(options.frameType, options.name, options.parent)
  frame:SetClipsChildren(true)

  -- Backdrop.
  Mixin(frame, BackdropTemplateMixin)
  frame:SetBackdrop(self.BORDER_BACKDROP)
  frame:SetBackdropColor(Colors.Backdrop:GetRGBA(0.95))
  frame:SetBackdropBorderColor(Colors.Black:GetRGBA(1))

  -- Size.
  frame:SetWidth(options.width)
  frame:SetHeight(options.height)

  -- Points.
  if options.points then
    for _, point in ipairs(options.points) do
      frame:SetPoint(SafeUnpack(point))
    end
  end

  -- Tooltip.
  if options.onUpdateTooltip then
    -- GameTooltip's `OnUpdate` script will call this function every 0.2 seconds.
    function frame:UpdateTooltip()
      Tooltip:SetOwner(self, "ANCHOR_TOP")
      options.onUpdateTooltip(self, Tooltip)
      Tooltip:Show()
    end

    frame:SetScript("OnEnter", frame.UpdateTooltip)
    frame:SetScript("OnLeave", function() Tooltip:Hide() end)
  end

  -- Click handling.
  if options.enableClickHandling then
    --- @enum (key) WidgetFrameMouseButtonType
    local clickHandlers = {
      LeftButton = {},
      RightButton = {},
      MiddleButton = {},
      Button4 = {},
      Button5 = {}
    }

    -- OnMouseUp.
    frame:SetScript("OnMouseUp", function(_, button, upInside)
      if not (upInside and type(button) == "string") then return end
      local modifierValue = getCurrentModifierValue()
      local buttonHandlers = clickHandlers[button]
      if not (buttonHandlers and buttonHandlers[modifierValue]) then return end
      buttonHandlers[modifierValue]()
    end)

    --- Registers a `clickHandler` to be executed when the frame is clicked
    --- with the specified `buttonType` and `modifierType` combination.
    --- @param buttonType WidgetFrameMouseButtonType
    --- @param modifierType WidgetFrameClickModifierType
    --- @param clickHandler fun()
    function frame:SetClickHandler(buttonType, modifierType, clickHandler)
      local modifierValue = ModifierTypes[modifierType]
      clickHandlers[buttonType][modifierValue] = clickHandler
    end
  end

  return frame
end
