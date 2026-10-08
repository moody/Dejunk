local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local EquipmentTypes = Addon:GetModule("EquipmentTypes")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")

--- @class ItemFilters
local ItemFilters = Addon:GetModule("ItemFilters")

--- The kind of filter being run: for selling, or for destroying.
--- @alias ItemFilterType "SELL" | "DESTROY"

--- The filter types that an option applies to: one of them, or both.
--- @alias ItemFilterScope ItemFilterType | "BOTH"

--- What a filter decided about an item.
--- @alias ItemFilterResult "JUNK" | "NOT_JUNK" | "PASS"

--- The filter decided that the item is junk.
--- @type ItemFilterResult
ItemFilters.JUNK = "JUNK"

--- The filter decided that the item is not junk.
--- @type ItemFilterResult
ItemFilters.NOT_JUNK = "NOT_JUNK"

--- The filter did not apply.
--- @type ItemFilterResult
ItemFilters.PASS = "PASS"

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Concatenates reason string arguments.
--- @param ... string|number
--- @return string
local function concat(...)
  return Addon:Concat(" > ", ...)
end

--- Returns the given `item`'s subclass name in its quality color, in grey brackets.
--- @param item BagItem
--- @return string
local function getSubclassText(item)
  local qualityColor = Colors.ByQuality[item.quality] or Colors.White
  return Colors.Grey("(%s)"):format(qualityColor(Items:GetItemSubclassName(item)))
end

--- Returns the price of the item's whole stack, or `nil` if the item has no value.
--- @param item BagItem
--- @return integer?
local function getStackPrice(item)
  if item.noValue or item.price == 0 then return nil end
  return item.price * item.quantity
end

--- Returns `true` if the given `scope` includes the given `filterType`.
--- @param scope ItemFilterScope
--- @param filterType ItemFilterType
--- @return boolean
local function scopeIncludes(scope, filterType)
  return scope == "BOTH" or scope == filterType
end

--- Returns the reason for a price option, naming its value.
--- @param labelText string
--- @param state PriceOptionState
--- @return string
local function getPriceReason(labelText, state)
  local valueText = Colors.Grey("(%s)"):format(Colors.White(GetCoinTextureString(state.value)))
  return concat(L.PROFILE_OPTIONS_TEXT, labelText .. " " .. valueText)
end

--- Returns `true` if the given `itemQuality` is enabled within the given `checkboxValues`.
--- @param itemQuality integer
--- @param checkboxValues ItemQualitiesState
local function isItemQualityCheckboxValueEnabled(itemQuality, checkboxValues)
  return (
    (checkboxValues.poor and itemQuality == Enum.ItemQuality.Poor) or
    (checkboxValues.common and itemQuality == (Enum.ItemQuality.Common or Enum.ItemQuality.Standard)) or
    (checkboxValues.uncommon and itemQuality == (Enum.ItemQuality.Uncommon or Enum.ItemQuality.Good)) or
    (checkboxValues.rare and itemQuality == Enum.ItemQuality.Rare) or
    (checkboxValues.epic and itemQuality == Enum.ItemQuality.Epic)
  )
end

-- ============================================================================
-- ItemFilters
-- ============================================================================

--- Refundable items are never junk.
--- @param item BagItem
--- @return ItemFilterResult result, string? reason
function ItemFilters:Refundable(item)
  if Items:IsItemRefundable(item) then
    return self.NOT_JUNK, L.ITEM_IS_REFUNDABLE
  end

  return self.PASS
end

--- Locked items are never junk.
--- @param item BagItem
--- @return ItemFilterResult result, string? reason
function ItemFilters:Locked(item)
  if Items:IsItemLocked(item) then
    return self.NOT_JUNK, L.ITEM_IS_LOCKED
  end

  return self.PASS
end

--- Equipment with an item level above the value is not junk, for the selected qualities and the option's scope.
--- @param item BagItem
--- @param state ItemLevelOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:ExcludeAboveItemLevel(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) and Items:IsItemEquipment(item) then
    if Items:GetItemLevel(item) > state.value then
      if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
        local valueText = Colors.Grey("(%s)"):format(Colors.Yellow(state.value))
        return self.NOT_JUNK, concat(L.PROFILE_OPTIONS_TEXT, L.EXCLUDE_ABOVE_ITEM_LEVEL_TEXT .. " " .. valueText)
      end
    end
  end

  return self.PASS
end

--- Filters by lists: profile lists before global lists, and exclusions before inclusions.
--- @param item BagItem
--- @return ItemFilterResult result, string? reason
function ItemFilters:ByLists(item)
  if Lists.ProfileExclusions:Contains(item.id) then
    return self.NOT_JUNK, concat(L.LISTS, Lists.ProfileExclusions.name)
  end

  if Lists.ProfileInclusions:Contains(item.id) then
    return self.JUNK, concat(L.LISTS, Lists.ProfileInclusions.name)
  end

  if Lists.GlobalExclusions:Contains(item.id) then
    return self.NOT_JUNK, concat(L.LISTS, Lists.GlobalExclusions.name)
  end

  if Lists.GlobalInclusions:Contains(item.id) then
    return self.JUNK, concat(L.LISTS, Lists.GlobalInclusions.name)
  end

  return self.PASS
