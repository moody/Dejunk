local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionCardOptions
--- @field get fun(): boolean Returns whether the option is on.
--- @field set fun(value: boolean) Called with the new value when the card is clicked.
--- @field onRightClick? fun() Called when the card is right-clicked.
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip) Shown while hovering the card.

-- =============================================================================
-- ComponentFactory - OptionCard
-- =============================================================================

--- Creates a full-width card with a checkbox beside its content. Clicking
--- anywhere on the card toggles the option.
--- @param options OptionCardOptions
--- @return OptionCardComponent root
function ComponentFactory:OptionCard(options)
  --- @class OptionCardComponent : WaffleFlexComponent
  --- @field Content WaffleFlexComponent Column beside the checkbox.
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
      frame:HookScript("OnEnter", function(self) self:SetBackdropColor(Colors.White:GetRGBA(0.06)) end)
      frame:HookScript("OnLeave", function(self) self:SetBackdropColor(Colors.White:GetRGBA(0.03)) end)
      frame:SetClickHandler("LeftButton", "NONE", function() options.set(not options.get()) end)
      if options.onRightClick then frame:SetClickHandler("RightButton", "NONE", options.onRightClick) end
      return frame
    end
  })

  root:AddChild({
    width = 18,
    height = 18,

    --- @param parent Frame
    frameFactory = function(parent)
      local checkBox = Widgets:CheckBox({ parent = parent, get = options.get, set = options.set })
      checkBox:EnableMouse(false)
      return checkBox
    end
  })

  root.Content = root:AddColumn({ height = "AUTO", gap = Widgets:Padding(0.25) })

  return root
end
