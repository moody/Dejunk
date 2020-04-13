local _, Addon = ...
local Bags = Addon.Bags
local Commands = Addon.Commands
local Core = Addon.Core
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local DTL = Addon.Libs.DTL
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Libs.L
local LOCKED = _G.LOCKED
local strlower = _G.strlower
local UI = Addon.UI
local UseContainerItem = _G.UseContainerItem

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

    -- Get command, default to `toggle`
    local func = cmd and Commands[cmd] or nil
    if type(func) ~= "function" then func = Commands.toggle end

    -- Execute command
    func(args)
  end
end)

-- ============================================================================
-- Functions
-- ============================================================================

-- Toggles the user interface.
-- `/dejunk toggle`
function Commands.toggle()
  UI:Toggle()
end

-- Starts the dejunking process.
-- `/dejunk sell`
function Commands.sell()
  local frame = _G.MerchantFrame
  if frame and frame:IsShown() then
    Dejunker:Start()
  else
    Core:Print(L.CANNOT_SELL_WITHOUT_MERCHANT)
  end
end

-- Starts the destroying process.
-- `/dejunk destroy`
function Commands.destroy()
  Destroyer:Start()
end

-- Opens all lootable items in the player's bags.
  -- `/dejunk open`
Commands.open = (function()
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

  return function()
    -- Stop if a frame is open which modifies the behavior of `UseContainerItem`
    for i in pairs(frames) do
      local frame = _G[frames[i]]
      if frame and frame:IsShown() then
        Core:Print(L.CANNOT_OPEN_ITEMS)
        return
      end
    end

    local items = Bags:GetItems()
    local hasLootables = false
    local incompleteTooltips = false

    for _, item in ipairs(items) do
      if item.Lootable then
        hasLootables = true
        if DTL:ScanBagSlot(item.Bag, item.Slot) then
          if not DTL:Find(false, LOCKED) then
            Core:Print(L.OPENING_ITEM:format(item.ItemLink))
            UseContainerItem(item.Bag, item.Slot)
          else
            Core:Print(L.IGNORING_ITEM_LOCKED:format(item.ItemLink, LOCKED))
          end
        else
          if not incompleteTooltips then
            incompleteTooltips = true
            Core:Print(L.IGNORING_ITEMS_INCOMPLETE_TOOLTIPS)
          end
        end
      end
    end

    if not hasLootables then
      Core:Print(L.NO_ITEMS_TO_OPEN)
    end
  end
end)()
