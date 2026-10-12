local Addon = select(2, ...) ---@type Addon
local Items = Addon:GetModule("Items")

--- @class EquipmentSetsCache
local EquipmentSetsCache = Addon:GetModule("EquipmentSetsCache")

local EMPTY = {}

local cache = {}

-- ============================================================================
-- Functions
-- ============================================================================

--- Refreshes the cache.
function EquipmentSetsCache:Refresh()
  if Addon.IS_VANILLA or Addon.IS_TBC then return end

  for k in pairs(cache) do cache[k] = nil end

  for _, equipmentSetId in pairs(C_EquipmentSet.GetEquipmentSetIDs() or EMPTY) do
    for _, itemLocation in pairs(C_EquipmentSet.GetItemLocations(equipmentSetId) or EMPTY) do
      -- See: Blizzard_FrameXML/EquipmentManager.lua -> `EquipmentManager_UnpackLocation()`.
      if itemLocation and itemLocation >= 0 then
        local player = bit.band(itemLocation, ITEM_INVENTORY_LOCATION_PLAYER) ~= 0
        local bags = bit.band(itemLocation, ITEM_INVENTORY_LOCATION_BAGS) ~= 0
        if player and bags then
          itemLocation = itemLocation - ITEM_INVENTORY_LOCATION_PLAYER - ITEM_INVENTORY_LOCATION_BAGS
          local bag = bit.rshift(itemLocation, ITEM_INVENTORY_BAG_BIT_OFFSET)
          local slot = itemLocation - bit.lshift(bag, ITEM_INVENTORY_BAG_BIT_OFFSET)
          cache[Items:GetSlotKey(bag, slot)] = true
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
  return cache[Items:GetSlotKey(bag, slot)] == true
end
