--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")

local Context = Harness:NewContext()
Context:Load("src/store/default-states.lua")
Context:Load("src/store/migrations.lua")

local DefaultStates = Context:GetModule("DefaultStates")
local Migrations = Context:GetModule("Migrations")
local Wux = Context.Addon.Wux

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns the saved state in `test/fixtures/saved-variables/<version>.lua`.
--- @param version integer
--- @return table
local function loadFixture(version)
  local env = {}
  setfenv(assert(loadfile("test/fixtures/saved-variables/" .. version .. ".lua")), env)()
  return env.__DEJUNK_ADDON_V3_SAVED_VARIABLES__
end

--- Returns `state` after running only step `target`, so later steps do not change the expected output.
--- @param state table
--- @param target integer
--- @return table
local function runStep(state, target)
  return Migrations:Migrate(state, { [target] = Migrations.STEPS[target] }, target)
end

-- ============================================================================
-- Tests - Migrations: Step 2
-- ============================================================================

--- The settings that step 2 converts from booleans to tables.
local STEP_2_OPTION_KEYS = { "includeArtifactRelics", "excludeEquipmentSets" }

-- Test: a boolean option becomes a table that keeps the saved value, with a scope of both.
do
  for _, key in ipairs(STEP_2_OPTION_KEYS) do
    for _, enabled in ipairs({ true, false }) do
      local state = { version = 1, profiles = { profileMap = { p1 = { settings = { [key] = enabled } } } } }

      local migrated = runStep(state, 2)

      assert(Matchers:IsDeepEqual(migrated.profiles.profileMap.p1.settings[key], {
        enabled = enabled,
        scope = "BOTH"
      }), key .. " " .. tostring(enabled))
    end
  end
end

-- Test: each option keeps its own saved value.
do
  local settings = { includeArtifactRelics = true, excludeEquipmentSets = false }
  local state = { version = 1, profiles = { profileMap = { p1 = { settings = settings } } } }

  local migrated = runStep(state, 2)

  local migratedSettings = migrated.profiles.profileMap.p1.settings
  assert(Matchers:IsDeepEqual(migratedSettings.includeArtifactRelics, { enabled = true, scope = "BOTH" }))
  assert(Matchers:IsDeepEqual(migratedSettings.excludeEquipmentSets, { enabled = false, scope = "BOTH" }))
end

-- Test: every profile is migrated, not only the active one.
do
  local state = {
    version = 1,
    profiles = {
      activeProfileId = "p1",
      profileMap = {
        p1 = { settings = { includeArtifactRelics = true, excludeEquipmentSets = true } },
        p2 = { settings = { includeArtifactRelics = false, excludeEquipmentSets = false } }
      }
    }
  }

  local migrated = runStep(state, 2)

  local profileMap = migrated.profiles.profileMap
  for _, key in ipairs(STEP_2_OPTION_KEYS) do
    assert(profileMap.p1.settings[key].enabled == true, "p1 " .. key)
    assert(profileMap.p2.settings[key].enabled == false, "p2 " .. key)
  end
end

-- Test: an option that is already a table is left unchanged.
do
  for _, key in ipairs(STEP_2_OPTION_KEYS) do
    local option = { enabled = true, scope = "SELL" }
    local state = { version = 1, profiles = { profileMap = { p1 = { settings = { [key] = option } } } } }

    local migrated = runStep(state, 2)

    assert(Matchers:IsDeepEqual(migrated.profiles.profileMap.p1.settings[key], option), key)
  end
end

-- Test: an option missing from a profile stays missing while the other is migrated.
do
  local state = { version = 1, profiles = { profileMap = { p1 = { settings = { includeArtifactRelics = true } } } } }

  local migrated = runStep(state, 2)

  local settings = migrated.profiles.profileMap.p1.settings
  assert(Matchers:IsDeepEqual(settings.includeArtifactRelics, { enabled = true, scope = "BOTH" }))
  assert(settings.excludeEquipmentSets == nil)
end

