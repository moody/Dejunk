local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local RootReducer = Addon:GetModule("RootReducer")
local Wux = Addon.Wux

---@class StateManager
local StateManager = Addon:GetModule("StateManager")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Debug logger for each dispatched action.
--- @type WuxMiddleware<DejunkRootState>
local function debugMiddleware(store, next, action)
  Addon:Debug(Colors.Grey(("-"):rep(60)))
  Addon:Debug("Dispatched:", Colors.Gold(action.type))
  Addon:Dump({ action = action })
  Addon:Debug(Colors.Grey(("-"):rep(60)))
  return next(action)
end

-- ============================================================================
-- Store
-- ============================================================================

--- @type WuxStore<DejunkRootState>
local _Store

-- Create store once the `Wow.PlayerLogin` event fires.
EventManager:Once(E.Wow.PlayerLogin, function()
  local savedVariables = {
    global = "__DEJUNK_ADDON_GLOBAL_SAVED_VARIABLES__",
    perchar = "__DEJUNK_ADDON_PERCHAR_SAVED_VARIABLES__"
  }

  _Store = Wux:CreateStore(
    RootReducer:Build(),
    Wux:ReadSavedVariables(savedVariables),
    Addon.IS_DEBUG and { debugMiddleware } or nil
  )
  _Store:ConnectSavedVariables(savedVariables)
  _Store:Subscribe(function(state)
    EventManager:Fire(E.StateUpdated, state)
  end)

  EventManager:Fire(E.StoreCreated, _Store)
  EventManager:Fire(E.StateUpdated, _Store:GetState())
end)

-- ============================================================================
-- StateManager
-- ============================================================================

--- Returns the underlying Wux store.
--- @return WuxStore<DejunkRootState>
function StateManager:GetStore()
  return _Store
end

--- Convenience method. Equivalent to `StateManager:GetStore():Dispatch()`.
--- @param action WuxAction
function StateManager:Dispatch(action)
  _Store:Dispatch(action)
end

--- Returns the global state.
--- @return GlobalState
function StateManager:GetGlobalState()
  return _Store:GetState().global
end

--- Returns the perchar state.
--- @return PercharState
function StateManager:GetPercharState()
  return _Store:GetState().perchar
end
