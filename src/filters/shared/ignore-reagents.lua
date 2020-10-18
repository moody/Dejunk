local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L
local ItemQuality = Addon.ItemQuality

local SELL_REASON, DESTROY_REASON = Addon.Filters:SharedReason(
  L.IGNORE_TEXT,
  L.BY_CATEGORY_TEXT,
  L.IGNORE_REAGENTS_TEXT
)

local function run(item, ignore, reason)
  if
    ignore.reagents and
    item.Class == Consts.REAGENT_CLASS and
    item.Quality ~= ItemQuality.Poor
  then
    return "NOT_JUNK", reason
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    return run(item, DB.Profile.sell.ignore, SELL_REASON)
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    return run(item, DB.Profile.destroy.ignore, DESTROY_REASON)
  end
})
