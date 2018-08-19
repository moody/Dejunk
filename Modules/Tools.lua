-- Tools: a collection of helpful functions.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL

-- Upvalues
local assert = assert
local GetItemInfo = GetItemInfo

-- Modules
local Tools = Addon.Tools

local Colors = Addon.Colors
local Consts = Addon.Consts
local ListManager = Addon.ListManager

-- ============================================================================
-- List Name Functions
-- ============================================================================

-- Returns the localized Inclusions string in color.
function Tools:GetInclusionsString()
  return DCL:ColorString(L.INCLUSIONS_TEXT, Colors.Inclusions)
end

-- Returns the localized Exclusions string in color.
function Tools:GetExclusionsString()
  return DCL:ColorString(L.EXCLUSIONS_TEXT, Colors.Exclusions)
end

-- Returns the localized Destroyables string in color.
function Tools:GetDestroyablesString()
  return DCL:ColorString(L.DESTROYABLES_TEXT, Colors.Destroyables)
end

-- Returns the list name as a localized string in color.
-- @param listName - a list name key defined in ListManager
function Tools:GetColoredListName(listName)
  assert(ListManager.Lists[listName])

  if (listName == "Inclusions") then
    return self:GetInclusionsString()
  elseif (listName == "Exclusions") then
    return self:GetExclusionsString()
  elseif (listName == "Destroyables") then
    return self:GetDestroyablesString()
  else
    error(format("Unsupported list name: \"%s\"", listName))
  end
end

-- ============================================================================
-- Item Functions
-- ============================================================================

-- Gets the item id from a specified item link.
-- @return - the item id, or nil
function Tools:GetItemIDFromLink(itemLink)
  return (itemLink and itemLink:match("item:(%d+)")) or nil
end

-- Returns true if the specified item can be sold.
-- @param item - the item
function Tools:ItemCanBeSold(item)
  return (item.Price > 0 and (item.Quality >= LE_ITEM_QUALITY_POOR and item.Quality <= LE_ITEM_QUALITY_EPIC))
end

-- Returns true if the specified item can be destroyed.
-- @param item - the item
function Tools:ItemCanBeDestroyed(item)
  -- Disallow destroying of Pet Cages
  if (item.Class == Consts.BATTLEPET_CLASS) then return false end
  return (item.Quality >= LE_ITEM_QUALITY_POOR and item.Quality <= LE_ITEM_QUALITY_EPIC)
end

-- Returns true if the specified item can be refunded.
-- @param item - the item
function Tools:ItemCanBeRefunded(item)
  local refundTimeRemaining = select(3, GetContainerItemPurchaseInfo(item.Bag, item.Slot))
  return refundTimeRemaining and (refundTimeRemaining > 0)
end
