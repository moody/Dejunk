local _, Addon = ...
local DB = Addon.DB
local GetCoinTextureString = _G.GetCoinTextureString
local ItemQuality = Addon.ItemQuality
local L = Addon.Libs.L
local Utils = Addon.Utils

local REASON = Addon.Filters:SellReason(
  L.GENERAL_TEXT,
  L.BELOW_PRICE_TEXT .. " (%s)"
)

local function isBelowPrice(item, price, reason)
  if (item.Price * item.Quantity) >= price then
    return "NOT_JUNK", reason:format(GetCoinTextureString(price))
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.sell.belowPrice.enabled and
      item.Quality ~= ItemQuality.Poor and
      Utils:ItemCanBeSold(item)
    then
      return isBelowPrice(
        item,
        DB.Profile.sell.belowPrice.value,
        REASON
      )
    end

    return "PASS"
  end
})
