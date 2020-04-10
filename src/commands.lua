local _, Addon = ...
local Commands = Addon.Commands
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

    -- Parse
    Commands:Parse(args)
  end
end)

-- ============================================================================
-- Functions
-- ============================================================================

function Commands:Parse(args)
  -- First arg is command name
  local cmd = table.remove(args, 1)
  local func = self.Default

  -- TODO: add commands

  -- Execute command
  func(self, args)
end

-- Default command.
function Commands:Default()
  UI:Toggle()
end
