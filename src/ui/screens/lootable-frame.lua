local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local BagItemsCache = Addon:GetModule("BagItemsCache")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class LootableFrame
local LootableFrame = Addon:GetModule("LootableFrame")

local LOOTABLE_CARD_COUNT = 5

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

local lootableItems = {}

--- Item IDs ignored for the remainder of the session.
--- @type table<number, true>
local ignoredItemIds = {}

--- Repopulates `lootableItems` with the current lootable, non-ignored items.
local function updateLootableItems()
  BagItemsCache:GetItems(lootableItems)
  for i = #lootableItems, 1, -1 do
    if not lootableItems[i].lootable or ignoredItemIds[lootableItems[i].id] then
      table.remove(lootableItems, i)
    end
  end
end

-- Refresh components based on lootable item data.
local function refreshComponents()
  updateLootableItems()

  if StateManager:GetGlobalState().autoLootableFrame and #lootableItems == 0 then
    LootableFrame:Hide()
    return
  end

  Components.Root.TitleText:GetFrame():SetText(
    Colors.Yellow(("%s (%s)"):format(L.LOOTABLE_ITEMS, Colors.White(#lootableItems)))
  )
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = ComponentFactory:Window({
  name = "LootableFrame",
  width = 250,
  height = 250,
  frameStrata = "LOW",
  isSpecialFrame = false,
  titleText = Colors.Yellow(L.LOOTABLE_ITEMS),
  getPoint = function() return StateManager:GetGlobalState().points.lootableFrame end,
  setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.lootableFrame.set(point)) end,
  onResetPoint = function() StateManager:Dispatch(ActionCreators.Global.points.lootableFrame.reset()) end,
  refresh = refreshComponents
})

-- ============================================================================
-- Content Components
-- ============================================================================

-- Panel around the item list.
Components.LootablePanel = Components.Root:AddColumn({ padding = Widgets:Padding() }):AddChild({
  padding = Widgets:Padding(),

  --- @param parent Frame
  frameFactory = function(parent)
    return Widgets:Frame({ parent = parent })
  end
})

Components.ItemList = Components.LootablePanel:AttachComponent(ComponentFactory:ItemList({
  cardCount = LOOTABLE_CARD_COUNT,
  getItems = function() return lootableItems end,
  isItemEnabled = function(item) return not Items:IsItemLocked(item) end,

  onUpdateItemTooltip = function(item, tooltip)
    tooltip:SetBagItem(item.bag, item.slot)
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(L.LEFT_CLICK, L.LOOT)
  end,

  onItemClick = function(item, button)
    if button == "LeftButton" then
      if Addon:IsBusy() then return end
      if not Items:IsItemStillInBags(item) then return end
      if Items:IsItemLocked(item) then return end
      C_Container.UseContainerItem(item.bag, item.slot)
    end
  end,

  -- Ignores every item sharing this item's ID for the remainder of the session.
  iconButtons = {
    {
      icon = Addon:GetAsset("eye-slash-icon"),
      highlightColor = Colors.Yellow,
      onClick = function(item) ignoredItemIds[item.id] = true end,
      onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(L.IGNORE)
        tooltip:AddLine(L.IGNORE_LOOTABLE_ITEM_TOOLTIP)
      end
    }
  }
}))

-- ============================================================================
-- LootableFrame
-- ============================================================================

function LootableFrame:Show()
  Components.Root:SetVisibility("VISIBLE")
  Components.Root:Layout()
end

function LootableFrame:Hide()
  Components.Root:SetVisibility("GONE")
  Components.Root:Layout()
end

function LootableFrame:Toggle()
  if Components.Root:IsVisible() then
    self:Hide()
  else
    updateLootableItems()
    if #lootableItems == 0 then
      Addon:Print(L.NO_LOOTABLE_ITEMS)
    else
      self:Show()
    end
  end
end

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.BagsUpdated, function()
  if not StateManager:GetGlobalState().autoLootableFrame then return end

  updateLootableItems()

  if #lootableItems == 0 then
    LootableFrame:Hide()
  elseif not Components.Root:IsVisible() then
    LootableFrame:Show()
  end
end)
