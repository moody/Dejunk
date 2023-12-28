local _, Addon = ...
local EquipmentSetsCache = Addon:GetModule("EquipmentSetsCache")

local cache = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns a cache key for the given bag and slot.
--- @param bag number
--- @param slot number
local function getCacheKey(bag, slot)
  return ("%s_%s"):format(bag, slot)
end

-- ============================================================================
-- Functions
-- ============================================================================

--- Refreshes the cache.
function EquipmentSetsCache:Refresh()
  for k in pairs(cache) do cache[k] = nil end

  for _, equipmentSetId in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do
    for _, itemLocation in pairs(C_EquipmentSet.GetItemLocations(equipmentSetId)) do
      if itemLocation and itemLocation ~= 1 then
        local _, _, _, voidStorage, slot, bag = EquipmentManager_UnpackLocation(itemLocation)

        -- In Wrath, `voidStorage` is not returned.
        if Addon.IS_WRATH then
          bag = slot
          slot = voidStorage
        end

        if bag ~= nil and slot ~= nil then
          cache[getCacheKey(bag, slot)] = true
        end
      end
    end
  end
end

--- Returns `true` if the given bag and slot contains a equipment set item,
--- based on the current state of the cache.
--- @param bag number
--- @param slot number
function EquipmentSetsCache:IsBagSlotCached(bag, slot)
  return cache[getCacheKey(bag, slot)] == true
end
