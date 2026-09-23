--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local TableUtils = require("test/table-utils")
Harness:Load("src/store/action-types.lua")
Harness:Load("src/store/action-creators.lua")
Harness:Load("src/store/default-states.lua")
Harness:Load("src/store/root-reducer.lua")

local Addon = Harness.Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local RootReducer = Addon:GetModule("RootReducer")
local Wux = Addon.Wux

-- ============================================================================
-- Setup
-- ============================================================================

--- Ignored by every reducer. Creates the initial state from `nil`, or leaves an existing state unchanged.
local TEST_ACTION = { type = "@@TEST/ACTION" }

local PROFILE_ID = "abc123"
local PROFILE_NAME = "Test"
local CHARACTER_KEY = "Char-Realm"

local reducer = RootReducer:Build()

--- Dispatches `options.action` and asserts that it changes only `options.path`, to `options.expected`, without
--- mutating `options.state`.
--- @param options { state: table, action: table, path: string, expected: any }
local function assertDispatchResult(options)
  assert(
    not Matchers:IsDeepEqual(TableUtils:GetByPath(options.state, options.path), options.expected),
    options.action.type .. ": expected must differ from the current value"
  )

  local unmutatedState = Wux:DeepCopy(options.state)
  local expectedState = Wux:DeepCopy(options.state)
  TableUtils:SetByPath(expectedState, options.path, options.expected)

  local nextState = reducer(options.state, options.action)

  assert(Matchers:IsDeepEqual(options.state, unmutatedState))
  assert(Matchers:IsDeepEqual(nextState, expectedState))
end

-- ============================================================================
-- Tests - RootReducer:Build()
-- ============================================================================

-- Test: the first dispatch yields the default state, with empty profile maps.
do
  local state = reducer(nil, TEST_ACTION)
  assert(state.version == DefaultStates.CURRENT_VERSION)
  assert(Matchers:IsDeepEqual(state.global, DefaultStates.Global))
  assert(state.profiles.activeProfileId == DefaultStates.DEFAULT_PROFILE_ID)
  assert(next(state.profiles.profileMap) == nil)
  assert(next(state.profiles.characterMap) == nil)
end

-- Test: an existing `version` is kept.
do
  local state = reducer({ version = DefaultStates.CURRENT_VERSION + 1 }, TEST_ACTION)
  assert(state.version == DefaultStates.CURRENT_VERSION + 1)
end

-- Test: an action that no reducer handles returns the same state reference.
do
  local state = reducer(nil, TEST_ACTION)
  assert(reducer(state, TEST_ACTION) == state)

  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = CHARACTER_KEY, profileId = PROFILE_ID }))
  assert(reducer(state, TEST_ACTION) == state)
end

-- Test: `global` and `profiles` stay reference-isolated: a profile action
-- leaves `global` unchanged, and a global action leaves `profiles` unchanged.
do
  local state = reducer(nil, TEST_ACTION)

  local afterProfileAction = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))
  assert(afterProfileAction.global == state.global)

  local afterGlobalAction = reducer(state, ActionCreators.Global.setChatMessages(false))
  assert(afterGlobalAction.profiles == state.profiles)
end

-- ============================================================================
-- Tests - RootReducer:Build() - global
-- ============================================================================

local POINT = { point = "point", relativePoint = "relativePoint", offsetX = 1, offsetY = 2 }

