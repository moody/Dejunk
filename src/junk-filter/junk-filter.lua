local Addon = select(2, ...) ---@type Addon
local ItemFilters = Addon:GetModule("ItemFilters")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
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

do -- Convenience methods.
  local items = {}

  --- Returns the number of sellable and destroyable junk items.
  --- @return integer numSellable, integer numDestroyable
  function JunkFilter:GetNumJunkItems()
    local numSellable = #self:GetSellableJunkItems(items)
    local numDestroyable = #self:GetDestroyableJunkItems(items)
    return numSellable, numDestroyable
  end

  --- Returns the next sellable junk item if one exists.
  --- @return BagItem|nil
  function JunkFilter:GetNextSellableJunkItem()
    self:GetSellableJunkItems(items)
    return items[1]
  end

  --- Returns the next destroyable junk item if one exists.
  --- @return BagItem|nil
  function JunkFilter:GetNextDestroyableJunkItem()
    self:GetDestroyableJunkItems(items)
    return items[1]
  end
end

--- Creates or updates an array of sellable junk items.
--- @param items? BagItem[]
--- @return BagItem[] sellableItems
function JunkFilter:GetSellableJunkItems(items)
  return getJunkItems(self.IsSellableJunkItem, items)
end

--- Creates or updates an array of destroyable junk items.
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
  if not Items:IsItemStillInBags(item) then
    return false
  end

  local profileSettings = StateManager:GetProfileState().settings

  -- Check if item can be sold or destroyed.
  if not (Items:IsItemSellable(item) or Items:IsItemDestroyable(item)) then
    return false
  end

  --- @type ItemFilterResult, string?
  local result, reason

  -- Refundable.
  result, reason = ItemFilters:Refundable(item)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Locked.
  result, reason = ItemFilters:Locked(item)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Exclude equipment above item level. Runs before the lists so it can
  -- override an Inclusions match.
  result, reason = ItemFilters:ExcludeAboveItemLevel(item, profileSettings.excludeAboveItemLevel)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Lists.
  result, reason = ItemFilters:ByLists(item)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Exclude equipment sets.
  if not (Addon.IS_VANILLA or Addon.IS_TBC) then
    result, reason = ItemFilters:ExcludeEquipmentSets(item, profileSettings.excludeEquipmentSets)
    if result ~= ItemFilters.PASS then
      return result == ItemFilters.JUNK, reason
    end
  end

  -- Exclude unbound equipment.
  result, reason = ItemFilters:ExcludeUnboundEquipment(item, profileSettings.excludeUnboundEquipment)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    result, reason = ItemFilters:ExcludeWarbandEquipment(item, profileSettings.excludeWarbandEquipment)
    if result ~= ItemFilters.PASS then
      return result == ItemFilters.JUNK, reason
    end
  end

  -- Exclude by equipment type.
  result, reason = ItemFilters:ExcludeByEquipmentType(item, profileSettings.excludeByEquipmentType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include by quality.
  result, reason = ItemFilters:IncludeByQuality(item, profileSettings.includeByQuality)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include below item level.
  result, reason = ItemFilters:IncludeBelowItemLevel(item, profileSettings.includeBelowItemLevel)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include by equipment type.
  result, reason = ItemFilters:IncludeByEquipmentType(item, profileSettings.includeByEquipmentType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include artifact relics.
  if Addon.IS_RETAIL and profileSettings.includeArtifactRelics and Items:IsItemArtifactRelic(item) then
    return true, concat(L.OPTIONS_TEXT, L.INCLUDE_ARTIFACT_RELICS_TEXT)
  end

  -- No filters matched.
  return false, L.NO_FILTERS_MATCHED
end
