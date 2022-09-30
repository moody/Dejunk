local _, Addon = ...
local Colors = Addon.Colors
local Items = Addon.Items
local JunkFilter = Addon.JunkFilter
local L = Addon.Locale
local Lists = Addon.Lists
local SavedVariables = Addon.SavedVariables

-- ============================================================================
-- Local Functions
-- ============================================================================

local concat
do
  local cache = {}
  concat = function(...)
    for k in pairs(cache) do cache[k] = nil end
    for i = 1, select("#", ...) do cache[#cache + 1] = select(i, ...) end
    return table.concat(cache, Colors.Grey(" > "))
  end
end


local function getJunkItems(filterFunc, items)
  items = Items:GetItems(items)

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

function JunkFilter:GetSellableJunkItems(items)
  return getJunkItems(self.IsSellableJunkItem, items)
end

function JunkFilter:GetDestroyableJunkItems(items)
  return getJunkItems(self.IsDestroyableJunkItem, items)
end

function JunkFilter:GetJunkItems(items)
  return getJunkItems(self.IsJunkItem, items)
end

function JunkFilter:IsSellableJunkItem(item)
  if not Items:IsItemSellable(item) then return false end
  return self:IsJunkItem(item)
end

function JunkFilter:IsDestroyableJunkItem(item)
  if not Items:IsItemDestroyable(item) then return false end
  return self:IsJunkItem(item)
end

function JunkFilter:IsJunkItem(item)
  local savedVariables = SavedVariables:Get()

  if not (Items:IsItemSellable(item) or Items:IsItemDestroyable(item)) then
    return false
  end

  if Items:IsItemRefundable(item) then
    return false, L.ITEM_IS_REFUNDABLE
  end

  if Items:IsItemLocked(item) then
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
