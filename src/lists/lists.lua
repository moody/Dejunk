local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local ListItemParser = Addon:GetModule("ListItemParser")
local StateManager = Addon:GetModule("StateManager")

--- @class Lists
local Lists = Addon:GetModule("Lists")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @alias ListItemIds table<string, boolean>
--- @alias ListKey "GlobalInclusions" | "GlobalExclusions" | "PerCharInclusions" | "PerCharExclusions"

--- @class ListData
--- @field name string
--- @field description string
--- @field protected load fun(): ListItemIds
--- @field protected save fun(itemIds: ListItemIds): nil
--- @field protected getSibling fun(): List
--- @field protected getOpposite fun(): List

--- @class List : ListData
--- @field private items ListItem[]
--- @field private itemIds ListItemIds
--- @field private searchItems ListItem[]

-- ============================================================================
-- Local Functions
-- ============================================================================

local function compareByQuality(a, b)
  return a.quality == b.quality and a.name < b.name or a.quality < b.quality
end

-- ============================================================================
-- Mixins
-- ============================================================================

--- @class List
local Mixins = {}

--- Returns the list's sibling.
--- For example: if `GlobalInclusions`, returns `PerCharInclusions`.
function Mixins:GetSibling()
  return self.getSibling()
end

--- Returns the list's opposite.
--- For example: if `GlobalInclusions`, returns `GlobalExclusions`.
function Mixins:GetOpposite()
  return self.getOpposite()
end

--- Returns `true` if the list contains the given `itemId`.
--- @param itemId string|number
--- @return boolean
function Mixins:Contains(itemId)
  return self.itemIds[tostring(itemId)] == true
end

--- Attempts to add the given `itemId` to the list.
--- @param itemId string|number
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

--- Attempts to remove the given `itemId` from the list.
---@param itemId string|number
function Mixins:Remove(itemId)
  itemId = tostring(itemId)

  if self:Contains(itemId) then
    self.itemIds[itemId] = nil

    local index = self:GetIndex(itemId)
    if index ~= -1 then
      local item = table.remove(self.items, index)
      Addon:Print(L.ITEM_REMOVED_FROM_LIST:format(item.link, self.name))
    end

    self.save(self.itemIds)
  else
    local link = select(2, GetItemInfo(itemId))
    if link then Addon:Print(L.ITEM_NOT_ON_LIST:format(link, self.name)) end
  end
end

--- Returns the list's item array index for the given `itemId`, or `-1` if not found.
--- @param itemId string|number
--- @return integer index
function Mixins:GetIndex(itemId)
  itemId = tostring(itemId)

  for i, item in ipairs(self.items) do
    if tostring(item.id) == itemId then
      return i
    end
  end

  return -1
end

--- Removes all items from the list.
function Mixins:RemoveAll()
  if #self.items > 0 or next(self.itemIds) then
    for k in pairs(self.items) do self.items[k] = nil end
    for k in pairs(self.itemIds) do self.itemIds[k] = nil end

    self.save(self.itemIds)

    Addon:Print(L.ALL_ITEMS_REMOVED_FROM_LIST:format(self.name))
  end
end

--- Returns the list's items.
---@return ListItem[] items
function Mixins:GetItems()
  return self.items
end

