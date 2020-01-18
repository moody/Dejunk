-- https://github.com/moody/DethsDBLib

local _, Addon = ...

local metadata = {
  name = "DethsDBLib",
  version = "2.0.2",
  description = "Addon library for managing Saved Variables.",
  author = "Dethanyel"
}

local name = ("%s_%s"):format(metadata.name, metadata.version)
local lib = _G[name]

if lib then
  lib.__loaded = true
else
  lib = {
    metadata = metadata,
    consts = {},
    mixins = {},
    utils = {}
  }

  _G[name] = lib
end

Addon[metadata.name] = lib
