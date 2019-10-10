local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L
local LE_ITEM_ARMOR_COSMETIC = _G.LE_ITEM_ARMOR_COSMETIC
local LE_ITEM_ARMOR_GENERIC = _G.LE_ITEM_ARMOR_GENERIC

-- Ignore these generic types since they provide no cosmetic appearance
local IGNORE_ARMOR_EQUIPSLOTS = {
  ["INVTYPE_FINGER"] = true,
  ["INVTYPE_NECK"] = true,
  ["INVTYPE_TRINKET"] = true
}

function Filter:Run(item)
  local subClass = item.SubClass and Consts.ARMOR_SUBCLASSES[item.SubClass]

  if
    DB.Profile.IgnoreCosmetic and
    (
      item.Class == Consts.ARMOR_CLASS and
      not IGNORE_ARMOR_EQUIPSLOTS[item.EquipSlot] and
      (
        subClass == LE_ITEM_ARMOR_COSMETIC or
        subClass == LE_ITEM_ARMOR_GENERIC
      )
    )
  then
    return "NOT_JUNK", L.REASON_IGNORE_COSMETIC_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
