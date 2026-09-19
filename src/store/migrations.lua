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
local STEPS = {}

-- ============================================================================
-- Migrations
-- ============================================================================

--- Returns `state` migrated to `currentVersion`, without mutating the input. Runs each step above the saved version in
--- ascending order. A state without a valid version is treated as version 1, an empty state is only stamped, and a
--- newer state is returned unchanged since downgrades are unsupported.
--- @param state table
--- @param steps? table<integer, fun(state: table): table> Defaults to this module's steps.
--- @param currentVersion? integer Defaults to `DefaultStates.CURRENT_VERSION`.
--- @return table
function Migrations:Migrate(state, steps, currentVersion)
  steps = steps or STEPS
  currentVersion = currentVersion or DefaultStates.CURRENT_VERSION

  if next(state) == nil then return { version = currentVersion } end

  state = Wux:DeepCopy(state)
  local version = type(state.version) == "number" and state.version or 1
  if version > currentVersion then return state end

  for target = version + 1, currentVersion do
    local step = assert(steps[target], "missing migration to version " .. target)
    state = step(state)
  end

  state.version = currentVersion
  return state
end
