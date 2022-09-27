local _, Addon = ...
local Bags = Addon.Bags
local Colors = Addon.Colors
local Commands = Addon.Commands
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local JunkFrame = Addon.UserInterface.JunkFrame
local L = Addon.Locale
local Seller = Addon.Seller
local UserInterface = Addon.UserInterface

-- ============================================================================
-- Events
-- ============================================================================

EventManager:Once(E.Wow.PlayerLogin, function()
  SLASH_DEJUNK1 = "/dejunk"
  SlashCmdList.DEJUNK = function(msg)
    msg = strlower(msg or "")

    -- Split message into args.
    local args = {}
    for arg in msg:gmatch("%S+") do args[#args + 1] = arg end

    -- First arg is command name.
    local key = table.remove(args, 1)
    key = type(Commands[key]) == "function" and key or "help"
    Commands[key]()
  end
end)

-- ============================================================================
-- Commands
-- ============================================================================

function Commands.help()
  Addon:ForcePrint(L.COMMANDS .. ":")
  Addon:ForcePrint(Colors.Gold("  /dejunk"), "-", L.COMMAND_DESCRIPTION_HELP)
  Addon:ForcePrint(Colors.Gold("  /dejunk options"), "-", L.COMMAND_DESCRIPTION_OPTIONS)
  Addon:ForcePrint(Colors.Gold("  /dejunk junk"), "-", L.COMMAND_DESCRIPTION_JUNK)
  Addon:ForcePrint(Colors.Gold("  /dejunk sell"), "-", L.COMMAND_DESCRIPTION_SELL)
  Addon:ForcePrint(Colors.Gold("  /dejunk destroy"), "-", L.COMMAND_DESCRIPTION_DESTROY)
  Addon:ForcePrint(Colors.Gold("  /dejunk loot"), "-", L.COMMAND_DESCRIPTION_LOOT)
end

function Commands.options()
  UserInterface:Toggle()
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

do -- Commands.loot()
  local frames = {
    "BankFrame",
    "MerchantFrame",
    "TradeFrame",

    -- Classic
    "AuctionFrame",

    -- Retail
    "AuctionHouseFrame",
    "AzeriteRespecFrame",
    "GuildBankFrame",
    "ScrappingMachineFrame",
    "VoidStorageFrame"
  }

  function Commands.loot()
    -- Stop if a frame is open which modifies the behavior of `UseContainerItem`.
    for _, key in pairs(frames) do
      local frame = _G[key]
      if frame and frame:IsShown() then
        return Addon:Print(L.CANNOT_OPEN_LOOTABLE_ITEMS)
      end
    end

    local items = Bags:GetItems()
    local hasLootables = false

    for _, item in ipairs(items) do
      if item.lootable then
        hasLootables = true
        UseContainerItem(item.bag, item.slot)
      end
    end

    if not hasLootables then
      Addon:Print(L.NO_LOOTABLE_ITEMS_TO_OPEN)
    end
  end
end
