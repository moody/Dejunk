local _, Addon = ...
if Addon.IS_CLASSIC then return end

local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L
local ItemQuality = Addon.ItemQuality

local REASON = Addon.Filters:SellReason(
  L.IGNORE_TEXT,
  L.BY_CATEGORY_TEXT,
  L.IGNORE_GEMS_TEXT
)

local function run(item, ignore, reason)
  if
    ignore.gems and
    item.Class == Consts.GEM_CLASS and
    item.Quality ~= ItemQuality.Poor
  then
    return "NOT_JUNK", reason
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    return run(item, DB.Profile.sell.ignore, REASON)
  end
})
