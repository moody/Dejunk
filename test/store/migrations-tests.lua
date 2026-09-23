--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
Harness:Load("src/store/default-states.lua")
Harness:Load("src/store/migrations.lua")

local Addon = Harness.Addon
local DefaultStates = Addon:GetModule("DefaultStates")
local Migrations = Addon:GetModule("Migrations")

-- ============================================================================
-- Setup
-- ============================================================================

-- Tests pass mock steps and a mock current version of 3, so they do not depend on the real ones.

--- Returns mock steps for versions 2 and 3 that change nothing, and a list they add their version to when they run.
local function createMockSteps()
  local ran = {}
  local steps = {
    [2] = function(state)
      table.insert(ran, 2)
      return state
    end,
    [3] = function(state)
      table.insert(ran, 3)
      return state
    end,
  }
  return steps, ran
end

-- ============================================================================
-- Tests - Migrations:Migrate()
-- ============================================================================

-- Test: the real current version is used when none is given.
do
  local state = Migrations:Migrate({})
  assert(state.version == DefaultStates.CURRENT_VERSION)
end

-- Test: an empty state is stamped with the current version and runs no step.
do
  local steps, ran = createMockSteps()

  local state = Migrations:Migrate({}, steps, 3)

  assert(Matchers:IsDeepEqual(state, { version = 3 }))
  assert(#ran == 0)
end

-- Test: a state with no version is treated as version 1, and runs every step in ascending order.
do
  local steps, ran = createMockSteps()

  local state = Migrations:Migrate({ global = {} }, steps, 3)

  assert(Matchers:IsDeepEqual(ran, { 2, 3 }))
  assert(Matchers:IsDeepEqual(state, { version = 3, global = {} }))
end

-- Test: an invalid version (not a number, or below 1) is treated as no version.
do
  for _, version in ipairs({ "two", 0, -1 }) do
    local steps, ran = createMockSteps()

    Migrations:Migrate({ version = version, global = {} }, steps, 3)

    assert(Matchers:IsDeepEqual(ran, { 2, 3 }), tostring(version))
  end
end

-- Test: only the steps above the saved version run.
do
  local steps, ran = createMockSteps()

  local state = Migrations:Migrate({ version = 2, global = {} }, steps, 3)

  assert(Matchers:IsDeepEqual(ran, { 3 }))
  assert(state.version == 3)
end

-- Test: each step receives the state returned by the previous step.
do
  local steps = {
    [2] = function(state)
      return { version = state.version, global = { value = "from step 2" } }
    end,
    [3] = function(state)
      state.global.seen = state.global.value
      return state
    end,
  }

  local state = Migrations:Migrate({ version = 1, global = {} }, steps, 3)

  assert(Matchers:IsDeepEqual(state, { version = 3, global = { value = "from step 2", seen = "from step 2" } }))
end

-- Test: a state at the current version is returned unchanged.
do
  local steps, ran = createMockSteps()

  local state = Migrations:Migrate({ version = 3, global = {} }, steps, 3)

  assert(Matchers:IsDeepEqual(state, { version = 3, global = {} }))
  assert(#ran == 0)
end

-- Test: a newer version is returned unchanged, keeping its version.
do
  local steps, ran = createMockSteps()

  local state = Migrations:Migrate({ version = 5, global = {} }, steps, 3)

  assert(Matchers:IsDeepEqual(state, { version = 5, global = {} }))
  assert(#ran == 0)
end

-- Test: the input state is not mutated.
do
  local input = { version = 1, global = { value = 1 } }
  local steps = {
    [2] = function(state)
      state.global.value = 2
      return state
    end,
  }

  local state = Migrations:Migrate(input, steps, 2)

  assert(state.global.value == 2)
  assert(Matchers:IsDeepEqual(input, { version = 1, global = { value = 1 } }))
end

-- Test: a step that throws raises its error and leaves the input unchanged.
do
  local input = { version = 1, global = { value = 1 } }
  local steps = {
    [2] = function(state)
      state.global.value = 2
      error("step failed")
    end,
  }

  local ok, message = pcall(Migrations.Migrate, Migrations, input, steps, 2)

  assert(not ok)
  assert(message:find("step failed", 1, true))
  assert(Matchers:IsDeepEqual(input, { version = 1, global = { value = 1 } }))
end

-- Test: a version with no step raises an error.
do
  local steps = createMockSteps()
  steps[3] = nil

  local ok, message = pcall(Migrations.Migrate, Migrations, { version = 1, global = {} }, steps, 3)

  assert(not ok)
  assert(message:find("version 3", 1, true))
end

-- Test: migrating a migrated state changes nothing.
do
  local steps, ran = createMockSteps()
  local migrated = Migrations:Migrate({ global = {} }, steps, 3)

  local again = Migrations:Migrate(migrated, steps, 3)

  assert(Matchers:IsDeepEqual(again, migrated))
  assert(#ran == 2)
end

print("All assertions passed.")
