local _, Addon = ...
local Actions = Addon:GetModule("Actions") --- @class Actions

-- ============================================================================
-- Global
-- ============================================================================

-- TODO: add actions.

-- ============================================================================
-- Per Character
-- ============================================================================

--- @return WuxAction
function Actions:ToggleCharacterSpecificSettings()
  return { type = "perchar/characterSpecificSettings/toggle" }
end
