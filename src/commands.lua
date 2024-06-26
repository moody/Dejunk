local _, Addon = ...
local Colors = Addon:GetModule("Colors") ---@type Colors
local Commands = Addon:GetModule("Commands")
local Destroyer = Addon:GetModule("Destroyer")
local E = Addon:GetModule("Events") ---@type Events
local EventManager = Addon:GetModule("EventManager") ---@type EventManager
local JunkFrame = Addon:GetModule("JunkFrame")
local L = Addon:GetModule("Locale") ---@type Locale
local Lists = Addon:GetModule("Lists")
local Looter = Addon:GetModule("Looter")
local MainWindow = Addon:GetModule("MainWindow") ---@type MainWindow
local Seller = Addon:GetModule("Seller")
local TransportFrame = Addon:GetModule("TransportFrame")

-- ============================================================================
-- Events
-- ============================================================================

EventManager:Once(E.Wow.PlayerLogin, function()
  SLASH_DEJUNK1 = "/dejunk"
  SlashCmdList.DEJUNK = function(msg)
    msg = strlower(msg or "")

    -- Split message into args.
    local args = {}
    for arg in msg:gmatch("%S+") do args[#args + 1] = strlower(arg) end

    -- First arg is command name.
    local key = table.remove(args, 1)
    key = type(Commands[key]) == "function" and key or "help"
    Commands[key](SafeUnpack(args))
  end
end)

-- ============================================================================
-- Commands
-- ============================================================================

function Commands.help()
  Addon:ForcePrint(L.COMMANDS .. ":")
  Addon:ForcePrint(Colors.Gold("  /dejunk"), "-", L.COMMAND_DESCRIPTION_HELP)
  Addon:ForcePrint(Colors.Gold("  /dejunk keybinds"), "-", L.COMMAND_DESCRIPTION_KEYBINDS)
  Addon:ForcePrint(Colors.Gold("  /dejunk options"), "-", L.COMMAND_DESCRIPTION_OPTIONS)
  Addon:ForcePrint(Colors.Gold("  /dejunk junk"), "-", L.COMMAND_DESCRIPTION_JUNK)
  Addon:ForcePrint(
    Colors.Gold("  /dejunk transport"),
    Colors.Grey(("{%s||%s}"):format(Colors.Gold("inclusions"), Colors.Gold("exclusions"))),
    Colors.Grey(("{%s||%s}"):format(Colors.Gold("global"), Colors.Gold("character"))),
    "-",
    L.COMMAND_DESCRIPTION_TRANSPORT
  )
  Addon:ForcePrint(Colors.Gold("  /dejunk sell"), "-", L.COMMAND_DESCRIPTION_SELL)
  Addon:ForcePrint(Colors.Gold("  /dejunk destroy"), "-", L.COMMAND_DESCRIPTION_DESTROY)
  Addon:ForcePrint(Colors.Gold("  /dejunk loot"), "-", L.COMMAND_DESCRIPTION_LOOT)
end

function Commands.options()
  MainWindow:Toggle()
end

function Commands.junk()
  JunkFrame:Toggle()
end

function Commands.sell()
  Seller:Start()
end

function Commands.destroy()
  Destroyer:Start()
end

function Commands.loot()
  Looter:Start()
end

function Commands.keybinds()
  CloseMenus()
  CloseAllWindows()

  -- Open the settings panel.
  local keybindingsCategoryId = SettingsPanel.keybindingsCategory:GetID()
  Settings.OpenToCategory(keybindingsCategoryId)
end

function Commands.transport(listName, listType)
  local list = nil
  if listName == "inclusions" then list = listType == "global" and Lists.GlobalInclusions or Lists.PerCharInclusions end
  if listName == "exclusions" then list = listType == "global" and Lists.GlobalExclusions or Lists.PerCharExclusions end
  if list then TransportFrame:Toggle(list) else Commands.help() end
end

Commands.import = Commands.transport
Commands.export = Commands.transport
