local _, Addon = ...
local DBL = Addon.DethsBagLib
if DBL.__loaded then return end

local _G = _G
local ARMOR_CLASS = _G.GetItemClassInfo(_G.LE_ITEM_CLASS_ARMOR)
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER
local GetContainerItemID = _G.GetContainerItemID
local GetContainerItemInfo = _G.GetContainerItemInfo
local GetContainerItemLink = _G.GetContainerItemLink
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetDetailedItemLevelInfo = _G.GetDetailedItemLevelInfo
local GetItemInfo = _G.GetItemInfo
local IS_CLASSIC = select(4, _G.GetBuildInfo()) < 80000
local ItemMixins = DBL.ItemMixins
local next = next
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS
local pairs = pairs
local PREFIX = ("%s_%s_Backend_"):format(DBL.metadata.name, DBL.metadata.version)
local RETRIEVING_ITEM_INFO = _G.RETRIEVING_ITEM_INFO
local strtrim = _G.strtrim
local UIParent = _G.UIParent
local WEAPON_CLASS = _G.GetItemClassInfo(_G.LE_ITEM_CLASS_WEAPON)

-- Backend
local Backend = DBL.Backend
Backend.IsUpToDate = false
Backend.UpdateQueued = false
Backend.UpdateTimer = 0

Backend.Bags = {
  --[[ References to BagIndex tables should never change.
  [BagIndex] = {
    [SlotIndex] = item returned from Backend:GetItem()
    ...
  }
  ...
  --]]
}

Backend.Listeners = {
  -- [function] = true
}

Backend.ItemLevelQueue = {
  -- [item] = true
}

-- Add tables to Backend.Bags
for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do Backend.Bags[bag] = {} end

--[[ Debug func
local function debug(msg) print(format("|cFFFF7F50[DBL]|r %s", msg)) end
--]] local debug = _G.nop

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Bag iterator function.
local function iterateBags()
  local bag, slot = BACKPACK_CONTAINER, 0
  local numSlots = GetContainerNumSlots(bag)
  return function()
    slot = slot + 1
    if (slot > numSlots) then
      slot = 1
      repeat
        bag = bag + 1
        if (bag > NUM_BAG_SLOTS) then return nil end
        numSlots = GetContainerNumSlots(bag)
      until (numSlots > 0)
    end
    return bag, slot, GetContainerItemID(bag, slot)
  end
end

-- ============================================================================
-- BagUpdateFrame
-- ============================================================================

do
  local bagUpdateFrame = _G.CreateFrame("Frame", PREFIX.."BagUpdateFrame")
  local events = {
    BAG_UPDATE_DELAYED = true,
    PLAYER_LEVEL_UP = true,
    PLAYER_ENTERING_WORLD = true
  }
  if not IS_CLASSIC then events.ACTIVE_TALENT_GROUP_CHANGED = true end

  function bagUpdateFrame:OnEvent(event, ...)
    if events[event] then Backend:QueueUpdate() end
  end
  bagUpdateFrame:SetScript("OnEvent", bagUpdateFrame.OnEvent)
  for k in pairs(events) do bagUpdateFrame:RegisterEvent(k) end

  function bagUpdateFrame:OnUpdate(elapsed) Backend:OnUpdate(elapsed) end
  bagUpdateFrame:SetScript("OnUpdate", bagUpdateFrame.OnUpdate)
end

-- ============================================================================
-- Functions
-- ============================================================================

-- Queues DBL for updating.
function Backend:QueueUpdate()
  self.UpdateTimer = 0
  self.IsUpToDate = false
  self.UpdateQueued = true
  self.ListenersQueued = false
  for k in pairs(self.ItemLevelQueue) do self.ItemLevelQueue[k] = nil end
end

-- Called by bagUpdateFrame above.
function Backend:OnUpdate(elapsed)
  -- Update items if queued and all item info is available
  if self.UpdateQueued then
    if self:VerifyCache() then
      self.UpdateTimer = 0
      self.UpdateQueued = false
      self.ListenersQueued = true
      self:UpdateItems()
    end
  -- Update queued item levels
  elseif next(self.ItemLevelQueue) then
    for item in pairs(self.ItemLevelQueue) do
      local itemLevel = Backend:ScanItemLevel(item)
      if itemLevel then
        -- debug(format("%s ilvl: %s", item.ItemLink, itemLevel))
        item.ItemLevel = itemLevel
        self.ItemLevelQueue[item] = nil
      end
    end
  -- Notify listeners if queued and 1 second passes without a bag update
  elseif self.ListenersQueued then
    self.UpdateTimer = self.UpdateTimer + elapsed
    if (self.UpdateTimer >= 1) then -- 1 second delay
      if self:ValidateItems() then
        self.UpdateTimer = 0
        self.ListenersQueued = false
        for listener in pairs(self.Listeners) do listener() end
      end
    end
  end
end

-- Returns true if all items in the player's bags have info available.
function Backend:VerifyCache()
  for bag, slot, itemID in iterateBags() do
    if itemID then -- slot is not empty
      --[[
        NOTE: Mythic keystones and battle pets use a different type of item
        link than all other items. These links cause GetItemInfo(link) to
        return empty. When this happens, we fall back to using
        GetItemInfo(itemID).
      ]]
      local link = GetContainerItemLink(bag, slot)
      local name = link and GetItemInfo(link) or GetItemInfo(itemID)
      if not name or (name == RETRIEVING_ITEM_INFO) then return false end
    end
  end
  return true
end

