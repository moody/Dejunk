local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionCardBaseOptions
--- @field onRightClick? fun() Called when the card is right-clicked.
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip) Shown while hovering the card.

--- @class OptionCardOptions : OptionCardBaseOptions
--- @field leading? WaffleFlexComponent Component shown beside the content.
--- @field onLeftClick? fun() Called when the card is left-clicked.

-- =============================================================================
-- ComponentFactory - OptionCard
-- =============================================================================

--- Creates a full-width card with its content in a column, beside a `leading` component.
--- @param options OptionCardOptions
--- @return OptionCardComponent root
function ComponentFactory:OptionCard(options)
  --- @class OptionCardComponent : WaffleFlexComponent
  --- @field Content WaffleFlexComponent Column beside the leading component.
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    height = "AUTO",
    align = "START",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        enableClickHandling = true,
        onUpdateTooltip = options.onUpdateTooltip
      })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.03))
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      -- Brighten while hovered.
      frame:OnEvent("HOVERED", function()
        frame:SetBackdropColor(Colors.White:GetRGBA(frame:GetEventValue("HOVERED") and 0.06 or 0.03))
      end)

      if options.onLeftClick then frame:SetClickHandler("LeftButton", "NONE", options.onLeftClick) end
      if options.onRightClick then frame:SetClickHandler("RightButton", "NONE", options.onRightClick) end
      return frame
    end
  })

  if options.leading then root:AttachComponent(options.leading) end

  root.Content = root:AddColumn({ height = "AUTO", gap = Widgets:Padding(0.25) })

  return root
end
