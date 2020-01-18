local _, Addon = ...
local DDBL = Addon.DethsDBLib
if DDBL.__loaded then return end

local consts = DDBL.consts
local mixins  = DDBL.mixins
local utils = DDBL.utils

-- ============================================================================
-- Getters & Setters
-- ============================================================================

-- Returns the value of the specified key in the global SVs.
-- @param {string} k - the key, can be a nested value (e.g. "A.B.C")
function mixins:GetGlobal(k)
  local v = utils.get(self.Global, k)
  return v
end

-- Sets the specified key in the global SVs to the specified value.
-- @param {string} k - the key, can be a nested value (e.g. "A.B.C")
-- @param {any} v - the new value
function mixins:SetGlobal(k, v)
  utils.set(self.Global, k, v)
end

-- Returns the value of the specified key in the current profile SVs.
-- @param {string} k - the key, can be a nested value (e.g. "A.B.C")
function mixins:Get(k)
  local v = utils.get(self.Profile, k)
  return v
end

-- Sets the specified key in the current profile SVs to the specified value.
-- @param {string} k - the key, can be a nested value (e.g. "A.B.C")
-- @param {any} v - the new value
function mixins:Set(k, v)
  utils.set(self.Profile, k, v)
end

-- ============================================================================
-- General Functions
-- ============================================================================

-- Creates a new profile with the specified key.
-- @param {string} key - the key for the profile to be created
-- @param {table | nil} toImport - table of existing profile settings to import
-- @return {boolean} - true if the profile is successfully created
function mixins:CreateProfile(key, toImport)
  if not key or self._svar.Profiles[key] then return false end

  if (type(toImport) == "table") then
    toImport = utils.copy(toImport, true)
    utils.populate(toImport, self._defaults.Profile)
    self._svar.Profiles[key] = toImport
  else
    self._svar.Profiles[key] = utils.copy(self._defaults.Profile, true)
  end

  return true
end

-- Copies a profile by key, overwriting the current profile's settings.
-- @param {string} key - the key of the profile to copy
-- @return {boolean} - true if the profile is successfully copied
function mixins:CopyProfile(key)
  if not key or (key == self._profile_key) then return false end

  local profile = self._svar.Profiles[key]
  if profile then
    -- Deep copy profile
    local copy = utils.copy(profile, true)
    -- Set profile key to reference new table
    self._svar.Profiles[self._profile_key] = copy
    -- Set current profile
    self.Profile = copy
    return true
  end

  return false
end

-- Deletes a profile by key.
-- @param {string} key - the key of the profile to delete
-- @return {boolean} - true if the profile is successfully deleted
function mixins:DeleteProfile(key)
  if not key or (key == self._profile_key) then return false end
  self._svar.Profiles[key] = nil
  return true
end

-- Sets the current profile by key, creating it if necessary. Reverts to the
-- player profile if the key is not specified.
-- @param {string} key - the key of the profile to be set [optional]
-- @return {boolean} - true if the profile is successfully changed
function mixins:SetProfile(key)
  if not key then key = consts.PLAYER_KEY end
  if (key == self._profile_key) then return false end

  -- Set profile
  self:CreateProfile(key) -- Does nothing if profile already exists
  self.Profile = self._svar.Profiles[key]
  self._profile_key = key

  -- Set current profile key in svar.ProfileKeys
  self._svar.ProfileKeys[consts.PLAYER_KEY] = (key ~= consts.PLAYER_KEY) and key or nil
  return true
end

-- Returns the key of the player profile.
function mixins:GetPlayerKey()
  return consts.PLAYER_KEY
end

-- Returns the key of the current profile.
function mixins:GetProfileKey()
  return self._profile_key
end

-- Returns a sorted table of profile keys.
function mixins:GetProfileKeys()
  local t = {}
  for k in pairs(self._svar.Profiles) do t[#t+1] = k end
  table.sort(t)
  return t
end

-- Returns true if a profile with the specified key exists.
-- @param {string} key - the key of the profile to check for
function mixins:ProfileExists(key)
  return type(self._svar.Profiles[key]) == "table"
end
