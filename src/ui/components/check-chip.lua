local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

local HEIGHT = 24
local CHECK_BOX_SIZE = 12

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
  return Addon.Waffle:Flex({
    width = "AUTO",
    height = HEIGHT,

    --- @param parent Frame
    frameFactory = function(parent)
      --- @class CheckChipWidget : FrameWidget, Button
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      local isHovered = false

      local checkBox = Widgets:CheckBox({
        parent = frame,
        points = { { "LEFT", Widgets:Padding(0.75), 0 } },
        width = CHECK_BOX_SIZE,
        height = CHECK_BOX_SIZE,
        color = options.color,
        get = options.get,
        set = options.set
      })
      checkBox:EnableMouse(false)

      frame.label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
      frame.label:SetPoint("LEFT", checkBox, "RIGHT", Widgets:Padding(0.5), 0)
      frame.label:SetText(options.text)

      local function refresh()
        frame:SetBackdropColor(Colors.White:GetRGBA(isHovered and 0.08 or 0))
        local isLit = isHovered or options.get()
        frame.label:SetTextColor((isLit and Colors.White or Colors.Grey):GetRGB())
      end

      frame:SetScript("OnClick", function() options.set(not options.get()) end)
      frame:SetScript("OnEnter", function()
        isHovered = true
        refresh()
      end)
      frame:SetScript("OnLeave", function()
        isHovered = false
        refresh()
      end)

      refresh()
      EventManager:On(E.StateUpdated, refresh)

      return frame
    end,

    --- @param frame CheckChipWidget
    onMeasure = function(frame)
      local padding = Widgets:Padding(0.75)
      return padding + CHECK_BOX_SIZE + Widgets:Padding(0.5) + frame.label:GetStringWidth() + padding, HEIGHT
    end
  })
end
