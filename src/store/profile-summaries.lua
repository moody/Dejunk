local Addon = select(2, ...) ---@type Addon

--- @class ProfileSummaries
local ProfileSummaries = Addon:GetModule("ProfileSummaries")

--- Facts about a profile. Treat it as read-only.
--- @class ProfileSummary
--- @field characterKeys string[] Keys of the characters assigned to the profile, sorted.
--- @field autoSell boolean `true` if the profile's `Auto Sell` option is on.
--- @field numInclusions integer Number of items on the profile's inclusions list.
--- @field numExclusions integer Number of items on the profile's exclusions list.

--- The character keys of a profile with no characters.
--- @type string[]
local NO_CHARACTER_KEYS = {}

-- ============================================================================
-- State
-- ============================================================================

-- State tables are replaced when they change, never edited in place, so the caches below key on the table itself.

--- The summary of each profile table, with the character map it was built for.
--- @type table<ProfileState, { characterMap: table, summary: ProfileSummary }>
local summaries = setmetatable({}, { __mode = "k" })

--- The number of entries of each table that `countEntries()` has counted.
--- @type table<table, integer>
local entryCounts = setmetatable({}, { __mode = "k" })

--- The character map that `characterKeysByProfileId` was built from.
--- @type table?
local groupedCharacterMap

--- The sorted character keys of each profile ID, for `groupedCharacterMap`.
--- @type table<string, string[]>
local characterKeysByProfileId = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns the number of entries in the table.
--- @param t table
--- @return integer
local function countEntries(t)
  local count = entryCounts[t]

  if not count then
    count = 0
    for _ in pairs(t) do count = count + 1 end
    entryCounts[t] = count
  end

  return count
end

--- Returns the sorted keys of the characters assigned to the profile.
--- @param characterMap table<string, string> Maps character keys to profile IDs.
--- @param profileId string
--- @return string[]
local function getCharacterKeys(characterMap, profileId)
  -- Group every character by profile, once per character map.
  if characterMap ~= groupedCharacterMap then
    groupedCharacterMap = characterMap
    characterKeysByProfileId = {}

    for characterKey, characterProfileId in pairs(characterMap) do
      local characterKeys = characterKeysByProfileId[characterProfileId]
      if not characterKeys then
        characterKeys = {}
        characterKeysByProfileId[characterProfileId] = characterKeys
      end

      characterKeys[#characterKeys + 1] = characterKey
    end

    for _, characterKeys in pairs(characterKeysByProfileId) do table.sort(characterKeys) end
  end

  return characterKeysByProfileId[profileId] or NO_CHARACTER_KEYS
end

-- ============================================================================
-- ProfileSummaries
-- ============================================================================

--- Returns facts about the profile. The same summary is returned until the profile or the character map is a
--- different table.
--- @param profile ProfileState
--- @param characterMap table<string, string> Maps character keys to profile IDs.
--- @return ProfileSummary
function ProfileSummaries:Get(profile, characterMap)
  local cached = summaries[profile]

  if not cached or cached.characterMap ~= characterMap then
    local settings = profile.settings

    cached = {
      characterMap = characterMap,
      summary = {
        characterKeys = getCharacterKeys(characterMap, profile.id),
        autoSell = settings.autoSell,
        numInclusions = countEntries(settings.inclusions),
        numExclusions = countEntries(settings.exclusions)
      }
    }

    summaries[profile] = cached
  end

  return cached.summary
end
