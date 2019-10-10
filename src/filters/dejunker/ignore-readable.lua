local _, Addon = ...
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L

function Filter:Run(item)
  if DB.Profile.IgnoreReadable and item.Readable then
    return "NOT_JUNK", L.REASON_IGNORE_READABLE_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
