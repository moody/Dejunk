local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class CheckChipGroupComponentOptions
--- @field chips CheckChipComponentOptions[] One `CheckChip` each, in order.
--- @field columns? integer Lays the chips out in this many equal-width columns. Cannot be used with `spread`.
--- @field spread? boolean Keeps the chips on one line, spread across it. Cannot be used with `columns`.

-- =============================================================================
-- ComponentFactory - CheckChipGroup
-- =============================================================================

--- Creates a dark strip of `CheckChip`s, sized to their labels and wrapping onto
--- more lines as needed.
--- @param options CheckChipGroupComponentOptions
--- @return WaffleFlexComponent root
function ComponentFactory:CheckChipGroup(options)
  local root = Addon.Waffle:Flex({
    height = "AUTO",
    wrap = not options.spread,
    justify = options.spread and "SPACE_BETWEEN" or "START",
    -- Columns already fill the line, so a gap would wrap the last one.
    gap = options.columns and 0 or Widgets:Padding(0.5),

    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.Black:GetRGBA(0.35))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      return frame
    end
  })

  local columnWidth = options.columns and ("%s%%"):format(100 / options.columns)

  for _, chipOptions in ipairs(options.chips) do
    local chip = root:AttachComponent(ComponentFactory:CheckChip(chipOptions))
    if columnWidth then chip:SetWidth(columnWidth) end

    -- Pass the mouse through while disabled.
    chip:WhenFrameReady(function(frame)
      --- @cast frame CheckChipWidget
      frame:PropagateWhenDisabled(true)
    end)
  end

  return root
end
