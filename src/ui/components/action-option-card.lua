local Addon = select(2, ...) ---@type Addon

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ActionOptionCardOptions : OptionCardBaseOptions
--- @field icon string Texture shown beside the content.
--- @field onLeftClick fun() Called when the card is left-clicked.

-- =============================================================================
-- ComponentFactory - ActionOptionCard
-- =============================================================================

--- Creates an `OptionCard` with an icon beside its content. Clicking the card calls `onLeftClick`.
--- @param options ActionOptionCardOptions
--- @return ActionOptionCardComponent root
function ComponentFactory:ActionOptionCard(options)
  --- @class ActionOptionCardComponent : OptionCardComponent
  local root = ComponentFactory:OptionCard({
    leading = Addon.Waffle:Flex({
      width = ComponentFactory.OPTION_CARD_LEADING_SIZE,
      height = ComponentFactory.OPTION_CARD_LEADING_SIZE,

      --- @param parent Frame
      frameFactory = function(parent)
        local texture = parent:CreateTexture(nil, "ARTWORK")
        texture:SetTexture(options.icon)
        return texture
      end
    }),
    onLeftClick = options.onLeftClick,
    onRightClick = options.onRightClick,
    onUpdateTooltip = options.onUpdateTooltip
  })

  return root
end
