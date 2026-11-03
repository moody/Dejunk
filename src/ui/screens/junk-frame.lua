local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local Destroyer = Addon:GetModule("Destroyer")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local ItemTooltip = Addon:GetModule("ItemTooltip")
local JunkFilter = Addon:GetModule("JunkFilter")
local JunkItemsCache = Addon:GetModule("JunkItemsCache")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local Seller = Addon:GetModule("Seller")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class JunkFrame
local JunkFrame = Addon:GetModule("JunkFrame")

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

local wasAutoShown = false

local junkItems = {}

-- The counts text that the title currently shows.
local titleCountsText

-- Refresh components based on junk item data.
local function refreshComponents()
  JunkItemsCache:GetJunkItems(junkItems)

  -- Auto Junk Frame.
  if wasAutoShown and StateManager:GetGlobalState().autoJunkFrame and #junkItems == 0 then
    wasAutoShown = false
    JunkFrame:Hide()
    return
  end

  local countsText = JunkItemsCache:GetNumJunkItemsText()
  if countsText ~= titleCountsText then
    titleCountsText = countsText
    Components.Root.TitleText:GetFrame():SetText(Colors.Yellow(L.JUNK_ITEMS) .. " " .. countsText)
  end

  local totalJunkValue = 0
  for _, item in pairs(junkItems) do
    totalJunkValue = totalJunkValue + (item.noValue and 0 or (item.price * item.quantity))
  end
  Components.ItemsPanel:SetTitleText(Colors.White(B.Money:GetCoinText(totalJunkValue)))

  if Addon:IsBusy() then
    Components.StartSellingButton:GetFrame():FireEvent("ENABLED", false)
    Components.DestroyNextItemButton:GetFrame():FireEvent("ENABLED", false)
  else
    local canSell = Addon:IsAtMerchant() and JunkItemsCache:GetNextSellableJunkItem() ~= nil
    local canDestroy = JunkItemsCache:GetNextDestroyableJunkItem() ~= nil
    Components.StartSellingButton:GetFrame():FireEvent("ENABLED", canSell)
    Components.DestroyNextItemButton:GetFrame():FireEvent("ENABLED", canDestroy)
  end
end

--- Returns the reason the item cannot be sold, junk or not, or `nil` if it can be.
--- @param item BagItem
--- @return string? reason
local function getCannotSellReason(item)
  if not Items:IsItemSellable(item) then return L.ITEM_CANNOT_BE_SOLD end
  return JunkFilter:GetSellBlockReason(item)
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = ComponentFactory:Window({
  name = "JunkFrame",
  width = 350,
  height = 400,
  titleText = Colors.Yellow(L.JUNK_ITEMS),
  getPoint = function() return StateManager:GetGlobalState().points.junkFrame end,
  setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.junkFrame.set(point)) end,
  onResetPoint = function() StateManager:Dispatch(ActionCreators.Global.points.junkFrame.reset()) end,
  refresh = refreshComponents
})

-- ============================================================================
-- Content Components
-- ============================================================================

Components.Content = Components.Root:AddChild({
  direction = "COLUMN",
  padding = Widgets:Padding(),
  gap = Widgets:Padding(0.5),
})

-- Title bar shows the total value. Ctrl+Alt+Right-click on it adds every junk item to an Exclusions list.
Components.ItemsPanel = Components.Content:AttachComponent(ComponentFactory:TitledPanel({
  titleText = Colors.White(L.JUNK_ITEMS),

  onUpdateTooltip = function(_, tooltip)
    tooltip:SetText(L.JUNK_ITEMS)
    tooltip:AddLine(L.JUNK_FRAME_TOOLTIP:format(
      Lists.ProfileInclusions.name,
      Lists.GlobalInclusions.name,
      Colors.White(B.Strings.SHIFT_KEY_TEXT)
    ))
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(
      Addon:Concat("+", B.Strings.CTRL_KEY_TEXT, B.Strings.ALT_KEY_TEXT, L.RIGHT_CLICK),
      L.ADD_ALL_TO_LIST:format(Lists.ProfileExclusions.name)
    )
    tooltip:AddDoubleLine(
      Addon:Concat("+", B.Strings.CTRL_KEY_TEXT, B.Strings.ALT_KEY_TEXT, B.Strings.SHIFT_KEY_TEXT, L.RIGHT_CLICK),
      L.ADD_ALL_TO_LIST:format(Lists.GlobalExclusions.name)
    )
  end,

  onClick = function(button)
    if button == "RightButton" and IsControlKeyDown() and IsAltKeyDown() then
      local list = IsShiftKeyDown() and Lists.GlobalExclusions or Lists.ProfileExclusions
      for _, item in pairs(junkItems) do list:Add(item.id) end
    end
  end
}))

