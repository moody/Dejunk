--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")
local Matchers = require("test/matchers")

-- ============================================================================
-- Setup
-- ============================================================================

local Context = Harness:NewContext()
Context:Load("src/ui/widgets/primitives/frame/frame-event-state.lua")
Context:Load("src/ui/widgets/primitives/frame/frame-events.lua")
Context:Load("src/ui/widgets/primitives/frame/events/enabled.lua")
Context:Load("src/ui/widgets/primitives/frame/events/focused.lua")
Context:Load("src/ui/widgets/primitives/frame/events/hovered.lua")

local FrameWidgetEvents = Context:GetModule("FrameWidgetEvents")

--- Returns a fake frame set up as `Widgets:Frame` does. `native` adds `SetEnabled()`, and `editBox` adds the edit
--- focus scripts.
--- @param parent? table
--- @param options? { native?: boolean, editBox?: boolean }
--- @return table
local function newFrame(parent, options)
  options = options or {}
  local frame = { parent = parent, hooks = {} }

  function frame:GetParent() return self.parent end

  function frame:GetName() return "TestFrame" end

  function frame:HookScript(name, fn)
    self.hooks[name] = self.hooks[name] or {}
    table.insert(self.hooks[name], fn)
  end

  function frame:HasScript(name)
    return options.editBox == true and name:find("EditFocus") ~= nil
  end

  if options.native then
    function frame:SetEnabled(enabled) self.nativeEnabled = enabled end
  end

  frame.OnEvent = FrameWidgetEvents.onEvent
  frame.FireEvent = FrameWidgetEvents.fireEvent
  frame.GetEventValue = FrameWidgetEvents.getEventValue
  FrameWidgetEvents:Init(frame)

  return frame
end

--- Calls the hooks of the frame for the script.
--- @param frame table
--- @param name string
local function runScript(frame, name)
  for _, fn in ipairs(frame.hooks[name] or {}) do fn(frame) end
end

--- Returns a handler that appends each `{ value, source }` it receives to `calls`.
--- @param calls table[]
--- @return function
local function recordCalls(calls)
  return function(value, source)
    table.insert(calls, { value = value, source = source })
  end
end

--- Returns the value of each call.
--- @param calls table[]
--- @return boolean[]
local function values(calls)
  local result = {}
  for _, call in ipairs(calls) do table.insert(result, call.value) end
  return result
end

--- @class TestFrameEvent
--- @field name FrameWidgetEventName Name of the event.
--- @field initial boolean Value before anything fires.
--- @field fired boolean A value other than `initial`.
--- @field bubbles boolean Whether the event also reaches the ancestors of the frame it fires on.
--- @field takesSource boolean Whether `FireEvent()` passes on a given source.

--- The events that the tests for `OnEvent()` and `FireEvent()` run on.
--- @type TestFrameEvent[]
local EVENTS = {
  { name = "HOVERED", initial = false, fired = true, bubbles = false, takesSource = true },
  { name = "FOCUSED", initial = false, fired = true, bubbles = true, takesSource = true },
  { name = "ENABLED", initial = true, fired = false, bubbles = false, takesSource = false }
}

--- Returns the events whose `field` is `value`.
--- @param field "bubbles" | "takesSource"
--- @param value boolean
--- @return TestFrameEvent[]
local function eventsWhere(field, value)
  local result = {}
  for _, event in ipairs(EVENTS) do
    if event[field] == value then table.insert(result, event) end
  end
  return result
end

--- Asserts that the value of each call is `expected`, naming the event if not.
--- @param event TestFrameEvent
--- @param calls table[]
--- @param expected boolean[]
local function assertValues(event, calls, expected)
  local equal, message = Matchers:IsDeepEqual(values(calls), expected)
  assert(equal, event.name .. ": " .. tostring(message))
end

-- ============================================================================
-- Tests - FrameWidget:OnEvent()
-- ============================================================================

-- Test: throws an error for an unknown event or a handler that is not a function.
do
  local frame = newFrame()

  assert(not pcall(frame.OnEvent, frame, "NOPE", function() end))
  assert(not pcall(frame.OnEvent, frame, "HOVERED", "not a function"))
end

-- Test: each event calls the handler right away with its current value and the frame as the source.
do
  for _, event in ipairs(EVENTS) do
    local frame = newFrame()
    local calls = {}

    frame:OnEvent(event.name, recordCalls(calls))

    assertValues(event, calls, { event.initial })
    assert(calls[1].source == frame, event.name)
  end
end

