local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.IgnoreRecipes and
      item.Class == Consts.RECIPE_CLASS and
      item.Quality ~= LE_ITEM_QUALITY_POOR
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
      DB.Profile.DestroyIgnoreRecipes and
      item.Class == Consts.RECIPE_CLASS and
      item.Quality ~= LE_ITEM_QUALITY_POOR
    then
      return "NOT_JUNK", L.REASON_IGNORE_RECIPES_TEXT
    end

    return "PASS"
  end
})