Components.ItemList = Components.ItemsPanel.Content:AttachComponent(ComponentFactory:ItemList({
  cardCount = 6,
  displayPrice = true,
  getItems = function() return junkItems end,
  isItemEnabled = function(item) return not (Addon:IsBusy() or B.Cursor:GetItemId() or Items:IsItemLocked(item)) end,
  iconButtons = {
    -- Sell button.
    {
      icon = Addon:GetAsset("coins-icon"),
      highlightColor = Colors.Yellow,
      isActive = function(item) return Addon:IsAtMerchant() and getCannotSellReason(item) == nil end,
      onClick = function(item) Seller:HandleItem(item) end,
      onUpdateTooltip = function(item, tooltip)
        local cannotSellReason = getCannotSellReason(item)
        local isJunk, reason = false, cannotSellReason
        if not cannotSellReason then isJunk, reason = JunkItemsCache:IsSellableJunkItem(item) end

        tooltip:SetText(L.SELL)
        if not Addon:IsAtMerchant() then
          tooltip:AddLine(Colors.Grey(L.CANNOT_SELL_WITHOUT_MERCHANT))
        elseif cannotSellReason then
          tooltip:AddLine(Colors.Grey(L.CANNOT_SELL_THIS_ITEM_NOW))
        else
          tooltip:AddLine(Colors.Gold(L.CLICK_TO_SELL_MANUALLY))
        end

        local heading, reasonLine = ItemTooltip:GetSellLines(isJunk, reason)
        tooltip:AddLine(" ")
        tooltip:AddLine(heading)
        tooltip:AddLine(reasonLine)
      end
    },
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
      isActive = function(item) return Items:IsItemDestroyable(item) end,
      onClick = function(item) Destroyer:HandleItem(item) end,
      onUpdateTooltip = function(item, tooltip)
        local isDestroyable = Items:IsItemDestroyable(item)
        local isJunk, reason = false, L.ITEM_CANNOT_BE_DESTROYED
        if isDestroyable then isJunk, reason = JunkItemsCache:IsDestroyableJunkItem(item) end

        tooltip:SetText(L.DESTROY)
        if isDestroyable then
          tooltip:AddLine(Colors.Gold(L.CLICK_TO_DESTROY_MANUALLY))
        else
          tooltip:AddLine(Colors.Grey(L.CANNOT_DESTROY_THIS_ITEM))
        end

        local heading, reasonLine = ItemTooltip:GetDestroyLines(isJunk, reason)
        tooltip:AddLine(" ")
        tooltip:AddLine(heading)
        tooltip:AddLine(reasonLine)
      end
    }
  },

  onUpdateItemTooltip = function(item, tooltip)
    tooltip:SetBagItem(item.bag, item.slot)
  end,

  addItem = function(itemId)
    local list = IsShiftKeyDown() and Lists.GlobalInclusions or Lists.ProfileInclusions
    list:Add(itemId)
  end
}))

Components.ButtonRow = Components.Content:AddRow({
  maxHeight = 30,
  gap = Widgets:Padding(0.5)
})

Components.StartSellingButton = Components.ButtonRow:AddChild({
  frameFactory = function(parent)
    return Widgets:Button({
      name = "$parent_StartSellingButton",
      labelColor = Colors.Yellow,
      labelText = L.START_SELLING,
      onClick = Commands.sell
    })
  end
})

Components.DestroyNextItemButton = Components.ButtonRow:AddChild({
  frameFactory = function(parent)
    return Widgets:Button({
      name = "$parent_DestroyNextItemButton",
      labelColor = Colors.Red,
      labelText = L.DESTROY_NEXT_ITEM,
      onClick = Commands.destroy,
      onUpdateTooltip = function(self, tooltip)
        tooltip:SetOwner(self, "ANCHOR_RIGHT")
        local item = JunkItemsCache:GetNextDestroyableJunkItem()
        if item then
          tooltip:SetBagItem(item.bag, item.slot)
        end
      end
    })
  end
})

-- ============================================================================
-- JunkFrame
-- ============================================================================

function JunkFrame:Show()
  Components.Root:SetVisibility("VISIBLE")
  Components.Root:Layout()
end

function JunkFrame:Hide()
  Components.Root:SetVisibility("GONE")
  Components.Root:Layout()
end

function JunkFrame:Toggle()
  if Components.Root:IsVisible() then
    self:Hide()
  else
    self:Show()
  end
end

-- ============================================================================
-- Ticker
-- ============================================================================

Addon:GetModule("TickerManager"):NewTicker(1 / 30, function()
  if not (Addon:IsAtMerchant() and StateManager:GetGlobalState().autoJunkFrame) then
    wasAutoShown = false
    return
  end

  if not (wasAutoShown or Components.Root:IsVisible()) then
    JunkItemsCache:GetJunkItems(junkItems)
    if #junkItems > 0 then
      wasAutoShown = true
      JunkFrame:Show()
    end
  end
end)

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.MerchantClosed, function()
  wasAutoShown = false
  if StateManager:GetGlobalState().autoJunkFrame then JunkFrame:Hide() end
end)
