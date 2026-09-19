--- @diagnostic disable: undefined-global, missing-fields, assign-type-mismatch

local Harness = require("test/harness")
local Matchers = require("test/matchers")
Harness:Load("src/store/default-states.lua")
Harness:Load("src/store/state-reconciler.lua")

local Addon = Harness.Addon
local DefaultStates = Addon:GetModule("DefaultStates")
local StateReconciler = Addon:GetModule("StateReconciler")
local Wux = Addon.Wux

-- ============================================================================
-- Tests - StateReconciler:Reconcile()
-- ============================================================================

-- Test: an empty state is backfilled from `DefaultStates`.
do
  local state = StateReconciler:Reconcile({})
  assert(Matchers:IsDeepEqual(state.global, DefaultStates.Global))
  assert(Matchers:IsDeepEqual(state.profiles, DefaultStates.Profiles))
end

-- Test: a value of the wrong type is replaced with its default.
do
  local state = StateReconciler:Reconcile({ global = { chatMessages = "yes", minimapIcon = false } })
  assert(state.global.chatMessages == DefaultStates.Global.chatMessages)
  assert(Matchers:IsDeepEqual(state.global.minimapIcon, DefaultStates.Global.minimapIcon))
end

-- Test: a profile setting of the wrong type is replaced with its default.
do
  local state = StateReconciler:Reconcile({
    profiles = {
      profileMap = { p1 = { id = "p1", name = "P1", settings = { autoSell = "yes", includeByQuality = false } } },
    },
  })
  local settings = state.profiles.profileMap.p1.settings
  assert(settings.autoSell == DefaultStates.Profile.settings.autoSell)
  assert(Matchers:IsDeepEqual(settings.includeByQuality, DefaultStates.Profile.settings.includeByQuality))
end

-- Test: a section that is not a table is replaced with a copy of its default.
do
  local state = StateReconciler:Reconcile({ global = 5, profiles = "none" })
  assert(Matchers:IsDeepEqual(state.global, DefaultStates.Global))
  assert(Matchers:IsDeepEqual(state.profiles, DefaultStates.Profiles))
end

-- Test: a value of the right type is kept at any depth, and everything else is backfilled.
do
  local state = StateReconciler:Reconcile({
    profiles = {
      profileMap = {
        p1 = { id = "p1", name = "P1", settings = { autoSell = true, includeByQuality = { qualities = { epic = true } } } },
      },
    },
  })
  local expected = Wux:DeepCopy(DefaultStates.Profile.settings)
  expected.autoSell = true
  expected.includeByQuality.qualities.epic = true
  assert(Matchers:IsDeepEqual(state.profiles.profileMap.p1.settings, expected))
end

-- Test: a table with an empty default keeps its contents, and is replaced only when it is not a table.
do
  local state = StateReconciler:Reconcile({
    global = { inclusions = { ["1"] = true, ["2"] = "odd" }, exclusions = "none" },
  })
  assert(Matchers:IsDeepEqual(state.global.inclusions, { ["1"] = true, ["2"] = "odd" }))
  assert(Matchers:IsDeepEqual(state.global.exclusions, {}))
end

-- Test: keys with no default are kept.
do
  local state = StateReconciler:Reconcile({
    extra = 1,
    global = { extra = 2, minimapIcon = { hide = true, minimapPos = 90 } },
  })
  assert(state.extra == 1)
  assert(state.global.extra == 2)
  assert(Matchers:IsDeepEqual(state.global.minimapIcon, { hide = true, minimapPos = 90 }))
end

-- Test: the settings of every profile are reconciled.
do
  local state = StateReconciler:Reconcile({
    profiles = {
      profileMap = {
        p1 = { id = "p1", name = "P1", settings = {} },
        p2 = { id = "p2", name = "P2" },
      },
    },
  })
  assert(Matchers:IsDeepEqual(state.profiles.profileMap.p1, { id = "p1", name = "P1", settings = DefaultStates.Profile.settings }))
  assert(Matchers:IsDeepEqual(state.profiles.profileMap.p2, { id = "p2", name = "P2", settings = DefaultStates.Profile.settings }))
end

-- Test: a profile that is not a table is removed.
do
  local state = StateReconciler:Reconcile({
    profiles = { profileMap = { bad = "none", good = { id = "good", name = "Good", settings = {} } } },
  })
  assert(Matchers:IsDeepEqual(state.profiles.profileMap, {
    good = { id = "good", name = "Good", settings = DefaultStates.Profile.settings },
  }))
end

-- Test: the result does not share tables with `DefaultStates`.
do
  local state = StateReconciler:Reconcile({ profiles = { profileMap = { p1 = { id = "p1", name = "P1" } } } })

  state.global.points.mainWindow.offsetX = 999
  state.profiles.profileMap.p1.settings.includeByQuality.enabled = "changed"

  assert(DefaultStates.Global.points.mainWindow.offsetX ~= 999)
  assert(DefaultStates.Profile.settings.includeByQuality.enabled ~= "changed")
end

-- Test: the input state is not mutated.
do
  local input = { global = { chatMessages = "yes" }, profiles = { profileMap = { p1 = { id = "p1", name = "P1" } } } }
  local expected = Wux:DeepCopy(input)

  StateReconciler:Reconcile(input)

  assert(Matchers:IsDeepEqual(input, expected))
end

-- Test: reconciling a reconciled state changes nothing.
do
  local once = StateReconciler:Reconcile({ global = { chatMessages = "yes" }, profiles = { profileMap = { p1 = { id = "p1", name = "P1" } } } })
  local twice = StateReconciler:Reconcile(once)
  assert(Matchers:IsDeepEqual(twice, once))
end

print("All assertions passed.")
