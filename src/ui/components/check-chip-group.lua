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
--- @field justify? WaffleFlexJustify Spreads each line's chips. Defaults to `START`.

-- =============================================================================
-- ComponentFactory - CheckChipGroup
-- =============================================================================

--- Creates a dark strip of `CheckChip`s that wraps onto more lines as needed.
--- @param options CheckChipGroupComponentOptions
--- @return WaffleFlexComponent root
function ComponentFactory:CheckChipGroup(options)
  local root = Addon.Waffle:Flex({
    height = "AUTO",
    wrap = true,
    justify = options.justify or "START",
    gap = Widgets:Padding(0.5),

    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.Black:GetRGBA(0.35))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      return frame
    end
  })

  for _, chip in ipairs(options.chips) do
    root:AttachComponent(ComponentFactory:CheckChip(chip))
  end

  return root
end
