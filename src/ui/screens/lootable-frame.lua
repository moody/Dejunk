local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class LootableFrame
local LootableFrame = Addon:GetModule("LootableFrame")

local NUM_LOOTABLE_PANEL_BUTTONS = 5

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

local lootableItems = {}

--- Item IDs ignored for the remainder of the session.
--- @type table<number, true>
local ignoredItemIds = {}

-- Refresh components based on lootable item data.
local function refreshComponents()
  Items:GetItems(lootableItems)
  for i = #lootableItems, 1, -1 do
    if not lootableItems[i].lootable or ignoredItemIds[lootableItems[i].id] then
      table.remove(lootableItems, i)
    end
  end

  Components.Root.TitleText:GetFrame():SetText(
    Colors.Yellow(("%s (%s)"):format(L.LOOTABLE_ITEMS, Colors.White(#lootableItems)))
  )

  --- @type SliderWidget
  local slider = Components.LootablePanelSlider:GetFrame()
  local offset = math.floor(slider:GetValue() + 0.5)

  -- Update button rows.
  for i, lootablePanelButtonRow in ipairs(Components.LootablePanelButtonRows) do
    local item = lootableItems[i + offset]
    --- @type ItemButtonWidget
    local itemButton = lootablePanelButtonRow.ItemButton:GetFrame()
    --- @type TitleFrameIconButtonWidget
    local ignoreButton = lootablePanelButtonRow.IgnoreButton:GetFrame()
    if item then
      itemButton:SetItem(item)
      itemButton:Show()
      ignoreButton:Show()
    else
      itemButton:Hide()
      ignoreButton:Hide()
    end
  end

  -- Update slider.
  local maxScroll = math.max(#lootableItems - NUM_LOOTABLE_PANEL_BUTTONS, 0)
  if slider then slider:SetMinMaxValues(0, maxScroll) end
  Components.LootablePanelSlider:SetHidden(maxScroll <= 0)

  -- Update "no items" text.
  --- @type LootablePanelWidget
  local panel = Components.LootablePanel:GetFrame()
  if #lootableItems == 0 then panel.noItemsText:Show() else panel.noItemsText:Hide() end

  Components.Root:Layout()
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = ComponentFactory:Window({
  name = "LootableFrame",
  width = 300,
  height = 240,
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

-- Container for the lootable item buttons and slider.
Components.LootablePanel = Components.Root:AddColumn({ padding = Widgets:Padding() }):AddChild({
  padding = Widgets:Padding(),
  frameFactory = function(parent)
    --- @class LootablePanelWidget : FrameWidget
    --- @field noItemsText FontString
    local frame = Widgets:Frame({ parent = parent, name = "$parent_LootablePanel" })

    -- No items text.
    frame.noItemsText = frame:CreateFontString("$parent_NoItemsText", "ARTWORK", "GameFontNormal")
    frame.noItemsText:SetPoint("CENTER")
    frame.noItemsText:SetText(Colors.White(L.NO_ITEMS))
    frame.noItemsText:SetAlpha(0.3)

    -- Scroll on mouse wheel.
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
      local slider = Components.LootablePanelSlider:GetFrame()
      if slider then slider:SetValue(slider:GetValue() - delta) end
    end)

    return frame
  end
})

local lootablePanelContent = Components.LootablePanel:AddRow({ gap = Widgets:Padding() })

-- Container for the item buttons.
local lootablePanelButtonColumn = lootablePanelContent:AddColumn({ gap = Widgets:Padding(0.5) })

Components.LootablePanelSlider = lootablePanelContent:AddChild({
  width = 12,
  frameFactory = function(parent)
    return Widgets:Slider({ name = "$parent_Slider", parent = parent })
  end
})

Components.LootablePanelButtonRows = {}
for i = 1, NUM_LOOTABLE_PANEL_BUTTONS do
  --- @class LootablePanelButtonRow : WaffleFlexComponent
  local lootablePanelButtonRow = lootablePanelButtonColumn:AddRow({ gap = Widgets:Padding(0.5) })
  Components.LootablePanelButtonRows[i] = lootablePanelButtonRow

  lootablePanelButtonRow.ItemButton = lootablePanelButtonRow:AddChild({
    frameFactory = function()
      local frame = Widgets:ItemButton({
        onUpdateTooltip = function(self, tooltip)
          if not self.item then return end
          tooltip:SetOwner(self, "ANCHOR_RIGHT")
          tooltip:SetBagItem(self.item.bag, self.item.slot)
          tooltip:AddLine(" ")
          tooltip:AddDoubleLine(L.LEFT_CLICK, L.LOOT)
        end
      })

      frame:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
          if not self.item then return end
          if Addon:IsBusy() then return end
          if not Items:IsItemStillInBags(self.item) then return end
          if Items:IsItemLocked(self.item) then return end
          C_Container.UseContainerItem(self.item.bag, self.item.slot)
        end
      end)

      return frame
    end
  })

  -- Ignores every item sharing this item's ID for the remainder of the session.
  lootablePanelButtonRow.IgnoreButton = lootablePanelButtonRow:AddChild({
    width = 32,
    frameFactory = function()
      return Widgets:TitleFrameIconButton({
        texture = Addon:GetAsset("eye-slash-icon"),
        textureSize = 14,
        highlightColor = Colors.Yellow,
        onClick = function()
          --- @type ItemButtonWidget
          local itemButton = lootablePanelButtonRow.ItemButton:GetFrame()
          if itemButton.item then ignoredItemIds[itemButton.item.id] = true end
        end,
        onUpdateTooltip = function(_, tooltip)
          tooltip:SetText(L.IGNORE)
          tooltip:AddLine(L.IGNORE_LOOTABLE_ITEM_TOOLTIP)
        end
      })
    end
  })
end

-- ============================================================================
-- LootableFrame
-- ============================================================================

function LootableFrame:Show()
  Components.Root:SetHidden(false)
  Components.Root:Layout()
end

function LootableFrame:Hide()
  Components.Root:SetHidden(true)
  Components.Root:Layout()
end

function LootableFrame:Toggle()
  if Components.Root:GetHidden() then
    self:Show()
  else
    self:Hide()
  end
end
