-- =============================================================================
-- Wux: 0.3.0 - https://github.com/moody/Wux
-- =============================================================================

local _, Addon = ...
Addon.Wux = {}

--- @class Wux
local Wux = Addon.Wux

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class WuxAction
--- @field type string Unique identifying type for the action.
--- @field payload? any Optional data for the action.

--- @alias WuxDispatch fun(action: WuxAction): WuxAction

--- @alias WuxListener<T> fun(state: T) Function to react to state changes.

--- @alias WuxMiddleware<T> fun(store: WuxMiddlewareStore<T>, next: WuxDispatch, action: WuxAction): WuxAction Function that may inspect, transform, delay, or short-circuit an `action` before it reaches the next middleware (or the store's reducer) by choosing whether to call `next`.

--- @class WuxMiddlewareStore<T>
--- @field dispatch WuxDispatch
--- @field getState fun(): T

--- @alias WuxReducer<T> fun(state?: T, action: WuxAction): T Function to return a new state based on the given action.

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
--- If no non-nil value is found, returns `nil`.
--- @generic T
--- @param ... T
--- @return T|nil
function Wux:Coalesce(...)
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if value ~= nil then
      return value
    end
  end
  return nil
end

-- =============================================================================
-- Wux - Table Methods
-- =============================================================================

--- Returns a shallow copy of the given table.
--- @generic T : table
--- @param t T
--- @return T
function Wux:ShallowCopy(t)
  return copyTable(t, false)
end

--- Returns a deep copy of the given table.
--- @generic T : table
--- @param t T
--- @return T
function Wux:DeepCopy(t)
  return copyTable(t, true)
end

--- Returns an array consisting of the given table's values. Element order is not guaranteed.
--- @generic T
--- @param t table<any, T>
--- @return T[] values
function Wux:Values(t)
  local values = {}
  for _, v in pairs(t) do table.insert(values, v) end
  return values
end

-- =============================================================================
-- Wux - Array Methods
-- =============================================================================

--- Executes the given callback for each element within an array.
--- @generic T
--- @param arr T[]
--- @param callback fun(value: T, index: integer)
function Wux:ForEach(arr, callback)
  for i, v in ipairs(arr) do callback(v, i) end
end

--- Returns a filtered array of elements based on the given callback's boolean response.
--- If the callback returns true for an element, the element will be included in the resulting array.
--- @generic T
--- @param arr T[]
--- @param callback fun(value: T, index: integer): boolean
--- @return T[] filtered
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
--- @generic T, R
--- @param arr T[]
--- @param callback fun(value: T, index: integer): R
--- @return R[] mapped
function Wux:Map(arr, callback)
  local mapped = {}
  for i, v in ipairs(arr) do
    table.insert(mapped, callback(v, i))
  end
  return mapped
end

--- Returns the result of reducing an array into an accumulated value using the given callback.
--- @generic T, R
--- @param arr T[]
--- @param callback fun(accumulator: R, value: T, index: integer): R
--- @param initialValue? R If provided, accumulation begins at the first index; otherwise, defaults to the first index value, and accumulation begins at the second index.
--- @return R accumulator
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
--- @param reducers { [string]: WuxReducer<any> }
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
--- @generic T : table
--- @param reducer WuxReducer<T>
--- @param initialState? T
--- @param middlewares? WuxMiddleware<T>[] Applied in list order; the first middleware receives each action first.
--- @return WuxStore<T>
function Wux:CreateStore(reducer, initialState, middlewares)
  --- @class WuxStore<T>
  local Store = {}

  --- @type WuxListener<any>[]
  local listeners = {}

  --- @type table?
  local state = nil

  if type(initialState) == "table" then
    state = initialState
  end

  --- Returns the current state of the store.
  --- @return T state
  function Store:GetState()
    return state
  end

  --- Applies `action` to the store's reducer and notifies listeners if the
  --- state changed. Middleware wraps this function; it is never called directly.
  --- @param action WuxAction
  --- @return WuxAction action
  local function baseDispatch(action)
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

    return action
  end

  --- @type WuxDispatch
  local dispatch

  --- @type WuxMiddlewareStore<any>
  local middlewareStore = {
    getState = function() return state end,
    dispatch = function(action) return dispatch(action) end
  }

  -- Compose the middleware chain around baseDispatch. Declaration order is
  -- execution order; the first middleware in `middlewares` runs first.
  --- @type WuxMiddleware<any>[]
  middlewares = middlewares or {}
  --- @type WuxDispatch
  local chain = baseDispatch
  for i = #middlewares, 1, -1 do
    local middleware = middlewares[i]
    local next = chain
    chain = function(action)
      return middleware(middlewareStore, next, action)
    end
  end
  dispatch = chain

  --- Dispatches the given `action` through any middleware, then to the
  --- store's reducer. If the state changes, all listeners will be notified.
  --- @param action WuxAction
  --- @return WuxAction action
  function Store:Dispatch(action)
    return dispatch(action)
  end

  --- Registers the given `listener` to be called when the store's state changes.
  --- @param listener WuxListener<T>
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