--- Rows for the `global` action test, also read by the action type coverage test.
local GLOBAL_ROWS = {
  { action = ActionCreators.Global.setAutoJunkFrame(true), path = "global.autoJunkFrame", expected = true },
  { action = ActionCreators.Global.setChatMessages(false), path = "global.chatMessages", expected = false },
  { action = ActionCreators.Global.setItemIcons(true), path = "global.itemIcons", expected = true },
  { action = ActionCreators.Global.setItemTooltips(false), path = "global.itemTooltips", expected = false },
  { action = ActionCreators.Global.setMerchantButton(false), path = "global.merchantButton", expected = false },
  { action = ActionCreators.Global.setSafeDestroy(false), path = "global.safeDestroy", expected = false },
  { action = ActionCreators.Global.setSafeSell(true), path = "global.safeSell", expected = true },
  { action = ActionCreators.Global.patchMinimapIcon({ hide = true }), path = "global.minimapIcon.hide", expected = true },
  { action = ActionCreators.Global.setInclusions({ ["1001"] = true }), path = "global.inclusions", expected = { ["1001"] = true } },
  { action = ActionCreators.Global.setExclusions({ ["2001"] = true }), path = "global.exclusions", expected = { ["2001"] = true } },
  { action = ActionCreators.Global.points.mainWindow.set(POINT), path = "global.points.mainWindow", expected = POINT },
  { action = ActionCreators.Global.points.junkFrame.set(POINT), path = "global.points.junkFrame", expected = POINT },
  { action = ActionCreators.Global.points.lootableFrame.set(POINT), path = "global.points.lootableFrame", expected = POINT },
  { action = ActionCreators.Global.points.transportFrame.set(POINT), path = "global.points.transportFrame", expected = POINT },
  { action = ActionCreators.Global.points.merchantButton.set(POINT), path = "global.points.merchantButton", expected = POINT },
  { action = ActionCreators.Global.points.profilesFrame.set(POINT), path = "global.points.profilesFrame", expected = POINT },
}

-- Test: each `global` action changes only its own field.
do
  local state = reducer(nil, TEST_ACTION)

  for _, row in ipairs(GLOBAL_ROWS) do
    assertDispatchResult({
      state = state,
      action = row.action,
      path = row.path,
      expected = row.expected
    })
  end
end

-- Test: each `global.points` reset action restores its own point to a copy of the default.
do
  for name in pairs(DefaultStates.Global.points) do
    local pointActions = ActionCreators.Global.points[name]
    local state = reducer(nil, TEST_ACTION)
    state = reducer(state, pointActions.set(POINT))

    assertDispatchResult({
      state = state,
      action = pointActions.reset(),
      path = "global.points." .. name,
      expected = DefaultStates.Global.points[name],
    })

    local nextState = reducer(state, pointActions.reset())
    assert(nextState.global.points[name] ~= DefaultStates.Global.points[name], name .. ": reset must copy the default")
  end
end

-- ============================================================================
-- Tests - RootReducer:Build() - profiles
-- ============================================================================

-- Test: existing `profiles` state with missing keys is filled in with defaults.
do
  local state = reducer({ profiles = {} }, TEST_ACTION)
  assert(state.profiles.activeProfileId == DefaultStates.DEFAULT_PROFILE_ID)
  assert(next(state.profiles.profileMap) == nil)
  assert(next(state.profiles.characterMap) == nil)
end

-- Test: `CREATE_PROFILE` adds a profile with the given id and name and the
-- default settings, without changing `activeProfileId`.
do
  local state = reducer(nil, TEST_ACTION)

  local nextState = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))

  local profile = nextState.profiles.profileMap[PROFILE_ID]
  assert(profile.id == PROFILE_ID)
  assert(profile.name == PROFILE_NAME)
  assert(Matchers:IsDeepEqual(profile.settings, DefaultStates.Profile.settings))
  assert(nextState.profiles.activeProfileId == DefaultStates.DEFAULT_PROFILE_ID)
end

-- Test: `CREATE_PROFILE` does not mutate the shared `DefaultStates` templates.
do
  local state = reducer(nil, TEST_ACTION)

  reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))

  assert(next(DefaultStates.Profiles.profileMap) == nil)
  assert(DefaultStates.Profile.id == DefaultStates.DEFAULT_PROFILE_ID)
end

