local _, Addon = ...
local DDBL = Addon.DethsDBLib
if DDBL.__loaded then return end

local consts = DDBL.consts
local utils = DDBL.utils

local db_cache = {
  -- ["AddonName"] = db table
}

-- Creates and returns a new database table.
-- @param {string} addonName - the name of the addon
-- @param {table} defaults - a table of default key-value pairs
function DDBL:Create(addonName, defaults)
  local svarKey -- set during validation

  do -- Validation
    -- params
    assert(type(addonName) == "string", "addonName must be a string")
    assert(type(defaults) == "table", "defaults must be a table")
    assert(type(defaults.Global) == "table", "defaults.Global must be a table")
    assert(type(defaults.Profile) == "table", "defaults.Profile must be a table")

    -- addon is loaded and svars are available
    assert(
      select(2, _G.IsAddOnLoaded(addonName)),
      consts.ADDON_NOT_LOADED_MSG:format(addonName)
    )

    -- database for addon does not already exist
    assert(
      db_cache[addonName] == nil,
      ("attempt to create existing database for \"%s\""):format(addonName)
    )

    -- .toc metadata entry for DDBL
    svarKey = _G.GetAddOnMetadata(addonName, consts.TOC_ENTRY)
    assert(type(svarKey) == "string", consts.TOC_ERROR_MSG:format(addonName))
  end

  -- Create, store, and return
  local db = utils.initialize(svarKey, defaults)
  db_cache[addonName] = db
  return db
end

-- Allow usage: `Addon.DethsDBLib(...)`
setmetatable(DDBL, { __call = DDBL.Create })

-- ============================================================================
-- Frame
-- ============================================================================

local frame = _G.CreateFrame(
  "Frame",
  ("%s_%s_EventFrame"):format(
    DDBL.metadata.name,
    DDBL.metadata.version
  )
)

function frame:OnEvent(event)
  if (event == "PLAYER_LOGOUT") then
    -- Deinitialize all databases
    for _, db in pairs(db_cache) do
      utils.deinitialize(db)
    end
  end
end

frame:SetScript("OnEvent", frame.OnEvent)
frame:RegisterEvent("PLAYER_LOGOUT")
