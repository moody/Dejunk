local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local L = Addon.Libs.L

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.IgnoreQuestItems and
      item.Class == Consts.QUESTITEM_CLASS
    then
      return "NOT_JUNK", L.REASON_IGNORE_QUEST_ITEMS_TEXT
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if
      DB.Profile.DestroyIgnoreQuestItems and
      item.Class == Consts.QUESTITEM_CLASS
    then
      return "NOT_JUNK", L.REASON_IGNORE_QUEST_ITEMS_TEXT
    end

    return "PASS"
  end
})