-- Test: `ASSIGN_PROFILE` sets `activeProfileId` and records the character's assignment.
do
  local state = reducer(nil, TEST_ACTION)
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))

  local nextState = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = CHARACTER_KEY, profileId = PROFILE_ID }))

  assert(nextState.profiles.activeProfileId == PROFILE_ID)
  assert(nextState.profiles.characterMap[CHARACTER_KEY] == PROFILE_ID)
end

-- Test: `RENAME_PROFILE` renames only the given profile, active or not.
do
  local state = reducer(nil, TEST_ACTION)
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = CHARACTER_KEY, profileId = PROFILE_ID }))
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = "other", profileName = "Other" }))
  local oldSettings = state.profiles.profileMap["other"].settings

  local nextState = reducer(state, ActionCreators.Profiles.renameProfile({ profileId = "other", profileName = "Renamed" }))

  local profile = nextState.profiles.profileMap["other"]
  assert(profile.id == "other")
  assert(profile.name == "Renamed")
  assert(profile.settings == oldSettings)
  assert(nextState.profiles.profileMap[PROFILE_ID].name == PROFILE_NAME)
  assert(nextState.profiles.activeProfileId == PROFILE_ID)
end

-- Test: `DELETE_PROFILE` removes the profile and returns its assigned characters
-- to the default profile, leaving other characters unchanged.
do
  -- `PROFILE_ID` is assigned to two characters, and `other` is assigned to one.
  local state = reducer(nil, TEST_ACTION)
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = CHARACTER_KEY, profileId = PROFILE_ID }))
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = "other", profileName = "Other" }))
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = "Third-Realm", profileId = PROFILE_ID }))
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = "Other-Realm", profileId = "other" }))

  local nextState = reducer(state, ActionCreators.Profiles.deleteProfile({ profileId = PROFILE_ID }))

  assert(nextState.profiles.profileMap[PROFILE_ID] == nil)
  assert(nextState.profiles.profileMap["other"] ~= nil)
  assert(nextState.profiles.characterMap[CHARACTER_KEY] == DefaultStates.DEFAULT_PROFILE_ID)
  assert(nextState.profiles.characterMap["Third-Realm"] == DefaultStates.DEFAULT_PROFILE_ID)
  assert(nextState.profiles.characterMap["Other-Realm"] == "other")
  assert(nextState.profiles.activeProfileId == "other")
end

-- Test: `DELETE_PROFILE` on the active profile resets `activeProfileId` to the default profile.
do
  local state = reducer(nil, TEST_ACTION)
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = CHARACTER_KEY, profileId = PROFILE_ID }))

  local nextState = reducer(state, ActionCreators.Profiles.deleteProfile({ profileId = PROFILE_ID }))

  assert(nextState.profiles.activeProfileId == DefaultStates.DEFAULT_PROFILE_ID)
end

-- ============================================================================
-- Tests - RootReducer:Build() - profile
-- ============================================================================

local PROFILE_PATH = "profiles.profileMap." .. PROFILE_ID

