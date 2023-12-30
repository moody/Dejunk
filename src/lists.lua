local _, Addon = ...
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local ListItemParser = Addon:GetModule("ListItemParser")
local Lists = Addon:GetModule("Lists")
local SavedVariables = Addon:GetModule("SavedVariables")

-- ============================================================================
-- Mixins
-- ============================================================================

local Mixins = {}

function Mixins:GetSibling()
  return self.getSibling()
end

function Mixins:GetOpposite()
  return self.getOpposite()
end

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
    ListItemParser:Parse(self, itemId)
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

function Mixins:Sort()
  table.sort(self.items, function(a, b)
    return a.quality == b.quality and a.name < b.name or a.quality < b.quality
  end)
end

-- ============================================================================
-- Events
-- ============================================================================

-- Listen for `SavedVariablesReady` to initialize lists with existing data.
EventManager:Once(E.SavedVariablesReady, function()
  for list in Lists:Iterate() do
    list.sv = list.getSv()
    for itemId in pairs(list.sv) do
      ListItemParser:ParseExisting(list, itemId)
    end
  end
end)

-- Listen for `ListItemAdded` to remove the item from the opposite list if necessary.
EventManager:On(E.ListItemAdded, function(list, item)
  local opposite = list:GetOpposite()
  if opposite:Contains(item.id) then opposite:Remove(item.id) end
end)

do -- Listen for item parsed events.
  local function addListItem(list, item)
    list.sv[tostring(item.id)] = true
    list.items[#list.items + 1] = item
    EventManager:Fire(E.ListItemAdded, list, item)
  end

  -- Listen for `ListItemParsed` to add the item to the list and print a message.
  -- If the item cannot be sold or destroyed, then an error message is printed.
  EventManager:On(E.ListItemParsed, function(list, item)
    if Items:IsItemSellable(item) or Items:IsItemDestroyable(item) then
      addListItem(list, item)
      Addon:Print(L.ITEM_ADDED_TO_LIST:format(item.link, list.name))
    else
      list.sv[tostring(item.id)] = nil
      Addon:Print(L.CANNOT_SELL_OR_DESTROY_ITEM:format(item.link))
    end
  end)

  -- Listen for `ExistingListItemParsed` to add the item to the list without printing a message.
  -- This event is intended for item IDs already saved in the list's SavedVariables. As such,
  -- messages are not necessary nor desired.
  EventManager:On(E.ExistingListItemParsed, function(list, item)
    if Items:IsItemSellable(item) or Items:IsItemDestroyable(item) then
      addListItem(list, item)
    else
      list.sv[tostring(item.id)] = nil
    end
  end)
end

-- Listen for `ListItemFailedToParse` to print an error message.
EventManager:On(E.ListItemFailedToParse, function(list, itemId)
  Addon:Print(L.ITEM_ID_FAILED_TO_PARSE:format(Colors.Grey(itemId)))
end)

-- Listen for `ExistingListItemFailedToParse` to print an error message,
-- as well as to remove the item ID from the list's SavedVariables.
EventManager:On(E.ExistingListItemFailedToParse, function(list, itemId)
  list.sv[tostring(itemId)] = nil
  Addon:Print(L.ITEM_ID_FAILED_TO_PARSE:format(Colors.Grey(itemId)))
end)

-- Listen for `ListItemCannotBeParsed` to print an error message,
-- as well as to ensure removal of the item ID from the list's SavedVariables.
EventManager:On(E.ListItemCannotBeParsed, function(list, itemId)
  list.sv[tostring(itemId)] = nil
  Addon:Print(L.ITEM_ID_DOES_NOT_EXIST:format(Colors.Grey(itemId)))
end)

-- Listen for `ListParsingComplete` to sort the list after parsing.
EventManager:On(E.ListParsingComplete, function(list)
  list:Sort()
end)

-- ============================================================================
-- Initialize
-- ============================================================================

do -- Create the lists.
  local function createList(data)
    local list = data
    list.items = {}
    for k, v in pairs(Mixins) do list[k] = v end
    return list
  end

  -- PerCharInclusions.
  Lists.PerCharInclusions = createList({
    name = Colors.Red("%s (%s)"):format(L.INCLUSIONS_TEXT, Colors.White(L.CHARACTER)),
    description = L.INCLUSIONS_DESCRIPTION_PERCHAR,
    getSv = function() return SavedVariables:GetPerChar().inclusions end,
    getSibling = function() return Lists.GlobalInclusions end,
    getOpposite = function() return Lists.PerCharExclusions end
  })

  -- PerCharExclusions.
  Lists.PerCharExclusions = createList({
    name = Colors.Green("%s (%s)"):format(L.EXCLUSIONS_TEXT, Colors.White(L.CHARACTER)),
    description = L.EXCLUSIONS_DESCRIPTION_PERCHAR,
    getSv = function() return SavedVariables:GetPerChar().exclusions end,
    getSibling = function() return Lists.GlobalExclusions end,
    getOpposite = function() return Lists.PerCharInclusions end
  })

  -- GlobalInclusions.
  Lists.GlobalInclusions = createList({
    name = Colors.Red("%s (%s)"):format(L.INCLUSIONS_TEXT, Colors.White(L.GLOBAL)),
    description = L.INCLUSIONS_DESCRIPTION_GLOBAL:format(Lists.PerCharExclusions.name),
    getSv = function() return SavedVariables:GetGlobal().inclusions end,
    getSibling = function() return Lists.PerCharInclusions end,
    getOpposite = function() return Lists.GlobalExclusions end
  })

  -- GlobalExclusions.
  Lists.GlobalExclusions = createList({
    name = Colors.Green("%s (%s)"):format(L.EXCLUSIONS_TEXT, Colors.White(L.GLOBAL)),
    description = L.EXCLUSIONS_DESCRIPTION_GLOBAL:format(Lists.PerCharInclusions.name),
    getSv = function() return SavedVariables:GetGlobal().exclusions end,
    getSibling = function() return Lists.PerCharExclusions end,
    getOpposite = function() return Lists.GlobalInclusions end
  })
end

do -- Lists:Iterate()
  local lists = {
    [Lists.GlobalInclusions] = true,
    [Lists.PerCharInclusions] = true,
    [Lists.GlobalExclusions] = true,
    [Lists.PerCharExclusions] = true
  }
  function Lists:Iterate()
    return next, lists
  end
end
