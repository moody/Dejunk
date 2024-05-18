local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local StateManager = Addon:GetModule("StateManager")

--- @class JunkFilter
local JunkFilter = Addon:GetModule("JunkFilter")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Concatenates reason string arguments.
--- @param ... string|number
--- @return string
local function concat(...)
  return Addon:Concat(" > ", ...)
end

--- Comparison function for sorting items by price, quality, and name.
--- @param a BagItem
--- @param b BagItem
--- @return boolean
local function itemSortFunc(a, b)
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

--- Returns junk items as determined by the given `filterFunc`.
--- @param filterFunc fun(self: JunkFilter, item: BagItem): boolean, string?
--- @param items? BagItem[]
--- @return BagItem[] junkItems
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

  table.sort(items, itemSortFunc)

  return items
end

-- ============================================================================
-- JunkFilter
-- ============================================================================

--- Creates or updates an array of sellable items.
--- @param items? BagItem[]
--- @return BagItem[] sellableItems
function JunkFilter:GetSellableJunkItems(items)
  return getJunkItems(self.IsSellableJunkItem, items)
end

--- Creates or updates an array of destroyable items.
--- @param items? BagItem[]
--- @return BagItem[] destroyableItems
function JunkFilter:GetDestroyableJunkItems(items)
  return getJunkItems(self.IsDestroyableJunkItem, items)
end

--- Creates or updates an array of junk items.
--- @param items? BagItem[]
--- @return BagItem[] junkItems
function JunkFilter:GetJunkItems(items)
  return getJunkItems(self.IsJunkItem, items)
end

--- Returns `true` and a reason string if the given `item` is junk and can be sold.
--- @param item BagItem
--- @return boolean isSellableJunk, string? reason
function JunkFilter:IsSellableJunkItem(item)
  if not Items:IsItemSellable(item) then return false end
  return self:IsJunkItem(item)
end

--- Returns `true` and a reason string if the given `item` is junk and can be destroyed.
--- @param item BagItem
--- @return boolean isDestroyableJunk, string? reason
function JunkFilter:IsDestroyableJunkItem(item)
  if not Items:IsItemDestroyable(item) then return false end
  return self:IsJunkItem(item)
end

--- Returns `true` and a reason string if the given `item` is junk.
--- @param item BagItem
--- @return boolean isJunk, string? reason
function JunkFilter:IsJunkItem(item)
  local currentState = StateManager:GetCurrentState()

  -- Check if item can be sold or destroyed.
  if not (Items:IsItemSellable(item) or Items:IsItemDestroyable(item)) then
    return false
  end

  -- Refundable.
  if Items:IsItemRefundable(item) then
    return false, L.ITEM_IS_REFUNDABLE
  end

  -- Locked.
  if Items:IsItemLocked(item) then
    return false, L.ITEM_IS_LOCKED
  end

  -- PerChar lists.
  if Lists.PerCharExclusions:Contains(item.id) then
    return false, concat(L.LISTS, Lists.PerCharExclusions.name)
  end
  if Lists.PerCharInclusions:Contains(item.id) then
    return true, concat(L.LISTS, Lists.PerCharInclusions.name)
  end

  -- Global lists.
  if Lists.GlobalExclusions:Contains(item.id) then
    return false, concat(L.LISTS, Lists.GlobalExclusions.name)
  end
  if Lists.GlobalInclusions:Contains(item.id) then
    return true, concat(L.LISTS, Lists.GlobalInclusions.name)
  end

  -- Exclude equipment sets.
  if not Addon.IS_VANILLA and currentState.excludeEquipmentSets and item.isEquipmentSet then
    return false, concat(L.OPTIONS_TEXT, L.EXCLUDE_EQUIPMENT_SETS_TEXT)
  end

  -- Exclude unbound equipment.
  if currentState.excludeUnboundEquipment and (Items:IsItemEquipment(item) and not Items:IsItemBound(item)) then
    return false, concat(L.OPTIONS_TEXT, L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT)
  end

  -- Include poor items.
  if currentState.includePoorItems and item.quality == Enum.ItemQuality.Poor then
    return true, concat(L.OPTIONS_TEXT, L.INCLUDE_POOR_ITEMS_TEXT)
  end

  -- Soulbound equipment filters.
  if Items:IsItemBound(item) and Items:IsItemEquipment(item) then
    -- Include below item level.
    if currentState.includeBelowItemLevel.enabled then
      local value = currentState.includeBelowItemLevel.value
      if item.itemLevel < value then
        local valueText = Colors.Grey("(%s)"):format(Colors.Yellow(value))
        return true, concat(L.OPTIONS_TEXT, L.INCLUDE_BELOW_ITEM_LEVEL_TEXT .. " " .. valueText)
      end
    end
    -- Include unsuitable equipment.
    if currentState.includeUnsuitableEquipment and not Items:IsItemSuitable(item) then
      return true, concat(L.OPTIONS_TEXT, L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT)
    end
  end

  -- Include artifact relics.
  if Addon.IS_RETAIL and currentState.includeArtifactRelics and Items:IsItemArtifactRelic(item) then
    return true, concat(L.OPTIONS_TEXT, L.INCLUDE_ARTIFACT_RELICS_TEXT)
  end

  -- No filters matched.
  return false, L.NO_FILTERS_MATCHED
end
