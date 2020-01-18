local _, Addon = ...
local DB = Addon.DB
local L = Addon.Libs.L

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if DB.Profile.IgnoreReadable and item.Readable then
      return "NOT_JUNK", L.REASON_IGNORE_READABLE_TEXT
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if DB.Profile.DestroyIgnoreReadable and item.Readable then
      return "NOT_JUNK", L.REASON_IGNORE_READABLE_TEXT
    end

    return "PASS"
  end
})
