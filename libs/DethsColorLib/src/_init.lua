-- https://github.com/moody/DethsColorLib

local _, Addon = ...

local metadata = {
  name = "DethsColorLib",
  version = "2.1",
  description = "Addon library for working with colors.",
  author = "Dethanyel"
}

local name = ("%s_%s"):format(metadata.name, metadata.version)
local lib = _G[name]

if lib then
  lib.__loaded = true
else
  lib = {
    metadata = metadata
  }

  _G[name] = lib
end

Addon[metadata.name] = lib
