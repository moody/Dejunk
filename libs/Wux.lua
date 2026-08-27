-- =============================================================================
-- Wux: 0.3.1 - https://github.com/moody/Wux
-- =============================================================================

local _, Addon = ...
Addon.Wux = {}

--- @class Wux
local Wux = Addon.Wux

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

-- Actions

--- The action dispatched to a store and passed to its reducer.
--- @class WuxAction
--- @field type string Unique identifying type for the action.

--- A `WuxAction` with data attached.
--- @class WuxPayloadAction<P> : WuxAction
--- @field payload P Data for the action.

--- Function to create a `WuxPayloadAction` from a given value.
--- @alias WuxActionCreator<P> fun(value: P): WuxPayloadAction<P>

-- Store

--- Function to return a new state based on the given action. `state` is typed
--- as always present, matching the common case of an `initialState`; a
--- reducer that might see a `nil` state should still handle it, e.g. with
--- `Wux:Coalesce`.
--- @alias WuxReducer<S, A> fun(state: S, action: A): S

--- Function to react to state changes.
--- @alias WuxListener<S> fun(state: S)

--- Maps root state to SavedVariables globals. A string maps the whole state
--- to one global; a table maps each state key to its own.
--- @alias WuxSavedVariablesMapping string | table<string, string>

--- The store returned by `CreateStore()`.
--- @class WuxStore<S>
--- @field GetState fun(self: WuxStore<S>): S Returns the current state of the store.
--- @field Dispatch fun(self: WuxStore<S>, action: WuxAction): WuxAction Runs `action` through any middleware, then the store's reducer, then notifies listeners if the state changed.
--- @field Subscribe fun(self: WuxStore<S>, listener: WuxListener<S>): fun() Registers `listener` to be called when the store's state changes. Returns an `unsubscribe` function.
--- @field ConnectSavedVariables fun(self: WuxStore<S>, mapping: WuxSavedVariablesMapping): fun() Writes state to its mapped SavedVariables globals immediately, then again on every change. Returns an `unsubscribe` function.

-- Middleware

--- Function that processes a single action, used internally by a store and
--- passed to middleware as `next`.
--- @alias WuxDispatch fun(action: WuxAction): WuxAction

--- The subset of a store passed to middleware.
--- @class WuxMiddlewareStore<S>
--- @field dispatch WuxDispatch Dispatches through the full middleware chain, not just the middleware after the current one.
--- @field getState fun(): S Returns the store's current state.

