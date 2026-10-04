local Addon = select(2, ...) ---@type Addon

--- @class FrameWidgetEventState
local FrameWidgetEventState = Addon:GetModule("FrameWidgetEventState")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @alias FrameWidgetEventName "ENABLED" | "FOCUSED" | "HOVERED"

--- Called with the event's value and the frame it came from.
--- @alias FrameWidgetEventHandler fun(value: boolean, source: FrameWidget)

--- @class FrameWidgetEventEntry
--- @field fn FrameWidgetEventHandler Called when the event fires.
--- @field removed boolean Whether the handler was unsubscribed.

--- @class FrameWidgetEventValues
--- @field ENABLED boolean
--- @field FOCUSED boolean
--- @field HOVERED boolean

--- @class FrameWidgetEventsState
--- @field handlers table<FrameWidgetEventName, FrameWidgetEventEntry[]> Handlers by event, in registration order.
--- @field values FrameWidgetEventValues Current value of each event.
--- @field listening table<FrameWidgetEventName, boolean> Events that have had a handler added.
--- @field firing integer How many events are being delivered. Removed handlers are dropped once it reaches 0.

-- =============================================================================
-- State
-- =============================================================================

--- Event state by frame.
--- @type table<FrameWidget, FrameWidgetEventsState>
local states = setmetatable({}, { __mode = "k" })

--- Removes handlers that were unsubscribed.
--- @param list FrameWidgetEventEntry[]
local function compact(list)
  for i = #list, 1, -1 do
    if list[i].removed then table.remove(list, i) end
  end
end

--- Returns the frame's state, creating it on first use.
--- @param frame FrameWidget
--- @return FrameWidgetEventsState
function FrameWidgetEventState:Get(frame)
  local state = states[frame]

  if not state then
    state = {
      handlers = {},
      values = { ENABLED = true, FOCUSED = false, HOVERED = false },
      listening = {},
      firing = 0
    }
    states[frame] = state
  end

  return state
end

--- Returns the event's last stored value for the frame.
--- @param frame FrameWidget
--- @param event FrameWidgetEventName
--- @return boolean
function FrameWidgetEventState:GetValue(frame, event)
  local state = states[frame]
  return state and state.values[event] or false
end

--- Returns the closest ancestor that has frame events, if any.
--- @param frame FrameWidget
--- @return FrameWidget?
function FrameWidgetEventState:GetParent(frame)
  local parent = frame:GetParent() --[[@as FrameWidget?]]

  while parent and not parent.FireEvent do
    parent = parent:GetParent() --[[@as FrameWidget?]]
  end

  return parent
end

--- Adds a handler for the event. Returns a function that removes it.
--- @param frame FrameWidget
--- @param event FrameWidgetEventName
--- @param handler FrameWidgetEventHandler
--- @return fun() off
function FrameWidgetEventState:AddHandler(frame, event, handler)
  local state = self:Get(frame)
  local list = state.handlers[event]

  if not list then
    list = {}
    state.handlers[event] = list
  end

  if state.firing == 0 then compact(list) end

  --- @type FrameWidgetEventEntry
  local entry = { fn = handler, removed = false }
  list[#list + 1] = entry

  return function() entry.removed = true end
end

--- Stores the event's value on the frame, then calls the frame's handlers.
--- @param frame FrameWidget
--- @param event FrameWidgetEventName
--- @param value boolean
--- @param source FrameWidget
function FrameWidgetEventState:Notify(frame, event, value, source)
  local state = self:Get(frame)
  state.values[event] = value

  local list = state.handlers[event]
  if not list then return end

  state.firing = state.firing + 1
  for i = 1, #list do
    local entry = list[i]
    if not entry.removed then entry.fn(value, source) end
  end
  state.firing = state.firing - 1

  if state.firing == 0 then compact(list) end
end
