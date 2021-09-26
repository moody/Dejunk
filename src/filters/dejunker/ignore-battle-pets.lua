local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L

local REASON = Addon.Filters:SellReason(
  L.IGNORE_TEXT,
  L.BY_CATEGORY_TEXT,
  L.IGNORE_BATTLEPETS_TEXT
)

local function run(item, ignore, reason)
  if
    ignore.battlePets and
    (
      item.Class == Consts.BATTLEPET_CLASS or
      item.SubClass == Consts.COMPANION_SUBCLASS
    )
  then
    return "NOT_JUNK", reason
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    return run(item, DB.Profile.sell.ignore, REASON)
  end
})
