-- https://github.com/moody/DethsLibLoader

if _G.DethsLibLoader then return end

-- Upvalues
local assert, error, format, type = assert, error, format, type

-- DethsLibLoader
local DLL = {}
local libs = {}

-- Registers a new library with the specified name and version. Returns nil if
-- a version of the library already exists.
-- @param name - the name of the library
-- @param version - the version of the library
function DLL:Create(name, version)
  assert(type(name) == "string", "name must be a string")
  assert(type(version) == "string", "version must be a string")
  if libs[name] and libs[name][version] then
    libs[name][version].__initial_load = nil
    return
  end
  if not libs[name] then libs[name] = {} end
  local lib = { __initial_load = true }
  libs[name][version] = lib
  return lib
end

-- Returns the library with the specified name and version.
-- @param name - the name of the library
-- @param version - the version of the library
function DLL:Get(name, version)
  assert(type(name) == "string", "name must be a string")
  assert(type(version) == "string", "version must be a string")
  local lib = libs[name]
  if not lib or not lib[version] then
    error(format("\nDethsLibLoader library not found:\n  Name: \"%s\"\n  Version: \"%s\"", name, version))
  end
  return lib[version]
end

-- Add to global table
_G.DethsLibLoader = setmetatable({}, {
  __index = DLL,
  __newindex = function() error("DethsLibLoader is read-only.") end,
  __call = function(_, name, version) return DethsLibLoader:Get(name, version) end
})
