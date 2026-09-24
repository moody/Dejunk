local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")

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

--- Fires `E.ActiveProfileReset` when `RESET_PROFILE` targets the currently
--- active profile.
--- @type WuxMiddleware<DejunkRootState>
local function activeProfileResetMiddleware(store, next, action)
  local result = next(action)
  if action.type == ActionTypes.Profiles.RESET_PROFILE
      and action.payload.profileId == store.getState().profiles.activeProfileId then
    EventManager:Fire(E.ActiveProfileReset)
  end
  return result
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
  middlewares[#middlewares + 1] = activeProfileResetMiddleware
  return middlewares
end
