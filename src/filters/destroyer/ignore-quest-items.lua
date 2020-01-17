local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L

function Filter:Run(item)
  if
    DB.Profile.DestroyIgnoreQuestItems and
    item.Class == Consts.QUESTITEM_CLASS
  then
    return "NOT_JUNK", L.REASON_IGNORE_QUEST_ITEMS_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Destroyer, Filter)
