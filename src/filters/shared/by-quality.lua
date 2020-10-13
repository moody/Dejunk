local _, Addon = ...
local DB = Addon.DB
local L = Addon.Libs.L
local ItemQuality = Addon.ItemQuality

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      (item.Quality == ItemQuality.Poor and DB.Profile.sell.byQuality.poor) or
      (item.Quality == ItemQuality.Common and DB.Profile.sell.byQuality.common) or
      (item.Quality == ItemQuality.Uncommon and DB.Profile.sell.byQuality.uncommon) or
      (item.Quality == ItemQuality.Rare and DB.Profile.sell.byQuality.rare) or
      (item.Quality == ItemQuality.Epic and DB.Profile.sell.byQuality.epic)
    then
      return "JUNK", L.REASON_SELL_BY_QUALITY_TEXT
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if
      (item.Quality == ItemQuality.Poor and DB.Profile.destroy.byQuality.poor) or
      (item.Quality == ItemQuality.Common and DB.Profile.destroy.byQuality.common) or
      (item.Quality == ItemQuality.Uncommon and DB.Profile.destroy.byQuality.uncommon) or
      (item.Quality == ItemQuality.Rare and DB.Profile.destroy.byQuality.rare) or
      (item.Quality == ItemQuality.Epic and DB.Profile.destroy.byQuality.epic)
    then
      return "JUNK", L.REASON_DESTROY_BY_QUALITY_TEXT
    end

    return "PASS"
  end
})
