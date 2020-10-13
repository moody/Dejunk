local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local DTL = Addon.Libs.DTL
local L = Addon.Libs.L
local ItemQuality = Addon.ItemQuality

local function isBindsWhenEquipped(item)
  if not DTL:ScanBagSlot(item.Bag, item.Slot) then
    return Addon.Filters:IncompleteTooltipError()
  end

  if DTL:IsBindsWhenEquipped() then
    return "NOT_JUNK", L.REASON_IGNORE_BOE_TEXT
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.sell.ignore.bindsWhenEquipped and
      item.Class ~= Consts.RECIPE_CLASS and
      item.Quality ~= ItemQuality.Poor
    then
      return isBindsWhenEquipped(item)
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if
      DB.Profile.destroy.ignore.bindsWhenEquipped and
      item.Class ~= Consts.RECIPE_CLASS and
      item.Quality ~= ItemQuality.Poor
    then
      return isBindsWhenEquipped(item)
    end

    return "PASS"
  end
})