-- Test: other settings are left unchanged.
do
  local excludeUnboundEquipment = { enabled = true, qualities = { poor = true } }
  local settings = { autoSell = true, excludeUnboundEquipment = excludeUnboundEquipment, includeArtifactRelics = true }
  local state = { version = 1, profiles = { profileMap = { p1 = { id = "p1", name = "One", settings = settings } } } }

  local migrated = runStep(state, 2)

  local profile = migrated.profiles.profileMap.p1
  assert(profile.id == "p1")
  assert(profile.name == "One")
  assert(profile.settings.autoSell == true)
  assert(Matchers:IsDeepEqual(profile.settings.excludeUnboundEquipment, excludeUnboundEquipment))
end

-- Test: missing data is tolerated and stays missing.
do
  local cases = {
    noProfiles = { version = 1, global = {} },
    noProfileMap = { version = 1, profiles = {} },
    emptyProfileMap = { version = 1, profiles = { profileMap = {} } },
    profileNotATable = { version = 1, profiles = { profileMap = { p1 = "corrupt" } } },
    noSettings = { version = 1, profiles = { profileMap = { p1 = { id = "p1" } } } },
    settingsNotATable = { version = 1, profiles = { profileMap = { p1 = { settings = "corrupt" } } } },
    noOptions = { version = 1, profiles = { profileMap = { p1 = { settings = { autoSell = true } } } } },
  }

  for name, state in pairs(cases) do
    local expected = Wux:DeepCopy(state)
    expected.version = 2

    local migrated = runStep(state, 2)

    assert(Matchers:IsDeepEqual(migrated, expected), name)
  end
end

-- Test: the version 1 fixture converts both options in each profile and changes nothing else.
do
  local fixture = loadFixture(1)

  -- The expected state is the fixture at version 2, with the options below changed to what the step should produce.
  local expected = Wux:DeepCopy(fixture)
  expected.version = 2

  -- The default profile saved `false` and `true`, which the step keeps as the `enabled` values.
  local defaultSettings = expected.profiles.profileMap[DefaultStates.DEFAULT_PROFILE_ID].settings
  defaultSettings.includeArtifactRelics = { enabled = false, scope = "BOTH" }
  defaultSettings.excludeEquipmentSets = { enabled = true, scope = "BOTH" }

  -- `profile2` saved `true` and `false`.
  local profile2Settings = expected.profiles.profileMap.profile2.settings
  profile2Settings.includeArtifactRelics = { enabled = true, scope = "BOTH" }
  profile2Settings.excludeEquipmentSets = { enabled = false, scope = "BOTH" }

  local migrated = runStep(fixture, 2)

  assert(Matchers:IsDeepEqual(migrated, expected))
end

-- ============================================================================
-- Tests - Migrations: Step 3
-- ============================================================================

--- The lists whose bindings step 3 combines.
local STEP_3_LIST_NAMES = { "ProfileInclusions", "ProfileExclusions", "GlobalInclusions", "GlobalExclusions" }

--- Returns a version 2 state with the given keybindings.
--- @param keybindings table
--- @return table
local function stateWithKeybindings(keybindings)
  return { version = 2, global = { keybindings = keybindings } }
end

-- Test: keeps the add key when both keys are bound, and drops the remove key.
do
  for _, listName in ipairs(STEP_3_LIST_NAMES) do
    local state = stateWithKeybindings({ ["addTo" .. listName] = "CTRL-1", ["removeFrom" .. listName] = "CTRL-2" })
    local keybindings = runStep(state, 3).global.keybindings
    assert(Matchers:IsDeepEqual(keybindings, { ["addOrRemove" .. listName] = "CTRL-1" }), listName)
  end
end

-- Test: keeps the remove key when only it is bound.
do
  for _, listName in ipairs(STEP_3_LIST_NAMES) do
    local state = stateWithKeybindings({ ["removeFrom" .. listName] = "ALT-X" })
    local keybindings = runStep(state, 3).global.keybindings
    assert(Matchers:IsDeepEqual(keybindings, { ["addOrRemove" .. listName] = "ALT-X" }), listName)
  end
end

