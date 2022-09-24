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

-- Create frame.
JunkFrame.frame = (function()
  local frame = Widgets:Window({
    name = ADDON_NAME .. "_JunkFrame",
    width = 325,
    height = 375,
    titleText = Colors.Yellow(L.JUNK_ITEMS),
  })
  frame.items = {}

  -- Next item button.
  frame.nextItemButton = Widgets:Button({
    name = "$parent_NextItemButton",
    parent = frame,
    points = {
      { "BOTTOMLEFT", frame, Widgets:Padding(), Widgets:Padding() },
      { "BOTTOMRIGHT", frame, -Widgets:Padding(), Widgets:Padding() }
    },
    labelText = L.HANDLE_NEXT_ITEM,
    onClick = function(self)
      -- TODO: If item sellable AND merchant frame shown, sell. Otherwise destroy item.
      Addon:Debug("Not yet implemented.")
    end
  })

  frame:HookScript("OnUpdate", function(self)
    local hasItems = #self.items > 0
    self.nextItemButton:SetEnabled(hasItems)
    self.nextItemButton:SetAlpha(hasItems and 1 or 0.3)
  end)

  -- Items frame.
  frame.itemsFrame = Widgets:ItemsFrame({
    name = "$parent_ItemsFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.title, "BOTTOMLEFT", 0, -Widgets:Padding() },
      { "BOTTOMRIGHT", frame.nextItemButton, "TOPRIGHT", 0, Widgets:Padding(0.5) }
    },
    titleText = L.JUNK_ITEMS,
    tooltipText = L.JUNK_FRAME_TOOLTIP,
    getItems = function()
      JunkFilter:GetJunkItems(frame.items)
      table.sort(frame.items, sortFunc)
      return frame.items
    end,
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

  -- Hide when busy.
  frame:HideWhenBusy(frame.nextItemButton)
  frame:HideWhenBusy(frame.itemsFrame)

  frame:Hide()
  return frame
end)()
