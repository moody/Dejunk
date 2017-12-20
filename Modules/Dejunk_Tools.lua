-- Dejunk_Tools: contains helpful functions such as coloring a string, displaying a tooltip, etc.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local Clamp = Clamp
local GameTooltip = GameTooltip
local BACKPACK_CONTAINER, NUM_BAG_SLOTS = BACKPACK_CONTAINER, NUM_BAG_SLOTS
local GetItemInfo, GetContainerItemInfo, GetDetailedItemLevelInfo =
      GetItemInfo, GetContainerItemInfo, GetDetailedItemLevelInfo
local GetContainerNumSlots, GetContainerItemID, GetContainerItemLink =
      GetContainerNumSlots, GetContainerItemID, GetContainerItemLink
local GetContainerItemPurchaseInfo = GetContainerItemPurchaseInfo

local assert = assert
local pairs, ipairs = pairs, ipairs

-- Dejunk
local Tools = DJ.Tools

local Colors = DJ.Colors
local Consts = DJ.Consts

-- ============================================================================
--                              Color Functions
-- ============================================================================

-- Removes WoW color escape sequences from a string.
function Tools:RemoveColorFromString(string)
  return string:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

-- Formats and returns a string with the specified color.
-- @oaram string - the string to color
-- @param color  - Colors string or table: {r, g, b[, a]}
-- @return - a string formatted with color
function Tools:GetColorString(string, color)
  local r, g, b = 0, 0, 0

  if type(color) == "string" then
    r, g, b = unpack(Colors:GetColor(color))
  else
    r, g, b = unpack(color)
  end

  -- Convert to value between 0-255
  r = (Clamp(r, 0, 1) * 255)
  g = (Clamp(g, 0, 1) * 255)
  b = (Clamp(b, 0, 1) * 255)

  -- Color format (hex): AARRGGBB
  -- %02X = two-digit hex value, 00-FF
  return format("|cFF%02X%02X%02X%s|r", r, g, b, string)
end

-- Returns a random color.
-- @return color table: {r, g, b}
function Tools:GetRandomColor()
  return {math.random(), math.random(), math.random()}
end

-- Returns the localized Inclusions string in color.
function Tools:GetInclusionsString()
  return self:GetColorString(L.INCLUSIONS_TEXT, Colors.Inclusions)
end

-- Returns the localized Exclusions string in color.
function Tools:GetExclusionsString()
  return self:GetColorString(L.EXCLUSIONS_TEXT, Colors.Exclusions)
end

-- Returns the localized Destroyables string in color.
function Tools:GetDestroyablesString()
  return self:GetColorString(L.DESTROYABLES_TEXT, Colors.Destroyables)
end

-- Returns the list name as a localized string in color.
-- @param listName - a list name key defined in ListManager
function Tools:GetColoredListName(listName)
  assert(DJ.ListManager[listName])

  if (listName == DJ.ListManager.Inclusions) then
    return self:GetInclusionsString()
  elseif (listName == DJ.ListManager.Exclusions) then
    return self:GetExclusionsString()
  elseif (listName == DJ.ListManager.Destroyables) then
    return self:GetDestroyablesString()
  else
    error(format("Unsupported list name: \"%s\"", listName))
  end
end

-- ============================================================================
--                              Tooltip Functions
-- ============================================================================

-- Displays a generic game tooltip.
-- @param owner - the frame the tooltip belongs to
-- @param anchorType - the anchor type ("ANCHOR_LEFT", "ANCHOR_CURSOR", etc.)
-- @param title - the title of the tooltip
-- @param ... - the body lines of the tooltip
function Tools:ShowTooltip(owner, anchorType, title, ...)
	GameTooltip:SetOwner(owner, anchorType)
	GameTooltip:SetText(title, 1.0, 0.82, 0)

	for k, v in ipairs({...}) do
    --if (type(v) == "function") then v = v() end
		GameTooltip:AddLine(v, 1, 1, 1, true)
	end

	GameTooltip:Show()
end

-- Displays a tooltip for an item.
-- @param owner - the frame the tooltip belongs to
-- @param anchorType - the anchor type ("ANCHOR_LEFT", "ANCHOR_CURSOR", etc.)
-- @param link - the link of the item to display
function Tools:ShowItemTooltip(owner, anchorType, link)
	GameTooltip:SetOwner(owner, anchorType)
	GameTooltip:SetHyperlink(link)
	GameTooltip:Show()
end

-- Hides the game tooltip.
function Tools:HideTooltip()
  GameTooltip:Hide()
end

-- ============================================================================
--                         Tooltip Scanning Functions
-- ============================================================================

