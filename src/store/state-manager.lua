local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local DefaultStates = Addon:GetModule("DefaultStates")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local Middlewares = Addon:GetModule("Middlewares")
local Migrations = Addon:GetModule("Migrations")
local RootReducer = Addon:GetModule("RootReducer")
local StateReconciler = Addon:GetModule("StateReconciler")
local Wux = Addon.Wux

---@class StateManager
local StateManager = Addon:GetModule("StateManager")

local SAVED_VARIABLES_KEY = "__DEJUNK_ADDON_V3_SAVED_VARIABLES__"

-- ============================================================================
-- Store
-- ============================================================================

--- @type WuxStore<DejunkRootState>
local _Store

-- Create store once the `Wow.PlayerLogin` event fires.
EventManager:Once(E.Wow.PlayerLogin, function()
  --- @type DejunkRootState
  local initialState = Wux:ReadSavedVariables(SAVED_VARIABLES_KEY)
  initialState = Migrations:Migrate(initialState)
  initialState = StateReconciler:Reconcile(initialState)

  -- Initialize the `activeProfileId` before creating the store. If the
  -- character's mapped profile no longer exists (e.g. a corrupted entry
  -- `StateReconciler` had to drop from `profileMap`), fall back to the
  -- default profile and fix the character's own mapping too, so this
  -- doesn't recur next login.
  local characterKey = Addon:GetCharacterKey()
  local activeProfileId = initialState.profiles.characterMap[characterKey]
  if activeProfileId ~= nil
      and activeProfileId ~= DefaultStates.DEFAULT_PROFILE_ID
      and initialState.profiles.profileMap[activeProfileId] == nil then
    activeProfileId = DefaultStates.DEFAULT_PROFILE_ID
    initialState.profiles.characterMap[characterKey] = DefaultStates.DEFAULT_PROFILE_ID
  end
  initialState.profiles.activeProfileId = activeProfileId

  _Store = Wux:CreateStore(RootReducer:Build(), initialState, Middlewares:Build())

  do -- Wire up saved variables.
    local function write(state)
      state = Wux:ShallowCopy(state)
      state.profiles = Wux:ShallowCopy(state.profiles)
      state.profiles.activeProfileId = nil
      _G[SAVED_VARIABLES_KEY] = state
    end
    write(_Store:GetState())
    _Store:Subscribe(write)
  end

  do -- Wire up events.
    local previousActiveProfileId = _Store:GetState().profiles.activeProfileId

    _Store:Subscribe(function(state)
      if state.profiles.activeProfileId ~= previousActiveProfileId then
        previousActiveProfileId = state.profiles.activeProfileId
        EventManager:Fire(E.ActiveProfileChanged)
      end

      EventManager:Fire(E.StateUpdated, state)
    end)
  end

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

--- Returns the active profile state.
--- @return ProfileState
function StateManager:GetProfileState()
  local state = _Store:GetState()
  return state.profiles.profileMap[state.profiles.activeProfileId] or DefaultStates.Profile
end

-- StateManager:GetAllProfiles()
do
  local profiles = {}

  local function sortProfiles(a, b)
    return a.name < b.name
  end

  --- Returns every profile, sorted by name with the default profile always
  --- first: the live one if it's been persisted yet, otherwise the shared
  --- default template.
  --- @return ProfileState[]
  function StateManager:GetAllProfiles()
    for k in pairs(profiles) do profiles[k] = nil end
    local profileMap = _Store:GetState().profiles.profileMap
    for id, profile in pairs(profileMap) do
      if id ~= DefaultStates.DEFAULT_PROFILE_ID then
        profiles[#profiles + 1] = profile
      end
    end
    table.sort(profiles, sortProfiles)
    table.insert(profiles, 1, profileMap[DefaultStates.DEFAULT_PROFILE_ID] or DefaultStates.Profile)
    return profiles
  end
end

--- Creates a new profile and immediately activates it.
---@param profileName? string
function StateManager:CreateNewProfile(profileName)
  local profileId = Addon:GetShortUID()
  local characterKey = Addon:GetCharacterKey()
  profileName = profileName or characterKey
  _Store:Dispatch({
    type = Wux.ActionTypes.Batch,
    payload = {
      ActionCreators.Profiles.createProfile({ profileId = profileId, profileName = profileName }),
      ActionCreators.Profiles.assignProfile({ profileId = profileId, characterKey = characterKey })
    }
  })
end

-- ============================================================================
-- Events
-- ============================================================================

local function onActiveProfileChanged()
  Addon:Print(L.ACTIVE_PROFILE, Colors.Yellow(StateManager:GetProfileState().name))
end

EventManager:Once(E.StoreCreated, onActiveProfileChanged)
EventManager:On(E.ActiveProfileChanged, onActiveProfileChanged)