-- Test: each event's returned function removes the handler.
do
  for _, event in ipairs(EVENTS) do
    local frame = newFrame()
    local calls = {}
    local off = frame:OnEvent(event.name, recordCalls(calls))

    off()
    frame:FireEvent(event.name, event.fired)

    assertValues(event, calls, { event.initial })
  end
end

-- Test: removing a handler while its event fires does not skip the other handlers.
do
  for _, event in ipairs(EVENTS) do
    local frame = newFrame()
    local firstCalls, secondCalls = {}, {}
    local first = recordCalls(firstCalls)
    local off
    off = frame:OnEvent(event.name, function(...)
      first(...)
      if off then off() end
    end)
    frame:OnEvent(event.name, recordCalls(secondCalls))

    frame:FireEvent(event.name, event.fired)
    frame:FireEvent(event.name, event.initial)

    assertValues(event, firstCalls, { event.initial, event.fired })
    assertValues(event, secondCalls, { event.initial, event.fired, event.initial })
  end
end

-- ============================================================================
-- Tests - FrameWidget:FireEvent()
-- ============================================================================

-- Test: throws an error for an unknown event.
do
  local frame = newFrame()
  assert(not pcall(frame.FireEvent, frame, "NOPE", true))
end

-- Test: each event calls the handlers of the frame with the value and the frame as the source.
do
  for _, event in ipairs(EVENTS) do
    local frame = newFrame()
    local calls = {}
    frame:OnEvent(event.name, recordCalls(calls))

    frame:FireEvent(event.name, event.fired)

    assertValues(event, calls, { event.initial, event.fired })
    assert(calls[2].source == frame, event.name)
  end
end

-- Test: an event that takes a source calls the handlers of the frame with it.
do
  for _, event in ipairs(eventsWhere("takesSource", true)) do
    local frame, other = newFrame(), newFrame()
    local calls = {}
    frame:OnEvent(event.name, recordCalls(calls))

    frame:FireEvent(event.name, event.fired, other)

    assert(calls[2].source == other, event.name)
  end
end

-- Test: each event calls the handlers of the frame in registration order.
do
  for _, event in ipairs(EVENTS) do
    local frame = newFrame()
    local log = {}
    frame:OnEvent(event.name, function(value) if value == event.fired then table.insert(log, "first") end end)
    frame:OnEvent(event.name, function(value) if value == event.fired then table.insert(log, "second") end end)

    frame:FireEvent(event.name, event.fired)

    assert(Matchers:IsDeepEqual(log, { "first", "second" }), event.name)
  end
end

-- Test: each event stores the value, which `GetEventValue()` returns and handlers added later receive.
do
  for _, event in ipairs(EVENTS) do
    local frame = newFrame()
    local lateCalls = {}
    frame:OnEvent(event.name, function() end)

    frame:FireEvent(event.name, event.fired)
    frame:OnEvent(event.name, recordCalls(lateCalls))

    assert(frame:GetEventValue(event.name) == event.fired, event.name)
    assertValues(event, lateCalls, { event.fired })
  end
end

-- Test: an event that bubbles calls the handlers of the ancestors, not a sibling's, with the child as source.
do
  for _, event in ipairs(eventsWhere("bubbles", true)) do
    local root = newFrame()
    local container = newFrame(root)
    local child = newFrame(container)
    local sibling = newFrame(container)
    local rootCalls, containerCalls, siblingCalls, lateCalls = {}, {}, {}, {}
    root:OnEvent(event.name, recordCalls(rootCalls))
    container:OnEvent(event.name, recordCalls(containerCalls))
    sibling:OnEvent(event.name, recordCalls(siblingCalls))

    child:FireEvent(event.name, event.fired)
    root:OnEvent(event.name, recordCalls(lateCalls))

    assertValues(event, rootCalls, { event.initial, event.fired })
    assertValues(event, containerCalls, { event.initial, event.fired })
    assertValues(event, siblingCalls, { event.initial })
    assertValues(event, lateCalls, { event.fired })
    assert(rootCalls[2].source == child, event.name)
    assert(containerCalls[2].source == child, event.name)
  end
end

-- Test: an event that does not bubble calls only the handlers of the frame it fires on.
do
  for _, event in ipairs(eventsWhere("bubbles", false)) do
    local root = newFrame()
    local child = newFrame(root)
    local rootCalls, lateCalls = {}, {}
    root:OnEvent(event.name, recordCalls(rootCalls))

    child:FireEvent(event.name, event.fired)
    root:OnEvent(event.name, recordCalls(lateCalls))

    assertValues(event, rootCalls, { event.initial })
    assertValues(event, lateCalls, { event.initial })
  end
