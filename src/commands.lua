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
    local key = table.remove(args, 1)

    -- Get command, default to `toggle`
    local cmd = key and Commands[key] or nil
    if (type(cmd) ~= "table") or (type(cmd.run) ~= "function") then
      cmd = Commands.toggle
    end

    -- Execute command
    cmd(args)
  end
end)

-- ============================================================================
-- Commands
-- ============================================================================

-- Creates a new command.
local create = (function()
  local mt = {
    __call = function(self, ...)
      return self.run(...)
    end
  }

  return function(t)
    assert(type(t.sortIndex) == "number")
    assert(type(t.title) == "string")
    assert(type(t.help) == "string")
    assert(type(t.usage) == "string")
    assert(type(t.run) == "function")
    return setmetatable(t, mt)
  end
end)()


-- Toggles the user interface.
Commands.toggle = create({
  sortIndex = -1,
  title = L.TOGGLE_TEXT,
  help = L.CMD_HELP_TOGGLE,
  usage = "[toggle]",
  run = function() UI:Toggle() end
})


-- Starts the dejunking process.
Commands.sell = create({
  sortIndex = 1,
  title = L.SELL_TEXT,
  help = L.CMD_HELP_SELL,
  usage = "sell",
  run = function()
    local frame = _G.MerchantFrame
    if frame and frame:IsShown() then
      Dejunker:Start()
    else
      Core:Print(L.CANNOT_SELL_WITHOUT_MERCHANT)
    end
  end
})


-- Starts the destroying process.
Commands.destroy = create({
  sortIndex = 2,
  title = L.DESTROY_TEXT,
  help = L.CMD_HELP_DESTROY,
  usage = "destroy",
  run = function() Destroyer:Start() end
})


-- Opens all lootable items in the player's bags.
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

  return create({
    sortIndex = 3,
    title = L.OPEN_TEXT,
    help = L.CMD_HELP_OPEN,
    usage = "open",
    run = function()
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
  })
end)()

-- ============================================================================
-- Metatable
-- ============================================================================

-- Set up `Addon.Commmands()` to return a sorted array of commands.

local sortedCmds = {}

for _, cmd in pairs(Commands) do
  sortedCmds[#sortedCmds+1] = cmd
end

table.sort(sortedCmds, function(a, b)
  return (
    a.sortIndex == b.sortIndex and
    a.title < b.title or
    a.sortIndex < b.sortIndex
  )
end)

setmetatable(Commands, {
  __call = function(self)
    return sortedCmds
  end
})
