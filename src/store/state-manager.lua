local _, Addon = ...
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local StateManager = Addon:GetModule("StateManager") --- @class StateManager
local Reducers = Addon:GetModule("Reducers") --- @type Reducers
local Wux = Addon.Wux --- @type Wux

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

local _Store = nil

-- Create store once the `Wow.PlayerLogin` event fires.
EventManager:Once(E.Wow.PlayerLogin, function()
  local initialState = {
    global = _G[GLOBAL_SV_KEY],
    perchar = _G[PERCHAR_SV_KEY]
  }

  _Store = Wux:CreateStore(Reducers.rootReducer, initialState)
  _Store:Subscribe(updateSavedVariables)
  updateSavedVariables(_Store:GetState())

  EventManager:Fire(E.StoreCreated, _Store)
  EventManager:Fire(E.StateUpdated, _Store:GetState())
end)

-- ============================================================================
-- StateManager
-- ============================================================================

--- Returns the underlying Wux store.
--- @return WuxStore
function StateManager:GetStore()
  return _Store
end

--- Returns true if `perchar.characterSpecificSettings` is enabled.
--- @return boolean
function StateManager:IsCharacterSpecificSettings()
  return _Store:GetState().perchar.characterSpecificSettings == true
end

--- Returns either global state or perchar state depending on
--- the value of `perchar.characterSpecificSettings`.
--- @return GlobalState | PercharState
function StateManager:GetCurrentState()
  local state = _Store:GetState()
  if state.perchar.characterSpecificSettings == true then
    return state.perchar
  else
    return state.global
  end
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
