local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Destroyer = Addon:GetModule("Destroyer")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local JunkFrame = Addon:GetModule("JunkFrame")
local L = Addon:GetModule("Locale")
local LootableFrame = Addon:GetModule("LootableFrame")
local MainWindow = Addon:GetModule("MainWindow")
local ProfilesFrame = Addon:GetModule("ProfilesFrame")
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
-- Local Functions
-- ============================================================================

--- Prints a `/dejunk <suffix>` line followed by its description.
--- @param suffix string
--- @param description string
local function printCommand(suffix, description)
  local cmd = suffix ~= "" and ("/dejunk " .. suffix) or "/dejunk"
  Addon:ForcePrint(Colors.Gold("  " .. cmd), Colors.Grey("-"), description)
end

-- ============================================================================
-- Commands
-- ============================================================================

--- Prints a list of commands.
function Commands.help()
  Addon:ForcePrint(L.COMMANDS .. ":")
  printCommand("", L.COMMAND_DESCRIPTION_OPTIONS)
  printCommand("sell", L.COMMAND_DESCRIPTION_SELL)
  printCommand("destroy", L.COMMAND_DESCRIPTION_DESTROY)
  printCommand("junk", L.COMMAND_DESCRIPTION_JUNK)
  printCommand("loot", L.COMMAND_DESCRIPTION_LOOT)
  printCommand("profiles", L.COMMAND_DESCRIPTION_PROFILES)
  printCommand("help", L.COMMAND_DESCRIPTION_HELP)
end

--- Toggles the `MainWindow`.
function Commands.options()
  MainWindow:Toggle()
end

--- Toggles the `JunkFrame`.
function Commands.junk()
  JunkFrame:Toggle()
end

--- Toggles the `LootableFrame`.
function Commands.loot()
  LootableFrame:Toggle()
end

--- Toggles the `ProfilesFrame`.
function Commands.profiles()
  ProfilesFrame:Toggle()
end

--- Starts the `Seller`.
function Commands.sell()
  Seller:Start()
end

--- Starts the `Destroyer`.
function Commands.destroy()
  Destroyer:Start()
end
