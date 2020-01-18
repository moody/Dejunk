local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.IgnoreBattlePets and
      (
        item.Class == Consts.BATTLEPET_CLASS or
        item.SubClass == Consts.COMPANION_SUBCLASS
      )
    then
      return "NOT_JUNK", L.REASON_IGNORE_BATTLEPETS_TEXT
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if
      DB.Profile.DestroyIgnoreBattlePets and
      (
        item.Class == Consts.BATTLEPET_CLASS or
        item.SubClass == Consts.COMPANION_SUBCLASS
      )
    then
      return "NOT_JUNK", L.REASON_IGNORE_BATTLEPETS_TEXT
    end

    return "PASS"
  end
})