do
  local _G = _G
  local toolsTip = CreateFrame("GameTooltip", AddonName.."ToolsTipScanner", nil, "GameTooltipTemplate")
  local toolsTipTextLeft = AddonName.."ToolsTipScannerTextLeft"

  -- Returns true if the tooltip of the item in a specified bag and slot
  -- contains a single line with the specified text.
  -- @param bag - the bag the item resides in
  -- @param slot - the bag slot item resides in
  -- @param ... - the lines of text to find in a single tooltip line
  function Tools:BagItemTooltipHasLine(bag, slot, ...)
    toolsTip:SetOwner(UIParent, "ANCHOR_NONE")
    toolsTip:SetBagItem(bag, slot)

    local lines = {...}
    local linesFound = 0
    assert(#lines > 0)

    for i = 1, toolsTip:NumLines() do
      local tipText = (_G[toolsTipTextLeft..i]):GetText() or ""

      for _, v in pairs(lines) do
        if (tipText ~= "") and tipText:find(v, 1, true) then
          linesFound = linesFound + 1
          if (linesFound == #lines) then return true end
        else break end
      end

      linesFound = 0
    end

    return false
  end

  -- Returns true if the tooltip of the item in a specified bag and slot
  -- contains the specified lines of text.
  -- @param bag - the bag the item resides in
  -- @param slot - the bag slot item resides in
  -- @param ... - the lines of text to scan the tooltip for
  function Tools:BagItemTooltipHasText(bag, slot, ...)
    toolsTip:SetOwner(UIParent, "ANCHOR_NONE")
    toolsTip:SetBagItem(bag, slot)

    local lines = {...}
    assert(#lines > 0)

    for i = 1, toolsTip:NumLines() do
      local tipText = (_G[toolsTipTextLeft..i]):GetText() or ""

      for k, v in pairs(lines) do
        if (tipText ~= "") and tipText:find(v, 1, true) then
          lines[k] = nil -- remove found line
          break
        end
      end
    end

    return (#lines == 0) -- true if all lines were found
  end

  -- Returns the first entire tooltip line where the specified text is found.
  -- @param bag - the bag the item resides in
  -- @param slot - the bag slot the item resides in
  -- @param text - the text to search for
  function Tools:GetBagItemTooltipText(bag, slot, text)
    toolsTip:SetOwner(UIParent, "ANCHOR_NONE")
    toolsTip:SetBagItem(bag, slot)

    for i = 1, toolsTip:NumLines() do
      local tipText = (_G[toolsTipTextLeft..i]):GetText() or ""
      if (tipText ~= "") and tipText:find(text, 1, true) then
        return tipText
      end
    end

    return nil
  end
end

-- ============================================================================
--                                 UI Functions
-- ============================================================================

do
  local sizer = UIParent:CreateTexture("DejunkSizer", "BACKGROUND")
  sizer:SetColorTexture(0, 0, 0, 0)

  -- Measures the width and height between the top-left point of the startRegion
  -- and the bottom-right point of the endRegion.
  -- @param parent - the parent frame used to create a temporary texture
  -- @param startRegion - the left-most region
  -- @param endRegion - the right-most region
  -- @param startPoint - the point on the startRegion to measure from [optional]
  -- @param endPoint - the point on the endRegion to measure to [optional]
  -- @return width - the width between the two regions
  -- @return height - the height
  function Tools:Measure(parent, startRegion, endRegion, startPoint, endPoint)
    sizer:ClearAllPoints()
    sizer:SetParent(parent)
    sizer:SetPoint(startPoint or "TOPLEFT", startRegion)
    sizer:SetPoint(endPoint or "BOTTOMRIGHT", endRegion)

    local width, height = sizer:GetWidth(), sizer:GetHeight()

    return width, height
  end
end

do
  local paddingCache = {}

  -- Returns the default padding with an optional multiplier.
  -- @param multiplier - a number to multiply padding by [optional]
  -- @return - the absolute value of default padding times the multiplier or 1.
  function Tools:Padding(multiplier)
    multiplier = multiplier or 1
    local key = tostring(multiplier)
    if not paddingCache[key] then
      paddingCache[key] = abs(10 * multiplier)
    end

    return paddingCache[key]
  end
end

-- ============================================================================
--                                Item Functions
-- ============================================================================

-- Gets the item id from a specified item link.
-- @return - the item id, or nil
function Tools:GetItemIDFromLink(itemLink)
  return (itemLink and itemLink:match("item:(%d+)")) or nil
end

-- Gets the upgrade type from an item link. Can be used to determine if an item
-- is scaled or not. Only use with item links from items in the player's bags.
function Tools:GetItemLinkUpgradeType(itemLink)
  -- ":player level:player spec id:upgrade type:"
  return itemLink:match(format(":%d:%%d+:(%%d+):", UnitLevel("PLAYER")))
end

-- Searches the player's bags for the location of an item with a specified link.
-- @return bag and slot index pair, or nil if the item was not found
function Tools:FindItemInBags(itemLink)
  local itemID = self:GetItemIDFromLink(itemLink)

  if itemID then -- search bags for item
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)

        if link and link:find(itemID) then
          return bag, slot end
      end
    end
  end

  return nil
end

do -- GetItemFromBag()
  local ITEM_LEVEL = ITEM_LEVEL:gsub("%%d", "")

  -- Gets the information of an item within a specified bag and slot.
  -- @return a table of item information, or nil if the info could not be retrieved
  function Tools:GetItemFromBag(bag, slot)
    -- Ignore refundable items by default
    local refundTimeRemaining = select(3, GetContainerItemPurchaseInfo(bag, slot))
    if refundTimeRemaining and (refundTimeRemaining > 0) then return nil end

    -- Get item info
    local _, quantity, locked, _, _, _, itemLink, _, noValue, itemID = GetContainerItemInfo(bag, slot)
    if not (quantity and itemLink and itemID) then return nil end

    -- Get additional item info
    local _, _, quality, _, reqLevel, class, subClass, _, equipSlot, _, price = GetItemInfo(itemLink)
    if not (quality and reqLevel and class and subClass and equipSlot and price) then return nil end

    -- Item level, we have to scan tooltips for ilvl in scaled gear so that
    -- Dejunker filters work as expected (see Dejunker:IsSellEquipmentBelowILVLItem)
    local itemLevel = nil
    if ((class == Consts.ARMOR_CLASS) or (class == Consts.WEAPON_CLASS)) and
    self:GetItemLinkUpgradeType(itemLink) then
      itemLevel = self:GetBagItemTooltipText(bag, slot, ITEM_LEVEL)
      itemLevel = itemLevel and tonumber(itemLevel:match("%d+")) or
        GetDetailedItemLevelInfo(itemLink)
    else
      itemLevel = GetDetailedItemLevelInfo(itemLink)
    end
    if not itemLevel then return nil end

    return {
      Bag = bag,
      Slot = slot,
      Quantity = quantity,
      Locked = locked,
      ItemLink = itemLink,
      NoValue = noValue,
      ItemID = itemID,
      Quality = quality,
      ReqLevel = reqLevel,
      Class = class,
      SubClass = subClass,
      EquipSlot = equipSlot,
      Price = price,
      ItemLevel = itemLevel
    }
  end
end

-- Scans the players bags for items matching a specified filter.
-- @param filterFunc - an item filter function with params: (bag, slot)
-- and a return value of an item retrieved by Tools:GetItemFromBag(bag, slot)
-- @param maxItems - the maximum amount of items to return [optional]
-- @return items - a list of items
-- @return allItemsCached - true if all items were able to be checked
function Tools:GetBagItemsByFilter(filterFunc, maxItems)
  if maxItems and (maxItems <= 0) then maxItems = nil end

  local items = {}
  local allItemsCached = true

  for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local itemID = GetContainerItemID(bag, slot)

      if itemID then -- bag slot is not empty (seems to be guaranteed)
        if not GetItemInfo(itemID) then
          allItemsCached = false
        else
          local item = filterFunc(bag, slot)
          if item then
            items[#items+1] = item

            -- return if max items reached
            if maxItems and (#items == maxItems) then
              return items, allItemsCached end
          end
        end
      end
    end
  end

  return items, allItemsCached
end

-- Checks whether or not an item can be sold based on price and quality.
-- @param price - the price of an item
-- @param quality - the quality of an item
-- @return - boolean
function Tools:ItemCanBeSold(item)
  return (item.Price > 0 and (item.Quality >= LE_ITEM_QUALITY_POOR and item.Quality <= LE_ITEM_QUALITY_EPIC))
end

-- Checks whether or not an item can be destroyed.
-- @param item - the item to test
-- @return - boolean
function Tools:ItemCanBeDestroyed(item)
  -- Disallow destroying of Pet Cages
  if (item.Class == Consts.BATTLEPET_CLASS) then return false end
  return (item.Quality >= LE_ITEM_QUALITY_POOR and item.Quality <= LE_ITEM_QUALITY_EPIC)
end

-- Creates and returns an item by item id.
-- @param itemID - the item id of the item to create
-- @return - a table with item data
function Tools:GetItemByID(itemID)
  local name, itemLink, quality, _, _, class, subClass, _, _, texture, price = GetItemInfo(itemID)
  if not (name and itemLink and quality and class and subClass and texture and price) then return nil end

  return {
    ItemID = itemID,
    Name = name,
    ItemLink = itemLink,
    Quality = quality,
    Class = class,
    SubClass = subClass,
    Texture = texture,
    Price = price
  }
end
