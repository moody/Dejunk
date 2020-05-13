local _, Addon = ...
local DB = Addon.DB
local L = Addon.Libs.L

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if DB.Profile.sell.ignore.readable and item.Readable then
      return "NOT_JUNK", L.REASON_IGNORE_READABLE_TEXT
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if DB.Profile.destroy.ignore.readable and item.Readable then
      return "NOT_JUNK", L.REASON_IGNORE_READABLE_TEXT
    end

    return "PASS"
  end
})
