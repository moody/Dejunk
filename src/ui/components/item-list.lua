local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ItemListComponentOptions
--- @field getItems fun(): (BagItem | ListItem)[] Returns the items to list, in order.
--- @field cardCount integer Number of items shown at once. The rest are reached by scrolling.
--- @field addItem? fun(itemId: number) Called with the ID of an item dropped on the list. Drops do nothing without it.
--- @field displayPrice? boolean Shows the price of each stack. Defaults to `false`.
--- @field iconSize? integer Defaults to the `ItemCard` default.
--- @field fontObject? Font Defaults to the `ItemCard` default.
--- @field iconButton? ItemCardIconButtonOptions Adds a button to the right of each card.
--- @field onUpdateItemTooltip? fun(item: BagItem | ListItem, tooltip: Tooltip) Defaults to the item's tooltip.
--- @field onItemClick? fun(item: BagItem | ListItem, button: string)
--- @field isItemEnabled? fun(item: BagItem | ListItem): boolean Disabled items are dimmed and ignore the mouse.

-- =============================================================================
-- ComponentFactory - ItemList
-- =============================================================================

--- Creates a scrollable list of item cards. Clicking it with an item on the cursor adds that item.
--- @param options ItemListComponentOptions
--- @return ItemListComponent root
function ComponentFactory:ItemList(options)
  --- Adds the item held on the cursor to the list, then empties the cursor.
  local function addCursorItem()
    local itemId = B.Cursor:GetItemId()
    if itemId and options.addItem then
      options.addItem(itemId)
      B.Cursor:Clear()
    end
  end

  --- @class ItemListComponent : CardListComponent
  local root = ComponentFactory:CardList({
    cardCount = options.cardCount,
    getEntries = options.getItems,
    onMouseDown = addCursorItem,

    createCard = function()
      return ComponentFactory:ItemCard({
        displayPrice = options.displayPrice,
        iconSize = options.iconSize,
        fontObject = options.fontObject,
        iconButton = options.iconButton,
        onUpdateTooltip = options.onUpdateItemTooltip,

        onClick = function(item, button)
          if B.Cursor:GetItemId() then
            if button == "LeftButton" then addCursorItem() end
          elseif options.onItemClick then
            options.onItemClick(item, button)
          end
        end
      })
    end,

    setCard = function(card, item)
      card:SetItem(item)

      local isEnabled = true
      if item and options.isItemEnabled then isEnabled = options.isItemEnabled(item) end
      card:SetEnabled(isEnabled)
    end
  })

  return root
end
