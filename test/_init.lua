if not _G.__WEST_LIB__ then return end

local _, Addon = ...
local west = _G.__WEST_LIB__()
Addon.West = west

-- Register slash command
_G.SLASH_DEJUNKTEST1 = "/dejunktest"
_G.SlashCmdList.DEJUNKTEST = west.run
