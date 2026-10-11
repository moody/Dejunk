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

--- Results of `DejunkApi:IsJunk()` by `bagId * 1000 + slotId`.
--- @type table<integer, boolean>
local cachedResults = {}

--- IDs of the items that the cached results are for, by the same keys.
--- @type table<integer, integer>
local cachedItemIds = {}

local cacheClearedTime = 0

local function clearCache()
  for k in pairs(cachedResults) do cachedResults[k] = nil end
  for k in pairs(cachedItemIds) do cachedItemIds[k] = nil end
  cacheClearedTime = GetTime()
end

-- Clear the cache when anything that decides it changes.
EventManager:On(E.Wow.BagUpdate, clearCache)
EventManager:On(E.Wow.BagUpdateDelayed, clearCache)
EventManager:On(E.Wow.EquipmentSetsChanged, clearCache)
EventManager:On(E.Wow.ItemLocked, clearCache)
EventManager:On(E.Wow.ItemUnlocked, clearCache)
EventManager:On(E.BagsUpdated, clearCache)
EventManager:On(E.StateUpdated, clearCache)

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

  -- Clear the cache if at least 1 second has passed.
  if GetTime() - cacheClearedTime >= 1 then clearCache() end

  -- Use the cached result while the slot still holds the same item.
  local key = bagId * 1000 + slotId
  local itemId = C_Container.GetContainerItemID(bagId, slotId)
  if itemId and cachedItemIds[key] == itemId then return cachedResults[key] end
  cachedItemIds[key] = itemId

  local item = Items:GetFreshItem(bagId, slotId)
  local isJunk = item and JunkFilter:IsJunkItem(item) or false
  cachedResults[key] = isJunk

  return isJunk
end
