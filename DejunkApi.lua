local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local StateManager = Addon:GetModule("StateManager")

--- @type DejunkApiListener[]
local listeners = {}

--- @param event string
local function notifyListeners(event)
  for _, listener in ipairs(listeners) do
    listener(event)
  end
end

-- Register events to notify listeners.
EventManager:Once(E.StoreCreated, function()
  EventManager:On(E.BagsUpdated, function() notifyListeners(DejunkApi.Events.BagsUpdated) end)
  EventManager:On(E.StateUpdated, function() notifyListeners(DejunkApi.Events.StateUpdated) end)
end)

-- ============================================================================
-- Dejunk API
-- ============================================================================

--- @alias DejunkApiListener fun(event: string): nil

--- @class DejunkApi
DejunkApi = {
  Events = {
    BagsUpdated = "BagsUpdated",
    StateUpdated = "StateUpdated"
  }
}

--- Adds a listener to be called whenever Dejunk's bag cache or state is updated.
--- @param listener DejunkApiListener The listener to add
--- @return fun(): DejunkApiListener|nil removeListener Function which returns the `listener` if removed; otherwise `nil`.
function DejunkApi:AddListener(listener)
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
function DejunkApi:IsJunk(bagId, slotId)
  if StateManager:GetStore() == nil then return false end
  local item = Items:GetFreshItem(bagId, slotId)
  return item and JunkFilter:IsJunkItem(item) or false
end
