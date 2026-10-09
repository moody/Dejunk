local Addon = select(2, ...) ---@type Addon
local FrameWidgetEvents = Addon:GetModule("FrameWidgetEvents")

-- =============================================================================
-- FOCUSED
-- =============================================================================

--- Fires as an edit box gains and loses focus, and bubbles to its ancestors.
--- @class FrameWidgetFocusedEvent : FrameWidgetEvent
local Focused = FrameWidgetEvents:Register("FOCUSED", true)

--- Watches the focus of frames that can have it.
--- @param frame FrameWidget
function Focused:Init(frame)
  if not frame:HasScript("OnEditFocusGained") then return end

  frame:HookScript("OnEditFocusGained", function() frame:FireEvent("FOCUSED", true) end)
  frame:HookScript("OnEditFocusLost", function() frame:FireEvent("FOCUSED", false) end)
end
