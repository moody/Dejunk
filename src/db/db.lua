local AddonName, Addon = ...
local DatabaseUtils = Addon.DatabaseUtils
local DB = Addon.DB
local E = Addon.Events
local EventManager = Addon.EventManager

-- ============================================================================
-- Events
-- ============================================================================

-- Initialize the database on player login.
EventManager:Once(E.Wow.PlayerLogin, function()
  local db = Addon.DethsDBLib(AddonName, {
    Global = DatabaseUtils:Global(),
    Profile = DatabaseUtils:Profile()
  })
  setmetatable(DB, { __index = db })

  Addon:TransitionDB()
  DatabaseUtils:Reformat()

  EventManager:Fire(E.DatabaseReady)
  EventManager:Fire(E.ProfileChanged)
end)
