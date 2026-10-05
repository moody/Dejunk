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
  --- @class CheckChipComponent : WaffleFlexComponent
  local chip = Addon.Waffle:Flex({
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
      return frame
    end
  })

  chip.Checkbox = chip:AddChild({
    width = 12,
    height = 12,
    shrink = 0,

    --- @param parent Frame
    frameFactory = function(parent)
      return Widgets:CheckBox({ parent = parent, color = options.color })
    end
  })

  chip.Label = chip:AttachComponent(ComponentFactory:Text({
    width = "AUTO",
    text = options.text,
    fontObject = Widgets.CONTROL_FONT
  }))

  -- Refresh on hover, enabled, and state changes.
  chip.Label:WhenFrameReady(function(label)
    chip.Checkbox:WhenFrameReady(function(checkbox)
      --- @cast checkbox CheckBoxWidget
      --- @type FrameWidget
      local frame = chip:GetFrame()

      --- Applies hover and checked colors to the chip and its label, and updates the checkbox.
      --- Disabled chips are not highlighted.
      local function refresh()
        local isHovered = frame:GetEventValue("HOVERED") and frame:GetEventValue("ENABLED")
        local isChecked = options.get()
        frame:SetBackdropColor(Colors.White:GetRGBA(isHovered and 0.08 or 0))
        label:SetTextColor(((isHovered or isChecked) and Colors.White or Colors.Grey):GetRGB())
        checkbox:SetChecked(isChecked)
        checkbox:FireEvent("HOVERED", frame:GetEventValue("HOVERED"))
      end

      frame:OnEvent("HOVERED", refresh)
      frame:OnEvent("ENABLED", refresh)
      EventManager:On(E.StateUpdated, refresh)
    end)
  end)

  return chip
end
