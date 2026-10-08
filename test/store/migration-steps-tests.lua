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

-- Test: a boolean `includeArtifactRelics` becomes a table that keeps the saved value, with a scope of both.
do
  for _, enabled in ipairs({ true, false }) do
    local state = {
      version = 1,
      profiles = { profileMap = { p1 = { settings = { includeArtifactRelics = enabled } } } }
    }

    local migrated = runStep(state, 2)

    assert(Matchers:IsDeepEqual(migrated.profiles.profileMap.p1.settings.includeArtifactRelics, {
      enabled = enabled,
      scope = "BOTH"
    }), tostring(enabled))
  end
end

-- Test: every profile is migrated, not only the active one.
do
  local state = {
    version = 1,
    profiles = {
      activeProfileId = "p1",
      profileMap = {
        p1 = { settings = { includeArtifactRelics = true } },
        p2 = { settings = { includeArtifactRelics = false } }
      }
    }
  }

  local migrated = runStep(state, 2)

  local profileMap = migrated.profiles.profileMap
  assert(Matchers:IsDeepEqual(profileMap.p1.settings.includeArtifactRelics, { enabled = true, scope = "BOTH" }))
  assert(Matchers:IsDeepEqual(profileMap.p2.settings.includeArtifactRelics, { enabled = false, scope = "BOTH" }))
end

-- Test: an already migrated `includeArtifactRelics` is left unchanged.
do
  local relics = { enabled = true, scope = "SELL" }
  local state = { version = 1, profiles = { profileMap = { p1 = { settings = { includeArtifactRelics = relics } } } } }

  local migrated = runStep(state, 2)

  assert(Matchers:IsDeepEqual(migrated.profiles.profileMap.p1.settings.includeArtifactRelics, relics))
end

-- Test: other settings are left unchanged.
do
  local settings = { autoSell = true, includeArtifactRelics = true, excludeEquipmentSets = false }
  local state = { version = 1, profiles = { profileMap = { p1 = { id = "p1", name = "One", settings = settings } } } }

  local migrated = runStep(state, 2)

  local profile = migrated.profiles.profileMap.p1
  assert(profile.id == "p1")
  assert(profile.name == "One")
  assert(profile.settings.autoSell == true)
  assert(profile.settings.excludeEquipmentSets == false)
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
    noRelics = { version = 1, profiles = { profileMap = { p1 = { settings = { autoSell = true } } } } },
  }

  for name, state in pairs(cases) do
    local expected = Wux:DeepCopy(state)
    expected.version = 2

    local migrated = runStep(state, 2)

    assert(Matchers:IsDeepEqual(migrated, expected), name)
  end
end

-- Test: the version 1 fixture converts `includeArtifactRelics` in each profile and changes nothing else.
do
  local fixture = loadFixture(1)
  local expected = Wux:DeepCopy(fixture)
  expected.version = 2
  expected.profiles.profileMap[DefaultStates.DEFAULT_PROFILE_ID].settings.includeArtifactRelics = {
    enabled = false,
    scope = "BOTH"
  }
  expected.profiles.profileMap.profile2.settings.includeArtifactRelics = { enabled = true, scope = "BOTH" }

  local migrated = runStep(fixture, 2)

  assert(Matchers:IsDeepEqual(migrated, expected))
end

-- ============================================================================
-- Tests - Migrations fixtures
-- ============================================================================

-- Test: the version 1 fixture migrates to the current version with the real steps.
do
  local migrated = Migrations:Migrate(loadFixture(1))

  assert(migrated.version == DefaultStates.CURRENT_VERSION)
  local profileMap = migrated.profiles.profileMap
  assert(Matchers:IsDeepEqual(profileMap[DefaultStates.DEFAULT_PROFILE_ID].settings.includeArtifactRelics, {
    enabled = false,
    scope = "BOTH"
  }))
  assert(Matchers:IsDeepEqual(profileMap.profile2.settings.includeArtifactRelics, { enabled = true, scope = "BOTH" }))
end

print("All assertions passed.")
