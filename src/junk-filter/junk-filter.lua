local Addon = select(2, ...) ---@type Addon
local ItemFilters = Addon:GetModule("ItemFilters")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")

--- @class JunkFilter
local JunkFilter = Addon:GetModule("JunkFilter")

-- ============================================================================
-- JunkFilter
-- ============================================================================

--- Returns why the given `item` cannot be sold right now, or `nil` if nothing stops the sale. Does not check whether
--- the item is junk.
--- @param item BagItem
--- @return string? reason
function JunkFilter:GetSellBlockReason(item)
  if Items:IsItemRefundable(item) then
    return L.ITEM_IS_REFUNDABLE
  end
end

--- Returns `true` and a reason string if the given `item` is junk and can be sold. A junk item that
--- `GetSellBlockReason()` blocks returns `false` and that reason.
--- @param item BagItem
--- @return boolean isSellableJunk, string? reason
function JunkFilter:IsSellableJunkItem(item)
  local isJunk, reason = self:IsJunkItem(item, "SELL")

  if isJunk then
    local blockReason = self:GetSellBlockReason(item)
    if blockReason then return false, blockReason end
  end

  return isJunk, reason
end

--- Returns `true` and a reason string if the given `item` is junk for the given `filterType`, or for
--- either type if none is given.
--- @param item BagItem
--- @param filterType? ItemFilterType
--- @return boolean isJunk, string? reason
function JunkFilter:IsJunkItem(item, filterType)
  if not filterType then
    local isSellableJunk, sellReason = self:IsJunkItem(item, "SELL")
    if isSellableJunk then return true, sellReason end

    local isDestroyableJunk, destroyReason = self:IsJunkItem(item, "DESTROY")
    if isDestroyableJunk then return true, destroyReason end

    return false, sellReason or destroyReason
  end

  if not Items:IsItemStillInBags(item) then
    return false
  end

  -- Check if item can be sold or destroyed, depending on the filter type.
  if filterType == "SELL" and not Items:IsItemSellable(item) then
    return false, L.ITEM_CANNOT_BE_SOLD
  end

  if filterType == "DESTROY" and not Items:IsItemDestroyable(item) then
    return false, L.ITEM_CANNOT_BE_DESTROYED
  end

  --- @type ItemFilterResult, string?
  local result, reason

  local profileSettings = StateManager:GetProfileState().settings

  -- Exclude equipment above item level. Runs before the lists so it can
  -- override an Inclusions match.
  result, reason = ItemFilters:ExcludeAboveItemLevel(item, profileSettings.excludeAboveItemLevel, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Exclude above price.
  result, reason = ItemFilters:ExcludeAbovePrice(item, profileSettings.excludeAbovePrice, filterType)
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
    result, reason = ItemFilters:ExcludeEquipmentSets(item, profileSettings.excludeEquipmentSets, filterType)
    if result ~= ItemFilters.PASS then
      return result == ItemFilters.JUNK, reason
    end
  end

  -- Exclude unbound equipment.
  result, reason = ItemFilters:ExcludeUnboundEquipment(item, profileSettings.excludeUnboundEquipment, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    result, reason = ItemFilters:ExcludeWarbandEquipment(item, profileSettings.excludeWarbandEquipment, filterType)
    if result ~= ItemFilters.PASS then
      return result == ItemFilters.JUNK, reason
    end
  end

  -- Exclude by equipment type.
  result, reason = ItemFilters:ExcludeByEquipmentType(item, profileSettings.excludeByEquipmentType, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include by quality.
  result, reason = ItemFilters:IncludeByQuality(item, profileSettings.includeByQuality, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include below item level.
  result, reason = ItemFilters:IncludeBelowItemLevel(item, profileSettings.includeBelowItemLevel, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include below price.
  result, reason = ItemFilters:IncludeBelowPrice(item, profileSettings.includeBelowPrice, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include by equipment type.
  result, reason = ItemFilters:IncludeByEquipmentType(item, profileSettings.includeByEquipmentType, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include artifact relics.
  if Addon.IS_RETAIL then
    result, reason = ItemFilters:IncludeArtifactRelics(item, profileSettings.includeArtifactRelics, filterType)
    if result ~= ItemFilters.PASS then
      return result == ItemFilters.JUNK, reason
    end
  end

  -- No filters matched.
  return false, L.NO_FILTERS_MATCHED
end
