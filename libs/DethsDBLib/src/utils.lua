local _, Addon = ...
local DDBL = Addon.DethsDBLib
if DDBL.__loaded then return end

local consts = DDBL.consts
local utils  = DDBL.utils
local mixins = DDBL.mixins

-- =============================================================================
-- Table utils
-- =============================================================================

-- Returns a copy of the specified table.
-- @param {table} t - the table to copy
-- @param {boolean} deep - if true, the table will be copied recursively
-- @return {table} the copy of table t
function utils.copy(t, deep)
  if (t == nil) then return nil end
  local copy = {}

  -- Copy
  for k, v in pairs(t) do
    copy[k] = (deep and (type(v) == "table")) and utils.copy(v, deep) or v
  end

  -- Copy metatable
  setmetatable(copy, utils.copy(getmetatable(t), deep))

  -- Return
  return copy
end

do -- utils.get()
  local keys = {
    -- [1] = a nested table
    -- ...
    -- [n] = key in nested table
  }

  -- Returns the value, table, and key for a specified key in a specified table.
  -- @param {table} t - the table
  -- @param {string} k - the key, can be a nested value (e.g. "A.B.C")
  -- @return {any} - the value
  -- @return {table} - the table the key resides in
  -- @return {string} - the key
  function utils.get(t, k)
    if k:find(".", 1, true) then
      for key in pairs(keys) do keys[key] = nil end

      -- Split keys by dot operator (e.g. "A.B.C" = {"A", "B", "C"})
      for key in k:gmatch("([^.]+)") do keys[#keys+1] = key end

      -- If key is nested, update ref to nested table and key
      if (#keys > 1) then
        for i=1, (#keys - 1) do t = t[keys[i]] end
        k = keys[#keys]
      end
    end

    return t[k], t, k
  end
end

-- Sets a key in a table to a given value.
-- @param {table} t - the table
-- @param {string} k - the key, can be a nested value (e.g. "A.B.C")
-- @param {any} v - the new value
function utils.set(t, k, v)
  local _, nt, nk = utils.get(t, k)
  nt[nk] = v
end

-- =============================================================================
-- Population functions
-- =============================================================================

-- Populates a table with missing default key-value pairs.
-- @param {table} t - the table to populate
-- @param {table} defaults - the table with default values
-- @return {table} t
function utils.populate(t, defaults)
  for k, v in pairs(defaults) do
    if (type(v) == "table") then
      if (type(t[k]) == "table") then
        utils.populate(t[k], v) -- recursively populate
      else
        t[k] = utils.copy(v, true) -- deep copy
      end
    elseif (t[k] == nil) then
      t[k] = v -- add default value
    end
  end

  return t
end

-- Depopulates a table by removing default key-value pairs.
-- @param {table} t - the table to remove from
-- @param {table} defaults - the table with default values
-- @return {table} t
function utils.depopulate(t, defaults)
  for k, v in pairs(t) do
    if (type(v) == "table") and (type(defaults[k]) == "table") then
       -- Recursively depopulate
      utils.depopulate(v, defaults[k])
      -- If table is now empty, remove it
      if (next(v) == nil) then t[k] = nil end
    elseif (defaults[k] == v) then
      t[k] = nil -- remove default value
    end
  end

  return t
end

-- =============================================================================
-- Initialization functions
-- =============================================================================

-- Initializes and returns a database object populated with default values.
-- @param {string} svarKey - X-DethsDBLib .toc key
-- @param {table} defaults - default key-value pairs for the database
function utils.initialize(svarKey, defaults)
  -- Get SavedVariables table, create it if necessary
  local svar = _G[svarKey]
  if (type(svar) ~= "table") then
    local t = {}
    _G[svarKey] = t
    svar = t
  end

  -- Create profile keys table if it doesn't exist
  if (type(svar.ProfileKeys) ~= "table") then svar.ProfileKeys = {} end

  -- Create or populate the Global table
  if (type(svar.Global) ~= "table") then
    svar.Global = utils.copy(defaults.Global, true)
  else -- Populate
    utils.populate(svar.Global, defaults.Global)
  end

  -- Create profiles table if it doesn't exist
  if (type(svar.Profiles) ~= "table") then
    svar.Profiles = {}
  else -- Populate each profile
    for _, profile in pairs(svar.Profiles) do
      utils.populate(profile, defaults.Profile)
    end
  end

  -- Initialize current profile and key
  local profileKey = svar.ProfileKeys[consts.PLAYER_KEY] or consts.PLAYER_KEY
  local profile = svar.Profiles[profileKey]

  if not profile then -- Revert to player profile
    profileKey = consts.PLAYER_KEY
    svar.ProfileKeys[profileKey] = nil

    if svar.Profiles[profileKey] then
      profile = svar.Profiles[profileKey]
    else -- Create new profile for player
      profile = utils.copy(defaults.Profile, true)
      svar.Profiles[profileKey] = profile
    end
  end

  -- Create DB table
  local db = {
    Global = svar.Global,
    Profile = profile,
    _profile_key = profileKey,
    _svar = svar,
    _defaults = defaults
  }

  -- Add mixins
  for k, v in pairs(mixins) do db[k] = v end

  -- Upgrade database
  utils.upgrade(db)

  return db
end

-- Deinitializes the specified database by removing all default key-value pairs.
-- @param {table} db - the database to deinitialize
function utils.deinitialize(db)
  local svar, defaults = db._svar, db._defaults

  -- Wipe defaults from global
  utils.depopulate(svar.Global, defaults.Global)

  -- Remove Global if empty
  if not next(svar.Global) then svar.Global = nil end

  -- Wipe defaults from profiles
  for k, profile in pairs(svar.Profiles) do
    utils.depopulate(profile, defaults.Profile)
    -- Remove player profile if empty
    if (k == consts.PLAYER_KEY) and not next(profile) then
      svar.Profiles[k] = nil
    end
  end

  -- Remove Profiles if empty
  if not next(svar.Profiles) then svar.Profiles = nil end

  -- Remove ProfileKeys if empty
  if not next(svar.ProfileKeys) then svar.ProfileKeys = nil end
end

-- Upgrades the specified database to the current version of DDBL.
-- @param {table} db - the database to upgrade
function utils.upgrade(db)
  local svar = db._svar
  if (svar.DDBL_Version == DDBL.metadata.version) then return end

  -- Legacy upgrade (1.0 -> 1.1)
  local version = tonumber(svar.DDBL_Version or "")
  if version and (version <= 1.0) then
    -- Move _current_profile_key profile entries to svar.ProfileKeys
    for key, profile in pairs(svar.Profiles) do
      local profileKey = profile._current_profile_key
      if profileKey then
        svar.ProfileKeys[key] = profileKey
        profile._current_profile_key = nil
      end
    end
  end

  svar.DDBL_Version = DDBL.metadata.version
end