--- Returns the list's items filtered by name using the given `searchText`.
--- @param searchText string
--- @return ListItem[] searchItems
function Mixins:GetSearchItems(searchText)
  searchText = string.lower(searchText or "")
  for k in pairs(self.searchItems) do self.searchItems[k] = nil end

  for _, item in ipairs(self.items) do
    if item.name:lower():find(searchText, 1, true) then
      self.searchItems[#self.searchItems + 1] = item
    end
  end

  return self.searchItems
end

-- ============================================================================
-- Events
-- ============================================================================

-- Listen for `StoreCreated` to initialize lists with existing data.
EventManager:Once(E.StoreCreated, function()
  for list in Lists:Iterate() do
    for itemId in pairs(list.load()) do
      ListItemParser:ParseExisting(list, itemId)
    end
  end
end)

-- Listen for `ListItemParsed` to add the item to the list and print a message.
-- If the item cannot be sold or destroyed, then an error message is printed.
EventManager:On(E.ListItemParsed, function(list, item, silent)
  if Items:IsItemSellable(item) or Items:IsItemDestroyable(item) then
    -- Add item.
    list.items[#list.items + 1] = item
    list.itemIds[tostring(item.id)] = true
    -- Remove from opposite list.
    local opposite = list:GetOpposite()
    if opposite:Contains(item.id) then opposite:Remove(item.id) end
    -- Print.
    if not silent then Addon:Print(L.ITEM_ADDED_TO_LIST:format(item.link, list.name)) end
  else
    if not silent then Addon:Print(L.CANNOT_SELL_OR_DESTROY_ITEM:format(item.link)) end
  end
end)

-- Listen for `ListItemFailedToParse` to print an error message.
EventManager:On(E.ListItemFailedToParse, function(list, itemId, silent)
  if not silent then Addon:Print(L.ITEM_ID_FAILED_TO_PARSE:format(Colors.Grey(itemId))) end
end)

-- Listen for `ListItemCannotBeParsed` to print an error message.
EventManager:On(E.ListItemCannotBeParsed, function(list, itemId, silent)
  if not silent then Addon:Print(L.ITEM_ID_DOES_NOT_EXIST:format(Colors.Grey(itemId))) end
end)

-- Listen for `ListParsingComplete` to save and sort the list after parsing.
EventManager:On(E.ListParsingComplete, function(list)
  list.save(list.itemIds)
  table.sort(list.items, compareByQuality)
end)

-- ============================================================================
-- Initialize
-- ============================================================================

do -- Create the lists.
  ---@param data ListData
  ---@return List list
  local function createList(data)
    --- @class List
    local list = data
    list.items = {}
    list.itemIds = {}
    list.searchItems = {}
    for k, v in pairs(Mixins) do list[k] = v end
    return list
  end

  -- PerCharInclusions.
  Lists.PerCharInclusions = createList({
    name = Colors.Red("%s (%s)"):format(L.INCLUSIONS_TEXT, Colors.White(L.CHARACTER)),
    description = L.INCLUSIONS_DESCRIPTION_PERCHAR,
    load = function() return StateManager:GetPercharState().inclusions end,
    save = function(itemIds) StateManager:GetStore():Dispatch(Actions:SetPercharInclusions(itemIds)) end,
    getSibling = function() return Lists.GlobalInclusions end,
    getOpposite = function() return Lists.PerCharExclusions end
  })

  -- PerCharExclusions.
  Lists.PerCharExclusions = createList({
    name = Colors.Green("%s (%s)"):format(L.EXCLUSIONS_TEXT, Colors.White(L.CHARACTER)),
    description = L.EXCLUSIONS_DESCRIPTION_PERCHAR,
    load = function() return StateManager:GetPercharState().exclusions end,
    save = function(itemIds) StateManager:GetStore():Dispatch(Actions:SetPercharExclusions(itemIds)) end,
    getSibling = function() return Lists.GlobalExclusions end,
    getOpposite = function() return Lists.PerCharInclusions end
  })

  -- GlobalInclusions.
  Lists.GlobalInclusions = createList({
    name = Colors.Red("%s (%s)"):format(L.INCLUSIONS_TEXT, Colors.White(L.GLOBAL)),
    description = L.INCLUSIONS_DESCRIPTION_GLOBAL:format(Lists.PerCharExclusions.name),
    load = function() return StateManager:GetGlobalState().inclusions end,
    save = function(itemIds) StateManager:GetStore():Dispatch(Actions:SetGlobalInclusions(itemIds)) end,
    getSibling = function() return Lists.PerCharInclusions end,
    getOpposite = function() return Lists.GlobalExclusions end
  })

  -- GlobalExclusions.
  Lists.GlobalExclusions = createList({
    name = Colors.Green("%s (%s)"):format(L.EXCLUSIONS_TEXT, Colors.White(L.GLOBAL)),
    description = L.EXCLUSIONS_DESCRIPTION_GLOBAL:format(Lists.PerCharInclusions.name),
    load = function() return StateManager:GetGlobalState().exclusions end,
    save = function(itemIds) StateManager:GetStore():Dispatch(Actions:SetGlobalExclusions(itemIds)) end,
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

  --- Provides an iterator for the lists. Usage:
  --- ```
  --- for list in Lists:Iterate() do
  ---   -- Do stuff.
  --- end
  --- ```
  --- @return function next
  --- @return table<List, boolean> lists
  function Lists:Iterate()
    return next, lists
  end
end
