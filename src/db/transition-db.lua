local _, Addon = ...
local Chat = Addon.Chat
local DB = Addon.DB
local L = Addon.Libs.L

-- ============================================================================
-- Helpers
-- ============================================================================

local function mergeLists(old, new)
  -- `sell.inclusions`
  local sellInclusions = old.sell and old.sell.inclusions or old.Inclusions
  if type(sellInclusions) == "table" then
    for k in pairs(sellInclusions) do
      new.sell.inclusions[k] = true
    end
  end

  -- `sell.exclusions`
  local sellExclusions = old.sell and old.sell.exclusions or old.Exclusions
  if type(sellExclusions) == "table" then
    for k in pairs(sellExclusions) do
      new.sell.exclusions[k] = true
    end
  end

  -- `destroy.inclusions`
  local destroyInclusions =
    old.destroy and old.destroy.inclusions or old.Destroyables
  if type(destroyInclusions) == "table" then
    for k in pairs(destroyInclusions) do
      new.destroy.inclusions[k] = true
    end
  end

  -- `destroy.exclusions`
  local destroyExclusions =
    old.destroy and old.destroy.exclusions or old.Undestroyables
  if type(destroyExclusions) == "table" then
    for k in pairs(destroyExclusions) do
      new.destroy.exclusions[k] = true
    end
  end
end

-- ============================================================================
-- TransitionDB
-- ============================================================================

function Addon:TransitionDB()
  if type(_G.DEJUNK_ADDON_SV) ~= "table" then return end
  local profileKeys = _G.DEJUNK_ADDON_SV.ProfileKeys
  local profiles = _G.DEJUNK_ADDON_SV.Profiles

  -- ProfileKeys
  if type(profileKeys) == "table" then
    DB._svar.ProfileKeys = profileKeys

    -- Set profile of player correctly
    local oldKey = profileKeys[DB:GetPlayerKey()]
    if type(oldKey) == "string" then
      DB:SetProfile(oldKey)
    end
  end

  -- Profiles
  if type(profiles) == "table" then
    for key, oldProfile in pairs(profiles) do
      if DB:ProfileExists(key) or DB:CreateProfile(key) then
        mergeLists(oldProfile, DB._svar.Profiles[key])
      end
    end
  end

  Chat:Force(L.TRANSITIONED_DATABASE_MESSAGE)

  -- Delete
  _G.DEJUNK_ADDON_SV = nil
end
