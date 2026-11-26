local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local B = Addon:GetModule("Blizzard")
local BagItemsCache = Addon:GetModule("BagItemsCache")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local Destroyer = Addon:GetModule("Destroyer")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local ItemFilters = Addon:GetModule("ItemFilters")
local Items = Addon:GetModule("Items")
local JunkItemsCache = Addon:GetModule("JunkItemsCache")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ExpendableItemsFrame
local ExpendableItemsFrame = Addon:GetModule("ExpendableItemsFrame")

local Components = {}

--- The junk items and the unprotected items that pass `Selection`, cheapest stack first.
--- @type BagItem[]
local expendableItems = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Removes the items after the first `count` of `items`.
--- @param items BagItem[]
--- @param count integer
local function trimItems(items, count)
  for i = #items, count + 1, -1 do items[i] = nil end
end

-- ============================================================================
-- Selection
-- ============================================================================

--- The qualities and types that the player selected in the options.
local Selection = {}

--- Returns `true` if the item's quality is selected in `qualities`.
--- @param item BagItem
--- @param qualities ItemQualitiesState
--- @return boolean
function Selection:IsQualitySelected(item, qualities)
  return (
    (qualities.poor and item.quality == Enum.ItemQuality.Poor) or
    (qualities.common and item.quality == (Enum.ItemQuality.Common or Enum.ItemQuality.Standard)) or
    (qualities.uncommon and item.quality == (Enum.ItemQuality.Uncommon or Enum.ItemQuality.Good)) or
    (qualities.rare and item.quality == Enum.ItemQuality.Rare) or
    (qualities.epic and item.quality == Enum.ItemQuality.Epic)
  )
end

--- Returns `true` if the item's type is selected in `types`.
--- @param item BagItem
--- @param types ExpendableItemsTypesState
--- @return boolean
function Selection:IsTypeSelected(item, types)
  if Items:IsItemEquipment(item) then return types.equipment end
  if item.classId == Enum.ItemClass.Tradegoods then return types.tradeGoods end
  if item.classId == Enum.ItemClass.Consumable then return types.consumables end
  return types.other
end

--- Returns `true` if the item's quality and type are selected.
--- @param item BagItem
--- @param state ExpendableItemsFrameState
--- @return boolean
function Selection:IsItemSelected(item, state)
  return self:IsQualitySelected(item, state.qualities) and self:IsTypeSelected(item, state.types)
end

-- ============================================================================
-- Root Component
-- ============================================================================

--- Repopulates `expendableItems` from the bags.
local function updateExpendableItems()
  local state = StateManager:GetGlobalState().expendableItemsFrame
  BagItemsCache:GetItems(expendableItems)

  local numItems = 0
  for i = 1, #expendableItems do
    local item = expendableItems[i]
    local result = JunkItemsCache:GetResult(item, "DESTROY")

    if result == ItemFilters.JUNK or (result == ItemFilters.PASS and Selection:IsItemSelected(item, state)) then
      numItems = numItems + 1
      expendableItems[numItems] = item
    end
  end
  trimItems(expendableItems, numItems)

  table.sort(expendableItems, Items.compareByStackPrice)
end

