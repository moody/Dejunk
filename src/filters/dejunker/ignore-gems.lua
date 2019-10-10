local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Consts = Addon.Consts
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L

function Filter:Run(item)
  if DB.Profile.IgnoreGems and item.Class == Consts.GEM_CLASS then
    return "NOT_JUNK", L.REASON_IGNORE_GEMS_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
