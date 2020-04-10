local _, Addon = ...
local Commands = Addon.Commands
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local strlower = _G.strlower
local UI = Addon.UI

-- ============================================================================
-- Events
-- ============================================================================

EventManager:Once(E.Wow.PlayerLogin, function()
  _G.SLASH_DEJUNK1 = "/dejunk"
  _G.SLASH_DEJUNK2 = "/dj"
  _G.SlashCmdList.DEJUNK = function(msg)
    msg = strlower(msg or "")

    -- Split message into args
    local args = {}
    for s in msg:gmatch('%S+') do args[#args+1] = s end

    -- First arg is command name
    local cmd = table.remove(args, 1)
    local func = cmd and Commands[cmd] or nil

    -- Execute command
    if type(func) == "function" then
      func(args)
    else
      UI:Toggle()
    end
  end
end)

-- ============================================================================
-- Functions
-- ============================================================================

-- `/dejunk destroy`
function Commands.destroy()
  Destroyer:Start()
end
