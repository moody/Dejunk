local _, Addon = ...
local Bags = Addon.Bags
local Colors = Addon.Colors
local Commands = Addon.Commands
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
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
    key = type(Commands[key]) == "function" and key or "toggle"
    Commands[key]()
  end
end)

-- ============================================================================
-- Commands
-- ============================================================================

function Commands.toggle()
  UserInterface:Toggle()
end

function Commands.help()
  Addon:Print(L.COMMANDS .. ":")
  Addon:Print("  /dejunk", Colors.Grey("- " .. L.CMD_HELP_TOGGLE))
  Addon:Print("  /dejunk sell", Colors.Grey("- " .. L.CMD_HELP_SELL))
  Addon:Print("  /dejunk destroy", Colors.Grey("- " .. L.CMD_HELP_DESTROY))
  Addon:Print("  /dejunk loot", Colors.Grey("- " .. L.CMD_HELP_LOOT))
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
        UseContainerItem(item.Bag, item.Slot)
      end
    end

    if not hasLootables then
      Addon:Print(L.NO_LOOTABLE_ITEMS_TO_OPEN)
    end
  end
end
