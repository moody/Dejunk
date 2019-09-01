-- Colors: provides easy access to various colors.

local AddonName, Addon = ...
local Colors = Addon.Colors

local _colors = {
  -- General
  Primary = "999999FF",
  Red = "CC3F3FFF",
  Green = "3FCC3FFF",
  -- Blue = "3F3FCCFF",
  Yellow = "CCCC3FFF",

  -- Lists
  Inclusions = "CC3F3FFF",
  Exclusions = "3FCC3FFF",
  Destroyables = "CCCC3FFF",
}

for k, v in pairs(_colors) do Colors[k] = v end
