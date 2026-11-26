local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ItemIconComponentOptions
--- @field size integer Width and height of the icon.

-- =============================================================================
-- ComponentFactory - ItemIcon
-- =============================================================================

--- Creates the icon of an item, with its stack count in the bottom right corner.
--- @param options ItemIconComponentOptions
--- @return ItemIconComponent root
function ComponentFactory:ItemIcon(options)
  local icon ---@type Texture?
  local count ---@type FontString?
  local texture ---@type (string | number)?
  local isDesaturated = false
  local countText = ""

  --- @class ItemIconComponent : WaffleFlexComponent<Texture>
  local root = Addon.Waffle:Flex({
    width = options.size,
    height = options.size,

    --- @param parent Frame
    frameFactory = function(parent)
      icon = parent:CreateTexture(nil, "ARTWORK")
      icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      icon:SetTexture(texture)
      icon:SetDesaturated(isDesaturated)

      -- Stack count, in the bottom right corner of the icon.
      count = parent:CreateFontString(nil, "OVERLAY", B.FontObjects.Number:GetName())
      count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
      count:SetText(countText)

      return icon
    end
  })

  --- Shows the item's icon and its stack count, which is hidden for a stack of one.
  --- @param item BagItem | ListItem
  --- @param desaturated? boolean `true` shows the icon in black and white.
  function root:SetItem(item, desaturated)
    texture = item.texture
    isDesaturated = desaturated == true
    countText = (item.quantity or 1) > 1 and item.quantity or ""

    if icon then
      icon:SetTexture(texture)
      icon:SetDesaturated(isDesaturated)
    end

    if count then count:SetText(countText) end
  end

  return root
end