--- Rows for the `profile` action test, also read by the action type coverage test.
local PROFILE_ROWS = {
  { action = ActionCreators.Profile.setProfileName("Renamed"), path = PROFILE_PATH .. ".name", expected = "Renamed" },
  { action = ActionCreators.Profile.setAutoRepair(true), path = PROFILE_PATH .. ".settings.autoRepair", expected = true },
  { action = ActionCreators.Profile.setAutoSell(true), path = PROFILE_PATH .. ".settings.autoSell", expected = true },
  { action = ActionCreators.Profile.mergeExcludeAboveItemLevel({ value = 350 }), path = PROFILE_PATH .. ".settings.excludeAboveItemLevel.value", expected = 350 },
  { action = ActionCreators.Profile.setExcludeEquipmentSets(false), path = PROFILE_PATH .. ".settings.excludeEquipmentSets", expected = false },
  { action = ActionCreators.Profile.mergeExcludeUnboundEquipment({ enabled = true }), path = PROFILE_PATH .. ".settings.excludeUnboundEquipment.enabled", expected = true },
  { action = ActionCreators.Profile.mergeExcludeWarbandEquipment({ enabled = true }), path = PROFILE_PATH .. ".settings.excludeWarbandEquipment.enabled", expected = true },
  { action = ActionCreators.Profile.setIncludeArtifactRelics(true), path = PROFILE_PATH .. ".settings.includeArtifactRelics", expected = true },
  { action = ActionCreators.Profile.mergeIncludeBelowItemLevel({ value = 200 }), path = PROFILE_PATH .. ".settings.includeBelowItemLevel.value", expected = 200 },
  { action = ActionCreators.Profile.mergeIncludeByQuality({ qualities = { epic = true } }), path = PROFILE_PATH .. ".settings.includeByQuality.qualities.epic", expected = true },
  { action = ActionCreators.Profile.mergeIncludeUnsuitableEquipment({ enabled = true }), path = PROFILE_PATH .. ".settings.includeUnsuitableEquipment.enabled", expected = true },
  { action = ActionCreators.Profile.setInclusions({ ["3001"] = true }), path = PROFILE_PATH .. ".settings.inclusions", expected = { ["3001"] = true } },
  { action = ActionCreators.Profile.setExclusions({ ["4001"] = true }), path = PROFILE_PATH .. ".settings.exclusions", expected = { ["4001"] = true } },
}

-- Test: a profile action on the default profile is a no-op; the default
-- profile is never added to `profileMap`.
do
  local state = reducer(nil, TEST_ACTION)

  local nextState = reducer(state, ActionCreators.Profile.setAutoSell(true))

  assert(nextState == state)
  assert(next(nextState.profiles.profileMap) == nil)
end

-- Test: a profile action is a no-op when the active profile is missing from `profileMap`.
do
  local state = reducer(nil, TEST_ACTION)
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = CHARACTER_KEY, profileId = "missing" }))

  local nextState = reducer(state, ActionCreators.Profile.setAutoSell(true))

  assert(nextState == state)
end

-- Test: each profile action changes only its own field on the active profile.
do
  local state = reducer(nil, TEST_ACTION)
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = CHARACTER_KEY, profileId = PROFILE_ID }))

  for _, row in ipairs(PROFILE_ROWS) do
    assertDispatchResult({
      state = state,
      action = row.action,
      path = row.path,
      expected = row.expected
    })
  end
end

-- Test: a profile action changes only the active profile.
do
  local state = reducer(nil, TEST_ACTION)
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = PROFILE_ID, profileName = PROFILE_NAME }))
  state = reducer(state, ActionCreators.Profiles.assignProfile({ characterKey = CHARACTER_KEY, profileId = PROFILE_ID }))
  state = reducer(state, ActionCreators.Profiles.createProfile({ profileId = "other", profileName = "Other" }))

  local nextState = reducer(state, ActionCreators.Profile.setAutoSell(true))

  assert(nextState.profiles.profileMap[PROFILE_ID].settings.autoSell == true)
  assert(nextState.profiles.profileMap["other"] == state.profiles.profileMap["other"])
end

-- ============================================================================
-- Tests - ActionTypes
-- ============================================================================

-- Test: every `global` and `profile` action type is covered by a row or a points reset.
do
  local covered = {}
  for _, row in ipairs(GLOBAL_ROWS) do covered[row.action.type] = true end
  for _, row in ipairs(PROFILE_ROWS) do covered[row.action.type] = true end
  for name in pairs(DefaultStates.Global.points) do
    covered[ActionCreators.Global.points[name].reset().type] = true
  end

  for _, actionTypes in ipairs({ ActionTypes.Global, ActionTypes.Profile }) do
    for name, actionType in pairs(actionTypes) do
      assert(covered[actionType], name .. " has no test")
    end
  end
end

print("All assertions passed.")
