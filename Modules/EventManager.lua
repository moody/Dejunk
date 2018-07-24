-- EventManager: manages events. Ha!

local AddonName, Addon = ...

-- Modules
local EventManager = Addon.EventManager

-- Variables
local listeners = {}

-- Debug function
local function debug(msg)
  Addon.Core:Debug("EventManager", msg)
end

-- ============================================================================
-- Functions
-- ============================================================================

function EventManager:Register(listener, ...)
  assert(type(listener) == "table", "listener must be a table")
  assert(type(listener.OnDejunkEvent) == "function", "listener must have function \"listener:OnDejunkEvent(event, ...)\"")
  for _, event in pairs({...}) do
    if not listeners[event] then listeners[event] = {} end
    listeners[event][listener] = true
  end
end

function EventManager:Unregister(listener, ...)
  local events = {...}
  if (#events == 0) then -- Unregister all
    for event in pairs(listeners) do listeners[event][listener] = nil end
  else
    for _, event in pairs(events) do
      if listeners[event] then listeners[event][listener] = nil end
    end
  end
end

function EventManager:Emit(event, ...)
  if listeners[event] then
    debug("Emitting event: "..event)
    for listener in pairs(listeners[event]) do
      listener:OnDejunkEvent(event, ...)
    end
  end
end
