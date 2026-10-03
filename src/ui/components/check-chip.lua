local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class CheckChipComponentOptions
--- @field text string Label beside the checkbox.
--- @field color? Color Checkbox color. Defaults to `Colors.Blue`.
--- @field get fun(): boolean Returns whether the chip is checked.
--- @field set fun(value: boolean) Called with the new value when clicked.

-- =============================================================================
-- ComponentFactory - CheckChip
-- =============================================================================

--- Creates a small checkbox and label, sized to the label. Clicking anywhere on
--- the chip toggles it.
--- @param options CheckChipComponentOptions
--- @return WaffleFlexComponent root
function ComponentFactory:CheckChip(options)
  local chip
  local isHovered = false

  --- Applies hover and checked colors to the chip and its label.
  local function refresh()
    local frame, label = chip:GetFrame(), chip.Label:GetFrame()
    if frame then frame:SetBackdropColor(Colors.White:GetRGBA(isHovered and 0.08 or 0)) end
    if label then label:SetTextColor(((isHovered or options.get()) and Colors.White or Colors.Grey):GetRGB()) end
  end

  --- @class CheckChipComponent : WaffleFlexComponent
  chip = Addon.Waffle:Flex({
    width = "AUTO",
    height = "AUTO",
    align = "CENTER",
    paddingTop = Widgets.CONTROL_PADDING,
    paddingRight = Widgets:Padding(),
    paddingBottom = Widgets.CONTROL_PADDING,
    paddingLeft = Widgets:Padding(),
    gap = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      --- @class CheckChipWidget : FrameWidget, Button
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      frame:SetScript("OnClick", function() options.set(not options.get()) end)
      frame:SetScript("OnEnter", function()
        isHovered = true
        refresh()
      end)
      frame:SetScript("OnLeave", function()
        isHovered = false
        refresh()
      end)

      EventManager:On(E.StateUpdated, refresh)

      return frame
    end
  })

  -- Checkbox.
  chip:AddChild({
    width = 12,
    height = 12,
    shrink = 0,

    --- @param parent Frame
    frameFactory = function(parent)
      local checkBox = Widgets:CheckBox({
        parent = parent,
        color = options.color,
        get = options.get,
        set = options.set
      })
      checkBox:EnableMouse(false)
      return checkBox
    end
  })

  chip.Label = chip:AttachComponent(ComponentFactory:Text({
    width = "AUTO",
    text = options.text,
    fontObject = Widgets.CONTROL_FONT
  }))
  chip.Label:WhenFrameReady(refresh)

  return chip
end
