local _, Addon = ...
local Bags = Addon.Bags
local Chat = Addon.Chat
local Commands = Addon.Commands
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local DTL = Addon.Libs.DTL
local E = Addon.Events
local EventManager = Addon.EventManager
local ItemFrames = Addon.ItemFrames
local L = Addon.Libs.L
local LOCKED = _G.LOCKED
local strlower = _G.strlower
local UI = Addon.UI
local unpack = _G.unpack
local UseContainerItem = _G.UseContainerItem

-- ============================================================================
-- Events
-- ============================================================================

EventManager:Once(E.Wow.PlayerLogin, function()
  _G.SLASH_DEJUNK1 = "/dejunk"
  _G.SLASH_DEJUNK2 = "/dj"
  _G.SlashCmdList.DEJUNK = function(msg)
    msg = strlower(msg or "")

    -- Split message into args.
    local args = {}
    for s in msg:gmatch('%S+') do args[#args+1] = s end

    -- First arg is command name.
    local key = table.remove(args, 1)

    -- Get command, default to `toggle`.
    local cmd = key and Commands[key] or nil
    if (type(cmd) ~= "table") or (type(cmd.run) ~= "function") then
      cmd = Commands.toggle
    end

    -- Execute command.
    cmd(unpack(args))
  end
end)

-- ============================================================================
-- Commands
-- ============================================================================

-- Creates a new command.
local create = (function()
  local mt = {
    __call = function(self, arg1, ...)
      -- Check for subcommand.
      if type(arg1) == "string" then
        local subcommand = self.subcommands[arg1]
        if type(subcommand) == "table" then
          return subcommand(...)
        end
      end
      -- Default to `run()`.
      return self.run(arg1, ...)
    end
  }

  local i = 0
  local function nextIndex()
    i = i + 1
    return i
  end

  return function(t)
    assert(type(t.keyword) == "string")
    assert(type(t.help) == "string")
    assert(type(t.run) == "function")

    t.sortIndex = nextIndex()

    if type(t.subcommands) ~= "table" then
      t.subcommands = {}
    else
      for _, sub in pairs(t.subcommands) do
        sub.parent = t
      end
    end

    return setmetatable(t, mt)
  end
end)()


-- Toggles the options frame.
Commands.toggle = create({
  keyword = "toggle",
  help = L.CMD_HELP_TOGGLE,
  run = function() UI:Toggle() end
})


-- Toggles the sell frame.
Commands.sell = create({
  keyword = "sell",
  help = L.CMD_HELP_SELL,
  run = function() ItemFrames.Sell:Toggle() end,
  subcommands = {
    start = create({
      keyword = "start",
      help = L.CMD_HELP_SELL_START,
      run = function() Dejunker:Start() end,
    }),
    next = create({
      keyword = "next",
      help = L.CMD_HELP_SELL_NEXT,
      run = function() Dejunker:HandleNextItem() end,
    }),
  },
})


-- Toggles the destroy frame.
Commands.destroy = create({
  keyword = "destroy",
  help = L.CMD_HELP_DESTROY,
  run = function() ItemFrames.Destroy:Toggle() end,
  subcommands = {
    start = create({
      keyword = "start",
      help = L.CMD_HELP_DESTROY_START,
      run = function() Destroyer:Start() end,
    }),
    next = create({
      keyword = "next",
      help = L.CMD_HELP_DESTROY_NEXT,
      run = function() Destroyer:HandleNextItem() end,
    }),
  }
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
    keyword = "open",
    help = L.CMD_HELP_OPEN,
    run = function()
      -- Stop if a frame is open which modifies the behavior of `UseContainerItem`
      for i in pairs(frames) do
        local frame = _G[frames[i]]
        if frame and frame:IsShown() then
          Chat:Print(L.CANNOT_OPEN_ITEMS)
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
              Chat:Print(L.OPENING_ITEM:format(item.ItemLink))
              UseContainerItem(item.Bag, item.Slot)
            else
              Chat:Print(L.IGNORING_ITEM_LOCKED:format(item.ItemLink, LOCKED))
            end
          else
            if not incompleteTooltips then
              incompleteTooltips = true
              Chat:Print(L.IGNORING_ITEMS_INCOMPLETE_TOOLTIPS)
            end
          end
        end
      end

      if not hasLootables then
        Chat:Print(L.NO_ITEMS_TO_OPEN)
      end
    end
  })
end)()

-- ============================================================================
-- Usage
-- ============================================================================

local function getUsageText(cmd)
  local usage = cmd.keyword
  local parent = cmd.parent
  while parent do
    usage = parent.keyword .. " " .. usage
    parent = parent.parent
  end
  return "/dejunk " .. usage
end

for _, cmd in pairs(Commands) do
  for _, sub in pairs(cmd.subcommands) do
    sub.usage = getUsageText(sub)
  end

  cmd.usage = getUsageText(cmd)
end

-- ============================================================================
-- Metatables
-- ============================================================================

-- Set up command tables to return a sorted array of commands when called.

local function compareCommands(a, b)
  return a.sortIndex < b.sortIndex
end

local function returnSortedOnCall(t)
  -- Get commands.
  local commands = {}
  for _, cmd in pairs(t) do
    commands[#commands+1] = cmd
    -- Recurse on subcommands.
    returnSortedOnCall(cmd.subcommands)
  end

  -- Sort [commands].
  table.sort(commands, compareCommands)

  -- Return [commands] when [t] is called.
  setmetatable(t, { __call = function() return commands end })
end

returnSortedOnCall(Commands)
