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

do
  --- The lists that have a keybinding, as their names appear in the binding names.
  local LIST_NAMES = { "ProfileInclusions", "ProfileExclusions", "GlobalInclusions", "GlobalExclusions" }

  --- Returns `true` if `key` is a saved key, not `UNBOUND_KEY` or a value of another type.
  --- @param key any
  --- @return boolean
  local function isBound(key)
    return type(key) == "string" and key ~= DefaultStates.UNBOUND_KEY
  end

  --- Version 3:
  --- - `global.keybindings`: for each list, `addTo<List>` and `removeFrom<List>` become one `addOrRemove<List>`. It
  ---   takes the `addTo` key, or the `removeFrom` key if `addTo` had none. Both old names are removed.
  ---
  --- An `addOrRemove<List>` that already has a key is kept.
  Migrations.STEPS[3] = function(state)
    local keybindings = type(state.global) == "table" and state.global.keybindings

    if type(keybindings) == "table" then
      for _, listName in ipairs(LIST_NAMES) do
        local addToName = "addTo" .. listName
        local removeFromName = "removeFrom" .. listName
        local addOrRemoveName = "addOrRemove" .. listName

        if not isBound(keybindings[addOrRemoveName]) then
          if isBound(keybindings[addToName]) then
            keybindings[addOrRemoveName] = keybindings[addToName]
          elseif isBound(keybindings[removeFromName]) then
            keybindings[addOrRemoveName] = keybindings[removeFromName]
          end
        end

        keybindings[addToName] = nil
        keybindings[removeFromName] = nil
      end
    end

    return state
  end
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
