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

--- @class CheapestItemsFrame
local CheapestItemsFrame = Addon:GetModule("CheapestItemsFrame")

local Components = {}

--- @alias CheapestItemsTab "JUNK" | "ALL"

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
-- Filters
-- ============================================================================

--- The rules that the Qualities and Types options set for the All tab.
local Filters = {}

--- Returns `true` if the item's quality is selected in `qualities`.
--- @param item BagItem
--- @param qualities ItemQualitiesState
--- @return boolean
function Filters:IsQualitySelected(item, qualities)
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
--- @param types CheapestItemsTypesState
--- @return boolean
function Filters:IsTypeSelected(item, types)
  if Items:IsItemEquipment(item) then return types.equipment end
  if item.classId == Enum.ItemClass.Tradegoods then return types.tradeGoods end
  if item.classId == Enum.ItemClass.Consumable then return types.consumables end
  return types.other
end

--- Returns `true` if the item's quality and type are selected.
--- @param item BagItem
--- @param state CheapestItemsFrameState
--- @return boolean
function Filters:IsItemAllowed(item, state)
  return self:IsQualitySelected(item, state.qualities) and self:IsTypeSelected(item, state.types)
end

-- ============================================================================
-- CheapestItems
-- ============================================================================

--- The destroyable bag items, and the lists of them that the tabs show.
local CheapestItems = {
  --- The reusable list that `Update()` fills with the destroyable items, cheapest stack first.
  --- @type BagItem[]
  buffer = {},

  --- The items the junk filter calls junk for destroying, cheapest stack first.
  --- @type BagItem[]
  junk = {},

  --- The junk items and the items that no filter matched and that pass `Filters`, cheapest stack first.
  --- @type BagItem[]
  all = {}
}

--- Repopulates the lists from the bags.
--- @param state CheapestItemsFrameState
function CheapestItems:Update(state)
  local buffer, junk, all = self.buffer, self.junk, self.all

  BagItemsCache:GetItems(buffer)

  local numBuffered = 0
  for i = 1, #buffer do
    local item = buffer[i]
    if Items:IsItemDestroyable(item) then
      numBuffered = numBuffered + 1
      buffer[numBuffered] = item
    end
  end
  trimItems(buffer, numBuffered)

  table.sort(buffer, Items.compareByStackPrice)

  local numJunk, numAll = 0, 0
  for i = 1, numBuffered do
    local item = buffer[i]
    local result = JunkItemsCache:GetResult(item, "DESTROY")
    local isJunk = result == ItemFilters.JUNK

    if isJunk then
      numJunk = numJunk + 1
      junk[numJunk] = item
    end

    if isJunk or (result == ItemFilters.PASS and Filters:IsItemAllowed(item, state)) then
      numAll = numAll + 1
      all[numAll] = item
    end
  end
  trimItems(junk, numJunk)
  trimItems(all, numAll)
end

-- ============================================================================
-- Tabs
-- ============================================================================

--- The Junk and All tabs, and the one the list shows.
local Tabs = {
  --- Format of a tab's text: its name, then the number of items it lists.
  TEXT_FORMAT = "%s (%d)",

  --- The tab the list shows.
  --- @type CheapestItemsTab
  selected = "JUNK",

  --- The count last shown on the Junk tab.
  --- @type integer?
  shownJunk = nil,

  --- The count last shown on the All tab.
  --- @type integer?
  shownAll = nil
}

--- Selects the given tab.
--- @param tab CheapestItemsTab
function Tabs:Select(tab)
  self.selected = tab
  Components.JunkTab:SetSelected(tab == "JUNK")
  Components.AllTab:SetSelected(tab == "ALL")
end

--- Shows the number of items each tab lists.
--- @param numJunk integer
--- @param numAll integer
function Tabs:SetCounts(numJunk, numAll)
  if numJunk ~= self.shownJunk then
    self.shownJunk = numJunk
    Components.JunkTab:SetLabelText(self.TEXT_FORMAT:format(L.JUNK, numJunk))
  end

  if numAll ~= self.shownAll then
    self.shownAll = numAll
    Components.AllTab:SetLabelText(self.TEXT_FORMAT:format(L.ALL, numAll))
  end
end

-- ============================================================================
-- Root Component
-- ============================================================================

