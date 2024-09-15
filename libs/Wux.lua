-- =============================================================================
-- Wux: 0.2.0 - https://github.com/moody/Wux
-- =============================================================================

local _, Addon = ...
Addon.Wux = {}

--- @class Wux
local Wux = Addon.Wux

-- =============================================================================
-- EmmyLua Annotations
-- =============================================================================

--- @class WuxAction
--- @field type string Unique identifying type for the action.
--- @field payload? any Optional data for the action.

--- @alias WuxReducer<T> fun(state?: T, action: WuxAction): T Function to return a new state based on the given action.

--- @alias WuxListener<T> fun(state: T) Function to react to state changes.

-- =============================================================================
-- Wux - ActionTypes
-- =============================================================================

Wux.ActionTypes = {
  --- This action type enables dispatching multiple actions at once, reducing unnecessary listener notifications.
  ---
  --- ```
  --- Store:Dispatch({
  ---   type = Wux.ActionTypes.Batch,
  ---   payload = {
  ---     { type = "ACTION_1", payload = { ... } },
  ---     { type = "ACTION_2", payload = { ... } }
  ---   }
  --- })
  --- ```
  Batch = "@@WUX/BATCH",

  --- Dispatched internally on store creation to initialize state.
  InitializeState = "@@WUX/INITIALIZE_STATE",
}

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Returns a copy of the given table.
--- @param t table The table to copy.
--- @param deep boolean If true, performs a deep copy.
local function copyTable(t, deep)
  if type(t) ~= "table" then return t end

  local copy = {}
  for k, v in pairs(t) do
    if deep then
      copy[k] = copyTable(v, deep)
    else
      copy[k] = v
    end
  end

  return copy
end

-- =============================================================================
-- Wux - Utility Methods
-- =============================================================================

--- Returns the first non-nil value from the given list of arguments.
--- @vararg any
--- @return any
function Wux:Coalesce(...)
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if value ~= nil then
      return value
    end
  end
end

-- =============================================================================
-- Wux - Table Methods
-- =============================================================================

--- Returns a shallow copy of the given table.
--- @param t table
--- @return table
function Wux:ShallowCopy(t)
  return copyTable(t, false)
end

--- Returns a deep copy of the given table.
--- @param t table
--- @return table
function Wux:DeepCopy(t)
  return copyTable(t, true)
end

--- Returns an array consisting of the given table's values. Element order is not guaranteed.
--- @param t table
--- @return any[] values
function Wux:Values(t)
  local values = {}
  for _, v in pairs(t) do table.insert(values, v) end
  return values
end

-- =============================================================================
-- Wux - Array Methods
-- =============================================================================

--- Executes the given callback for each element within an array.
--- @param arr any[]
--- @param callback fun(value: any, index: integer)
function Wux:ForEach(arr, callback)
  for i, v in ipairs(arr) do callback(v, i) end
end

--- Returns a filtered array of elements based on the given callback's boolean response.
--- If the callback returns true for an element, the element will be included in the resulting array.
--- @param arr any[]
--- @param callback fun(value: any, index: integer): boolean
--- @return any[] filtered
function Wux:Filter(arr, callback)
  local filtered = {}
  for i, v in ipairs(arr) do
    if callback(v, i) == true then
      table.insert(filtered, v)
    end
  end
  return filtered
end

--- Returns a new array with elements returned by the given callback.
--- @param arr any[]
--- @param callback fun(value: any, index: integer): any
--- @return any[] mapped
function Wux:Map(arr, callback)
  local mapped = {}
  for i, v in ipairs(arr) do
    table.insert(mapped, callback(v, i))
  end
  return mapped
end

--- Returns the result of reducing an array into an accumulated value using the given callback.
--- @param arr any[]
--- @param callback fun(accumulator: any, value: any, index: integer): any
--- @param initialValue? any If provided, accumulation begins at the first index; otherwise, defaults to the first index value, and accumulation begins at the second index.
--- @return any accumulator
function Wux:Reduce(arr, callback, initialValue)
  local initialIndex = 1
  if type(initialValue) == "nil" then
    initialValue = arr[1]
    initialIndex = 2
  end

  local accumulator = initialValue
  for i = initialIndex, #arr do
    accumulator = callback(accumulator, arr[i], i)
  end

  return accumulator
end

-- =============================================================================
-- Wux - Store Methods
-- =============================================================================

--- Returns a root reducer composed of all given reducers.
--- @param reducers { [string]: WuxReducer }
--- @return WuxReducer<table> reducer
function Wux:CombineReducers(reducers)
  return function(state, action)
    state = state or {}
    local nextState = {}
    local hasChanged = false

    for key, reducer in pairs(reducers) do
      local prevKeyState = state[key]
      nextState[key] = reducer(prevKeyState, action)
      if nextState[key] ~= prevKeyState then
        hasChanged = true
      end
    end

    return hasChanged and nextState or state
  end
end

--- Returns a new store based on the given reducer.
--- @param reducer WuxReducer
--- @param initialState? table
--- @return WuxStore
function Wux:CreateStore(reducer, initialState)
  --- @class WuxStore
  local Store = {}

  --- @type WuxListener[]
  local listeners = {}

  --- @type table
  local state = nil

  if type(initialState) == "table" then
    state = initialState
  end

  --- Returns the current state of the store.
  --- @return table state
  function Store:GetState()
    return state
  end

  --- Dispatches the given `action` to the store's reducer.
  --- If the state changes, all listeners will be notified.
  --- @param action WuxAction
  function Store:Dispatch(action)
    local prevState = state

    -- Handle batched actions.
    if action.type == Wux.ActionTypes.Batch then
      for _, batchedAction in ipairs(action.payload) do
        state = reducer(state, batchedAction)
      end
    else
      -- Handle single action.
      state = reducer(prevState, action)
    end

    -- Notify listeners if state changed.
    if state ~= prevState then
      for _, listener in ipairs(listeners) do
        listener(state)
      end
    end
  end

  --- Registers the given `listener` to be called when the store's state changes.
  --- @param listener WuxListener<table>
  --- @return fun() unsubscribe Unsubscribes the `listener`.
  function Store:Subscribe(listener)
    table.insert(listeners, listener)
    return function()
      for i = #listeners, 1, -1 do
        if listeners[i] == listener then
          return table.remove(listeners, i)
        end
      end
    end
  end

  Store:Dispatch({ type = Wux.ActionTypes.InitializeState })

  return Store
end
