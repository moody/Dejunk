local Addon = select(2, ...) ---@type Addon
local FrameWidgetEvents = Addon:GetModule("FrameWidgetEvents")

-- =============================================================================
-- HOVERED
-- =============================================================================

--- Fires as the mouse enters and leaves the frame.
--- @class FrameWidgetHoveredEvent : FrameWidgetEvent
local Hovered = FrameWidgetEvents:Register("HOVERED")

--- Starts watching the mouse once the frame has a handler. The frame is not hovered until the mouse enters it.
--- @param frame FrameWidget
function Hovered:Listen(frame)
  frame:HookScript("OnEnter", function() frame:FireEvent("HOVERED", true) end)
  frame:HookScript("OnLeave", function() frame:FireEvent("HOVERED", false) end)
end
