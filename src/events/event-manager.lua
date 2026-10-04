local _, Addon = ...
local EventManager = Addon:GetModule("EventManager") ---@class EventManager

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class EventHandlerEntry
--- @field func function Called when the event fires.
--- @field once boolean Whether the handler is removed as it is called.
--- @field removed boolean Whether the handler was removed.

--- @class EventHandlers
--- @field entries EventHandlerEntry[] Handlers in registration order.
--- @field byFunc table<function, EventHandlerEntry> Handlers that are not removed, by function.

-- ============================================================================
-- State
-- ============================================================================

--- Handlers by event.
--- @type table<string, EventHandlers>
local handlers = {}

--- Events that have fired at least once.
--- @type table<string, boolean>
local fired = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Registers a handler for the event. A function that is already registered for
--- the event keeps its place, and takes the new `once` value.
--- @param event string
--- @param func function
--- @param once boolean
local function register(event, func, once)
  assert(type(event) == "string")
  assert(type(func) == "function")

  local eventHandlers = handlers[event]

  if not eventHandlers then
    eventHandlers = { entries = {}, byFunc = {} }
    handlers[event] = eventHandlers
  end

  local entry = eventHandlers.byFunc[func]

  if entry then
    entry.once = once
    return
  end

  entry = { func = func, once = once, removed = false }
  eventHandlers.entries[#eventHandlers.entries + 1] = entry
  eventHandlers.byFunc[func] = entry
end

-- ============================================================================
-- EventManager
-- ============================================================================

--- Sets up a function to be called when the specified event is fired.
--- @param event string
--- @param func function
function EventManager:On(event, func)
  register(event, func, false)
end

--- Sets up a function to be called and removed the next time the specified event is fired.
--- @param event string
--- @param func function
function EventManager:Once(event, func)
  register(event, func, true)
end

--- Calls a function once with no arguments: immediately if the specified event
--- has already fired, otherwise right after it first does.
--- @param event string
--- @param func function
function EventManager:WaitForFirst(event, func)
  assert(type(event) == "string")
  assert(type(func) == "function")

  if fired[event] then
    func()
  else
    register(event, function() func() end, true)
  end
end

--- Calls all registered handlers for a specified event, in registration order.
--- Handlers registered while the event fires wait for the next time it fires.
--- @param event string
--- @vararg any event handler arguments
function EventManager:Fire(event, ...)
  assert(type(event) == "string")
  fired[event] = true

  local eventHandlers = handlers[event]
  if not eventHandlers then return end

  local entries = eventHandlers.entries
  local hasRemoved = false

  for i = 1, #entries do
    local entry = entries[i]

    if not entry.removed then
      if entry.once then
        entry.removed = true
        eventHandlers.byFunc[entry.func] = nil
        hasRemoved = true
      end

      entry.func(...)
    end
  end

  if hasRemoved then
    -- Replace the list, so an outer fire still looping over the old one is unaffected.
    local kept = {}
    for _, entry in ipairs(eventHandlers.entries) do
      if not entry.removed then kept[#kept + 1] = entry end
    end
    eventHandlers.entries = kept
  end
end

-- ============================================================================
-- Event Frame
-- ============================================================================

--- Fires the game events it receives.
local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event, ...)
  EventManager:Fire(event, ...)
end)

for _, event in pairs(Addon:GetModule("Events").Wow) do
  frame:RegisterEvent(event)
end
