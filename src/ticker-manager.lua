local Addon = select(2, ...) ---@type Addon

--- @class TickerManager
local TickerManager = Addon:GetModule("TickerManager")

--- @class Ticker
--- @field protected callback function
--- @field protected isActive boolean
--- @field protected maxTicks number
--- @field protected ticks number
--- @field protected timePerTick number
--- @field protected timer number

--- @type table<Ticker, boolean>
local activeTickers = {}

-- ============================================================================
-- Frame for updating active tickers.
-- ============================================================================

CreateFrame("Frame"):SetScript("OnUpdate", function(_, elapsed)
  for ticker in pairs(activeTickers) do ticker:OnUpdate(elapsed) end
end)

-- ============================================================================
-- Mixins
-- ============================================================================

--- @class Ticker
local TickerMixins = {}

--- Reactivates the ticker and resets its timer and tick count.
function TickerMixins:Restart()
  self.timer = 0
  self.ticks = 0
  self.isActive = true
  activeTickers[self] = true
end

--- Deactivates the ticker.
function TickerMixins:Cancel()
  self.isActive = false
  activeTickers[self] = nil
end

--- Returns `true` if the ticker is not active.
--- @return boolean
function TickerMixins:IsCancelled()
  return not self.isActive
end

--- Updates the ticker's timer and executes its callback as necessary.
--- @param elapsed number The time since the last update
function TickerMixins:OnUpdate(elapsed)
  if not self.isActive then return end
  if self.maxTicks > 0 and self.ticks >= self.maxTicks then
    return self:Cancel()
  end

  self.timer = self.timer + elapsed
  if self.timer >= self.timePerTick then
    self.timer = 0
    self.callback()
    self.ticks = self.ticks + 1
  end
end

-- ============================================================================
-- Functions
-- ============================================================================

--- Creates a new ticker which executes a callback at a specified interval,
--- up to an optional number of iterations before cancelling.
--- @param seconds number The time between each tick
--- @param callback function The function to be called on each tick
--- @param iterations? number If `0` (default), the ticker will be called indefinitely.
--- @return Ticker ticker
function TickerManager:NewTicker(seconds, callback, iterations)
  --- @class (exact) Ticker
  local ticker = {
    callback = callback,
    maxTicks = iterations or 0,
    ticks = 0,
    timePerTick = seconds,
    timer = 0
  }

  -- Mixins.
  for k, v in pairs(TickerMixins) do ticker[k] = v end

  -- Set active.
  ticker.isActive = true
  activeTickers[ticker] = true

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
