--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

local Context = Harness:NewContext(function(globals)
  globals.CreateFrame = function(frameType, _, parent) return Mocks:CreateFrame(frameType, parent) end
  globals.UIParent = Mocks:CreateFrame()
end)

Context:Load("src/ui/widgets/primitives/frame/frame-event-state.lua")
Context:Load("src/ui/widgets/primitives/frame/frame-events.lua")
Context:Load("src/ui/widgets/primitives/frame/events/enabled.lua")
Context:Load("src/ui/widgets/primitives/frame/events/focused.lua")
Context:Load("src/ui/widgets/primitives/frame/events/hovered.lua")
Context:Load("src/ui/widgets/primitives/frame/frame.lua")

local Widgets = Context:GetModule("Widgets")

--- Returns a widget frame without a backdrop. Defaults to a `Button`.
--- @param options? FrameWidgetOptions
--- @return FrameWidget
local function newFrame(options)
  options = options or {}
  options.name = "TestFrame"
  options.backdrop = false
  options.frameType = options.frameType or "Button"
  return Widgets:Frame(options)
end

--- The values that the frame records for each expected propagation.
local PROPAGATIONS = {
  PASSES = { clicks = true, motion = true },
  BLOCKS = { clicks = false, motion = false }
}

--- Asserts that the frame passes its clicks and motion through (`PASSES`) or does not (`BLOCKS`).
--- @param frame table
--- @param expected "PASSES" | "BLOCKS"
local function assertPropagation(frame, expected)
  local actual = { clicks = frame._test.propagatesClicks, motion = frame._test.propagatesMotion }
  assert(Matchers:IsDeepEqual(actual, PROPAGATIONS[expected]))
end

-- ============================================================================
-- Tests - FrameWidget:PropagateWhenDisabled()
-- ============================================================================

-- Test: a frame does not pass the mouse through by default.
do
  local frame = newFrame()
  frame:FireEvent("ENABLED", false)
  assertPropagation(frame, "BLOCKS")
end

-- Test: passes clicks and motion through only while the frame is disabled.
do
  local frame = newFrame()

  frame:PropagateWhenDisabled(true)
  assertPropagation(frame, "BLOCKS")

  frame:FireEvent("ENABLED", false)
  assertPropagation(frame, "PASSES")

  frame:FireEvent("ENABLED", true)
  assertPropagation(frame, "BLOCKS")
end

-- Test: passes the mouse through right away when the frame is already disabled.
do
  local frame = newFrame()
  frame:FireEvent("ENABLED", false)
  frame:PropagateWhenDisabled(true)
  assertPropagation(frame, "PASSES")
end

-- Test: passes the mouse through while an ancestor is disabled.
do
  local parent = newFrame({ frameType = "Frame" })
  local child = newFrame({ parent = parent })
  child:PropagateWhenDisabled(true)

  parent:FireEvent("ENABLED", false)
  assertPropagation(child, "PASSES")

  parent:FireEvent("ENABLED", true)
  assertPropagation(child, "BLOCKS")
end

-- Test: passing `false` stops the frame from passing the mouse through.
do
  local frame = newFrame()
  frame:PropagateWhenDisabled(true)
  frame:FireEvent("ENABLED", false)

  frame:PropagateWhenDisabled(false)
  assertPropagation(frame, "BLOCKS")

  frame:FireEvent("ENABLED", true)
  frame:FireEvent("ENABLED", false)
  assertPropagation(frame, "BLOCKS")
end

-- Test: calling it again after passing `false` passes the mouse through again.
do
  local frame = newFrame()
  frame:PropagateWhenDisabled(false)
  frame:FireEvent("ENABLED", false)

  frame:PropagateWhenDisabled(true)

  assertPropagation(frame, "PASSES")
end

-- Test: throws an error when not given a boolean.
do
  local frame = newFrame()
  assert(not pcall(frame.PropagateWhenDisabled, frame))
  assert(not pcall(frame.PropagateWhenDisabled, frame, "yes"))
end

-- Test: returns the frame.
do
  local frame = newFrame()
  assert(frame:PropagateWhenDisabled(true) == frame)
  assert(frame:PropagateWhenDisabled(false) == frame)
end

-- ============================================================================
-- Tests - Widgets:Frame() propagateWhenDisabled
-- ============================================================================

-- Test: the `propagateWhenDisabled` option passes the mouse through while the frame is disabled.
do
  local frame = newFrame({ propagateWhenDisabled = true })

  frame:FireEvent("ENABLED", false)
  assertPropagation(frame, "PASSES")

  frame:FireEvent("ENABLED", true)
  assertPropagation(frame, "BLOCKS")
end
