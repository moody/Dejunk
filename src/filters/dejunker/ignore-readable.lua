local _, Addon = ...
local DB = Addon.DB
local L = Addon.Libs.L

local REASON = Addon.Filters:SellReason(
  L.IGNORE_TEXT,
  L.BY_TYPE_TEXT,
  L.IGNORE_READABLE_TEXT
)

local function run(item, ignore, reason)
  if ignore.readable and item.Readable then
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
