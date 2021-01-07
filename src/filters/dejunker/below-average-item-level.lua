local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local Filter = {}
local Filters = Addon.Filters
local floor = math.floor
local GetAverageItemLevel = _G.GetAverageItemLevel
local ItemQuality = Addon.ItemQuality
local L = Addon.Libs.L
local max = math.max
local Utils = Addon.Utils

local REASON = Filters:SellReason(
  L.BY_TYPE_TEXT,
  L.SELL_BELOW_AVERAGE_ILVL_TEXT .. " (%s)"
)

function Filter:Run(item)
  if
    DB.Profile.sell.byType.belowAverageItemLevel.enabled and
    Utils:IsEquipmentItem(item)
  then
    local average = floor(GetAverageItemLevel())
    local value = DB.Profile.sell.byType.belowAverageItemLevel.value
    local diff = max(average - value, 0)
    local reason = REASON:format(DCL:ColorString(value, Colors.Yellow))

    if (item.ItemLevel <= diff) then -- Sell
      return "JUNK", reason
    else  -- Ignore, unless poor quality
      if (item.Quality ~= ItemQuality.Poor) then
        return "NOT_JUNK", reason
      end
    end
  end

  return "PASS"
end

Filters:Add(Addon.Dejunker, Filter)
