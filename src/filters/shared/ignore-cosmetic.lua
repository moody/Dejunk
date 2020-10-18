local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L
local LE_ITEM_ARMOR_COSMETIC = _G.LE_ITEM_ARMOR_COSMETIC
local LE_ITEM_ARMOR_GENERIC = _G.LE_ITEM_ARMOR_GENERIC

local SELL_REASON, DESTROY_REASON = Addon.Filters:SharedReason(
  L.IGNORE_TEXT,
  L.BY_TYPE_TEXT,
  L.IGNORE_COSMETIC_TEXT
)

-- Ignore these generic types since they provide no cosmetic appearance
local IGNORE_ARMOR_EQUIPSLOTS = {
  INVTYPE_FINGER = true,
  INVTYPE_NECK = true,
  INVTYPE_TRINKET = true
}

local function isCosmetic(item)
  local subClass = item.SubClass and Consts.ARMOR_SUBCLASSES[item.SubClass]
  return (
    item.Class == Consts.ARMOR_CLASS and
    not IGNORE_ARMOR_EQUIPSLOTS[item.EquipSlot] and
    (
      subClass == LE_ITEM_ARMOR_COSMETIC or
      subClass == LE_ITEM_ARMOR_GENERIC
    )
  )
end

local function run(item, ignore, reason)
  if ignore.cosmetic and isCosmetic(item) then
    return "NOT_JUNK", reason
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
