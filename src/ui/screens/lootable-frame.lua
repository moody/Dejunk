local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local Looter = Addon:GetModule("Looter")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class LootableFrame
local LootableFrame = Addon:GetModule("LootableFrame")

local NUM_LOOTABLE_PANEL_BUTTONS = 8

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

local lootableItems = {}

-- Refresh components based on lootable item data.
local function refreshComponents()
  Items:GetItems(lootableItems)
  for i = #lootableItems, 1, -1 do
    if not lootableItems[i].lootable then table.remove(lootableItems, i) end
  end

  Components.TitleText:GetFrame():SetText(
    Colors.Yellow(("%s (%s)"):format(L.LOOTABLE_ITEMS, Colors.White(#lootableItems)))
  )

  --- @type SliderWidget
  local slider = Components.LootablePanelSlider:GetFrame()
  local offset = math.floor(slider:GetValue() + 0.5)

  -- Update buttons.
  for i, button in ipairs(Components.LootablePanelButtons) do
    local item = lootableItems[i + offset]
    --- @type ItemButtonWidget
    local f = button:GetFrame()
    if item then
      f:SetItem(item)
      f:Show()
    else
      f:Hide()
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

Components.Root = Addon.Waffle:Flex({
  width = 282,
  height = 325,
  direction = "COLUMN",
  hidden = true,

  defaultFrameFactory = function(parent)
    return CreateFrame("Frame")
  end,

  frameFactory = function(parent)
    local frame = Widgets:Frame({
      name = ADDON_NAME .. "_LootableFrame",
      enableClickHandling = true,
      enableDragging = true
    })
    frame:SetFrameLevel(10)

    frame:SetClickHandler("RightButton", "SHIFT", function()
      StateManager:Dispatch(ActionCreators.Global.points.lootableFrame.reset())
    end)

    Widgets:ConfigureForPointSync(frame, "LootableFrame")

    table.insert(UISpecialFrames, frame:GetName())

    frame:Hide()
    frame:HookScript("OnHide", function()
      Components.Root:SetHidden(true)
    end)

    -- Bind refreshComponents() to the root frame.
    TickerManager:NewTicker(1 / 30, refreshComponents):BindFrame(frame)

    return frame
  end
})

-- ============================================================================
-- Title Components
-- ============================================================================

Components.TitleRow = Components.Root:AddRow({
  height = 32,
  paddingLeft = Widgets:Padding(),
  frameFactory = function(parent)
    local frame = Widgets:Frame({ parent = parent })
    frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
    return frame
  end
})

Components.TitleText = Components.TitleRow:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
    fontString:SetWordWrap(false)
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Yellow(L.LOOTABLE_ITEMS))
    return fontString
  end
})

Components.CloseButton = Components.TitleRow:AddChild({
  width = 46,
  frameFactory = function(parent)
    return Widgets:TitleFrameIconButton({
      name = "$parent_CloseButton",
      texture = Addon:GetAsset("x-icon"),
      textureSize = 14,
      highlightColor = Colors.Red,
      onClick = function() LootableFrame:Hide() end
    })
  end
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

Components.LootablePanelButtons = {}
for i = 1, NUM_LOOTABLE_PANEL_BUTTONS do
  Components.LootablePanelButtons[i] = lootablePanelButtonColumn:AddChild({
    frameFactory = function()
      local button = Widgets:ItemButton({
        enableClickHandling = true,
        onUpdateTooltip = function(self, tooltip)
          if not self.item then return end
          tooltip:SetOwner(self, "ANCHOR_RIGHT")
          tooltip:SetBagItem(self.item.bag, self.item.slot)
          tooltip:AddLine(" ")
          tooltip:AddDoubleLine(L.LEFT_CLICK, L.LOOT)
        end
      })

      -- Override ItemButton's default click handling; dropping an item here isn't supported.
      button:SetScript("OnClick", nil)

      button:SetClickHandler("LeftButton", "NONE", function()
        Looter:HandleItem(button.item)
      end)

      return button
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
