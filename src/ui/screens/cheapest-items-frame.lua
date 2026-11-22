local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local B = Addon:GetModule("Blizzard")
local BagItemsCache = Addon:GetModule("BagItemsCache")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local DefaultStates = Addon:GetModule("DefaultStates")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

local CHEAPEST_CARD_COUNT = 5

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- The items the frame lists, cheapest stack first.
--- @type BagItem[]
local cheapestItems = {}

--- Returns the price of the item's whole stack, or `0` if it has no sell price.
--- @param item BagItem
--- @return integer
local function getStackPrice(item)
  return item.noValue and 0 or (item.price * item.quantity)
end

--- Returns `true` if the item is cheaper than `other`, or is in an earlier slot when the prices match.
--- @param item BagItem
--- @param other BagItem
--- @return boolean
local function isCheaperThan(item, other)
  local price, otherPrice = getStackPrice(item), getStackPrice(other)
  if price ~= otherPrice then return price < otherPrice end
  if item.bag ~= other.bag then return item.bag < other.bag end
  return item.slot < other.slot
end

--- Returns `true` if the item's quality is selected in `qualities`.
--- @param item BagItem
--- @param qualities ItemQualitiesState
--- @return boolean
local function isQualitySelected(item, qualities)
  return (
    (qualities.poor and item.quality == Enum.ItemQuality.Poor) or
    (qualities.common and item.quality == (Enum.ItemQuality.Common or Enum.ItemQuality.Standard)) or
    (qualities.uncommon and item.quality == (Enum.ItemQuality.Uncommon or Enum.ItemQuality.Good)) or
    (qualities.rare and item.quality == Enum.ItemQuality.Rare) or
    (qualities.epic and item.quality == Enum.ItemQuality.Epic)
  )
end

--- Repopulates `cheapestItems` with the destroyable bag items of a selected quality that are not quest items.
local function updateCheapestItems()
  local qualities = StateManager:GetGlobalState().cheapestItemsFrame.qualities

  BagItemsCache:GetItems(cheapestItems)

  local numKept = 0
  for i = 1, #cheapestItems do
    local item = cheapestItems[i]
    if Items:IsItemDestroyable(item) and not Items:IsItemQuestItem(item) and isQualitySelected(item, qualities) then
      numKept = numKept + 1
      cheapestItems[numKept] = item
    end
  end
  for i = #cheapestItems, numKept + 1, -1 do cheapestItems[i] = nil end

  table.sort(cheapestItems, isCheaperThan)
end

-- ============================================================================
-- Root Component
-- ============================================================================

-- Sits at the loot window's top-right corner. It is anchored to the loot window but not parented to it, since a child
-- of that protected frame cannot update its mouse propagation in combat.
Components.Root = Addon.Waffle:Flex({
  width = 250,
  height = 230,
  direction = "COLUMN",
  padding = Widgets:Padding(),
  visibility = "GONE",

  frameFactory = function()
    local frame = Widgets:Frame({
      name = ADDON_NAME .. "_CheapestItemsFrame",
      enableClickHandling = true,
      enableDragging = true,
      frameStrata = "HIGH"
    })

    Widgets:ConfigureForPointSync({
      frame = frame,
      getRelativeFrame = function() return _G.LootFrame end,
      getPoint = function()
        local point = StateManager:GetGlobalState().points.cheapestItemsFrame
        return (point.relativeTo ~= DefaultStates.Global.points.cheapestItemsFrame.relativeTo) and
            DefaultStates.Global.points.cheapestItemsFrame or
            point
      end,
      setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.cheapestItemsFrame.set(point)) end
    })

    frame:SetClickHandler("RightButton", "SHIFT", function()
      StateManager:Dispatch(ActionCreators.Global.points.cheapestItemsFrame.reset())
    end)

    TickerManager:NewTicker(1 / 30, updateCheapestItems):BindFrame(frame)

    return frame
  end
})

-- ============================================================================
-- Content Components
-- ============================================================================

Components.ItemsPanel = Components.Root:AttachComponent(ComponentFactory:TitledPanel({
  titleText = Colors.Yellow(L.CHEAPEST_ITEMS)
}))

Components.ItemList = Components.ItemsPanel.Content:AttachComponent(ComponentFactory:ItemList({
  cardCount = CHEAPEST_CARD_COUNT,
  getItems = function() return cheapestItems end,
  isItemEnabled = function(item) return not Items:IsItemLocked(item) end,

  -- The stack price, or why there is none.
  getItemSubtext = function(item)
    if Items:IsItemLocked(item) then return Colors.Grey(L.ITEM_IS_LOCKED) end
    if item.noValue then return Colors.Grey(B.Strings.NO_SELL_PRICE_TEXT) end
    return Colors.White(B.Money:GetCoinText(getStackPrice(item)))
  end,

  onUpdateItemTooltip = function(item, tooltip)
    tooltip:SetBagItem(item.bag, item.slot)
  end
}))

-- ============================================================================
-- Ticker
-- ============================================================================

-- Shows the frame while the option is on and the loot window is shown.
TickerManager:NewTicker(1 / 30, function()
  local isEnabled = StateManager:GetGlobalState().cheapestItemsFrame.enabled
  local isLootFrameShown = _G.LootFrame ~= nil and _G.LootFrame:IsShown()
  Components.Root:SetVisibility((isEnabled and isLootFrameShown) and "VISIBLE" or "GONE")
  Components.Root:Layout()
end)
