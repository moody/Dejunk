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

return Harness
