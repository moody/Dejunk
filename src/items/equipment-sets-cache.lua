local Addon = select(2, ...) ---@type Addon

--- @class EquipmentSetsCache
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
  if Addon.IS_VANILLA then return end

  for k in pairs(cache) do cache[k] = nil end

  for _, equipmentSetId in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do
    for _, itemLocation in pairs(C_EquipmentSet.GetItemLocations(equipmentSetId)) do
      -- See: Blizzard_FrameXML/EquipmentManager.lua -> `EquipmentManager_UnpackLocation()`.
      if itemLocation and itemLocation >= 0 then
        local player = bit.band(itemLocation, ITEM_INVENTORY_LOCATION_PLAYER) ~= 0
        local bags = bit.band(itemLocation, ITEM_INVENTORY_LOCATION_BAGS) ~= 0
        if player and bags then
          itemLocation = itemLocation - ITEM_INVENTORY_LOCATION_PLAYER - ITEM_INVENTORY_LOCATION_BAGS
          local bag = bit.rshift(itemLocation, ITEM_INVENTORY_BAG_BIT_OFFSET)
          local slot = itemLocation - bit.lshift(bag, ITEM_INVENTORY_BAG_BIT_OFFSET)
          cache[getCacheKey(bag, slot)] = true
        end
      end
    end
  end
end

--- Returns `true` if the given `bag` and `slot` contains an equipment set item,
--- based on the current state of the cache.
--- @param bag number
--- @param slot number
function EquipmentSetsCache:IsBagSlotCached(bag, slot)
  return cache[getCacheKey(bag, slot)] == true
end
