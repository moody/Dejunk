local _, Addon = ...
local Colors = Addon.Colors
local E = Addon.Events
local EventManager = Addon.EventManager
local GetItemInfo = GetItemInfo
local GetItemInfoInstant = GetItemInfoInstant
local Items = Addon.Items
local L = Addon.Locale
local Lists = Addon.Lists
local SavedVariables = Addon.SavedVariables
local Seller = Addon.Seller

local MAX_PARSE_ATTEMPTS = 50
local parseAttempts = {
  -- ["itemId"] = count
}

local function getItemById(itemId)
  local name, link, quality, _, _, _, _, _, _, texture, price, classId = GetItemInfo(itemId)
  if link == nil then return nil end

  return {
    id = itemId,
    name = name,
    link = link,
    quality = quality,
    texture = texture,
    price = price,
    classId = classId
  }
end

-- ============================================================================
-- Mixins
-- ============================================================================

local Mixins = {}

function Mixins:Contains(itemId)
  return not not self.sv[tostring(itemId)]
end

function Mixins:Add(itemId)
  itemId = tostring(itemId)

  if self:Contains(itemId) then
    local index = self:GetIndex(itemId)
    if index ~= -1 then
      Addon:Print(L.ITEM_ALREADY_ON_LIST:format(self.items[index].link, self.name))
    end
  else
    self.toAdd[itemId] = true
  end
end

function Mixins:Remove(itemId)
  itemId = tostring(itemId)

  if self.sv[itemId] then
    self.sv[itemId] = nil

    local index = self:GetIndex(itemId)
    if index ~= -1 then
      local item = table.remove(self.items, index)
      Addon:Print(L.ITEM_REMOVED_FROM_LIST:format(item.link, self.name))
    end
  else
    local link = select(2, GetItemInfo(itemId))
    if link then Addon:Print(L.ITEM_NOT_ON_LIST:format(link, self.name)) end
  end
end

function Mixins:GetIndex(itemId)
  itemId = tostring(itemId)

  for i, item in ipairs(self.items) do
    if tostring(item.id) == itemId then
      return i
    end
  end

  return -1
end

function Mixins:RemoveAll()
  if next(self.sv) then Addon:Print(L.ALL_ITEMS_REMOVED_FROM_LIST:format(self.name)) end
  for k in pairs(self.sv) do self.sv[k] = nil end
  for k in pairs(self.items) do self.items[k] = nil end
end

function Mixins:GetItems()
  return self.items
end

function Mixins:Parse()
  if not next(self.toAdd) then return end

  -- Parse items.
  for itemId in pairs(self.toAdd) do
    -- Instantly fail if item doesn't exist.
    if not GetItemInfoInstant(itemId) then
      self.sv[itemId] = nil
      self.toAdd[itemId] = nil
      Addon:Print(L.ITEM_ID_DOES_NOT_EXIST:format(Colors.Grey(itemId)))
    else
      -- Attempt to parse the item.
      local item = getItemById(itemId)
      if item then
        -- Only add item if it can be sold or destroyed.
        if Items:IsItemSellable(item) or Items:IsItemDestroyable(item) then
          if not self.sv[itemId] then
            Addon:Print(L.ITEM_ADDED_TO_LIST:format(item.link, self.name))
          end
          self.sv[itemId] = true
          self.items[#self.items + 1] = item
          EventManager:Fire(E.ListItemAdded, self, item)
        else
          if not self.sv[itemId] then
            Addon:Print(L.CANNOT_SELL_OR_DESTROY_ITEM:format(item.link))
          end
          self.sv[itemId] = nil
        end

        -- Remove from parsing.
        parseAttempts[itemId] = nil
        self.toAdd[itemId] = nil
      else
        -- Retry parsing until max attempts reached.
        local attempts = (parseAttempts[itemId] or 0) + 1
        if attempts >= MAX_PARSE_ATTEMPTS then
          parseAttempts[itemId] = nil
          self.sv[itemId] = nil
          self.toAdd[itemId] = nil
          Addon:Print(L.ITEM_ID_FAILED_TO_PARSE:format(Colors.Grey(itemId)))
        else
          parseAttempts[itemId] = attempts
        end
      end
    end
  end

  -- Sort the list once all items have been parsed.
  if not next(self.toAdd) then
    table.sort(self.items, function(a, b)
      return a.quality == b.quality and a.name < b.name or a.quality < b.quality
    end)
  end
end

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.SavedVariablesSwitched, function()
  local savedVariables = SavedVariables:Get()

  -- Inclusions.
  Lists.Inclusions.sv = savedVariables.inclusions
  for k in pairs(Lists.Inclusions.items) do Lists.Inclusions.items[k] = nil end
  for k in pairs(savedVariables.inclusions) do Lists.Inclusions.toAdd[k] = true end

  -- Exclusions.
  Lists.Exclusions.sv = savedVariables.exclusions
  for k in pairs(Lists.Exclusions.items) do Lists.Exclusions.items[k] = nil end
  for k in pairs(savedVariables.exclusions) do Lists.Exclusions.toAdd[k] = true end
end)

EventManager:On(E.ListItemAdded, function(list, item)
  local other = list == Lists.Inclusions and Lists.Exclusions or Lists.Inclusions
  if other:Contains(item.id) then other:Remove(item.id) end
end)

-- ============================================================================
-- Lists
-- ============================================================================

do -- Lists:Iterate()
  local lists = { [Lists.Inclusions] = true, [Lists.Exclusions] = true }
  function Lists:Iterate()
    return next, lists
  end
end

function Lists:IsBusy()
  for list in self:Iterate() do
    if next(list.toAdd) ~= nil then return true end
  end

  return false
end

-- ============================================================================
-- Initialize
-- ============================================================================

-- Add required values to each list.
Lists.Inclusions.name = Addon.Colors.Red(Addon.Locale.INCLUSIONS_TEXT)
Lists.Exclusions.name = Addon.Colors.Green(Addon.Locale.EXCLUSIONS_TEXT)

for list in Lists:Iterate() do
  -- Tables.
  list.toAdd = {}
  list.items = {}
  -- Mixins.
  for funcName, func in pairs(Mixins) do
    list[funcName] = func
  end
end

-- Attempt to parse lists every 0.1 seconds.
C_Timer.NewTicker(0.1, function()
  if Seller:IsBusy() then return end
  for list in Lists:Iterate() do list:Parse() end
end)
