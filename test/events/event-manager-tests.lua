--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `EventManager`, `Events`, and the event frame it creates, from a new context.
--- @return EventManager EventManager
--- @return table E
--- @return MockFrame eventFrame
local function loadEventManager()
  local eventFrame = Mocks:CreateFrame()

  local Context = Harness:NewContext()
  Context:SetGlobal("CreateFrame", function() return eventFrame end)
  Context:Load("src/events/events.lua")
  Context:Load("src/events/event-manager.lua")

  return Context:GetModule("EventManager"), Context:GetModule("Events"), eventFrame
end

--- Returns a function that appends `name` to `log` when called.
--- @param log string[]
--- @param name string
--- @return function
local function record(log, name)
  return function() table.insert(log, name) end
end

--- Returns a function that appends its arguments, and how many it received, to `calls` when called.
--- @param calls table[]
--- @return function
local function captureArgs(calls)
  return function(...) table.insert(calls, { n = select("#", ...), ... }) end
end

-- ============================================================================
-- Tests - EventManager:On()
-- ============================================================================

-- Test: the function is called every time the event fires, with the event's arguments.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local calls = {}
  EventManager:On(event, captureArgs(calls))

  EventManager:Fire(event, "a", nil, "c")
  EventManager:Fire(event)

  assert(Matchers:IsDeepEqual(calls, { { n = 3, "a", nil, "c" }, { n = 0 } }))
end

-- Test: functions are called in registration order.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  EventManager:On(event, record(log, "first"))
  EventManager:On(event, record(log, "second"))
  EventManager:On(event, record(log, "third"))

  EventManager:Fire(event)
  EventManager:Fire(event)

  assert(Matchers:IsDeepEqual(log, { "first", "second", "third", "first", "second", "third" }))
end

-- Test: functions registered for other events are not called.
do
  local EventManager = loadEventManager()

  local event, otherEvent = "TEST_EVENT", "OTHER_EVENT"
  local log = {}
  EventManager:On(event, record(log, "event"))
  EventManager:On(otherEvent, record(log, "otherEvent"))

  EventManager:Fire(event)

  assert(Matchers:IsDeepEqual(log, { "event" }))
end

-- Test: a function registered twice for the same event is called once per fire, in its first position.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  local duplicate = record(log, "duplicate")
  EventManager:On(event, duplicate)
  EventManager:On(event, record(log, "other"))
  EventManager:On(event, duplicate)

  EventManager:Fire(event)

  assert(Matchers:IsDeepEqual(log, { "duplicate", "other" }))
end