--- Updates the expendable items, and shows their count and the number of free slots.
local function refreshComponents()
  updateExpendableItems()

  Components.Root.TitleText:GetFrame():SetText(
    Colors.Yellow(("%s (%s)"):format(L.EXPENDABLE_ITEMS, Colors.White(#expendableItems)))
  )
  Components.ItemsPanel:SetTitleText(Colors.White(("%s: %d"):format(L.FREE_SLOTS, B.Container:GetNumFreeSlots())))
end

Components.Root = ComponentFactory:Window({
  name = "ExpendableItemsFrame",
  width = 275,
  height = 275,
  isSpecialFrame = false,
  titleText = Colors.Yellow(L.EXPENDABLE_ITEMS),
  getPoint = function() return StateManager:GetGlobalState().points.expendableItemsFrame end,
  setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.expendableItemsFrame.set(point)) end,
  onResetPoint = function() StateManager:Dispatch(ActionCreators.Global.points.expendableItemsFrame.reset()) end,
  refresh = refreshComponents
})

-- ============================================================================
-- Content Components
-- ============================================================================

Components.Content = Components.Root:AddChild({
  direction = "COLUMN",
  padding = Widgets:Padding()
})

-- Title bar shows the number of free slots.
Components.ItemsPanel = Components.Content:AttachComponent(ComponentFactory:TitledPanel({
  titleText = Colors.White(L.FREE_SLOTS)
}))

Components.ItemList = Components.ItemsPanel.Content:AttachComponent(ComponentFactory:ItemList({
  cardCount = 5,
  getItems = function() return expendableItems end,
  isItemEnabled = function(item) return not (Addon:IsBusy() or B.Cursor:GetItemId() or Items:IsItemLocked(item)) end,

  iconButtons = {
    -- Exclude button.
    {
      icon = Addon:GetAsset("ban-icon"),
      highlightColor = Colors.Green,
      onClick = function(item)
        local list = IsShiftKeyDown() and Lists.GlobalExclusions or Lists.ProfileExclusions
        list:Add(item.id)
      end,
      onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(L.EXCLUDE)
        tooltip:AddDoubleLine(L.LEFT_CLICK, L.ADD_TO_LIST:format(Lists.ProfileExclusions.name))
        tooltip:AddDoubleLine(
          Addon:Concat("+", B.Strings.SHIFT_KEY_TEXT, L.LEFT_CLICK),
          L.ADD_TO_LIST:format(Lists.GlobalExclusions.name)
        )
      end
    },
    -- Destroy button.
    {
      icon = Addon:GetAsset("trash-icon"),
      highlightColor = Colors.Red,
      onClick = function(item) Destroyer:HandleItem(item) end,
      onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(L.DESTROY)
        tooltip:AddLine(Colors.Gold(L.CLICK_TO_DESTROY_MANUALLY))
      end
    }
  },

  -- The stack price, or why there is none.
  getItemSubtext = function(item)
    if Items:IsItemLocked(item) then return Colors.Grey(L.ITEM_IS_LOCKED) end
    if item.noValue then return Colors.Grey(B.Strings.NO_SELL_PRICE_TEXT) end
    return Colors.White(B.Money:GetCoinText(Items:GetStackPrice(item)))
  end,

  -- The icon of an item the junk filter picked is in black and white.
  isIconDesaturated = function(item) return JunkItemsCache:GetResult(item, "DESTROY") == ItemFilters.JUNK end,

  onUpdateItemTooltip = function(item, tooltip)
    tooltip:SetBagItem(item.bag, item.slot)
  end
}))

-- ============================================================================
-- ExpendableItemsFrame
-- ============================================================================

--- Shows the frame, scrolled to the cheapest item.
function ExpendableItemsFrame:Show()
  Components.ItemList:ScrollToTop()
  Components.Root:SetVisibility("VISIBLE")
  Components.Root:Layout()
end

--- Hides the frame.
function ExpendableItemsFrame:Hide()
  Components.Root:SetVisibility("GONE")
  Components.Root:Layout()
end

--- Hides the frame if it is showing, otherwise shows it.
function ExpendableItemsFrame:Toggle()
  if Components.Root:IsVisible() then
    self:Hide()
  else
    self:Show()
  end
end

-- ============================================================================
-- AutoShow
-- ============================================================================

--- Shows the frame by itself, as the Auto Show option says.
local AutoShow = {
  --- `true` from the loot opened event to the loot closed event.
  isLooting = false,

  --- `true` if the bags had a free slot at the last check.
  hadFreeSlots = true
}

--- Returns `true` if the Auto Show option is `mode`.
--- @param mode ExpendableItemsAutoShow
--- @return boolean
function AutoShow:IsSetTo(mode)
  return StateManager:GetGlobalState().expendableItemsFrame.autoShow == mode
end

--- Starts a loot session, and shows the frame if the option says to.
function AutoShow:StartLooting()
  self.isLooting = true
  self.hadFreeSlots = B.Container:HasFreeSlots()

  if self:IsSetTo("ALWAYS") or (self:IsSetTo("BAGS_FULL") and not self.hadFreeSlots) then
    ExpendableItemsFrame:Show()
  end
end

--- Ends the loot session, and hides the frame if the option is `BAGS_FULL` or `ALWAYS`.
function AutoShow:StopLooting()
  self.isLooting = false

  if self:IsSetTo("BAGS_FULL") or self:IsSetTo("ALWAYS") then ExpendableItemsFrame:Hide() end
end

--- Shows the frame if the bags filled up while looting. Emptying them does not hide it.
function AutoShow:CheckBags()
  if not self.isLooting then return end

  local hadFreeSlots = self.hadFreeSlots
  self.hadFreeSlots = B.Container:HasFreeSlots()

  if not self:IsSetTo("BAGS_FULL") then return end
  if hadFreeSlots and not self.hadFreeSlots and not Components.Root:IsVisible() then
    ExpendableItemsFrame:Show()
  end
end

--- Shows the frame if it is hidden and the game says the inventory is full.
--- @param message string
function AutoShow:CheckError(message)
  if not self:IsSetTo("ON_ERROR") then return end
  if message == B.Strings.INVENTORY_FULL_ERROR_TEXT and not Components.Root:IsVisible() then
    ExpendableItemsFrame:Show()
  end
end

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.LootOpened, function() AutoShow:StartLooting() end)

EventManager:On(E.Wow.LootClosed, function() AutoShow:StopLooting() end)

EventManager:On(E.BagsUpdated, function() AutoShow:CheckBags() end)

EventManager:On(E.Wow.UIErrorMessage, function(_, message) AutoShow:CheckError(message) end)
