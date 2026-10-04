local Addon = select(2, ...) ---@type Addon
local FrameWidgetEventState = Addon:GetModule("FrameWidgetEventState")

--- @class FrameWidgetEvents
local FrameWidgetEvents = Addon:GetModule("FrameWidgetEvents")

--- Frame events by name.
--- @type table<FrameWidgetEventName, FrameWidgetEvent>
local events = {}

--- Returns the registered frame event.
--- @param name FrameWidgetEventName
--- @return FrameWidgetEvent
local function getEvent(name)
  return assert(events[name], "unknown frame event: " .. tostring(name))
end

-- =============================================================================
-- FrameWidgetEvent
-- =============================================================================

--- An event a frame can fire. Each one lives in its own file and overrides
--- only what it does differently.
--- @class FrameWidgetEvent
--- @field name FrameWidgetEventName
--- @field bubbles boolean Whether the event is also delivered to the source's ancestors.
local FrameWidgetEvent = {}
FrameWidgetEvent.__index = FrameWidgetEvent

--- Runs when a frame is created.
--- @param frame FrameWidget
function FrameWidgetEvent:Init(frame)
end

--- Runs when a frame gets its first handler for the event.
--- @param frame FrameWidget
function FrameWidgetEvent:Listen(frame)
end

--- Returns the event's current value for the frame.
--- @param frame FrameWidget
--- @return boolean
function FrameWidgetEvent:GetValue(frame)
  return FrameWidgetEventState:GetValue(frame, self.name)
end

--- Stores the value and calls the handlers of the frame, and of its ancestors
--- if the event bubbles. `source` is the frame the event came from.
--- @param frame FrameWidget
--- @param value boolean
--- @param source? FrameWidget Defaults to `frame`.
function FrameWidgetEvent:Fire(frame, value, source)
  source = source or frame
  local target = frame

  while target do
    FrameWidgetEventState:Notify(target, self.name, value, source)
    target = self.bubbles and FrameWidgetEventState:GetParent(target) or nil
  end
end

-- =============================================================================
-- FrameWidgetEvents
-- =============================================================================

--- Creates and registers the frame event for `name`. Each event file calls this.
--- @param name FrameWidgetEventName
--- @param bubbles? boolean Defaults to `false`.
--- @return FrameWidgetEvent
function FrameWidgetEvents:Register(name, bubbles)
  assert(not events[name], "frame event already registered: " .. tostring(name))

  local frameEvent = setmetatable({ name = name, bubbles = bubbles or false }, FrameWidgetEvent)
  events[name] = frameEvent
  return frameEvent
end

--- Runs each frame event's `Init` for the frame.
--- @param frame FrameWidget
function FrameWidgetEvents:Init(frame)
  for _, frameEvent in pairs(events) do frameEvent:Init(frame) end
end

--- Fires the event for the frame.
--- @param frame FrameWidget
--- @param event FrameWidgetEventName
--- @param value boolean
--- @param source? FrameWidget Defaults to `frame`.
function FrameWidgetEvents.fireEvent(frame, event, value, source)
  getEvent(event):Fire(frame, value, source)
end

--- Calls `handler` with the event's current value, then whenever it changes.
--- Returns a function that removes the handler.
--- @param frame FrameWidget
--- @param event FrameWidgetEventName
--- @param handler FrameWidgetEventHandler
--- @return fun() off
function FrameWidgetEvents.onEvent(frame, event, handler)
  local frameEvent = getEvent(event)
  assert(type(handler) == "function", "frame event handler must be a function")

  local off = FrameWidgetEventState:AddHandler(frame, event, handler)

  local state = FrameWidgetEventState:Get(frame)
  if not state.listening[event] then
    state.listening[event] = true
    frameEvent:Listen(frame)
  end

  handler(frameEvent:GetValue(frame), frame)

  return off
end

--- Returns the event's current value. `false` until the event first fires.
--- @param frame FrameWidget
--- @param event FrameWidgetEventName
--- @return boolean
function FrameWidgetEvents.getEventValue(frame, event)
  return getEvent(event):GetValue(frame)
end
