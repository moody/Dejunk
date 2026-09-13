local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Destroyer = Addon:GetModule("Destroyer")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local JunkFrame = Addon:GetModule("JunkFrame")
local L = Addon:GetModule("Locale")
local Looter = Addon:GetModule("Looter")
local MainWindow = Addon:GetModule("MainWindow")
local Seller = Addon:GetModule("Seller")

--- @class Commands
local Commands = Addon:GetModule("Commands")

-- ============================================================================
-- Events
-- ============================================================================

-- Register the `/dejunk` slash command on login.
EventManager:Once(E.Wow.PlayerLogin, function()
  SLASH_DEJUNK1 = "/dejunk"
  SlashCmdList.DEJUNK = function(msg)
    msg = strlower(msg or "")

    -- Split message into args.
    local args = {}
    for arg in msg:gmatch("%S+") do args[#args + 1] = strlower(arg) end

    -- First arg is command name.
    local key = table.remove(args, 1) or "options"
    key = type(Commands[key]) == "function" and key or "help"
    Commands[key](SafeUnpack(args))
  end
end)

-- ============================================================================
-- Commands
-- ============================================================================

--- Prints a list of commands.
function Commands.help()
  Addon:ForcePrint(L.COMMANDS .. ":")
  Addon:ForcePrint(Colors.Gold("  /dejunk"), "-", L.COMMAND_DESCRIPTION_OPTIONS)

  Addon:ForcePrint(Colors.Gold("  /dejunk sell"), "-", L.COMMAND_DESCRIPTION_SELL)
  Addon:ForcePrint(Colors.Gold("  /dejunk destroy"), "-", L.COMMAND_DESCRIPTION_DESTROY)
  Addon:ForcePrint(Colors.Gold("  /dejunk loot"), "-", L.COMMAND_DESCRIPTION_LOOT)

  Addon:ForcePrint(Colors.Gold("  /dejunk junk"), "-", L.COMMAND_DESCRIPTION_JUNK)

  Addon:ForcePrint(Colors.Gold("  /dejunk help"), "-", L.COMMAND_DESCRIPTION_HELP)
end

--- Toggles the `MainWindow`.
function Commands.options()
  MainWindow:Toggle()
end

--- Toggles the `JunkFrame`.
function Commands.junk()
  JunkFrame:Toggle()
end

--- Starts the `Seller`.
function Commands.sell()
  Seller:Start()
end

--- Starts the `Destroyer`.
function Commands.destroy()
  Destroyer:Start()
end

--- Starts the `Looter`.
function Commands.loot()
  Looter:Start()
end
