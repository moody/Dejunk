local _, Addon = ...
local Colors = Addon:GetModule("Colors")
local Commands = Addon.Commands
local Container = Addon.Container
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local Items = Addon.Items
local JunkFrame = Addon.UserInterface.JunkFrame
local L = Addon:GetModule("Locale")
local Lists = Addon.Lists
local Seller = Addon.Seller
local TransportFrame = Addon.UserInterface.TransportFrame
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
    "-",
    L.COMMAND_DESCRIPTION_TRANSPORT
  )
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

    CloseLoot()

    local items = Items:GetItems()
    local hasLootables = false

    for _, item in ipairs(items) do
      if item.lootable then
        hasLootables = true
        Container.UseContainerItem(item.bag, item.slot)
      end
    end

    if not hasLootables then
      Addon:Print(L.NO_LOOTABLE_ITEMS_TO_OPEN)
    end
  end
end

function Commands.keybinds()
  CloseMenus()
  CloseAllWindows()

  if Addon.IS_RETAIL then
    -- Open the settings panel.
    local keybindingsCategoryId = SettingsPanel.keybindingsCategory:GetID()
    SettingsPanel:OpenToCategory(keybindingsCategoryId)
  else
    -- Open the keybinding frame.
    if not KeyBindingFrame then KeyBindingFrame_LoadUI() end
    KeyBindingFrame:Show()
    -- Navigate to Dejunk binding category.
    for _, button in ipairs(KeyBindingFrame.categoryList.buttons) do
      local name = button.element and button.element.name
      if name == BINDING_CATEGORY_DEJUNK then
        return button:Click()
      end
    end
  end
end

function Commands.transport(listName)
  if listName == "inclusions" then
    TransportFrame:Toggle(Lists.Inclusions)
  elseif listName == "exclusions" then
    TransportFrame:Toggle(Lists.Exclusions)
  else
    Commands.help()
  end
end

Commands.import = Commands.transport
Commands.export = Commands.transport
