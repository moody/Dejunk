local Addon = select(2, ...) ---@type Addon
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class StateReconciler
local StateReconciler = Addon:GetModule("StateReconciler")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns `value` with missing values backfilled from `default`, and values of the wrong type replaced with copies of
--- it. Tables with an empty `default` keep their contents, and keys without a default are kept. Mutates `value`.
--- @generic T
--- @param value any
--- @param default T
--- @return T
local function reconcile(value, default)
  if type(value) ~= type(default) then return Wux:DeepCopy(default) end
  if type(default) ~= "table" then return value end

  for key, defaultValue in pairs(default) do
    value[key] = reconcile(value[key], defaultValue)
  end
  return value
end

-- ============================================================================
-- StateReconciler
-- ============================================================================

--- Returns `state` in the current shape, without mutating the input. Missing values are backfilled from
--- `DefaultStates`, values of the wrong type are replaced with copies of their defaults, and profiles that are not
--- tables are removed. Run after migrations, which move old data first.
--- @param state DejunkRootState
--- @return DejunkRootState
function StateReconciler:Reconcile(state)
  state = Wux:DeepCopy(state)
  state.global = reconcile(state.global, DefaultStates.Global)
  state.profiles = reconcile(state.profiles, DefaultStates.Profiles)

  for profileId, profile in pairs(state.profiles.profileMap) do
    if type(profile) == "table" then
      profile.settings = reconcile(profile.settings, DefaultStates.Profile.settings)
    else
      state.profiles.profileMap[profileId] = nil
    end
  end

  return state
end
