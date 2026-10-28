local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ItemListComponentOptions
--- @field getItems fun(): (BagItem | ListItem)[] Returns the items to list, in order.
--- @field cardCount integer Number of items shown at once. The rest are reached by scrolling.
--- @field addItem fun(itemId: number) Called with the ID of an item dropped on the list.
--- @field displayPrice? boolean Shows the price of each stack. Defaults to `false`.
--- @field onUpdateItemTooltip? fun(item: BagItem | ListItem, tooltip: Tooltip) Defaults to the item's tooltip.
--- @field onItemClick? fun(item: BagItem | ListItem, button: string)

-- =============================================================================
-- ComponentFactory - ItemList
-- =============================================================================

--- Creates a scrollable list of item cards. Clicking it with an item on the cursor adds that item.
--- @param options ItemListComponentOptions
--- @return ItemListComponent root
function ComponentFactory:ItemList(options)
  local slider = Widgets:Slider({ orientation = "VERTICAL" })
  slider:Hide()

  --- Shown in the middle of the list while it has no items.
  --- @type FontString
  local noItemsText

  --- Cards, from the top.
  --- @type ItemCardComponent[]
  local cards = {}

  --- Adds the item held on the cursor to the list, then empties the cursor.
  local function addCursorItem()
    local itemId = B.Cursor:GetItemId()
    if itemId then
      options.addItem(itemId)
      B.Cursor:Clear()
    end
  end

  --- @class ItemListComponent : WaffleFlexComponent<FrameWidget>
  local root = Addon.Waffle:Flex({
    gap = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent, backdrop = false })
      frame:EnableMouseWheel(true)
      frame:SetScript("OnMouseWheel", function(_, delta)
        slider:SetValue(slider:GetValue() - delta)
      end)
      frame:SetScript("OnMouseDown", addCursorItem)

      noItemsText = frame:CreateFontString("$parent_NoItemsText", "ARTWORK", B.FontObjects.Normal:GetName())
      noItemsText:SetPoint("CENTER")
      noItemsText:SetTextColor(Colors.Grey:GetRGB())
      noItemsText:SetText(L.NO_ITEMS)

      return frame
    end
  })

  -- Cards.
  local cardColumn = root:AddColumn({ gap = Widgets:Padding(0.5) })
  -- Slider, shown only while the list can scroll.
  local sliderColumn = root:AddColumn({ frame = slider, width = 12, visibility = "GONE" })

  for i = 1, options.cardCount do
    cards[i] = cardColumn:AttachComponent(ComponentFactory:ItemCard({
      displayPrice = options.displayPrice,
      onUpdateTooltip = options.onUpdateItemTooltip,

      onClick = function(item, button)
        if B.Cursor:GetItemId() then
          if button == "LeftButton" then addCursorItem() end
        elseif options.onItemClick then
          options.onItemClick(item, button)
        end
      end
    }))
  end

  --- Shows the items from the scrolled position on the cards, and sizes the slider to the list.
  local function refresh()
    local items = options.getItems()
    local count = #items
    noItemsText:SetShown(count == 0)

    local maxOffset = math.max(count - options.cardCount, 0)
    local _, sliderMax = slider:GetMinMaxValues()
    if sliderMax ~= maxOffset then slider:SetMinMaxValues(0, maxOffset) end

    local isScrollable = maxOffset > 0
    if isScrollable ~= sliderColumn:IsVisible() then
      sliderColumn:SetVisibility(isScrollable and "VISIBLE" or "GONE")
      if isScrollable then
        -- Re-show the slider a frame later, or its thumb stays invisible.
        TickerManager:After(0, function()
          if not slider:IsShown() then return end
          slider:Hide()
          slider:Show()
        end)
      end
    end

    local offset = math.floor(slider:GetValue() + 0.5)
    for i, card in ipairs(cards) do
      card:SetItem(items[i + offset])
    end

    root:Layout()
  end

  slider:SetScript("OnValueChanged", refresh)

  root:WhenFrameReady(function(frame)
    frame:HookScript("OnShow", refresh)
    TickerManager:NewTicker(1 / 30, refresh):BindFrame(frame)
  end)

  return root
end
