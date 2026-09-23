local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class LegacyMigration
local LegacyMigration = Addon:GetModule("LegacyMigration")

-- ============================================================================
-- Legacy State
-- ============================================================================

--- @class LegacyRootState
--- @field global LegacyListsState
--- @field perchar LegacyListsState

--- @class LegacyListsState
--- @field inclusions? ItemIdMap
--- @field exclusions? ItemIdMap

-- ============================================================================
-- LegacyMigration
-- ============================================================================

--- Reads the new and legacy SavedVariables (via `newMapping`/`legacyMapping`),
--- and moves legacy lists to the new global and profile states as necessary.
--- @param newMapping WuxSavedVariablesMapping
--- @param legacyMapping WuxSavedVariablesMapping
--- @param characterKey string
--- @param newProfileId string
--- @return DejunkRootState initialState For `Wux:CreateStore()`
function LegacyMigration:MigrateLegacyLists(newMapping, legacyMapping, characterKey, newProfileId)
  --- @type DejunkRootState
  local newState = Wux:ReadSavedVariables(newMapping)

  --- @type LegacyRootState
  local legacyState = Wux:ReadSavedVariables(legacyMapping)

  -- Migrate legacy global lists on initial login only.
  if next(newState) == nil and next(legacyState.global) ~= nil then
    if type(newState.global) ~= "table" then newState.global = {} end
    newState.global.inclusions = legacyState.global.inclusions
    newState.global.exclusions = legacyState.global.exclusions
  end

  -- Migrate legacy perchar lists to a new profile if any data exists.
  if next(legacyState.perchar) ~= nil then
    if (next(legacyState.perchar.inclusions or {}) or next(legacyState.perchar.exclusions or {})) then
      newState.profiles = newState.profiles or { characterMap = {}, profileMap = {} }
      newState.profiles.characterMap[characterKey] = newProfileId
      newState.profiles.profileMap[newProfileId] = {
        id = newProfileId,
        name = characterKey,
        settings = {
          inclusions = legacyState.perchar.inclusions,
          exclusions = legacyState.perchar.exclusions
        },
      }
    end
  end

  -- Wipe out the legacy saved variables.
  _G[legacyMapping.global] = nil
  _G[legacyMapping.perchar] = nil

  return newState
end
