--- @diagnostic disable: undefined-global

local Mocks = require("test/mocks")

--- A test game that runs the real `EventManager` and `TickerManager`, with `Blizzard` and `EquipmentSetsCache`
--- faked.
--- @class TestGame
local TestGame = {}

--- Returns a new test game in the given context. Call it before loading the files under test.
--- @param context TestContext
--- @return TestGameInstance game
function TestGame:New(context)
  --- @class TestGameInstance
  local game = {
    --- Seconds per frame.
    FRAME_SECONDS = 0.05,

    --- Every slot in the bags, in order. A slot with no `itemId` is empty.
    --- @type { bag: integer, slot: integer, itemId: integer? }[]
    slots = {},

    --- The time that `Blizzard.Utils:GetTime()` returns.
    time = 0,

    --- The seconds left to refund every item, or `nil` if it has no refund window.
    --- @type number?
    refundSeconds = nil,

    --- The IDs of the items whose data is not loaded. `Blizzard.Item:GetInfo()` returns nothing for them.
    --- @type table<integer, true>
    unloadedItemIds = {},

    --- The number of times every slot has been scanned.
    scanCount = 0
  }

  -- `Blizzard`, reading from `game.slots`.
  local Blizzard = { Container = {}, Item = {}, Utils = {} }

  local ContainerSpy = Mocks:CreateSpy(Blizzard.Container)

  ContainerSpy:Stub("IterateSlots"):Invokes(function()
    game.scanCount = game.scanCount + 1
    local index = 0

    return function()
      index = index + 1
      local entry = game.slots[index]
      if entry then return entry.bag, entry.slot, entry.itemId end
    end
  end)

  ContainerSpy:Stub("GetItemInfo"):Invokes(function(_, bag, slot)
    for _, entry in ipairs(game.slots) do
      if entry.bag == bag and entry.slot == slot and entry.itemId then
        return { bag = bag, slot = slot, id = entry.itemId, link = "item:" .. entry.itemId }
      end
    end
  end)

  ContainerSpy:Stub("GetRefundSeconds"):Invokes(function() return game.refundSeconds end)

  Mocks:CreateSpy(Blizzard.Item):Stub("GetInfo"):Invokes(function(_, item)
    local itemId = type(item) == "number" and item or tonumber(tostring(item):match("%d+"))
    if game.unloadedItemIds[itemId] then return end

    return "Name", 10, "INVTYPE_HEAD", 100, 2, 1
  end)
  Mocks:CreateSpy(Blizzard.Utils):Stub("GetTime"):Invokes(function() return game.time end)

  context:SetModule("Blizzard", Blizzard)

  --- The fake `Blizzard` module. A test can add what it needs.
  game.Blizzard = Blizzard

  local EquipmentSetsCache = {}
  local EquipmentSetsCacheSpy = Mocks:CreateSpy(EquipmentSetsCache)
  EquipmentSetsCacheSpy:Stub("Refresh")
  EquipmentSetsCacheSpy:Stub("IsBagSlotCached"):Returns(false)
  context:SetModule("EquipmentSetsCache", EquipmentSetsCache)

  -- The real event and ticker managers, each with a frame that the test drives.
  local tickerFrame = Mocks:CreateFrame()

  context:SetGlobal("CreateFrame", function() return Mocks:CreateFrame() end)
  context:Load("src/events/events.lua")
  context:Load("src/events/event-manager.lua")

  context:SetGlobal("CreateFrame", function() return tickerFrame end)
  context:Load("src/utils/ticker-manager.lua")

  local EventManager = context:GetModule("EventManager")

  --- Fires a game event, as the game does.
  --- @param event string
  --- @param ... any The arguments the event carries.
  function game:Fire(event, ...)
    EventManager:Fire(event, ...)
  end

  --- Moves the game's time forward a frame at a time, running the tickers that are due.
  --- @param seconds number
  function game:Advance(seconds)
    local remaining = seconds

    while remaining > 0 do
      local elapsed = math.min(remaining, self.FRAME_SECONDS)
      remaining = remaining - elapsed
      self.time = self.time + elapsed
      tickerFrame._test.scripts.OnUpdate(tickerFrame, elapsed)
    end
  end

  --- Moves the game's time forward by `count` update ticks of the bag items cache, plus a frame so the last tick has
  --- run.
  --- @param count integer
  function game:AdvanceTicks(count)
    local BagItemsCache = context:GetModule("BagItemsCache")
    self:Advance(count * BagItemsCache.UPDATE_TICK_SECONDS + self.FRAME_SECONDS)
  end

  --- The `Events` module.
  game.E = context:GetModule("Events")

  --- The real `EventManager`.
  game.EventManager = EventManager

  return game
end

return TestGame
