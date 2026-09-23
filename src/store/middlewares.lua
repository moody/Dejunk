local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class Middlewares
local Middlewares = Addon:GetModule("Middlewares")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Debug logger for each dispatched action.
--- @type WuxMiddleware<DejunkRootState>
local function debugMiddleware(store, next, action)
  print(" ")
  Addon:Debug(Colors.Grey(("-"):rep(60)))
  Addon:Debug("Dispatched:", Colors.Gold(action.type))
  Addon:Dump({ action = action })
  Addon:Debug(Colors.Grey(("-"):rep(60)))
  return next(action)
end

--- Intercepts profile actions to create and assign a new profile
--- if the user attempts to modify the default profile.
--- @type WuxMiddleware<DejunkRootState>
local function newProfileMiddleware(store, next, action)
  local state = store.getState()
  if state.profiles and state.profiles.activeProfileId == DefaultStates.DEFAULT_PROFILE_ID then
    if action.type:find("^(profile/).+") == 1 then
      local profileId = Addon:GetShortUID()
      local characterKey = Addon:GetCharacterKey()
      return store.dispatch({
        type = Wux.ActionTypes.Batch,
        payload = {
          ActionCreators.Profiles.createProfile({ profileId = profileId, profileName = characterKey }),
          ActionCreators.Profiles.assignProfile({ profileId = profileId, characterKey = characterKey }),
          action
        }
      })
    end
  end
  return next(action)
end

-- ============================================================================
-- Middlewares
-- ============================================================================

--- Builds the ordered list of middlewares for the store. Declaration order is
--- execution order, the first middleware here runs first.
--- @return WuxMiddleware<DejunkRootState>[]
function Middlewares:Build()
  local middlewares = {}
  if Addon.IS_DEBUG then middlewares[#middlewares + 1] = debugMiddleware end
  middlewares[#middlewares + 1] = newProfileMiddleware
  return middlewares
end
