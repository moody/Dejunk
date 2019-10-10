local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L

function Filter:Run(item)
  if DB.Profile.SellUnsuitable then
    local suitable = true

    if item.Class == Consts.ARMOR_CLASS then
      local index = Consts.ARMOR_SUBCLASSES[item.SubClass]
      suitable = Consts.SUITABLE_ARMOR[index] or item.EquipSlot == "INVTYPE_CLOAK"
    elseif item.Class == Consts.WEAPON_CLASS then
      local index = Consts.WEAPON_SUBCLASSES[item.SubClass]
      suitable = Consts.SUITABLE_WEAPONS[index]
    end

    if not suitable then
      return "JUNK", L.REASON_SELL_UNSUITABLE_TEXT
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
