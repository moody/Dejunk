--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Mocks = require("test/mocks")
local TestGame = require("test/test-game")

-- ============================================================================
-- Setup
-- ============================================================================

--- The ID of the active profile, unless a test changes it.
local PROFILE_ID = "PROFILE"

--- The time that `time()` returns, unless a test changes it.
local TIME = 1000

--- Returns `Logger`, a test game, and the spies of what it uses, from a new context. The active profile is named
--- `PROFILE_ID` and `time()` returns `TIME`. A test changes a stub with `GetStub()`.
--- @return Logger Logger
--- @return TestGameInstance Game
--- @return LoggerTestSpies spies
local function setupContext()
  local Context = Harness:NewContext()
  local Game = TestGame:New(Context)

  local StateManager = {}
  local StateManagerSpy = Mocks:CreateSpy(StateManager)
  StateManagerSpy:Stub("GetProfileState"):Returns({ id = PROFILE_ID })
  Context:SetModule("StateManager", StateManager)

  local Globals = {}
  local GlobalsSpy = Mocks:CreateSpy(Globals)
  GlobalsSpy:Stub("time"):Returns(TIME)
  Context:SetGlobal("time", Globals.time)

  Context:Load("src/services/logger.lua")

  --- @class LoggerTestSpies
  local spies = {
    --- Stubs `time()`.
    GlobalsSpy = GlobalsSpy,

    --- Stubs `StateManager:GetProfileState()`.
    StateManagerSpy = StateManagerSpy
  }

  return Context:GetModule("Logger"), Game, spies
end

--- Returns a sell attempt of a stack that sells for `price` each.
--- @param price integer
--- @param quantity integer
--- @return SellAttempt
local function createSellAttempt(price, quantity)
  return { item = { price = price, quantity = quantity }, type = "RUN" }
end

--- Returns a destroy attempt of an item that has a price.
--- @return DestroyAttempt
local function createDestroyAttempt()
  return { item = { price = 10, quantity = 1 }, type = "MANUAL" }
end

-- ============================================================================
-- Tests - Logger, entries
-- ============================================================================

-- Test: each outcome event adds an entry with its attempt and outcome.
do
  local Logger, Game = setupContext()
  local E = Game.E
  local cases = {
    { event = E.ConfirmedItemSold, outcome = Logger.Outcomes.SOLD, attempt = createSellAttempt(10, 1) },
    { event = E.ConfirmedItemDestroyed, outcome = Logger.Outcomes.DESTROYED, attempt = createDestroyAttempt() },
    { event = E.FailedToSellItem, outcome = Logger.Outcomes.FAILED_TO_SELL, attempt = createSellAttempt(10, 1) },
    { event = E.FailedToDestroyItem, outcome = Logger.Outcomes.FAILED_TO_DESTROY, attempt = createDestroyAttempt() },
    { event = E.MayNotHaveSoldItem, outcome = Logger.Outcomes.MAY_NOT_HAVE_SOLD, attempt = createSellAttempt(10, 1) },
    { event = E.MayNotHaveDestroyedItem, outcome = Logger.Outcomes.MAY_NOT_HAVE_DESTROYED, attempt = createDestroyAttempt() }
  }

  for _, case in ipairs(cases) do
    Game.EventManager:Fire(case.event, case.attempt)

    -- The newest entry is first.
    local entry = Logger:GetEntries()[1]
    assert(entry.attempt == case.attempt)
    assert(entry.outcome == case.outcome)
  end

  assert(#Logger:GetEntries() == #cases)
end

-- Test: the entries are newest first.
do
  local Logger, Game = setupContext()
  local first = createSellAttempt(10, 1)
  local second = createSellAttempt(10, 1)

  Game.EventManager:Fire(Game.E.ConfirmedItemSold, first)
  Game.EventManager:Fire(Game.E.ConfirmedItemSold, second)

  local entries = Logger:GetEntries()
  assert(entries[1].attempt == second)
  assert(entries[2].attempt == first)
end

-- Test: an entry has the profile ID and the time from when the outcome event arrived.
do
  local Logger, Game, spies = setupContext()

  Game.EventManager:Fire(Game.E.ConfirmedItemSold, createSellAttempt(10, 1))

  spies.StateManagerSpy:GetStub("GetProfileState"):Returns({ id = "OTHER_PROFILE" })
  spies.GlobalsSpy:GetStub("time"):Returns(TIME + 60)

  local entry = Logger:GetEntries()[1]
  assert(entry.profileId == PROFILE_ID)
  assert(entry.time == TIME)
end

-- Test: only the newest `MAX_ENTRIES` entries are kept.
do
  local Logger, Game = setupContext()
  local oldest = createSellAttempt(10, 1)

  Game.EventManager:Fire(Game.E.ConfirmedItemSold, oldest)
  for _ = 1, Logger.MAX_ENTRIES do
    Game.EventManager:Fire(Game.E.ConfirmedItemSold, createSellAttempt(10, 1))
  end

  local entries = Logger:GetEntries()
  assert(#entries == Logger.MAX_ENTRIES)
  for _, entry in ipairs(entries) do
    assert(entry.attempt ~= oldest)
  end
end

-- Test: fires `ItemLogged` with the new entry.
do
  local Logger, Game = setupContext()
  local logged = {}
  Game.EventManager:On(Game.E.ItemLogged, function(entry) logged[#logged + 1] = entry end)

  Game.EventManager:Fire(Game.E.FailedToSellItem, createSellAttempt(10, 1))

  assert(#logged == 1)
  assert(logged[1] == Logger:GetEntries()[1])
end

-- ============================================================================
-- Tests - Logger, totals
-- ============================================================================

-- Test: a confirmed sale adds one stack and its price to the totals.
do
  local Logger, Game = setupContext()

  Game.EventManager:Fire(Game.E.ConfirmedItemSold, createSellAttempt(10, 3))
  Game.EventManager:Fire(Game.E.ConfirmedItemSold, createSellAttempt(5, 1))

  local totals = Logger:GetTotals()
  assert(totals.numSold == 2)
  assert(totals.profit == 35)
  assert(totals.numDestroyed == 0)
end

-- Test: a confirmed destroy adds one stack to the totals, with no profit.
do
  local Logger, Game = setupContext()

  Game.EventManager:Fire(Game.E.ConfirmedItemDestroyed, createDestroyAttempt())

  local totals = Logger:GetTotals()
  assert(totals.numDestroyed == 1)
  assert(totals.numSold == 0)
  assert(totals.profit == 0)
end

-- Test: failed and unconfirmed outcomes are not in the totals.
do
  local Logger, Game = setupContext()
  local E = Game.E

  Game.EventManager:Fire(E.FailedToSellItem, createSellAttempt(10, 1))
  Game.EventManager:Fire(E.FailedToDestroyItem, createDestroyAttempt())
  Game.EventManager:Fire(E.MayNotHaveSoldItem, createSellAttempt(10, 1))
  Game.EventManager:Fire(E.MayNotHaveDestroyedItem, createDestroyAttempt())

  local totals = Logger:GetTotals()
  assert(totals.numSold == 0)
  assert(totals.numDestroyed == 0)
  assert(totals.profit == 0)
end

-- Test: the totals keep counting entries that were dropped past `MAX_ENTRIES`.
do
  local Logger, Game = setupContext()

  for _ = 1, Logger.MAX_ENTRIES + 1 do
    Game.EventManager:Fire(Game.E.ConfirmedItemSold, createSellAttempt(10, 1))
  end

  assert(Logger:GetTotals().numSold == Logger.MAX_ENTRIES + 1)
end
