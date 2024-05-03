local _, Addon = ...
local Tooltip = Addon:GetModule("Tooltip") ---@type Tooltip
local Widgets = Addon:GetModule("Widgets") ---@class Widgets

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class FrameWidgetOptions
--- @field name? string
--- @field frameType? string
--- @field parent? table
--- @field points? table[]
--- @field width? integer
--- @field height? integer
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip)

-- =============================================================================
-- Widgets - Frame
-- =============================================================================

--- Creates a basic frame with a backdrop.
--- @param options FrameWidgetOptions
--- @return FrameWidget frame
function Widgets:Frame(options)
  -- Defaults.
  options.frameType = Addon:IfNil(options.frameType, "Frame")
  options.parent = Addon:IfNil(options.parent, UIParent)
  options.width = Addon:IfNil(options.width, 1)
  options.height = Addon:IfNil(options.height, 1)

  -- Base frame.
  local frame = CreateFrame(options.frameType, options.name, options.parent) ---@class FrameWidget
  frame:SetClipsChildren(true)

  -- Backdrop.
  Mixin(frame, BackdropTemplateMixin)
  frame:SetBackdrop(self.BORDER_BACKDROP)
  frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
  frame:SetBackdropBorderColor(0, 0, 0, 1)

  -- Size.
  frame:SetWidth(options.width)
  frame:SetHeight(options.height)

  -- Points.
  if options.points then
    for _, point in ipairs(options.points) do
      frame:SetPoint(SafeUnpack(point))
    end
  end

  -- Tooltip.
  if options.onUpdateTooltip then
    -- GameTooltip's `OnUpdate` script will call this function every 0.2 seconds.
    function frame:UpdateTooltip()
      Tooltip:SetOwner(self, "ANCHOR_TOP")
      options.onUpdateTooltip(self, Tooltip)
      Tooltip:Show()
    end

    frame:SetScript("OnEnter", frame.UpdateTooltip)
    frame:SetScript("OnLeave", function() Tooltip:Hide() end)
  end

  return frame
end
