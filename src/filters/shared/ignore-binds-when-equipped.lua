local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local DTL = Addon.Libs.DTL
local L = Addon.Libs.L
local ItemQuality = Addon.ItemQuality

local SELL_REASON, DESTROY_REASON = Addon.Filters:SharedReason(
  L.IGNORE_TEXT,
  L.BY_TYPE_TEXT,
  L.IGNORE_BOE_TEXT
)

local function run(item, ignore, reason)
  if
    ignore.bindsWhenEquipped and
    item.Class ~= Consts.RECIPE_CLASS and
    item.Quality ~= ItemQuality.Poor
  then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    end

    if DTL:IsBindsWhenEquipped() then
      return "NOT_JUNK", reason
    end
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    return run(item, DB.Profile.sell.ignore, SELL_REASON)
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    return run(item, DB.Profile.destroy.ignore, DESTROY_REASON)
  end
})