end

-- ============================================================================
-- Tests - HOVERED
-- ============================================================================

-- Test: fires as the mouse enters and leaves.
do
  local frame = newFrame()
  local calls = {}
  frame:OnEvent("HOVERED", recordCalls(calls))

  runScript(frame, "OnEnter")
  runScript(frame, "OnLeave")

  assert(Matchers:IsDeepEqual(values(calls), { false, true, false }))
end

-- Test: the mouse scripts are hooked once, when the first handler is added.
do
  local frame = newFrame()
  assert(frame.hooks.OnEnter == nil)

  frame:OnEvent("HOVERED", function() end)
  frame:OnEvent("HOVERED", function() end)

  assert(#frame.hooks.OnEnter == 1)
  assert(#frame.hooks.OnLeave == 1)
end

-- ============================================================================
-- Tests - FOCUSED
-- ============================================================================

-- Test: fires as an edit box gains and loses focus, and reaches its ancestors.
do
  local container = newFrame()
  local editBox = newFrame(container, { editBox = true })
  local editBoxCalls, containerCalls = {}, {}
  editBox:OnEvent("FOCUSED", recordCalls(editBoxCalls))
  container:OnEvent("FOCUSED", recordCalls(containerCalls))

  runScript(editBox, "OnEditFocusGained")
  runScript(editBox, "OnEditFocusLost")

  assert(Matchers:IsDeepEqual(values(editBoxCalls), { false, true, false }))
  assert(Matchers:IsDeepEqual(values(containerCalls), { false, true, false }))
end

-- Test: frames without the edit focus scripts do not hook them.
do
  local frame = newFrame()
  assert(frame.hooks.OnEditFocusGained == nil)
  assert(frame.hooks.OnEditFocusLost == nil)
end

-- ============================================================================
-- Tests - ENABLED
-- ============================================================================

-- Test: disabling a frame disables its descendants, and enabling it restores them.
do
  local root = newFrame()
  local box = newFrame(root)
  local group = newFrame(box)
  local chip = newFrame(group, { native = true })
  local calls = {}

  chip:OnEvent("ENABLED", recordCalls(calls))
  assert(chip.nativeEnabled == true)

  box:FireEvent("ENABLED", false)
  assert(chip.nativeEnabled == false)
  assert(chip:GetEventValue("ENABLED") == false)
  assert(group:GetEventValue("ENABLED") == false)
  assert(root:GetEventValue("ENABLED") == true)

  box:FireEvent("ENABLED", true)
  assert(chip.nativeEnabled == true)
  assert(chip:GetEventValue("ENABLED") == true)
  assert(Matchers:IsDeepEqual(values(calls), { true, false, true }))
end

-- Test: a frame created under a disabled ancestor starts disabled.
do
  local box = newFrame()
  box:FireEvent("ENABLED", false)

  local chip = newFrame(box, { native = true })
  assert(chip.nativeEnabled == false)
  assert(chip:GetEventValue("ENABLED") == false)

  local calls = {}
  chip:OnEvent("ENABLED", recordCalls(calls))
  assert(Matchers:IsDeepEqual(values(calls), { false }))
end

-- Test: a frame that was disabled itself stays disabled when its ancestor is enabled again.
do
  local box = newFrame()
  local chip = newFrame(box, { native = true })

  chip:FireEvent("ENABLED", false)
  box:FireEvent("ENABLED", false)
  box:FireEvent("ENABLED", true)

  assert(chip:GetEventValue("ENABLED") == false)
  assert(chip.nativeEnabled == false)

  chip:FireEvent("ENABLED", true)

  assert(chip:GetEventValue("ENABLED") == true)
  assert(chip.nativeEnabled == true)
end

-- Test: handlers are called only when the effective value changes.
do
  local box = newFrame()
  local calls = {}
  box:OnEvent("ENABLED", recordCalls(calls))

  box:FireEvent("ENABLED", true)
  box:FireEvent("ENABLED", false)
  box:FireEvent("ENABLED", false)

  assert(Matchers:IsDeepEqual(values(calls), { true, false }))
end

-- Test: an ancestor that is not part of the event system does not break the chain.
do
  local root = newFrame()
  local outsider = { GetParent = function() return root end }
  local child = newFrame(outsider, { native = true })

  root:FireEvent("ENABLED", false)

  assert(child.nativeEnabled == false)
  assert(child:GetEventValue("ENABLED") == false)
end
