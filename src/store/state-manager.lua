local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local DefaultStates = Addon:GetModule("DefaultStates")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local LegacyMigration = Addon:GetModule("LegacyMigration")
local Middlewares = Addon:GetModule("Middlewares")
local RootReducer = Addon:GetModule("RootReducer")
local Wux = Addon.Wux

---@class StateManager
local StateManager = Addon:GetModule("StateManager")

local SAVED_VARIABLES_KEY = "__DEJUNK_ADDON_V3_SAVED_VARIABLES__"
local LEGACY_SV_MAPPING = {
  global = "__DEJUNK_ADDON_GLOBAL_SAVED_VARIABLES__",
  perchar = "__DEJUNK_ADDON_PERCHAR_SAVED_VARIABLES__"
}

-- ============================================================================
-- Store
-- ============================================================================

--- @type WuxStore<DejunkRootState>
local _Store

-- Create store once the `Wow.PlayerLogin` event fires.
EventManager:Once(E.Wow.PlayerLogin, function()
  --- @type DejunkRootState
  local initialState = LegacyMigration:MigrateLegacyLists(
    SAVED_VARIABLES_KEY,
    LEGACY_SV_MAPPING,
    Addon:GetCharacterKey(),
    Addon:GetShortUID()
  )

  -- Initialize the `activeProfileId` before creating the store.
  if type(initialState.profiles) ~= "table" then initialState.profiles = Wux:DeepCopy(DefaultStates.Profiles) end
  if type(initialState.profiles.characterMap) ~= "table" then initialState.profiles.characterMap = {} end
  initialState.profiles.activeProfileId = initialState.profiles.characterMap[Addon:GetCharacterKey()]

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

  --- Returns every profile, including the synthetic default profile (which is
  --- never actually stored in `profileMap`), sorted by name.
  --- @return ProfileState[]
  function StateManager:GetAllProfiles()
    for k in pairs(profiles) do profiles[k] = nil end
    for _, profile in pairs(_Store:GetState().profiles.profileMap) do
      profiles[#profiles + 1] = profile
    end
    table.sort(profiles, sortProfiles)
    table.insert(profiles, 1, DefaultStates.Profile)
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

--- Returns `true` if the default profile is active.
--- @return boolean
function StateManager:IsDefaultProfileActive()
  return _Store:GetState().profiles.activeProfileId == DefaultStates.DEFAULT_PROFILE_ID
end

-- ============================================================================
-- Events
-- ============================================================================

local function onActiveProfileChanged()
  Addon:Print(L.SET_PROFILE:format(Colors.Yellow(StateManager:GetProfileState().name)))
end

EventManager:Once(E.StoreCreated, onActiveProfileChanged)
EventManager:On(E.ActiveProfileChanged, onActiveProfileChanged)