-- Test: the same function can be registered for different events.
do
  local EventManager = loadEventManager()

  local event, otherEvent = "TEST_EVENT", "OTHER_EVENT"
  local log = {}
  local func = record(log, "func")
  EventManager:On(event, func)
  EventManager:On(otherEvent, func)

  EventManager:Fire(event)
  EventManager:Fire(otherEvent)

  assert(#log == 2)
end

-- Test: a function registered with `Once()` stays registered when it is registered with `On()` again.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  local func = record(log, "func")
  EventManager:Once(event, func)
  EventManager:On(event, func)

  EventManager:Fire(event)
  EventManager:Fire(event)

  assert(#log == 2)
end

-- Test: a function registered while the event fires is first called the next time it fires.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  local registered = false
  EventManager:On(event, function()
    table.insert(log, "early")

    if not registered then
      registered = true
      EventManager:On(event, record(log, "late"))
    end
  end)

  EventManager:Fire(event)
  assert(Matchers:IsDeepEqual(log, { "early" }))

  EventManager:Fire(event)
  assert(Matchers:IsDeepEqual(log, { "early", "early", "late" }))
end

-- Test: an invalid event or function throws an error.
do
  local EventManager = loadEventManager()
  assert(not pcall(EventManager.On, EventManager, nil, function() end))
  assert(not pcall(EventManager.On, EventManager, 1, function() end))
  assert(not pcall(EventManager.On, EventManager, "TEST_EVENT", nil))
  assert(not pcall(EventManager.On, EventManager, "TEST_EVENT", "not a function"))
end

-- ============================================================================
-- Tests - EventManager:Once()
-- ============================================================================

-- Test: the function is called the next time the event fires, with the event's arguments, and not again.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local calls = {}
  EventManager:Once(event, captureArgs(calls))

  assert(#calls == 0)
  EventManager:Fire(event, "a", "b")
  EventManager:Fire(event, "c")

  assert(Matchers:IsDeepEqual(calls, { { n = 2, "a", "b" } }))
end

-- Test: functions are called in registration order, mixed with `On()`.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  EventManager:On(event, record(log, "on1"))
  EventManager:Once(event, record(log, "once"))
  EventManager:On(event, record(log, "on2"))

  EventManager:Fire(event)
  assert(Matchers:IsDeepEqual(log, { "on1", "once", "on2" }))

  EventManager:Fire(event)
  assert(Matchers:IsDeepEqual(log, { "on1", "once", "on2", "on1", "on2" }))
end

-- Test: the remaining functions keep their order after the others are removed.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  EventManager:Once(event, record(log, "once1"))
  EventManager:On(event, record(log, "on1"))
  EventManager:Once(event, record(log, "once2"))
  EventManager:On(event, record(log, "on2"))

  EventManager:Fire(event)
  EventManager:Fire(event)

  assert(Matchers:IsDeepEqual(log, { "once1", "on1", "once2", "on2", "on1", "on2" }))
end

-- Test: a function registered twice is called once.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  local func = record(log, "func")
  EventManager:Once(event, func)
  EventManager:Once(event, func)

  EventManager:Fire(event)
  EventManager:Fire(event)

  assert(#log == 1)
end

-- Test: a function that registers itself again is called the next time the event fires.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local calls = 0
  local function func()
    calls = calls + 1
    if calls < 3 then EventManager:Once(event, func) end
  end
  EventManager:Once(event, func)

  for _ = 1, 5 do EventManager:Fire(event) end

  assert(calls == 3)
end

-- Test: a function can be registered again after it was called.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  local func = record(log, "func")
  EventManager:Once(event, func)
  EventManager:Fire(event)

  EventManager:Once(event, func)
  EventManager:Fire(event)
  EventManager:Fire(event)

  assert(#log == 2)
end

-- Test: a function is called once when the event fires again from inside it.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local calls = 0
  EventManager:Once(event, function()
    calls = calls + 1
    EventManager:Fire(event)
  end)

  EventManager:Fire(event)

  assert(calls == 1)
end

-- Test: an invalid event or function throws an error.
do
  local EventManager = loadEventManager()
  assert(not pcall(EventManager.Once, EventManager, nil, function() end))
  assert(not pcall(EventManager.Once, EventManager, "TEST_EVENT", nil))
end

-- ============================================================================
-- Tests - EventManager:WaitForFirst()
-- ============================================================================

-- Test: the function waits for the event, is called once, and is not called by later fires.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  EventManager:WaitForFirst(event, record(log, "func"))
  assert(#log == 0)

  EventManager:Fire(event)
  EventManager:Fire(event)

  assert(#log == 1)
end

-- Test: the function is not called by other events.
do
  local EventManager = loadEventManager()

  local event, otherEvent = "TEST_EVENT", "OTHER_EVENT"
  local log = {}
  EventManager:WaitForFirst(event, record(log, "func"))

  EventManager:Fire(otherEvent)

  assert(#log == 0)
end

-- Test: the function is called immediately if the event already fired, and not again.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  EventManager:Fire(event)

  EventManager:WaitForFirst(event, record(log, "func"))
  assert(#log == 1)

  EventManager:Fire(event)
  assert(#log == 1)
end

-- Test: the function is called with no arguments, whether it waited or not.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local calls = {}
  EventManager:WaitForFirst(event, captureArgs(calls))
  EventManager:Fire(event, "a", "b")

  EventManager:WaitForFirst(event, captureArgs(calls))

  assert(Matchers:IsDeepEqual(calls, { { n = 0 }, { n = 0 } }))
end

-- Test: waiting functions are called in registration order, mixed with `On()`.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  EventManager:WaitForFirst(event, record(log, "wait1"))
  EventManager:On(event, record(log, "on"))
  EventManager:WaitForFirst(event, record(log, "wait2"))

  EventManager:Fire(event)

  assert(Matchers:IsDeepEqual(log, { "wait1", "on", "wait2" }))
end

-- Test: the function is called immediately when it is registered by a function of the same event.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  EventManager:On(event, function()
    EventManager:WaitForFirst(event, record(log, "func"))
  end)

  EventManager:Fire(event)

  assert(#log == 1)
end

-- Test: the same function can wait for different events.
do
  local EventManager = loadEventManager()

  local event, otherEvent = "TEST_EVENT", "OTHER_EVENT"
  local log = {}
  local func = record(log, "func")
  EventManager:WaitForFirst(event, func)
  EventManager:WaitForFirst(otherEvent, func)

  EventManager:Fire(event)
  EventManager:Fire(otherEvent)

  assert(#log == 2)
end

-- Test: an invalid event or function throws an error.
do
  local EventManager = loadEventManager()
  assert(not pcall(EventManager.WaitForFirst, EventManager, nil, function() end))
  assert(not pcall(EventManager.WaitForFirst, EventManager, "TEST_EVENT", nil))
end

-- ============================================================================
-- Tests - EventManager:Fire()
-- ============================================================================

-- Test: an event with no registered functions does nothing.
do
  local EventManager = loadEventManager()
  EventManager:Fire("TEST_EVENT", "a", "b")
end

-- Test: an invalid event throws an error.
do
  local EventManager = loadEventManager()
  assert(not pcall(EventManager.Fire, EventManager, nil))
  assert(not pcall(EventManager.Fire, EventManager, true))
  assert(not pcall(EventManager.Fire, EventManager, 1))
  assert(not pcall(EventManager.Fire, EventManager, function() end))
end

-- Test: every argument is passed on, including trailing `nil`s.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local calls = {}
  EventManager:On(event, captureArgs(calls))

  EventManager:Fire(event, 1, nil, nil)

  assert(calls[1].n == 3)
end

-- Test: a nested fire of the same event runs to the end before the outer fire continues.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  local nested = false
  EventManager:On(event, function()
    table.insert(log, "first")

    if not nested then
      nested = true
      EventManager:Fire(event)
    end
  end)
  EventManager:On(event, record(log, "second"))

  EventManager:Fire(event)

  assert(Matchers:IsDeepEqual(log, { "first", "first", "second", "second" }))
end

-- Test: every function is called once when a nested fire removes functions registered with `Once()`.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  local nested = false
  EventManager:On(event, function()
    table.insert(log, "first")

    if not nested then
      nested = true
      EventManager:Fire(event)
    end
  end)
  EventManager:Once(event, record(log, "once"))
  EventManager:On(event, record(log, "last"))

  EventManager:Fire(event)

  assert(Matchers:IsDeepEqual(log, { "first", "first", "once", "last", "last" }))
end

-- Test: a function that throws an error stops the fire, and is removed if it was registered with `Once()`.
do
  local EventManager = loadEventManager()

  local event = "TEST_EVENT"
  local log = {}
  EventManager:Once(event, function() error("expected") end)
  EventManager:On(event, record(log, "on"))
  EventManager:Once(event, record(log, "once"))

  assert(not pcall(EventManager.Fire, EventManager, event))
  assert(#log == 0)

  EventManager:Fire(event)
  assert(Matchers:IsDeepEqual(log, { "on", "once" }))

  EventManager:Fire(event)
  assert(Matchers:IsDeepEqual(log, { "on", "once", "on" }))
end

-- ============================================================================
-- Tests - Event Frame
-- ============================================================================

-- Test: every WoW event is registered with the event frame.
do
  local _, E, eventFrame = loadEventManager()
  for _, event in pairs(E.Wow) do
    assert(eventFrame._test.registered[event], event)
  end
end

-- Test: an event the event frame receives is fired with its arguments.
do
  local EventManager, E, eventFrame = loadEventManager()

  local calls = {}
  EventManager:On(E.Wow.PlayerLogin, captureArgs(calls))

  eventFrame._test.scripts.OnEvent(eventFrame, E.Wow.PlayerLogin, "a", "b")

  assert(Matchers:IsDeepEqual(calls, { { n = 2, "a", "b" } }))
end
