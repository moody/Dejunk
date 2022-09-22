local _, Addon = ...
local Bags = Addon.Bags
local Colors = Addon.Colors
local JunkFilter = Addon.JunkFilter
local L = Addon.Locale
local Lists = Addon.Lists
local SavedVariables = Addon.SavedVariables

-- ============================================================================
-- Local Functions
-- ============================================================================

local function concat(...)
  return table.concat({ ... }, Colors.Grey(" > "))
end

local function getJunkItems(filterFunc)
  local items = Bags:GetItems()

  for i = #items, 1, -1 do
    local item = items[i]
    local isJunk, reason = filterFunc(JunkFilter, item)

    if isJunk then
      item.reason = reason
    else
      table.remove(items, i)
    end
  end

  return items
end

-- ============================================================================
-- JunkFilter
-- ============================================================================

function JunkFilter:GetSellableJunkItems()
  return getJunkItems(self.IsSellableJunkItem)
end

function JunkFilter:GetDestroyableJunkItems()
  return getJunkItems(self.IsDestroyableJunkItem)
end

function JunkFilter:IsSellableJunkItem(item)
  if not Bags:IsItemSellable(item) then return false end
  return self:IsJunkItem(item)
end

function JunkFilter:IsDestroyableJunkItem(item)
  if not Bags:IsItemDestroyable(item) then return false end
  return self:IsJunkItem(item)
end

function JunkFilter:IsJunkItem(item)
  local savedVariables = SavedVariables:Get()

  if not (Bags:IsItemSellable(item) or Bags:IsItemDestroyable(item)) then
    return false
  end

  if Bags:IsItemRefundable(item) then
    return false, L.ITEM_IS_REFUNDABLE
  end

  if Bags:IsItemLocked(item) then
    return false, L.ITEM_IS_LOCKED
  end

  if Lists.Exclusions:Contains(item.id) then
    return false, concat(L.LISTS, Lists.Exclusions.name)
  end

  if Lists.Inclusions:Contains(item.id) then
    return true, concat(L.LISTS, Lists.Inclusions.name)
  end

  if savedVariables.includePoorItems and item.quality == Enum.ItemQuality.Poor then
    return true, concat(L.OPTIONS_TEXT, L.INCLUDE_POOR_ITEMS_TEXT)
  end

  return false, L.NO_FILTERS_MATCHED
end
