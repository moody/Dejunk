local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local Commands = Addon.Commands
local E = Addon.Events
local EventManager = Addon.EventManager
local Items = Addon.Items
local JunkFilter = Addon.JunkFilter
local JunkFrame = Addon.UserInterface.JunkFrame
local L = Addon.Locale
local Lists = Addon.Lists
local SavedVariables = Addon.SavedVariables
local Widgets = Addon.UserInterface.Widgets

-- ============================================================================
-- Events
-- ============================================================================

do -- Auto Junk Frame.
  EventManager:On(E.Wow.MerchantShow, function()
    if SavedVariables:Get().autoJunkFrame then JunkFrame:Show() end
  end)

  EventManager:On(E.Wow.MerchantClosed, function()
    if SavedVariables:Get().autoJunkFrame then JunkFrame:Hide() end
  end)
end

-- ============================================================================
-- JunkFrame
-- ============================================================================

function JunkFrame:Show()
  self.frame:Show()
end

function JunkFrame:Hide()
  self.frame:Hide()
end

function JunkFrame:Toggle()
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end

-- ============================================================================
-- Initialize
-- ============================================================================

local function sortFunc(a, b)
  local aTotalPrice = a.price * a.quantity
  local bTotalPrice = b.price * b.quantity
  if aTotalPrice == bTotalPrice then
    if a.quality == b.quality then
      if a.name == b.name then
        return a.quantity < b.quantity
      end
      return a.name < b.name
    end
    return a.quality < b.quality
  end
  return aTotalPrice < bTotalPrice
end

local function hasSellableItems(items)
  for _, item in ipairs(items) do
    if Items:IsItemSellable(item) then
      return true
    end
  end
end

-- Create frame.
JunkFrame.frame = (function()
  local frame = Widgets:Window({
    name = ADDON_NAME .. "_JunkFrame",
    width = 325,
    height = 375,
    titleText = Colors.Yellow(L.JUNK_ITEMS),
  })
  frame:SetFrameLevel(frame:GetFrameLevel() + 1)
  frame.items = {}

  -- Next item button.
  frame.nextItemButton = Widgets:Button({
    name = "$parent_NextItemButton",
    parent = frame,
    points = {
      { "BOTTOMLEFT", frame, Widgets:Padding(), Widgets:Padding() },
      { "BOTTOMRIGHT", frame, -Widgets:Padding(), Widgets:Padding() }
    },
    labelColor = Colors.Yellow
  })

  frame:HookScript("OnUpdate", function(self)
    -- Get items.
    JunkFilter:GetJunkItems(frame.items)
    table.sort(frame.items, sortFunc)

    -- Title.
    self.title:SetText(Colors.Grey(("%s (%s)"):format(Colors.Yellow(L.JUNK_ITEMS), Colors.White(#self.items))))

    if #self.items > 0 then
      -- Next item button.
      if MerchantFrame and MerchantFrame:IsShown() and hasSellableItems(self.items) then
        self.nextItemButton.onClick = Commands.sell
        self.nextItemButton.label:SetText(L.START_SELLING)
      else
        self.nextItemButton.onClick = Commands.destroy
        self.nextItemButton.label:SetText(L.DESTROY_NEXT_ITEM)
      end
      self.nextItemButton:Show()
      -- Items frame.
      self.itemsFrame:SetPoint("BOTTOMRIGHT", frame.nextItemButton, "TOPRIGHT", 0, Widgets:Padding(0.5))
    else
      -- Next item button.
      self.nextItemButton.onClick = nil
      self.nextItemButton:Hide()
      -- Items frame.
      self.itemsFrame:SetPoint("BOTTOMRIGHT", frame, -Widgets:Padding(), Widgets:Padding())
    end

    -- Disable button if busy.
    local isBusy, reason = Addon:IsBusy()
    self.nextItemButton:SetEnabled(not isBusy)
    if isBusy then self.nextItemButton.label:SetText(reason) end
  end)

  -- Items frame.
  frame.itemsFrame = Widgets:ItemsFrame({
    name = "$parent_ItemsFrame",
    parent = frame,
    points = { { "TOPLEFT", frame.titleButton, "BOTTOMLEFT", Widgets:Padding(), 0 } },
    displayPrice = true,
    titleText = Colors.White(L.JUNK_ITEMS),
    onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(L.JUNK_ITEMS)
      tooltip:AddLine(L.JUNK_FRAME_TOOLTIP:format(Lists.Inclusions.name, Lists.Exclusions.name))
      tooltip:AddLine(" ")
      tooltip:AddDoubleLine(L.CTRL_ALT_RIGHT_CLICK, L.ADD_ALL_TO_LIST:format(Lists.Exclusions.name))
    end,
    getItems = function() return frame.items end,
    addItem = function(itemId) Lists.Inclusions:Add(itemId) end,
    removeItem = function(itemId) Lists.Exclusions:Add(itemId) end,
    removeAllItems = function()
      for _, item in pairs(frame.items) do
        Lists.Exclusions:Add(item.id)
      end
    end
  })

  frame.itemsFrame:HookScript("OnUpdate", function(self)
    local totalJunkValue = 0
    for _, item in pairs(frame.items) do
      totalJunkValue = totalJunkValue + item.price * item.quantity
    end
    self.title:SetText(Colors.White(GetCoinTextureString(totalJunkValue)))
  end)

  return frame
end)()
