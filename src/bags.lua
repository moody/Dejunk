local _, Addon = ...
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER
local Bags = Addon.Bags
local GetContainerItemID = _G.GetContainerItemID
local GetContainerItemInfo = _G.GetContainerItemInfo
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetDetailedItemLevelInfo = _G.GetDetailedItemLevelInfo
local GetItemInfo = _G.GetItemInfo
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS


-- Bag iterator function.
local function iterateBags()
  local bag, slot = BACKPACK_CONTAINER, 0
  local numSlots = GetContainerNumSlots(bag)

  return function()
    slot = slot + 1

    if (slot > numSlots) then
      slot = 1

      -- Move to next bag
      repeat
        bag = bag + 1
        if (bag > NUM_BAG_SLOTS) then return nil end
        numSlots = GetContainerNumSlots(bag)
      until (numSlots > 0)
    end

    return bag, slot, GetContainerItemID(bag, slot)
  end
end


-- Returns a table of info for the item in the specified bag slot, or nil if the
-- item could not be retrieved.
-- @param {number} bag
-- @param {number} slot
-- @param {table} item [optional]
-- @return {table | nil}
function Bags:GetItem(bag, slot, item)
  -- GetContainerItemInfo
  local
    texture,
    quantity,
    _, -- locked
    quality,
    readable,
    lootable,
    itemLink,
    _, -- filtered
    noValue,
    itemID =
    GetContainerItemInfo(bag, slot)

  if texture == nil or itemID == nil then return nil end

  -- GetItemInfo
  local
    name,
    _, -- itemLink
    _, -- quality
    itemLevel,
    reqLevel,
    class,
    subClass,
    maxStack,
    equipSlot,
    _, -- texture
    price,
    classID,
    subClassID,
    bindType,
    expacID,
    setID,
    isCraftingReagent =
    GetItemInfo(itemLink)

  if name == nil or isCraftingReagent == nil then
    name,
    _, -- itemLink
    _, -- quality
    itemLevel,
    reqLevel,
    class,
    subClass,
    maxStack,
    equipSlot,
    _, -- texture
    price,
    classID,
    subClassID,
    bindType,
    expacID,
    setID,
    isCraftingReagent =
    GetItemInfo(itemID)

    if name == nil or isCraftingReagent == nil then return nil end
  end

  -- Build item
  if type(item) ~= "table" then
    item = {}
  else
    for k in pairs(item) do item[k] = nil end
  end

  item.Bag = bag
  item.Slot = slot

  -- GetContainerItemInfo
  item.Texture = texture
  item.Quantity = quantity
  item.Quality = quality
  item.Readable = readable
  item.Lootable = lootable
  item.ItemLink = itemLink
  item.NoValue = noValue
  item.ItemID = itemID

  -- GetItemInfo
  item.Name = name
  item.RequiredLevel = reqLevel
  item.Class = class
  item.SubClass = subClass
  item.MaxStack = maxStack
  item.EquipSlot = equipSlot
  item.Price = price
  item.ClassID = classID
  item.SubClassID = subClassID
  item.BindType = bindType
  item.ExpacID = expacID
  item.SetID = setID
  item.IsCraftingReagent = isCraftingReagent

  -- GetDetailedItemLevelInfo
  item.ItemLevel = GetDetailedItemLevelInfo(itemLink) or itemLevel

  return item
end


-- Returns an array of items in the player's bags.
-- @param {table} items
-- @return {table} items
function Bags:GetItems(items)
  if type(items) ~= "table" then
    items = {}
  else
    for k in pairs(items) do items[k] = nil end
  end

  items.allCached = true

  for bag, slot, itemID in iterateBags() do
    if itemID then
      local item = self:GetItem(bag, slot)
      if item then
        items[#items+1] = item
      else
        items.allCached = false
      end
    end
  end

  return items
end


-- Returns true if the specified bag slot is empty.
-- @param {number} bag
-- @param {number} slot
-- @return {boolean}
function Bags:IsEmpty(bag, slot)
  return GetContainerItemID(bag, slot) == nil
end


-- Returns true if the specified item is still in the player's bags.
-- @param {table} item
-- @return {boolean}
function Bags:StillInBags(item)
  local _, quantity, _, _, _, _, _, _, _, itemID =
    GetContainerItemInfo(item.Bag, item.Slot)
  return item.ItemID == itemID and item.Quantity == quantity
end


-- Returns true if the specified item is locked.
-- @param {table} item
-- @return {boolean}
function Bags:IsLocked(item)
  local locked = select(3, GetContainerItemInfo(item.Bag, item.Slot))
  return locked
end
