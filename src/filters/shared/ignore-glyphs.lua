local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if DB.Profile.IgnoreGlyphs and item.Class == Consts.GLYPH_CLASS then
      return "NOT_JUNK", L.REASON_IGNORE_GLYPHS_TEXT
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if DB.Profile.DestroyIgnoreGlyphs and item.Class == Consts.GLYPH_CLASS then
      return "NOT_JUNK", L.REASON_IGNORE_GLYPHS_TEXT
    end

    return "PASS"
  end
})
