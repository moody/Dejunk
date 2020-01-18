local _, Addon = ...
local EventManager = Addon.EventManager
EventManager.events = {}

-- Sets up a function to be called when the specified event is fired.
-- @param event {string} - e.g. "PROFILE_CHANGED"
-- @param func {function} - event handler
function EventManager:On(event, func)
  if not self.events[event] then self.events[event] = {} end
  self.events[event][func] = true
end

-- Removes a function from being called when the specified event is fired.
-- @param event {string} - e.g. "PROFILE_CHANGED"
-- @param func {function} - event handler
function EventManager:Remove(event, func)
  if not self.events[event] then return end
  self.events[event][func] = nil
end

-- Calls all registered handlers for a specified event.
-- @param event {string} - e.g. "PROFILE_CHANGED"
-- @param ... {any} - variable argument, passed to each event handler
function EventManager:Fire(event, ...)
  if not self.events[event] then return end
  for func in pairs(self.events[event]) do func(...) end
end