end

--- Items that are saved to an equipment set are not junk.
--- @param item BagItem
--- @param state boolean
--- @return ItemFilterResult result, string? reason
function ItemFilters:ExcludeEquipmentSets(item, state)
  if state and item.isEquipmentSet then
    return self.NOT_JUNK, concat(L.PROFILE_OPTIONS_TEXT, L.EXCLUDE_EQUIPMENT_SETS_TEXT)
  end

  return self.PASS
end

--- Equipment that is not bound is not junk, for the selected qualities and the option's scope.
--- @param item BagItem
--- @param state QualitiesOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:ExcludeUnboundEquipment(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) then
    if Items:IsItemEquipment(item) and not Items:IsItemBound(item) then
      if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
        return self.NOT_JUNK, concat(L.PROFILE_OPTIONS_TEXT, L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT)
      end
    end
  end

  return self.PASS
end

--- Warband equipment is not junk, for the selected qualities and the option's scope.
--- @param item BagItem
--- @param state QualitiesOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:ExcludeWarbandEquipment(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) and Items:IsItemWarbandEquipment(item) then
    if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
      return self.NOT_JUNK, concat(L.PROFILE_OPTIONS_TEXT, L.EXCLUDE_WARBAND_EQUIPMENT_TEXT)
    end
  end

  return self.PASS
end

--- Equipment of a selected type is not junk, for the selected qualities and the option's scope.
--- @param item BagItem
--- @param state EquipmentTypeOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:ExcludeByEquipmentType(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) and Items:IsItemEquipment(item) then
    if EquipmentTypes:IsItemTypeSelected(item, state.armor, state.weapons) then
      if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
        local typeText = L.EXCLUDE_BY_EQUIPMENT_TYPE_TEXT .. " " .. getSubclassText(item)
        return self.NOT_JUNK, concat(L.PROFILE_OPTIONS_TEXT, typeText)
      end
    end
  end

  return self.PASS
end

--- Items of a selected quality are junk, for the option's scope.
--- @param item BagItem
--- @param state QualitiesOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:IncludeByQuality(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) then
    if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
      return self.JUNK, concat(L.PROFILE_OPTIONS_TEXT, L.INCLUDE_BY_QUALITY_TEXT)
    end
  end

  return self.PASS
end

--- Equipment with an item level below the value is junk, for the selected qualities and the option's scope.
--- @param item BagItem
--- @param state ItemLevelOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:IncludeBelowItemLevel(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) and Items:IsItemEquipment(item) then
    if Items:GetItemLevel(item) < state.value then
      if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
        local valueText = Colors.Grey("(%s)"):format(Colors.Yellow(state.value))
        return self.JUNK, concat(L.PROFILE_OPTIONS_TEXT, L.INCLUDE_BELOW_ITEM_LEVEL_TEXT .. " " .. valueText)
      end
    end
  end

  return self.PASS
end

--- Equipment of a selected type is junk, for the selected qualities and the option's scope.
--- @param item BagItem
--- @param state EquipmentTypeOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:IncludeByEquipmentType(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) and Items:IsItemEquipment(item) then
    if EquipmentTypes:IsItemTypeSelected(item, state.armor, state.weapons) then
      if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
        local typeText = L.INCLUDE_BY_EQUIPMENT_TYPE_TEXT .. " " .. getSubclassText(item)
        return self.JUNK, concat(L.PROFILE_OPTIONS_TEXT, typeText)
      end
    end
  end

  return self.PASS
end

--- Artifact relics are junk, for the option's scope.
--- @param item BagItem
--- @param state ScopeOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:IncludeArtifactRelics(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) and Items:IsItemArtifactRelic(item) then
    return self.JUNK, concat(L.PROFILE_OPTIONS_TEXT, L.INCLUDE_ARTIFACT_RELICS_TEXT)
  end

  return self.PASS
end

--- Items whose stack price is above the value are not junk, for the selected qualities and the option's scope.
--- @param item BagItem
--- @param state PriceOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:ExcludeAbovePrice(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) then
    local price = getStackPrice(item)
    if price and price > state.value then
      if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
        return self.NOT_JUNK, getPriceReason(L.EXCLUDE_ABOVE_PRICE_TEXT, state)
      end
    end
  end

  return self.PASS
end

--- Items whose stack price is below the value are junk, for the selected qualities and the option's scope.
--- @param item BagItem
--- @param state PriceOptionState
--- @param filterType ItemFilterType
--- @return ItemFilterResult result, string? reason
function ItemFilters:IncludeBelowPrice(item, state, filterType)
  if state.enabled and scopeIncludes(state.scope, filterType) then
    local price = getStackPrice(item)
    if price and price < state.value then
      if isItemQualityCheckboxValueEnabled(item.quality, state.qualities) then
        return self.JUNK, getPriceReason(L.INCLUDE_BELOW_PRICE_TEXT, state)
      end
    end
  end

  return self.PASS
end
