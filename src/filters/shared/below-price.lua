local _, Addon = ...
local DB = Addon.DB
local GetCoinTextureString = _G.GetCoinTextureString
local ItemQuality = Addon.ItemQuality
local L = Addon.Libs.L
local Utils = Addon.Utils

local function isBelowPrice(item, price)
  if (item.Price * item.Quantity) >= price then
    return "NOT_JUNK", L.REASON_ITEM_PRICE_IS_NOT_BELOW_TEXT:format(
      GetCoinTextureString(price)
    )
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
      return isBelowPrice(item, DB.Profile.sell.belowPrice.value)
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if DB.Profile.destroy.belowPrice.enabled and Utils:ItemCanBeSold(item) then
      return isBelowPrice(item, DB.Profile.destroy.belowPrice.value)
    end

    return "PASS"
  end
})
