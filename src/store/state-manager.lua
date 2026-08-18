local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local RootReducer = Addon:GetModule("RootReducer")
local Wux = Addon.Wux

---@class StateManager
local StateManager = Addon:GetModule("StateManager")

local GLOBAL_SV_KEY = "__DEJUNK_ADDON_GLOBAL_SAVED_VARIABLES__"
local PERCHAR_SV_KEY = "__DEJUNK_ADDON_PERCHAR_SAVED_VARIABLES__"

-- ============================================================================
-- Local Functions
-- ============================================================================

local function updateSavedVariables(state)
  _G[GLOBAL_SV_KEY] = state.global
  _G[PERCHAR_SV_KEY] = state.perchar
  EventManager:Fire(E.StateUpdated, state)
end

-- ============================================================================
-- Store
-- ============================================================================

--- @type WuxStore<DejunkRootState>
local _Store

-- Create store once the `Wow.PlayerLogin` event fires.
EventManager:Once(E.Wow.PlayerLogin, function()
  --- @type DejunkRootState
  local initialState = {
    global = _G[GLOBAL_SV_KEY],
    perchar = _G[PERCHAR_SV_KEY]
  }

  _Store = Wux:CreateStore(RootReducer:Build(), initialState)
  _Store:Subscribe(updateSavedVariables)
  updateSavedVariables(_Store:GetState())

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
--- @param action WuxAction<any>
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
