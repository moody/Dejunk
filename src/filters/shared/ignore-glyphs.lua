local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L
local ItemQuality = _G.Enum.ItemQuality

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.sell.ignore.glyphs and
      item.Class == Consts.GLYPH_CLASS and
      item.Quality ~= ItemQuality.Poor
    then
      return "NOT_JUNK", L.REASON_IGNORE_GLYPHS_TEXT
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if
      DB.Profile.destroy.ignore.glyphs and
      item.Class == Consts.GLYPH_CLASS and
      item.Quality ~= ItemQuality.Poor
    then
      return "NOT_JUNK", L.REASON_IGNORE_GLYPHS_TEXT
    end

    return "PASS"
  end
})
