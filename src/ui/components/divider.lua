local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class DividerComponentOptions
--- @field orientation? "HORIZONTAL" | "VERTICAL" Defaults to `HORIZONTAL`.
--- @field color? Color Defaults to `Colors.White`.
--- @field alpha? number Defaults to `0.08`.

-- =============================================================================
-- ComponentFactory - Divider
-- =============================================================================

--- Creates a 1px line spanning its parent's cross axis.
--- @param options? DividerComponentOptions
--- @return WaffleFlexComponent root
function ComponentFactory:Divider(options)
  options = options or {}
  options.orientation = Addon:IfNil(options.orientation, "HORIZONTAL")
  options.color = Addon:IfNil(options.color, Colors.White)
  options.alpha = Addon:IfNil(options.alpha, 0.08)

  local axis = (options.orientation == "VERTICAL") and "width" or "height"

  return Addon.Waffle:Flex({
    [axis] = 1,
    alignSelf = "STRETCH",

    --- @param parent Frame
    frameFactory = function(parent)
      local texture = parent:CreateTexture(nil, "ARTWORK")
      texture:SetColorTexture(options.color:GetRGBA(options.alpha))
      return texture
    end
  })
end
