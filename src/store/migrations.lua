local Addon = select(2, ...) ---@type Addon
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class Migrations
local Migrations = Addon:GetModule("Migrations")

-- ============================================================================
-- Steps
-- ============================================================================

--- Steps keyed by the version they migrate to, each returning the migrated state. A step must tolerate missing and
--- already-migrated data, and migrate every profile in `profiles.profileMap`, not just the active one.
--- @type table<integer, fun(state: table): table>
Migrations.STEPS = {}

--- Version 2:
--- - `includeArtifactRelics`: a boolean becomes `{ enabled = <old value>, scope = "BOTH" }`.
--- - `excludeEquipmentSets`: a boolean becomes `{ enabled = <old value>, scope = "BOTH" }`.
---
--- A value that is not a boolean is left as it is.
Migrations.STEPS[2] = function(state)
  if type(state.profiles) == "table" and type(state.profiles.profileMap) == "table" then
    for _, profile in pairs(state.profiles.profileMap) do
      if type(profile) == "table" and type(profile.settings) == "table" then
        local settings = profile.settings
        for _, key in ipairs({ "includeArtifactRelics", "excludeEquipmentSets" }) do
          if type(settings[key]) == "boolean" then
            settings[key] = { enabled = settings[key], scope = "BOTH" }
          end
        end
      end
    end
  end

  return state
end

-- ============================================================================
-- Migrations
-- ============================================================================

--- Returns `state` migrated to `currentVersion`, without mutating the input. Runs each step above the saved version in
--- ascending order.
--- - A version that is missing, not a number, or below 1 is treated as version 1.
--- - An empty state is only stamped.
--- - A newer state is returned unchanged, since downgrades are unsupported.
--- @param state table
--- @param steps? table<integer, fun(state: table): table> Defaults to this module's steps.
--- @param currentVersion? integer Defaults to `DefaultStates.CURRENT_VERSION`.
--- @return table
function Migrations:Migrate(state, steps, currentVersion)
  steps = steps or self.STEPS
  currentVersion = currentVersion or DefaultStates.CURRENT_VERSION

  if next(state) == nil then return { version = currentVersion } end

  state = Wux:DeepCopy(state)
  local version = type(state.version) == "number" and (state.version >= 1 and state.version) or 1
  if version > currentVersion then return state end

  for target = version + 1, currentVersion do
    local step = assert(steps[target], "missing migration to version " .. target)
    state = step(state)
  end

  state.version = currentVersion
  return state
end
