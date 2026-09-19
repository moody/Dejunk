--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
Harness:Load("src/store/legacy-migration.lua")

local Addon = Harness.Addon
local LegacyMigration = Addon:GetModule("LegacyMigration")
local Wux = Addon.Wux

-- ============================================================================
-- Setup
-- ============================================================================

local CHARACTER_KEY = "Char-Realm"
local NEW_PROFILE_ID = "abc123"

local NEW_KEY = "TEST_NEW_SAVED_VARIABLES"
local LEGACY_GLOBAL_KEY = "TEST_LEGACY_GLOBAL"
local LEGACY_PERCHAR_KEY = "TEST_LEGACY_PERCHAR"
local LEGACY_MAPPING = { global = LEGACY_GLOBAL_KEY, perchar = LEGACY_PERCHAR_KEY }

--- Clears all three SavedVariables globals, so a test sets only the ones it needs.
local function reset()
  _G[NEW_KEY] = nil
  _G[LEGACY_GLOBAL_KEY] = nil
  _G[LEGACY_PERCHAR_KEY] = nil
end

-- ============================================================================
-- Tests - LegacyMigration:MigrateLegacyLists()
-- ============================================================================

-- Test: existing new SavedVariables prevent global migration, even when
-- legacy global data remains.
do
  reset()
  _G[NEW_KEY] = { global = { inclusions = { ["untouched"] = true } } }
  _G[LEGACY_GLOBAL_KEY] = { inclusions = { ["1"] = true } }

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(Matchers:IsDeepEqual(state.global.inclusions, { ["untouched"] = true }))
end

-- Test: missing new SavedVariables trigger global migration, which carries
-- over only `inclusions` and `exclusions`.
do
  reset()
  local inclusions = { ["1"] = true, ["2"] = true }
  local exclusions = { ["3"] = true }
  _G[LEGACY_GLOBAL_KEY] = {
    chatMessages = false, -- Not a list, so it must not be migrated.
    inclusions = inclusions,
    exclusions = exclusions,
  }

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(Matchers:IsDeepEqual(state.global.inclusions, inclusions))
  assert(Matchers:IsDeepEqual(state.global.exclusions, exclusions))
  assert(state.global.chatMessages == nil, "non-list fields must never be migrated")
end

-- Test: a fresh install (no new or legacy SavedVariables) returns an empty state.
do
  reset()

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(next(state) == nil)
end

-- Test: existing state with no legacy data is returned unchanged.
do
  reset()
  _G[NEW_KEY] = {
    global = { inclusions = { ["1"] = true } },
    profiles = {
      characterMap = { ["Other-Realm"] = "existing123" },
      profileMap = { ["existing123"] = { id = "existing123", name = "Other", settings = { inclusions = {}, exclusions = {} } } },
    },
  }

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(Matchers:IsDeepEqual(state.global.inclusions, { ["1"] = true }))
  assert(state.profiles.characterMap["Other-Realm"] == "existing123")
  assert(state.profiles.profileMap["existing123"].name == "Other")
  assert(state.profiles.characterMap[CHARACTER_KEY] == nil)
  assert(state.profiles.profileMap[NEW_PROFILE_ID] == nil)
end

-- Test: legacy perchar data with empty lists does not create a profile.
do
  reset()
  _G[LEGACY_PERCHAR_KEY] = { characterSpecificSettings = true, autoSell = true, inclusions = {}, exclusions = {} }

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(state.profiles == nil)
end

-- Test: one non-empty list is enough to create a profile.
do
  reset()
  _G[LEGACY_PERCHAR_KEY] = { exclusions = { ["99"] = true } }

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  local profile = state.profiles.profileMap[NEW_PROFILE_ID]
  assert(profile ~= nil)
  assert(Matchers:IsDeepEqual(profile.settings.exclusions, { ["99"] = true }))
  assert(profile.settings.inclusions == nil or next(profile.settings.inclusions) == nil)
end

