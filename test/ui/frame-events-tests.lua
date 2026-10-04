--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")
local Matchers = require("test/matchers")

-- ============================================================================
-- Setup
-- ============================================================================

Harness:Load("src/ui/widgets/primitives/frame/frame-event-state.lua")
Harness:Load("src/ui/widgets/primitives/frame/frame-events.lua")
Harness:Load("src/ui/widgets/primitives/frame/events/enabled.lua")
Harness:Load("src/ui/widgets/primitives/frame/events/focused.lua")
Harness:Load("src/ui/widgets/primitives/frame/events/hovered.lua")

local Addon = Harness.Addon
local FrameWidgetEvents = Addon:GetModule("FrameWidgetEvents")

--- Returns a fake frame set up the way `Widgets:Frame` sets one up. `options.native` gives it a `SetEnabled()`
--- method, and `options.editBox` gives it the edit focus scripts.
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

--- Calls the hooks that the frame has for the script, as the game does.
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

-- ============================================================================
-- Tests - FrameWidget:OnEvent()
-- ============================================================================

-- Test: the handler is called right away with the current value and the frame as the source.
do
  local frame = newFrame()
  local calls = {}

  frame:OnEvent("HOVERED", recordCalls(calls))

  assert(Matchers:IsDeepEqual(values(calls), { false }))
  assert(calls[1].source == frame)
end

-- Test: throws an error for an unknown event or a handler that is not a function.
do
  local frame = newFrame()

  assert(not pcall(frame.OnEvent, frame, "NOPE", function() end))
  assert(not pcall(frame.OnEvent, frame, "HOVERED", "not a function"))
end

-- Test: the returned function removes the handler.
do
  local frame = newFrame()
  local calls = {}
  local off = frame:OnEvent("HOVERED", recordCalls(calls))

  off()
  frame:FireEvent("HOVERED", true)

  assert(Matchers:IsDeepEqual(values(calls), { false }))
end

-- Test: removing a handler while the event fires does not skip the other handlers.
do
  local frame = newFrame()
  local firstCalls, secondCalls = {}, {}
  local first = recordCalls(firstCalls)
  local off
  off = frame:OnEvent("HOVERED", function(...)
    first(...)
    if off then off() end
  end)
  frame:OnEvent("HOVERED", recordCalls(secondCalls))

  frame:FireEvent("HOVERED", true)
  frame:FireEvent("HOVERED", false)

  assert(Matchers:IsDeepEqual(values(firstCalls), { false, true }))
  assert(Matchers:IsDeepEqual(values(secondCalls), { false, true, false }))
end

-- ============================================================================
-- Tests - FrameWidget:FireEvent()
-- ============================================================================

-- Test: throws an error for an unknown event.
do
  local frame = newFrame()
  assert(not pcall(frame.FireEvent, frame, "NOPE", true))
end

-- ============================================================================
-- Tests - HOVERED
-- ============================================================================

-- Test: fires as the mouse enters and leaves, and later handlers receive the last value.
do
  local frame = newFrame()
  local calls = {}
  frame:OnEvent("HOVERED", recordCalls(calls))

  runScript(frame, "OnEnter")
  runScript(frame, "OnLeave")
  runScript(frame, "OnEnter")

  local lateCalls = {}
  frame:OnEvent("HOVERED", recordCalls(lateCalls))

  assert(Matchers:IsDeepEqual(values(calls), { false, true, false, true }))
  assert(Matchers:IsDeepEqual(values(lateCalls), { true }))
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

-- Test: bubbles from an edit box to its ancestors, but not to its siblings.
do
  local root = newFrame()
  local container = newFrame(root)
  local editBox = newFrame(container, { editBox = true })
  local sibling = newFrame(container)
  local rootCalls = {}
  local containerCalls = {}
  local siblingCalls = {}

  root:OnEvent("FOCUSED", recordCalls(rootCalls))
  container:OnEvent("FOCUSED", recordCalls(containerCalls))
  sibling:OnEvent("FOCUSED", recordCalls(siblingCalls))

  runScript(editBox, "OnEditFocusGained")
  runScript(editBox, "OnEditFocusLost")

  assert(Matchers:IsDeepEqual(values(rootCalls), { false, true, false }))
  assert(Matchers:IsDeepEqual(values(containerCalls), { false, true, false }))
  assert(Matchers:IsDeepEqual(values(siblingCalls), { false }))
  assert(rootCalls[2].source == editBox)
  assert(containerCalls[2].source == editBox)
end

-- Test: a handler added to an ancestor later receives the last value that passed through it.
do
  local container = newFrame()
  local editBox = newFrame(container, { editBox = true })
  runScript(editBox, "OnEditFocusGained")
  local calls = {}

  container:OnEvent("FOCUSED", recordCalls(calls))

  assert(Matchers:IsDeepEqual(values(calls), { true }))
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

-- Test: a frame without a native `SetEnabled()` can be disabled.
do
  local frame = newFrame()
  frame:FireEvent("ENABLED", false)
  assert(frame:GetEventValue("ENABLED") == false)
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
