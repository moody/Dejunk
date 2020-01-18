-- https://github.com/moody/DethsBagLib

local _, Addon = ...

local metadata = {
  name = "DethsBagLib",
  version = "2.2",
  description = "Addon library for bag item information.",
  author = "Dethanyel"
}

local name = ("%s_%s"):format(metadata.name, metadata.version)
local lib = _G[name]

if lib then
  lib.__loaded = true
else
  lib = {
    metadata = metadata,
    Backend = {},
    ItemMixins = {}
  }

  _G[name] = lib
end

Addon[metadata.name] = lib
