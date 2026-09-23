--- @diagnostic disable: undefined-global

-- ============================================================================
-- Global Mocks
-- ============================================================================

-- WoW globals read while `src/addon.lua` loads.
_G.C_AddOns = { GetAddOnMetadata = function(str) return str end }
_G.LibStub = function(str) return {} end

-- ============================================================================
-- Harness
-- ============================================================================

local Harness = {
  ADDON_NAME = "Dejunk",
  --- @class Addon
  Addon = {}
}

-- Initialize the `Addon` table.
local init = assert(loadfile("src/addon.lua"))
init(Harness.ADDON_NAME, Harness.Addon)

-- Initialize `Wux`.
local wux = assert(loadfile("libs/Wux.lua"))
wux(Harness.ADDON_NAME, Harness.Addon)
assert(Harness.Addon.Wux, "Wux failed to load")

--- Loads and executes a source file, passing `ADDON_NAME` and `Addon`.
--- @param path string
function Harness:Load(path)
  assert(loadfile(path))(self.ADDON_NAME, self.Addon)
end

--- Reads a SavedVariables file and returns the table it assigns, without creating a global. The file must assign
--- exactly one variable.
--- @param path string
--- @return table
function Harness:ReadSavedVariablesFile(path)
  local env = {}
  setfenv(assert(loadfile(path)), env)()
  local name, value = next(env)
  assert(name and next(env, name) == nil, path .. " must assign exactly one variable")
  return value
end

return Harness