--- Function that may inspect, transform, delay, or short-circuit an `action` before it reaches the next middleware (or the store's reducer) by choosing whether to call `next`.
--- @alias WuxMiddleware<S> fun(store: WuxMiddlewareStore<S>, next: WuxDispatch, action: WuxAction): WuxAction

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

--- Returns a copy of the given table. A non-table value is returned as-is.
--- @param t table The table to copy.
--- @param deep boolean If true, performs a deep copy.
--- @return table
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
--- @generic T
--- @param ... T
--- @return T
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

--- Returns a shallow copy of the given table. Nested tables are shared by
--- reference, not copied. A non-table value is returned as-is.
--- @generic T
--- @param t T
--- @return T
function Wux:ShallowCopy(t)
  return copyTable(t, false)
end

--- Returns a deep copy of the given table. A non-table value is returned as-is.
--- @generic T
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

--- Returns an action creator: a function that builds a `WuxPayloadAction`
--- with the given `actionType`, from whatever value it's called with.
--- Calling it with no value produces a bare `WuxAction`. The returned
--- function is untyped; cast it where you assign it.
---
--- ```
--- --- @type WuxActionCreator<integer>
--- local increment = Wux:CreateActionCreator("INCREMENT")
--- ```
--- @param actionType string
--- @return fun(value: any): WuxPayloadAction<any>
function Wux:CreateActionCreator(actionType)
  return function(value)
    return { type = actionType, payload = value }
  end
end

--- Returns a reducer that replaces its state with `action.payload` when
--- `action.type` matches `actionType`, or with `defaultState` when state is
--- `nil`. The payload is used as-is, not copied.
--- @generic S
--- @param actionType string
--- @param defaultState S
--- @return fun(state: S, action: WuxPayloadAction<S>): S
function Wux:CreatePayloadReducer(actionType, defaultState)
  return function(state, action)
    state = Wux:Coalesce(state, defaultState)
    if action.type == actionType then
      return action.payload
    end
    return state
  end
end

--- Returns a reducer that shallow-merges `action.payload`'s fields into its
--- state when `action.type` matches `actionType`, or with `defaultState`
--- when state is `nil`. Unlike `CreatePayloadReducer`, existing fields not
--- present in `payload` are left as-is, rather than replaced wholesale.
--- @generic S : table
--- @param actionType string
--- @param defaultState S
--- @return fun(state: S, action: WuxPayloadAction<table<string, any>>): S
function Wux:CreatePatchReducer(actionType, defaultState)
  return function(state, action)
    state = Wux:Coalesce(state, defaultState)
    if action.type == actionType then
      state = Wux:ShallowCopy(state)
      for key, value in pairs(action.payload) do
        state[key] = value
      end
    end
    return state
  end
end

--- Returns a root reducer composed of all given reducers. If none of them
--- change their slice of state, the previous state is returned as-is.
--- @param reducers table<string, WuxReducer<any, any>>
--- @return WuxReducer<table, any> reducer
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

--- Reads SavedVariables globals into a table shaped for `CreateStore`'s
--- `initialState`, based on the given mapping.
--- @param mapping WuxSavedVariablesMapping
--- @return table
function Wux:ReadSavedVariables(mapping)
  if type(mapping) == "string" then
    return _G[mapping] or {}
  end

  local state = {}
  for key, name in pairs(mapping) do
    state[key] = _G[name] or {}
  end
  return state
end

--- Writes state to its mapped SavedVariables globals.
--- @param mapping WuxSavedVariablesMapping
--- @param state table
function Wux:WriteSavedVariables(mapping, state)
  if type(mapping) == "string" then
    _G[mapping] = state
  else
    for key, name in pairs(mapping) do
      _G[name] = state[key]
    end
  end
end

--- Returns a new store based on the given reducer.
--- @generic S : table
--- @param reducer WuxReducer<S, any>
--- @param initialState? S
--- @param middlewares? WuxMiddleware<S>[] Applied in list order; the first middleware receives each action first.
--- @return WuxStore<S>
function Wux:CreateStore(reducer, initialState, middlewares)
  local Store = {}

  --- @type WuxListener<any>[]
  local listeners = {}

  --- @type table?
  local state = nil

  if type(initialState) == "table" then
    state = initialState
  end

  --- Returns the current state of the store.
  --- @return table state
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
      --- @cast action WuxPayloadAction<WuxAction[]>
      for _, batchedAction in ipairs(action.payload) do
        state = reducer(state, batchedAction)
      end
    else
      -- Handle single action.
      state = reducer(state, action)
    end

    -- Notify listeners if state changed.
    if state ~= prevState then
      for _, listener in ipairs(listeners) do
        listener(state)
      end
    end

    return action
  end

  -- Declared before it's assigned, so middlewareStore.dispatch below can
  -- close over it and pick up the fully composed chain once it's built.
  --- @type WuxDispatch
  local dispatch

  -- middlewareStore.dispatch calls through the `dispatch` upvalue above,
  -- not `chain` directly. That way, a middleware that dispatches a new
  -- action sends it through the whole chain again, rather than skipping
  -- ahead to wherever the current middleware happens to sit.
  --- @type WuxMiddlewareStore<any>
  local middlewareStore = {
    getState = function() return state end,
    dispatch = function(action) return dispatch(action) end
  }

  -- Compose the middleware chain around baseDispatch. Declaration order is
  -- execution order; the first middleware in `middlewares` runs first.
  middlewares = middlewares or {}
  --- @cast middlewares WuxMiddleware<any>[]
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
  --- @param listener WuxListener<any>
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

  --- Writes state to its mapped SavedVariables globals immediately, then
  --- again on every subsequent change.
  --- @param mapping WuxSavedVariablesMapping
  --- @return fun() unsubscribe
  function Store:ConnectSavedVariables(mapping)
    Wux:WriteSavedVariables(mapping, state)
    return Store:Subscribe(function(newState)
      Wux:WriteSavedVariables(mapping, newState)
    end)
  end

  -- Seed the initial state. This also passes through any given middleware.
  Store:Dispatch({ type = Wux.ActionTypes.InitializeState })

  return Store
end
