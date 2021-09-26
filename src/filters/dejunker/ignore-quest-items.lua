local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L

local REASON = Addon.Filters:SellReason(
  L.IGNORE_TEXT,
  L.BY_TYPE_TEXT,
  L.IGNORE_QUEST_ITEMS_TEXT
)

local function run(item, ignore, reason)
  if
    ignore.questItems and
    item.Class == Consts.QUESTITEM_CLASS
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
