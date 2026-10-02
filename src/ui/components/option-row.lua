local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionRowOptions
--- @field get fun(): boolean
--- @field set fun(value: boolean)
--- @field onRightClick? fun()
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip)

-- =============================================================================
-- ComponentFactory - OptionRow
-- =============================================================================

--- Creates a full-width row with a checkbox beside its content. Clicking
--- anywhere on the row toggles the option.
--- @param options OptionRowOptions
--- @return OptionRowComponent root
function ComponentFactory:OptionRow(options)
  --- @class OptionRowComponent : WaffleFlexComponent
  --- @field Content WaffleFlexComponent Column beside the checkbox.
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    height = "AUTO",
    align = "START",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        enableClickHandling = true,
        onUpdateTooltip = options.onUpdateTooltip
      })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:HookScript("OnEnter", function(self) self:SetBackdropColor(Colors.White:GetRGBA(0.1)) end)
      frame:HookScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
      frame:SetClickHandler("LeftButton", "NONE", function() options.set(not options.get()) end)
      if options.onRightClick then frame:SetClickHandler("RightButton", "NONE", options.onRightClick) end
      return frame
    end
  })

  root:AddChild({
    width = 16,
    height = 16,

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