-- Returns true if all Backend.Bags items are valid.
function Backend:ValidateItems()
  for bag, slot, itemID in iterateBags() do
    local item = self.Bags[bag][slot]
    --[[
      Fail if:
      1. Bag slot has item id, be we have no item
      2. Our item does not have the same item id
    --]]
    if (not item and itemID) or (item and (itemID ~= item.ItemID)) then
      self:QueueUpdate()
      return false
    end
  end
  -- Items are valid
  return true
end

-- Updates the Backend.Bags and Backend.Items tables.
function Backend:UpdateItems()
  for bag, slot, itemID in iterateBags() do
    -- Remove item if slot is now empty
    if not itemID then
      -- if self.Bags[bag][slot] then debug(format("[%s, %s] is now empty. Removing %s.", bag, slot, (self.Bags[bag][slot]).ItemLink)) end
      self.Bags[bag][slot] = nil
    -- Otherwise, add item to bag table
    else
      -- local wasEmpty = false
      -- if not self.Bags[bag][slot] then wasEmpty = true end
      local item = self:GetItem(bag, slot, self.Bags[bag][slot])
      if item then
        self.Bags[bag][slot] = item
        -- if wasEmpty then debug(format("Set [%s, %s] to %s", bag, slot, item.ItemLink)) end
      else -- this should never occur, but just in case...
        self:QueueUpdate()
        return
      end
    end

    self.IsUpToDate = true
  end
end

-- Returns a table of item info for the item residing within a specified bag
-- and slot, or nil if the info could not be retrieved.
function Backend:GetItem(bag, slot, item)
  -- Get item info, return nil if missing info
  -- Ignoring: locked (3), filtered (8)
  local texture, quantity, _, quality, readable, lootable, itemLink, _, noValue, itemID = GetContainerItemInfo(bag, slot)
  if not (texture and quantity and quality and (readable ~= nil) and (lootable ~= nil) and itemLink and (noValue ~= nil) and itemID) then return nil end

  -- Get additional item info, return nil if missing info
  -- Ignoring: itemLink (2), quality (3), itemLevel (4), texture (10)
  local name, _, _, _, reqLevel, class, subClass, maxStack, equipSlot, _, price, classID, subClassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(itemLink)
  if not name then name, _, _, _, reqLevel, class, subClass, maxStack, equipSlot, _, price, classID, subClassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(itemID) end
  if not (name and reqLevel and class and subClass and maxStack and equipSlot and price and classID and subClassID and bindType and expacID) then return nil end

  local itemLevel = GetDetailedItemLevelInfo(itemLink) or GetDetailedItemLevelInfo(itemID) or 1

  -- Build and return item
  if type(item) ~= "table" then
    item = {}
  else
    for k in pairs(item) do item[k] = nil end
  end

  item.Bag = bag
  item.Slot = slot

  -- Add mixins
  for k, v in pairs(ItemMixins) do item[k] = v end

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
  item.ItemLevel = itemLevel

  -- If item is armor or weapon, item level may be inaccurate. Queue for update via tooltip.
  if (class == ARMOR_CLASS) or (class == WEAPON_CLASS) then self.ItemLevelQueue[item] = true end

  return item
end

-- ============================================================================
-- ScanItemLevel
-- ============================================================================

local ITEM_LEVEL_CAPTURE = _G.ITEM_LEVEL:gsub("%%d", "(%%d+)")
local SCANNER_NAME = PREFIX .. "Scanner"
local SCANNER_TEXT_LEFT = SCANNER_NAME .. "TextLeft"
local SCANNER_TEXT_RIGHT = SCANNER_NAME .. "TextRight"

local scannerTooltip = _G.CreateFrame(
  "GameTooltip",
  SCANNER_NAME,
  nil,
  "GameTooltipTemplate"
)

-- Pooling functions
local get, release do
  local pool = {}

  -- Returns a table from the pool.
  get = function()
    local t = next(pool)
    if t then pool[t] = nil else t = {} end
    return t
  end

  -- Releases a table into the pool.
  -- @param {table} t
  release = function(t)
    for k in pairs(t) do t[k] = nil end
    pool[t] = true
  end
end

-- Returns all non-blank lines in the scanner tooltip.
-- @param rightSide - true for right-side scanning [optional]
local function getAllLines(rightSide)
  local textSide = rightSide and SCANNER_TEXT_RIGHT or SCANNER_TEXT_LEFT
  local lines = get()

  for i = 1, scannerTooltip:NumLines() do
    local line = strtrim((_G[textSide..i]):GetText()) or ""
    if (line ~= "") then lines[#lines+1] = line end
  end

  return lines
end

-- Returns true if tooltip information is available to be scanned.
local function isScannable()
  local allLines = getAllLines()
  if (#allLines == 0) then return false end

  for _, line in pairs(allLines) do
    if (line == RETRIEVING_ITEM_INFO) then
      release(allLines)
      return false
    end
  end

  release(allLines)
  return true
end

-- Returns the first match for a specified pattern in the tooltip.
-- @param rightSide - true for right-side scanning
-- @param pattern - the pattern to match
local function match(rightSide, pattern)
  local allLines = getAllLines(rightSide)
  local result

  for _, line in pairs(allLines) do
    result = line:match(pattern)
    if result then
      release(allLines)
      return result
    end
  end

  release(allLines)
  return nil
end

-- Scans and returns the bag item's item level from its tooltip.
-- @param item - the bag item to scan
function Backend:ScanItemLevel(item)
  scannerTooltip:SetOwner(UIParent, "ANCHOR_NONE")
  scannerTooltip:SetBagItem(item.Bag, item.Slot)
  if isScannable() then
    return tonumber(match(false, ITEM_LEVEL_CAPTURE) or "") or item.ItemLevel
  end
end
