local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

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

-- ============================================================================
-- Middlewares
-- ============================================================================

--- Builds the ordered list of middlewares for the store. Declaration order is
--- execution order, the first middleware here runs first.
--- @return WuxMiddleware<DejunkRootState>[]
function Middlewares:Build()
  local middlewares = {}
  if Addon.IS_DEBUG then middlewares[#middlewares + 1] = debugMiddleware end
  return middlewares
end