-- Test: keeps the add key when only it is bound.
do
  for _, listName in ipairs(STEP_3_LIST_NAMES) do
    local state = stateWithKeybindings({ ["addTo" .. listName] = "F5" })
    local keybindings = runStep(state, 3).global.keybindings
    assert(Matchers:IsDeepEqual(keybindings, { ["addOrRemove" .. listName] = "F5" }), listName)
  end
end

-- Test: leaves the new binding out when neither key is bound, and drops both old bindings.
do
  for _, listName in ipairs(STEP_3_LIST_NAMES) do
    local state = stateWithKeybindings({ ["addTo" .. listName] = "", ["removeFrom" .. listName] = "" })
    local keybindings = runStep(state, 3).global.keybindings
    assert(next(keybindings) == nil, listName)
  end
end

-- Test: a value that is not a string counts as no key.
do
  local state = stateWithKeybindings({ addToGlobalExclusions = true, removeFromGlobalExclusions = "F1" })
  local keybindings = runStep(state, 3).global.keybindings
  assert(Matchers:IsDeepEqual(keybindings, { addOrRemoveGlobalExclusions = "F1" }))
end

-- Test: each list keeps its own key.
do
  local state = stateWithKeybindings({
    addToProfileInclusions = "F1",
    removeFromProfileExclusions = "F2",
    addToGlobalInclusions = "F3",
    removeFromGlobalInclusions = "F4"
  })

  local keybindings = runStep(state, 3).global.keybindings

  assert(Matchers:IsDeepEqual(keybindings, {
    addOrRemoveProfileInclusions = "F1",
    addOrRemoveProfileExclusions = "F2",
    addOrRemoveGlobalInclusions = "F3"
  }))
end

-- Test: other bindings and other global settings are left unchanged.
do
  local state = stateWithKeybindings({ toggleMainWindow = "CTRL-O", startSelling = "", addToProfileInclusions = "F1" })
  state.global.safeSell = true

  local migrated = runStep(state, 3)

  assert(migrated.global.safeSell == true)
  assert(Matchers:IsDeepEqual(migrated.global.keybindings, {
    toggleMainWindow = "CTRL-O",
    startSelling = "",
    addOrRemoveProfileInclusions = "F1"
  }))
end

-- Test: a binding that already has a key is kept over the old keys.
do
  local state = stateWithKeybindings({ addOrRemoveProfileInclusions = "F9", addToProfileInclusions = "F1" })
  local keybindings = runStep(state, 3).global.keybindings
  assert(Matchers:IsDeepEqual(keybindings, { addOrRemoveProfileInclusions = "F9" }))
end

-- Test: keybindings that are already migrated are left unchanged.
do
  local keybindings = {
    toggleMainWindow = "CTRL-O",
    addOrRemoveGlobalInclusions = "F3",
    addOrRemoveProfileExclusions = ""
  }
  local state = stateWithKeybindings(Wux:DeepCopy(keybindings))
  local migrated = runStep(state, 3)
  assert(Matchers:IsDeepEqual(migrated.global.keybindings, keybindings))
end

-- Test: a boolean chat messages setting becomes a table that keeps the saved value, with the verbose detail.
do
  for _, isEnabled in ipairs({ true, false }) do
    local state = { version = 2, global = { chatMessages = isEnabled } }
    local chatMessages = runStep(state, 3).global.chatMessages
    assert(Matchers:IsDeepEqual(chatMessages, { enabled = isEnabled, detail = "VERBOSE" }), tostring(isEnabled))
  end
end

-- Test: chat messages that are already a table are left unchanged.
do
  local state = { version = 2, global = { chatMessages = { enabled = false, detail = "REDUCED" } } }
  local chatMessages = runStep(state, 3).global.chatMessages
  assert(Matchers:IsDeepEqual(chatMessages, { enabled = false, detail = "REDUCED" }))
end

-- Test: chat messages that are not a boolean are left as they are.
do
  local state = { version = 2, global = { chatMessages = "corrupt" } }
  assert(runStep(state, 3).global.chatMessages == "corrupt")
end

