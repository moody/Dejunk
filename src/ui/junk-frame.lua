local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local Destroyer = Addon:GetModule("Destroyer")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
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

local junkItems = {}

local function hasSellableItems(items)
  for _, item in ipairs(items) do
    if Items:IsItemSellable(item) then
      return true
    end
  end
  return false
end

local function refreshComponents()
  JunkFilter:GetJunkItems(junkItems)

  Components.TitleText:GetFrame():SetText(
    Colors.Yellow(("%s (%s)"):format(L.JUNK_ITEMS, Colors.White(#junkItems)))
  )

  local totalJunkValue = 0
  for _, item in pairs(junkItems) do
    totalJunkValue = totalJunkValue + (item.noValue and 0 or (item.price * item.quantity))
  end
  Components.ItemsFrame:GetFrame().title:SetText(Colors.White(GetCoinTextureString(totalJunkValue)))

  if Addon:IsBusy() then
    Components.StartSellingButton:GetFrame():SetEnabled(false)
    Components.DestroyNextItemButton:GetFrame():SetEnabled(false)
  else
    Components.StartSellingButton:GetFrame():SetEnabled(Addon:IsAtMerchant() and hasSellableItems(junkItems))
    Components.DestroyNextItemButton:GetFrame():SetEnabled(#junkItems > 0)
  end
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = Addon.Waffle:Flex({
  width = 325,
  height = 375,
  direction = "COLUMN",
  hidden = true,

  defaultFrameFactory = function(parent)
    return CreateFrame("Frame")
  end,

  frameFactory = function(parent)
    local frame = Widgets:Frame({
      name = ADDON_NAME .. "_JunkFrame",
      enableClickHandling = true,
      enableDragging = true
    })

    frame:SetClickHandler("RightButton", "SHIFT", function()
      StateManager:Dispatch(ActionCreators.Global.points.junkFrame.reset())
    end)

    Widgets:ConfigureForPointSync(frame, "JunkFrame")

    table.insert(UISpecialFrames, frame:GetName())

    local delayTimer = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
      delayTimer = delayTimer + elapsed
      if delayTimer < 0.02 then return end
      delayTimer = 0
      refreshComponents()
    end)

    frame:Hide()
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
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Yellow(L.JUNK_ITEMS))
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
      onClick = function() JunkFrame:Hide() end
    })
  end
})

-- ============================================================================
-- Content Components
-- ============================================================================

Components.Content = Components.Root:AddChild({
  direction = "COLUMN",
  padding = Widgets:Padding(),
  gap = Widgets:Padding(0.5),
})

Components.ItemsFrame = Components.Content:AddChild({
  frameFactory = function()
    local itemsFrame = Widgets:ItemsFrame({
      name = "$parent_ItemsFrame",
      displayPrice = true,
      titleText = Colors.White(L.JUNK_ITEMS),
      onUpdateTooltip = function(self, tooltip)
        tooltip:SetText(L.JUNK_ITEMS)
        tooltip:AddLine(L.JUNK_FRAME_TOOLTIP:format(
          Lists.ProfileInclusions.name,
          Lists.GlobalInclusions.name,
          Colors.White(L.SHIFT_KEY)
        ))
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(
          Addon:Concat("+", L.CONTROL_KEY, L.ALT_KEY, L.RIGHT_CLICK),
          L.ADD_ALL_TO_LIST:format(Lists.ProfileExclusions.name)
        )
        tooltip:AddDoubleLine(
          Addon:Concat("+", L.CONTROL_KEY, L.ALT_KEY, L.SHIFT_KEY, L.RIGHT_CLICK),
          L.ADD_ALL_TO_LIST:format(Lists.GlobalExclusions.name)
        )
      end,
      itemButtonOnUpdateTooltip = function(self, tooltip)
        tooltip:SetOwner(self, "ANCHOR_RIGHT")
        tooltip:SetBagItem(self.item.bag, self.item.slot)
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(L.LEFT_CLICK, L.SELL)
        tooltip:AddDoubleLine(L.RIGHT_CLICK, L.ADD_TO_LIST:format(Lists.ProfileExclusions.name))
        tooltip:AddDoubleLine(
          Addon:Concat("+", L.SHIFT_KEY, L.RIGHT_CLICK),
          L.ADD_TO_LIST:format(Lists.GlobalExclusions.name)
        )
        tooltip:AddDoubleLine(Addon:Concat("+", L.ALT_KEY, L.RIGHT_CLICK), Colors.Red(L.DESTROY))
      end,
      itemButtonOnClick = function(self, button)
        if button == "LeftButton" then
          Seller:HandleItem(self.item)
        end

        if button == "RightButton" then
          if IsAltKeyDown() then
            Destroyer:HandleItem(self.item)
          else
            local list = IsShiftKeyDown() and Lists.GlobalExclusions or Lists.ProfileExclusions
            list:Add(self.item.id)
          end
        end
      end,
      getItems = function() return junkItems end,
      addItem = function(itemId)
        local list = IsShiftKeyDown() and Lists.GlobalInclusions or Lists.ProfileInclusions
        list:Add(itemId)
      end,
      removeAllItems = function()
        local list = IsShiftKeyDown() and Lists.GlobalExclusions or Lists.ProfileExclusions
        for _, item in pairs(junkItems) do list:Add(item.id) end
      end
    })

    return itemsFrame
  end
})

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
        local item = JunkFilter:GetNextDestroyableJunkItem()
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
  Components.Root:SetHidden(false)
  Components.Root:Layout()
end

function JunkFrame:Hide()
  Components.Root:SetHidden(true)
  Components.Root:Layout()
end

function JunkFrame:Toggle()
  if Components.Root:GetHidden() then
    self:Show()
  else
    self:Hide()
  end
end

-- ============================================================================
-- Events
-- ============================================================================

-- Auto Junk Frame.
EventManager:Once(E.StoreCreated, function()
  EventManager:On(E.Wow.MerchantShow, function()
    if StateManager:GetProfileState().settings.autoJunkFrame then JunkFrame:Show() end
  end)
  EventManager:On(E.Wow.MerchantClosed, function()
    if StateManager:GetProfileState().settings.autoJunkFrame then JunkFrame:Hide() end
  end)
end)
