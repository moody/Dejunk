local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local JunkFrame = Addon.UserInterface.JunkFrame
local L = Addon.Locale
local Widgets = Addon.UserInterface.Widgets
local JunkFilter = Addon.JunkFilter
local Lists = Addon.Lists

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

local function initialize()
  local parentFrame = Widgets:Window({
    name = ADDON_NAME .. "_JunkFrame",
    parent = UIParent,
    points = { { "CENTER" } },
    width = 325,
    height = 375,
    titleText = Colors.Blue(L.JUNK_FRAME),
  })

  local items = {}

  -- Add item frame.
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
      JunkFilter:GetJunkItems(items)
      table.sort(items, sortFunc)
      return items
    end,
    addItem = function(itemId) Lists.Inclusions:Add(itemId) end,
    removeItem = function(itemId) Lists.Exclusions:Add(itemId) end,
    removeAllItems = function()
      for _, item in pairs(items) do
        Lists.Exclusions:Add(item.id)
      end
    end
  })

  -- Add "Handle Next Item" button.
  -- OnClick: If item sellable AND merchant frame shown, sell. Else destroy item.
  -- OnUpdate: Disable button if #items == 0, hide widgets if Seller:IsBusy() or Lists:IsBusy()

  JunkFrame.parentFrame = parentFrame
end

function JunkFrame:Show()
  if not self.parentFrame then initialize() end
  self.parentFrame:Show()
end

function JunkFrame:Hide()
  if self.parentFrame then self.parentFrame:Hide() end
end

function JunkFrame:Toggle()
  if not self.parentFrame then
    self:Show()
  else
    if self.parentFrame:IsShown() then
      self.parentFrame:Hide()
    else
      self.parentFrame:Show()
    end
  end
end

-- C_Timer.After(0.1, function() JunkFrame:Show() end)
