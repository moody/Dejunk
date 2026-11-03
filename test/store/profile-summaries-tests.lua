--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `ProfileSummaries` from a new context, so no test sees what another cached.
--- @return ProfileSummaries ProfileSummaries
local function setupContext()
  local Context = Harness:NewContext()
  Context:Load("src/store/profile-summaries.lua")
  return Context:GetModule("ProfileSummaries")
end

-- ============================================================================
-- Tests - ProfileSummaries:Get()
-- ============================================================================

-- Test: lists the characters assigned to the profile, sorted, and no others.
do
  local ProfileSummaries = setupContext()
  local profile = { id = "profileA", settings = { inclusions = {}, exclusions = {} } }
  local characterMap = {
    ["Zed-Realm"] = "profileA",
    ["Amy-Realm"] = "profileA",
    ["Bob-Realm"] = "profileB"
  }

  local summary = ProfileSummaries:Get(profile, characterMap)

  assert(Matchers:IsDeepEqual(summary.characterKeys, { "Amy-Realm", "Zed-Realm" }))
end

-- Test: lists no characters when none are assigned to the profile.
do
  local ProfileSummaries = setupContext()
  local profile = { id = "profileA", settings = { inclusions = {}, exclusions = {} } }

  local summary = ProfileSummaries:Get(profile, { ["Bob-Realm"] = "profileB" })

  assert(#summary.characterKeys == 0)
end

-- Test: gives each profile its own characters from the same character map.
do
  local ProfileSummaries = setupContext()
  local profileA = { id = "profileA", settings = { inclusions = {}, exclusions = {} } }
  local profileB = { id = "profileB", settings = { inclusions = {}, exclusions = {} } }
  local characterMap = { ["Amy-Realm"] = "profileA", ["Bob-Realm"] = "profileB" }

  local summaryA = ProfileSummaries:Get(profileA, characterMap)
  local summaryB = ProfileSummaries:Get(profileB, characterMap)

  assert(Matchers:IsDeepEqual(summaryA.characterKeys, { "Amy-Realm" }))
  assert(Matchers:IsDeepEqual(summaryB.characterKeys, { "Bob-Realm" }))
end

-- Test: counts the items on the inclusions and exclusions lists.
do
  local ProfileSummaries = setupContext()
  local profile = {
    id = "profileA",
    settings = { inclusions = { ["1"] = true, ["2"] = true }, exclusions = { ["3"] = true } }
  }

  local summary = ProfileSummaries:Get(profile, {})

  assert(summary.numInclusions == 2)
  assert(summary.numExclusions == 1)
end

-- Test: reports whether Auto Sell is on.
for _, isOn in ipairs({ true, false }) do
  local ProfileSummaries = setupContext()
  local profile = { id = "profileA", settings = { autoSell = isOn, inclusions = {}, exclusions = {} } }

  local summary = ProfileSummaries:Get(profile, {})

  assert(summary.autoSell == isOn)
end

-- Test: returns the same summary while the profile and the character map are the same tables.
do
  local ProfileSummaries = setupContext()
  local profile = { id = "profileA", settings = { inclusions = {}, exclusions = {} } }
  local characterMap = {}

  local first = ProfileSummaries:Get(profile, characterMap)
  local second = ProfileSummaries:Get(profile, characterMap)

  assert(first == second)
end

-- Test: summarizes again when the profile is a new table.
do
  local ProfileSummaries = setupContext()
  local characterMap = {}
  local oldProfile = { id = "profileA", settings = { inclusions = { ["1"] = true }, exclusions = {} } }
  local newProfile = { id = "profileA", settings = { inclusions = { ["1"] = true, ["2"] = true }, exclusions = {} } }

  ProfileSummaries:Get(oldProfile, characterMap)
  local summary = ProfileSummaries:Get(newProfile, characterMap)

  assert(summary.numInclusions == 2)
end

-- Test: summarizes again when the character map is a new table.
do
  local ProfileSummaries = setupContext()
  local profile = { id = "profileA", settings = { inclusions = {}, exclusions = {} } }

  ProfileSummaries:Get(profile, { ["Amy-Realm"] = "profileA" })
  local summary = ProfileSummaries:Get(profile, { ["Amy-Realm"] = "profileA", ["Zed-Realm"] = "profileA" })

  assert(Matchers:IsDeepEqual(summary.characterKeys, { "Amy-Realm", "Zed-Realm" }))
end