--- Updates the cheapest items, and shows their counts on the tabs.
local function refreshComponents()
  CheapestItems:Update(StateManager:GetGlobalState().cheapestItemsFrame)
  Tabs:SetCounts(#CheapestItems.junk, #CheapestItems.all)
end

Components.Root = ComponentFactory:Window({
  name = "CheapestItemsFrame",
  width = 250,
  height = 230,
  isSpecialFrame = false,
  titleText = Colors.Yellow(L.CHEAPEST_ITEMS),
  getPoint = function() return StateManager:GetGlobalState().points.cheapestItemsFrame end,
  setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.cheapestItemsFrame.set(point)) end,
  onResetPoint = function() StateManager:Dispatch(ActionCreators.Global.points.cheapestItemsFrame.reset()) end,
  refresh = refreshComponents
})

-- ============================================================================
-- Content Components
-- ============================================================================

Components.Content = Components.Root:AddChild({
  direction = "COLUMN",
  padding = Widgets:Padding(),
  gap = Widgets:Padding(0.5)
})

-- Tabs, with no gap so their underlines form one line.
Components.TabRow = Components.Content:AddRow({ height = "AUTO" })

Components.JunkTab = Components.TabRow:AttachComponent(ComponentFactory:Tab({
  labelText = L.JUNK,
  onClick = function() Tabs:Select("JUNK") end
}))

Components.AllTab = Components.TabRow:AttachComponent(ComponentFactory:Tab({
  labelText = L.ALL,
  onClick = function() Tabs:Select("ALL") end
}))

Tabs:Select(Tabs.selected)

Components.ItemList = Components.Content:AttachComponent(ComponentFactory:ItemList({
  cardCount = 4,
  getItems = function() return Tabs.selected == "JUNK" and CheapestItems.junk or CheapestItems.all end,
  emptyText = function() return Tabs.selected == "JUNK" and L.NO_JUNK_ITEMS or L.NO_ITEMS end,
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

  onUpdateItemTooltip = function(item, tooltip)
    tooltip:SetBagItem(item.bag, item.slot)
  end
}))

-- ============================================================================
-- CheapestItemsFrame
-- ============================================================================

--- Shows the frame on the Junk tab if it has items, otherwise on All.
function CheapestItemsFrame:Show()
  refreshComponents()
  Tabs:Select(#CheapestItems.junk > 0 and "JUNK" or "ALL")
  Components.Root:SetVisibility("VISIBLE")
  Components.Root:Layout()
end

--- Hides the frame.
function CheapestItemsFrame:Hide()
  Components.Root:SetVisibility("GONE")
  Components.Root:Layout()
end

--- Hides the frame if it is showing, otherwise shows it.
function CheapestItemsFrame:Toggle()
  if Components.Root:IsVisible() then
    self:Hide()
  else
    self:Show()
  end
end

-- ============================================================================
-- AutoShow
-- ============================================================================

--- Shows the frame by itself while looting, as the Auto Show option says.
local AutoShow = {
  --- `true` from the loot opened event to the loot closed event.
  isLooting = false,

  --- `true` if the bags had a free slot at the last check.
  hadFreeSlots = true
}

--- Starts a loot session, and shows the frame if the option says to.
function AutoShow:StartLooting()
  self.isLooting = true
  self.hadFreeSlots = B.Container:HasFreeSlots()

  local autoShow = StateManager:GetGlobalState().cheapestItemsFrame.autoShow
  if autoShow == "ALWAYS" or (autoShow == "BAGS_FULL" and not self.hadFreeSlots) then
    CheapestItemsFrame:Show()
  end
end

--- Ends the loot session, and hides the frame.
function AutoShow:StopLooting()
  self.isLooting = false
  CheapestItemsFrame:Hide()
end

--- Shows the frame if the bags filled up while looting. Emptying them does not hide it.
function AutoShow:CheckBags()
  if not self.isLooting then return end

  local hadFreeSlots = self.hadFreeSlots
  self.hadFreeSlots = B.Container:HasFreeSlots()

  if StateManager:GetGlobalState().cheapestItemsFrame.autoShow ~= "BAGS_FULL" then return end
  if hadFreeSlots and not self.hadFreeSlots and not Components.Root:IsVisible() then
    CheapestItemsFrame:Show()
  end
end

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.LootOpened, function() AutoShow:StartLooting() end)

EventManager:On(E.Wow.LootClosed, function() AutoShow:StopLooting() end)

EventManager:On(E.BagsUpdated, function() AutoShow:CheckBags() end)