-- Test: missing data is tolerated and stays missing.
do
  local cases = {
    noGlobal = { version = 2, profiles = {} },
    globalNotATable = { version = 2, global = "corrupt" },
    noKeybindings = { version = 2, global = { safeSell = true } },
    keybindingsNotATable = { version = 2, global = { keybindings = "corrupt" } },
    emptyKeybindings = { version = 2, global = { keybindings = {} } }
  }

  for name, state in pairs(cases) do
    local expected = Wux:DeepCopy(state)
    expected.version = 3

    local migrated = runStep(state, 3)

    assert(Matchers:IsDeepEqual(migrated, expected), name)
  end
end

-- Test: the version 2 fixture converts the keybindings and the chat messages, and changes nothing else.
do
  local fixture = loadFixture(2)

  -- The expected state is the fixture at version 3, with the keybindings and chat messages below changed to what the
  -- step should produce.
  local expected = Wux:DeepCopy(fixture)
  expected.version = 3
  expected.global.chatMessages = { enabled = true, detail = "VERBOSE" }
  expected.global.keybindings = {
    toggleMainWindow = "CTRL-O",
    toggleJunkFrame = "",
    toggleLootableFrame = "",
    startSelling = "ALT-S",
    destroyNextItem = "",
    -- ProfileInclusions had both keys bound, so the add key is kept.
    addOrRemoveProfileInclusions = "CTRL-1",
    -- ProfileExclusions had only the remove key.
    addOrRemoveProfileExclusions = "ALT-X",
    -- GlobalInclusions had only the add key.
    addOrRemoveGlobalInclusions = "F5"
    -- GlobalExclusions had neither, so it has no binding.
  }

  local migrated = runStep(fixture, 3)

  assert(Matchers:IsDeepEqual(migrated, expected))
end

-- ============================================================================
-- Tests - Migrations: Step 4
-- ============================================================================

--- Returns a version 3 state with the given character map.
--- @param characterMap table
--- @return table
local function stateWithCharacterMap(characterMap)
  return { version = 3, profiles = { characterMap = characterMap } }
end

-- Test: a key with a full name and a realm becomes the full name, keeping its profile.
do
  local state = stateWithCharacterMap({ ["Given Family-RealmName"] = "profile2" })
  local characterMap = runStep(state, 4).profiles.characterMap
  assert(Matchers:IsDeepEqual(characterMap, { ["Given Family"] = "profile2" }))
end

-- Test: a realm with a dash is removed whole.
do
  local state = stateWithCharacterMap({ ["Given Family-Realm-Name"] = "profile2" })
  local characterMap = runStep(state, 4).profiles.characterMap
  assert(Matchers:IsDeepEqual(characterMap, { ["Given Family"] = "profile2" }))
end

-- Test: keys without a space in the name are left unchanged.
do
  local state = stateWithCharacterMap({ ["Name-Realm"] = "profile2", ["Other-Some Realm"] = "profile3" })
  local characterMap = runStep(state, 4).profiles.characterMap
  assert(Matchers:IsDeepEqual(characterMap, { ["Name-Realm"] = "profile2", ["Other-Some Realm"] = "profile3" }))
end

-- Test: a full name that has no realm is left unchanged.
do
  local state = stateWithCharacterMap({ ["Given Family"] = "profile2" })
  local characterMap = runStep(state, 4).profiles.characterMap
  assert(Matchers:IsDeepEqual(characterMap, { ["Given Family"] = "profile2" }))
end

-- Test: keys of one character on different realms become one key, keeping the non-default profile.
do
  local state = stateWithCharacterMap({
    ["Given Family-RealmA"] = DefaultStates.DEFAULT_PROFILE_ID,
    ["Given Family-RealmB"] = "profile2",
    ["Given Family-RealmC"] = DefaultStates.DEFAULT_PROFILE_ID
  })
  local characterMap = runStep(state, 4).profiles.characterMap
  assert(Matchers:IsDeepEqual(characterMap, { ["Given Family"] = "profile2" }))
end

-- Test: between two non-default profiles, the first old key in alphabetical order wins.
do
  local state = stateWithCharacterMap({
    ["Given Family-RealmB"] = "profile3",
    ["Given Family-RealmA"] = "profile2"
  })
  local characterMap = runStep(state, 4).profiles.characterMap
  assert(Matchers:IsDeepEqual(characterMap, { ["Given Family"] = "profile2" }))
