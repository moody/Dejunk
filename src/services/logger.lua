local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local StateManager = Addon:GetModule("StateManager")

--- @class Logger
local Logger = Addon:GetModule("Logger")

--- The most entries kept. The oldest are dropped first.
--- @type integer
Logger.MAX_ENTRIES = 300

--- How an attempt ended.
--- @enum LogOutcome
Logger.Outcomes = {
  SOLD = "SOLD",
  DESTROYED = "DESTROYED",
  FAILED_TO_SELL = "FAILED_TO_SELL",
  FAILED_TO_DESTROY = "FAILED_TO_DESTROY",
  MAY_NOT_HAVE_SOLD = "MAY_NOT_HAVE_SOLD",
  MAY_NOT_HAVE_DESTROYED = "MAY_NOT_HAVE_DESTROYED"
}

--- An attempt and how it ended.
--- @class LogEntry
--- @field attempt SellAttempt | DestroyAttempt
--- @field outcome LogOutcome
--- @field profileId string The active profile when the outcome was reported.
--- @field time integer When the outcome was reported, from `time()`.

--- What was sold and destroyed this session. Only confirmed outcomes count, and the entry limit does not affect them.
--- @class LogTotals
--- @field numSold integer The stacks sold.
--- @field numDestroyed integer The stacks destroyed.
--- @field profit integer The copper earned from sales.

--- The entries, newest first.
--- @type LogEntry[]
local entries = {}

--- @type LogTotals
local totals = { numSold = 0, numDestroyed = 0, profit = 0 }

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Adds an entry for the attempt, drops the oldest entries past the limit, and fires `ItemLogged` with the entry.
--- @param attempt SellAttempt | DestroyAttempt
--- @param outcome LogOutcome
local function addEntry(attempt, outcome)
  --- @type LogEntry
  local entry = {
    attempt = attempt,
    outcome = outcome,
    profileId = StateManager:GetProfileState().id,
    time = time()
  }

  table.insert(entries, 1, entry)
  entries[Logger.MAX_ENTRIES + 1] = nil

  EventManager:Fire(E.ItemLogged, entry)
end

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.ConfirmedItemSold, function(attempt)
  local item = attempt.item
  totals.numSold = totals.numSold + 1
  totals.profit = totals.profit + Items:GetStackPrice(item)
  addEntry(attempt, Logger.Outcomes.SOLD)
end)

EventManager:On(E.ConfirmedItemDestroyed, function(attempt)
  totals.numDestroyed = totals.numDestroyed + 1
  addEntry(attempt, Logger.Outcomes.DESTROYED)
end)

EventManager:On(E.FailedToSellItem, function(attempt)
  addEntry(attempt, Logger.Outcomes.FAILED_TO_SELL)
end)

EventManager:On(E.FailedToDestroyItem, function(attempt)
  addEntry(attempt, Logger.Outcomes.FAILED_TO_DESTROY)
end)

EventManager:On(E.MayNotHaveSoldItem, function(attempt)
  addEntry(attempt, Logger.Outcomes.MAY_NOT_HAVE_SOLD)
end)

EventManager:On(E.MayNotHaveDestroyedItem, function(attempt)
  addEntry(attempt, Logger.Outcomes.MAY_NOT_HAVE_DESTROYED)
end)

-- ============================================================================
-- Logger
-- ============================================================================

--- Returns the entries, newest first.
--- @return LogEntry[]
function Logger:GetEntries()
  return entries
end

--- Returns the totals of this session.
--- @return LogTotals
function Logger:GetTotals()
  return totals
end