-- Test: non-empty perchar lists create a profile named for the character
-- key, holding only `inclusions` and `exclusions`.
do
  reset()
  _G[LEGACY_PERCHAR_KEY] = {
    characterSpecificSettings = true,
    autoSell = true, -- Not a list, so it must not be migrated.
    inclusions = { ["10"] = true },
    exclusions = { ["20"] = true },
  }

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(state.profiles.characterMap[CHARACTER_KEY] == NEW_PROFILE_ID)
  local profile = state.profiles.profileMap[NEW_PROFILE_ID]
  assert(profile.id == NEW_PROFILE_ID)
  assert(profile.name == CHARACTER_KEY)
  assert(Matchers:IsDeepEqual(profile.settings.inclusions, { ["10"] = true }))
  assert(Matchers:IsDeepEqual(profile.settings.exclusions, { ["20"] = true }))
  assert(profile.settings.autoSell == nil, "only inclusions/exclusions should be set on settings")
end

-- Test: migrating a character keeps profiles that already exist.
do
  reset()
  _G[NEW_KEY] = {
    profiles = {
      characterMap = { ["Other-Realm"] = "existing123" },
      profileMap = { ["existing123"] = { id = "existing123", name = "Other", settings = { inclusions = {}, exclusions = {} } } },
    }
  }
  _G[LEGACY_PERCHAR_KEY] = { inclusions = { ["10"] = true } }

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(state.profiles.characterMap["Other-Realm"] == "existing123")
  assert(state.profiles.profileMap["existing123"].name == "Other")
  assert(state.profiles.characterMap[CHARACTER_KEY] == NEW_PROFILE_ID)
  assert(Matchers:IsDeepEqual(state.profiles.profileMap[NEW_PROFILE_ID].settings.inclusions, { ["10"] = true }))
end

-- Test: migration wipes the legacy SavedVariables, including ones with
-- nothing to migrate.
do
  reset()
  _G[LEGACY_GLOBAL_KEY] = { inclusions = { ["1"] = true } }
  _G[LEGACY_PERCHAR_KEY] = { characterSpecificSettings = true, inclusions = {}, exclusions = {} }

  LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(_G[LEGACY_GLOBAL_KEY] == nil)
  assert(_G[LEGACY_PERCHAR_KEY] == nil)
end

-- Test: a 2.1.1 fixture migrates its lists into `global` and a new
-- profile, carrying over nothing else.
do
  reset()
  local fixtureGlobal = Harness:ReadSavedVariablesFile("test/fixtures/2.1.1/global.lua")
  local fixturePerchar = Harness:ReadSavedVariablesFile("test/fixtures/2.1.1/perchar.lua")
  _G[LEGACY_GLOBAL_KEY] = fixtureGlobal
  _G[LEGACY_PERCHAR_KEY] = fixturePerchar
  assert(next(fixtureGlobal.inclusions) and next(fixturePerchar.inclusions), "fixture lists must not be empty")

  -- Copied first: the migration returns the fixture's own list tables.
  local globalInclusions = Wux:ShallowCopy(fixtureGlobal.inclusions)
  local globalExclusions = Wux:ShallowCopy(fixtureGlobal.exclusions)
  local percharInclusions = Wux:ShallowCopy(fixturePerchar.inclusions)
  local percharExclusions = Wux:ShallowCopy(fixturePerchar.exclusions)

  local state = LegacyMigration:MigrateLegacyLists(NEW_KEY, LEGACY_MAPPING, CHARACTER_KEY, NEW_PROFILE_ID)

  assert(Matchers:HasNoKeysOtherThan(state.global, { "inclusions", "exclusions" }))
  assert(Matchers:IsDeepEqual(state.global.inclusions, globalInclusions))
  assert(Matchers:IsDeepEqual(state.global.exclusions, globalExclusions))

  local profile = state.profiles.profileMap[NEW_PROFILE_ID]
  assert(state.profiles.characterMap[CHARACTER_KEY] == NEW_PROFILE_ID)
  assert(Matchers:HasNoKeysOtherThan(profile.settings, { "inclusions", "exclusions" }))
  assert(Matchers:IsDeepEqual(profile.settings.inclusions, percharInclusions))
  assert(Matchers:IsDeepEqual(profile.settings.exclusions, percharExclusions))
end

print("All assertions passed.")
