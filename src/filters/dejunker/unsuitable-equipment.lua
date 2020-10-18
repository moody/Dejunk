local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L

local REASON = Addon.Filters:SellReason(
  L.BY_TYPE_TEXT,
  L.SELL_UNSUITABLE_TEXT
)

function Filter:Run(item)
  if DB.Profile.sell.byType.unsuitable then
    local suitable = true

    if item.Class == Consts.ARMOR_CLASS then
      local index = Consts.ARMOR_SUBCLASSES[item.SubClass]
      suitable = Consts.SUITABLE_ARMOR[index] or item.EquipSlot == "INVTYPE_CLOAK"
    elseif item.Class == Consts.WEAPON_CLASS then
      local index = Consts.WEAPON_SUBCLASSES[item.SubClass]
      suitable = Consts.SUITABLE_WEAPONS[index]
    end

    if not suitable then
      return "JUNK", REASON
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
