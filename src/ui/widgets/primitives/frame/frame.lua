local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local FrameWidgetEvents = Addon:GetModule("FrameWidgetEvents")
local Tooltip = Addon:GetModule("Tooltip")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class FrameWidgetOptions
--- @field name? string Global frame name. Defaults to a unique name.
--- @field frameType? string Defaults to `Frame`.
--- @field parent? table Defaults to `UIParent`.
--- @field points? table[] Points to anchor the frame at, as argument lists for `SetPoint()`.
--- @field width? integer Defaults to `1`.
--- @field height? integer Defaults to `1`.
--- @field frameStrata? FrameStrata
--- @field clipChildren? boolean Defaults to `true`.
--- @field backdrop? boolean Defaults to `true`. Without one, the frame has no backdrop methods.
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip) Shows a tooltip while the frame is hovered.
--- @field enableClickHandling? boolean Adds a `SetClickHandler()` method.
--- @field enableDragging? boolean Lets the frame be dragged, and raises it above other frames when shown or clicked.
--- @field propagateWhenDisabled? boolean Passes the mouse through while disabled. Defaults to `false`.

-- =============================================================================
-- Modifier (Click Handling)
-- =============================================================================

local ModifierValues = {
  SHIFT = 1,
  CONTROL = 2,
  ALT = 4
}

--- @enum (key) FrameWidgetClickModifierType
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
-- Mouse Propagation
-- =============================================================================

--- Whether each frame passes the mouse through while disabled. Frames never set are absent.
--- @type table<FrameWidget, boolean>
local propagatesWhenDisabled = setmetatable({}, { __mode = "k" })

--- Passes the frame's clicks and motion through while it is disabled and set to propagate.
--- @param frame FrameWidget
local function refreshPropagation(frame)
  local propagate = propagatesWhenDisabled[frame] and not frame:GetEventValue("ENABLED")
  frame:SetPropagateMouseClicks(propagate)
  frame:SetPropagateMouseMotion(propagate)
end

--- Sets whether the frame passes its mouse to the frame beneath it while disabled. Takes over the frame's
--- mouse propagation, and has no effect on a frame that does not take the mouse. Returns the frame.
--- @param frame FrameWidget
--- @param propagate boolean
--- @return FrameWidget frame
local function propagateWhenDisabled(frame, propagate)
  assert(type(propagate) == "boolean")

  local isFirstCall = propagatesWhenDisabled[frame] == nil
  propagatesWhenDisabled[frame] = propagate

  if isFirstCall then
    frame:OnEvent("ENABLED", function() refreshPropagation(frame) end)
  else
    refreshPropagation(frame)
  end

  return frame
end

-- =============================================================================
-- Widgets - Frame
-- =============================================================================

--- Creates a frame with an optional backdrop.
--- @param options FrameWidgetOptions
--- @return FrameWidget frame
function Widgets:Frame(options)
  --- @class FrameWidget : Frame, BackdropTemplate
  local frame = CreateFrame(
    options.frameType or "Frame",
    options.name or Widgets:GetUniqueName("Frame"),
    options.parent or UIParent
  )

  -- Events.
  frame.OnEvent = FrameWidgetEvents.onEvent
  frame.FireEvent = FrameWidgetEvents.fireEvent
  frame.GetEventValue = FrameWidgetEvents.getEventValue
  FrameWidgetEvents:Init(frame)

  -- Propagation.
  frame.PropagateWhenDisabled = propagateWhenDisabled
  if options.propagateWhenDisabled then
    frame:PropagateWhenDisabled(true)
  end

  -- Strata.
  if type(options.frameStrata) == "string" then
    frame:SetFrameStrata(options.frameStrata)
  end

  -- Clip children.
  frame:SetClipsChildren(options.clipChildren ~= false)

  -- Backdrop.
  if options.backdrop ~= false then
    Mixin(frame, BackdropTemplateMixin)
    frame:SetBackdrop(self.BORDER_BACKDROP)
    frame:SetBackdropColor(Colors.Backdrop:GetRGBA(0.95))
    frame:SetBackdropBorderColor(Colors.Black:GetRGBA(1))
  end

  -- Size.
  frame:SetWidth(options.width or 1)
  frame:SetHeight(options.height or 1)

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
    --- @enum (key) FrameWidgetMouseButtonType
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
    --- @param buttonType FrameWidgetMouseButtonType
    --- @param modifierType FrameWidgetClickModifierType
    --- @param clickHandler fun()
    function frame:SetClickHandler(buttonType, modifierType, clickHandler)
      local modifierValue = ModifierTypes[modifierType]
      clickHandlers[buttonType][modifierValue] = clickHandler
    end
  end

  -- Dragging.
  if options.enableDragging then
    frame:SetToplevel(true)
    frame:HookScript("OnShow", frame.Raise)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  end

  return frame
end
