local _, Addon = ...
local DBL = Addon.DethsBagLib
if DBL.__loaded then return end

local GetContainerItemInfo = _G.GetContainerItemInfo
local ItemMixins = DBL.ItemMixins
local select = select

-- Returns true if the item is locked.
function ItemMixins:IsLocked()
  local locked = select(3, GetContainerItemInfo(self.Bag, self.Slot))
  return locked
end

-- Returns true if the item has been filtered out by the blizzard bag search bar.
function ItemMixins:IsFiltered()
  local filtered = select(8, GetContainerItemInfo(self.Bag, self.Slot))
  return filtered
end
