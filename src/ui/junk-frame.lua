local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local JunkFrame = Addon.UserInterface.JunkFrame
local L = Addon.Locale
local Widgets = Addon.UserInterface.Widgets
local JunkFilter = Addon.JunkFilter
local Lists = Addon.Lists

-- ============================================================================
-- JunkFrame
-- ============================================================================

function JunkFrame:Show()
  self.parentFrame:Show()
end

function JunkFrame:Hide()
  self.parentFrame:Hide()
end

function JunkFrame:Toggle()
  if self.parentFrame:IsShown() then
    self.parentFrame:Hide()
  else
    self.parentFrame:Show()
  end
end

-- ============================================================================
-- Initialize
-- ============================================================================

local function sortFunc(a, b)
  local aTotalPrice = a.price * a.quantity
  local bTotalPrice = b.price * b.quantity
  if a.price == b.price then
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

-- Parent frame.
local parentFrame = Widgets:Window({
  name = ADDON_NAME .. "_JunkFrame",
  width = 325,
  height = 375,
  titleText = Colors.Yellow(L.JUNK_ITEMS),
})
parentFrame.items = {}

-- Items frame.
parentFrame.itemsFrame = Widgets:ItemsFrame({
  name = "$parent_ItemsFrame",
  parent = parentFrame,
  points = {
    { "TOPLEFT", parentFrame.title, "BOTTOMLEFT", 0, -Widgets:Padding() },
    { "BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -Widgets:Padding(), Widgets:Padding() }
  },
  titleText = L.JUNK_ITEMS,
  tooltipText = L.JUNK_FRAME_TOOLTIP,
  getItems = function()
    JunkFilter:GetJunkItems(parentFrame.items)
    table.sort(parentFrame.items, sortFunc)
    return parentFrame.items
  end,
  addItem = function(itemId) Lists.Inclusions:Add(itemId) end,
  removeItem = function(itemId) Lists.Exclusions:Add(itemId) end,
  removeAllItems = function()
    for _, item in pairs(parentFrame.items) do
      Lists.Exclusions:Add(item.id)
    end
  end
})

parentFrame.itemsFrame:HookScript("OnUpdate", function(self)
  local totalJunkValue = 0
  for _, item in pairs(parentFrame.items) do
    totalJunkValue = totalJunkValue + item.price * item.quantity
  end
  self.title:SetText(Colors.White(GetCoinTextureString(totalJunkValue)))
end)

-- Add "Handle Next Item" button.
-- OnClick: If item sellable AND merchant frame shown, sell. Else destroy item.
-- OnUpdate: Disable button if #parentFrame.items == 0, hide widgets if Seller:IsBusy() or Lists:IsBusy()

JunkFrame.parentFrame = parentFrame
parentFrame:Hide()
