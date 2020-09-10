local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L
local ItemQuality = _G.Enum.ItemQuality

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.sell.ignore.recipes and
      item.Class == Consts.RECIPE_CLASS and
      item.Quality ~= ItemQuality.Poor
    then
      return "NOT_JUNK", L.REASON_IGNORE_RECIPES_TEXT
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if
      DB.Profile.destroy.ignore.recipes and
      item.Class == Consts.RECIPE_CLASS and
      item.Quality ~= ItemQuality.Poor
    then
      return "NOT_JUNK", L.REASON_IGNORE_RECIPES_TEXT
    end

    return "PASS"
  end
})
