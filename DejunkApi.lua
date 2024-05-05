local _, Addon = ...
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local StateManager = Addon:GetModule("StateManager") ---@type StateManager

local listeners = {}

local function notifyListeners()
  for _, listener in ipairs(listeners) do
    listener()
  end
end

EventManager:Once(E.StoreCreated, function()
  EventManager:On(E.BagsUpdated, notifyListeners)
  EventManager:On(E.StateUpdated, notifyListeners)
end)

-- ============================================================================
-- Dejunk API
-- ============================================================================

--- Adds a listener to be called whenever Dejunk's state changes.
--- The returned function can be called to remove the listener.
--- @param listener fun() The listener to add
--- @return fun(): fun() | nil removeListener Returns the listener if removed; otherwise `nil`.
function DejunkApi_AddListener(listener)
  listeners[#listeners + 1] = listener
  return function()
    for i = #listeners, 1, -1 do
      if listeners[i] == listener then
        return table.remove(listeners, i)
      end
    end
  end
end

--- Returns `true` if the item in the given bag and slot is junk.
--- @param bagId integer
--- @param slotId integer
--- @return boolean isJunk
function DejunkApi_IsJunk(bagId, slotId)
  if StateManager:GetStore() == nil then return false end
  local item = Items:GetItem(bagId, slotId)
  return item and JunkFilter:IsJunkItem(item) or false
end
