local Addon = select(2, ...) ---@type Addon
local FrameWidgetEventState = Addon:GetModule("FrameWidgetEventState")
local FrameWidgetEvents = Addon:GetModule("FrameWidgetEvents")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class FrameWidgetEnabledState
--- @field isEnabled boolean The frame's own enabled state.
--- @field effective boolean The last effective state delivered, so handlers only run on a change.
--- @field followsParent boolean Whether the frame follows its parent's enabled state.

-- =============================================================================
-- State
-- =============================================================================

--- Enabled state by frame.
--- @type table<FrameWidget, FrameWidgetEnabledState>
local states = setmetatable({}, { __mode = "k" })

--- Returns the frame's enabled state, creating it on first use.
--- @param frame FrameWidget
--- @return FrameWidgetEnabledState
local function getState(frame)
  local state = states[frame]

  if not state then
    state = { isEnabled = true, effective = true, followsParent = false }
    states[frame] = state
  end

  return state
end

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Returns whether the frame's type has a `SetEnabled`.
--- @param frame FrameWidget
--- @return boolean
local function hasNativeEnabled(frame)
  return frame.SetEnabled ~= nil
end

--- Returns whether the frame and all of its ancestors are enabled.
--- @param frame FrameWidget
--- @return boolean
local function isEffectivelyEnabled(frame)
  local state = states[frame]
  if state and not state.isEnabled then return false end

  local parent = FrameWidgetEventState:GetParent(frame)
  return not parent or isEffectivelyEnabled(parent)
end

--- Applies the frame's effective enabled state: to the frame itself, if it has
--- a `SetEnabled`, and to anything listening for the event.
--- @param frame FrameWidget
local function refresh(frame)
  local state = getState(frame)
  local effective = isEffectivelyEnabled(frame)

  if hasNativeEnabled(frame) then frame:SetEnabled(effective) end

  if effective ~= state.effective then
    state.effective = effective
    FrameWidgetEventState:Notify(frame, "ENABLED", effective, frame)
  end
end

--- Makes the frame follow its parent's enabled state, so a disabled ancestor reaches it.
--- @param frame FrameWidget
local function followParent(frame)
  local state = getState(frame)
  if state.followsParent then return end
  state.followsParent = true

  local parent = FrameWidgetEventState:GetParent(frame)
  if parent then parent:OnEvent("ENABLED", function() refresh(frame) end) end
end

-- =============================================================================
-- ENABLED
-- =============================================================================

--- A frame is enabled while it and every ancestor are. Firing sets the frame's
--- own state, and handlers receive the effective state.
--- @class FrameWidgetEnabledEvent : FrameWidgetEvent
local Enabled = FrameWidgetEvents:Register("ENABLED")

--- Frames with a `SetEnabled` follow their ancestors from creation.
--- @param frame FrameWidget
function Enabled:Init(frame)
  if hasNativeEnabled(frame) then followParent(frame) end
end

--- @param frame FrameWidget
function Enabled:Listen(frame)
  followParent(frame)
end

--- @param frame FrameWidget
--- @return boolean
function Enabled:GetValue(frame)
  return isEffectivelyEnabled(frame)
end

--- @param frame FrameWidget
--- @param value boolean The frame's own enabled state.
function Enabled:Fire(frame, value)
  getState(frame).isEnabled = value
  refresh(frame)
end