end

-- Test: a key with no realm keeps its profile over a key with a realm.
do
  local state = stateWithCharacterMap({
    ["Given Family"] = "profile3",
    ["Given Family-RealmA"] = "profile2"
  })
  local characterMap = runStep(state, 4).profiles.characterMap
  assert(Matchers:IsDeepEqual(characterMap, { ["Given Family"] = "profile3" }))
end

-- Test: each character keeps its own profile.
do
  local state = stateWithCharacterMap({
    ["Given Family-RealmA"] = "profile2",
    ["Other Person-RealmA"] = "profile3",
    ["Name-Realm"] = "profile4"
  })
  local characterMap = runStep(state, 4).profiles.characterMap
  assert(Matchers:IsDeepEqual(characterMap, {
    ["Given Family"] = "profile2",
    ["Other Person"] = "profile3",
    ["Name-Realm"] = "profile4"
  }))
end

-- Test: other state is left unchanged.
do
  local state = stateWithCharacterMap({ ["Given Family-RealmA"] = "profile2" })
  state.global = { safeSell = true }
  state.profiles.activeProfileId = "profile2"
  state.profiles.profileMap = { profile2 = { id = "profile2" } }

  local expected = Wux:DeepCopy(state)
  expected.version = 4
  expected.profiles.characterMap = { ["Given Family"] = "profile2" }

  assert(Matchers:IsDeepEqual(runStep(state, 4), expected))
end

-- Test: missing data is tolerated and stays missing.
do
  local cases = {
    noProfiles = { version = 3, global = {} },
    profilesNotATable = { version = 3, profiles = "corrupt" },
    noCharacterMap = { version = 3, profiles = {} },
    characterMapNotATable = { version = 3, profiles = { characterMap = "corrupt" } },
    emptyCharacterMap = { version = 3, profiles = { characterMap = {} } }
  }

  for name, state in pairs(cases) do
    local expected = Wux:DeepCopy(state)
    expected.version = 4

    local migrated = runStep(state, 4)

    assert(Matchers:IsDeepEqual(migrated, expected), name)
  end
end

-- ============================================================================
-- Tests - Migrations fixtures
-- ============================================================================

-- Test: the version 1 fixture migrates to the current version with the real steps.
do
  local migrated = Migrations:Migrate(loadFixture(1))
  assert(migrated.version == DefaultStates.CURRENT_VERSION)

  local profileMap = migrated.profiles.profileMap

  local defaultSettings = profileMap[DefaultStates.DEFAULT_PROFILE_ID].settings
  assert(Matchers:IsDeepEqual(defaultSettings.includeArtifactRelics, { enabled = false, scope = "BOTH" }))
  assert(Matchers:IsDeepEqual(defaultSettings.excludeEquipmentSets, { enabled = true, scope = "BOTH" }))

  local profile2Settings = profileMap.profile2.settings
  assert(Matchers:IsDeepEqual(profile2Settings.includeArtifactRelics, { enabled = true, scope = "BOTH" }))
  assert(Matchers:IsDeepEqual(profile2Settings.excludeEquipmentSets, { enabled = false, scope = "BOTH" }))
end

-- Test: the version 2 fixture migrates to the current version with the real steps.
do
  local migrated = Migrations:Migrate(loadFixture(2))
  assert(migrated.version == DefaultStates.CURRENT_VERSION)

  local keybindings = migrated.global.keybindings
  assert(keybindings.addOrRemoveProfileInclusions == "CTRL-1")
  assert(keybindings.addOrRemoveProfileExclusions == "ALT-X")
  assert(keybindings.addOrRemoveGlobalInclusions == "F5")
  assert(keybindings.addOrRemoveGlobalExclusions == nil)
  assert(keybindings.addToProfileInclusions == nil)
  assert(keybindings.removeFromProfileInclusions == nil)

  assert(Matchers:IsDeepEqual(migrated.global.chatMessages, { enabled = true, detail = "VERBOSE" }))
end

print("All assertions passed.")
