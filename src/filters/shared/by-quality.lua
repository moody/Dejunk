local _, Addon = ...
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local ItemQuality = Addon.ItemQuality
local L = Addon.Libs.L

local SELL_REASON, DESTROY_REASON = Addon.Filters:SharedReason(
  L.BY_QUALITY_TEXT,
  "%s"
)

local POOR = DCL:ColorString(L.POOR_TEXT, DCL.Wow.Poor)
local COMMON = DCL:ColorString(L.COMMON_TEXT, DCL.Wow.Common)
local UNCOMMON = DCL:ColorString(L.UNCOMMON_TEXT, DCL.Wow.Uncommon)
local RARE = DCL:ColorString(L.RARE_TEXT, DCL.Wow.Rare)
local EPIC = DCL:ColorString(L.EPIC_TEXT, DCL.Wow.Epic)

local function run(item, byQuality, reason)
  if item.Quality == ItemQuality.Poor and byQuality.poor then
    return "JUNK", reason:format(POOR)
  end

  if item.Quality == ItemQuality.Common and byQuality.common then
    return "JUNK", reason:format(COMMON)
  end

  if item.Quality == ItemQuality.Uncommon and byQuality.uncommon then
    return "JUNK", reason:format(UNCOMMON)
  end

  if item.Quality == ItemQuality.Rare and byQuality.rare then
    return "JUNK", reason:format(RARE)
  end

  if item.Quality == ItemQuality.Epic and byQuality.epic then
    return "JUNK", reason:format(EPIC)
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    return run(item, DB.Profile.sell.byQuality, SELL_REASON)
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    return run(item, DB.Profile.destroy.byQuality, DESTROY_REASON)
  end
})
