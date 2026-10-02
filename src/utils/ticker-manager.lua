local Addon = select(2, ...) ---@type Addon

--- @class TickerManager
local TickerManager = Addon:GetModule("TickerManager")

--- Tickers moved into `activeTickers` at the start of the next `OnUpdate`.
--- @type table<Ticker, boolean>
local queuedTickers = {}

--- @type table<Ticker, boolean>
local activeTickers = {}

-- Frame for updating active tickers.
CreateFrame("Frame"):SetScript("OnUpdate", function(_, elapsed)
  for ticker in pairs(queuedTickers) do
    queuedTickers[ticker] = nil
    activeTickers[ticker] = true
  end

  for ticker in pairs(activeTickers) do ticker:OnUpdate(elapsed) end
end)

-- ============================================================================
-- Ticker
-- ============================================================================

--- @class Ticker
--- @field package callback function
--- @field package frame Region
--- @field package isCancelled boolean
--- @field package maxTicks number
--- @field package ticks number
--- @field package timePerTick number
--- @field package timer number
local Ticker = {}
Ticker.__index = Ticker

--- Reactivates the ticker and resets its timer and tick count.
function Ticker:Restart()
  self.timer = 0
  self.ticks = 0
  self.isCancelled = false
  queuedTickers[self] = true
end

--- Deactivates the ticker.
function Ticker:Cancel()
  self.isCancelled = true
  queuedTickers[self] = nil
  activeTickers[self] = nil
end

--- Returns `true` if the ticker is cancelled.
--- @return boolean
function Ticker:IsCancelled()
  return self.isCancelled
end

--- Binds the ticker to `frame`: it only advances while `frame` is visible.
--- @param frame Region
--- @return Ticker
function Ticker:BindFrame(frame)
  self.frame = frame
  self.timer = self.timePerTick
  return self
end

--- Updates the ticker's timer and executes its callback as necessary.
--- @param elapsed number The time since the last update
function Ticker:OnUpdate(elapsed)
  if self.isCancelled then return end

  if self.frame and not self.frame:IsVisible() then
    self.timer = self.timePerTick
    return
  end

  -- Only reached when the last tick's callback errored before cancelling.
  if self.maxTicks > 0 and self.ticks >= self.maxTicks then
    return self:Cancel()
  end

  self.timer = self.timer + elapsed
  if self.timer >= self.timePerTick then
    -- Counted before the callback, so a `Restart()` inside it is kept.
    self.timer = 0
    self.ticks = self.ticks + 1
    self.callback()

    if self.maxTicks > 0 and self.ticks >= self.maxTicks then
      self:Cancel()
    end
  end
end

-- ============================================================================
-- TickerManager
-- ============================================================================

--- Creates a new ticker which executes a callback at a specified interval,
--- up to an optional number of iterations before cancelling.
--- @param seconds number The time between each tick
--- @param callback function The function to be called on each tick
--- @param iterations? number If `0` (default), the ticker will be called indefinitely.
--- @return Ticker ticker
function TickerManager:NewTicker(seconds, callback, iterations)
  local ticker = setmetatable({
    callback = callback,
    isCancelled = false,
    maxTicks = iterations or 0,
    ticks = 0,
    timePerTick = seconds,
    timer = 0
  }, Ticker)

  queuedTickers[ticker] = true

  return ticker
end

--- Convenience method. Equivalent to:
--- ```lua
--- TickerManager:NewTicker(seconds, callback, 1)
--- ```
--- @param seconds number
--- @param callback function
--- @return Ticker ticker
function TickerManager:NewTimer(seconds, callback)
  return self:NewTicker(seconds, callback, 1)
end

--- Registers a function to be called once after a specified interval.
--- @param seconds number
--- @param callback function
function TickerManager:After(seconds, callback)
  self:NewTicker(seconds, callback, 1)
end

--- Returns a debounce function that delays invoking a callback until a specified duration of inactivity has passed.
--- @param seconds number
--- @param callback function
--- @return function debounce
function TickerManager:NewDebouncer(seconds, callback)
  local timer
  return function()
    if timer then
      timer:Restart()
    else
      timer = self:NewTimer(seconds, callback)
    end
  end
end
