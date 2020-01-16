local _, Addon = ...
local Core = Addon.Core
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local GetItemInfo = _G.GetItemInfo
local GetItemInfoInstant = _G.GetItemInfoInstant
local L = Addon.Libs.L
local ListHelper = Addon.ListHelper
local Lists = Addon.Lists

-- Returns true if the `ListHelper` is currently parsing either a specific list
-- or in general.
-- @param {table} list - [optional]
-- @return {boolean}
function ListHelper:IsParsing(list)
  -- parsing specific list?
  if list then
    return next(list.toAdd) ~= nil
  end

  -- parsing in general?
  for _, li in pairs(Lists) do
    if next(li.toAdd) then return true end
  end

  return false
end

-----------------------------------------------------

do -- OnUpdate(), called in Core:OnUpdate()
  local interval = 0

  function ListHelper:OnUpdate(elapsed)
    if Dejunker:IsDejunking() or Destroyer:IsDestroying() then return end

    -- Additions
    interval = interval + elapsed
    if (interval >= Core.MinDelay) then
      interval = 0
      for _, list in pairs(Lists) do
        self:ParseList(list)
      end
    end
  end
end

do -- ParseList()
  local MAX_PARSE_ATTEMPTS = 50
  local parseAttempts = {
    -- [itemID] = count
  }

  -- Creates and returns an item by item id.
  -- @param itemID - the item id of the item to create
  -- @return - a table with item data
  local function getItemByID(itemID)
    local name, itemLink, quality, _, _, class, _, _, _, texture, price = GetItemInfo(itemID)
    if not (name and itemLink and quality and class and texture and price) then return nil end

    return {
      ItemID = itemID,
      Name = name,
      ItemLink = itemLink,
      Quality = quality,
      Class = class,
      Texture = texture,
      Price = price
    }
  end

  -- Parses queued itemIDs and adds them to the specified list.
  -- @param {table} list - the list to parse
  function ListHelper:ParseList(list)
    if not next(list.toAdd) then return end

    -- Parse items
    for itemID in pairs(list.toAdd) do
      -- Instantly fail if item doesn't exist
      if not GetItemInfoInstant(itemID) then
        list._sv[itemID] = nil -- remove from sv
        list.toAdd[itemID] = nil -- remove from queue
        Core:Print(
          L.FAILED_TO_PARSE_ITEM_ID:format(
            DCL:ColorString(itemID, DCL.CSS.Grey)
          )
        )
      else
        -- Attempt to parse the item
        local item = getItemByID(itemID)
        if item then
          -- Remove from sv if item cannot be added
          if not list:FinalizeAdd(item) then
            list._sv[itemID] = nil
          end
          -- Remove from parsing
          parseAttempts[itemID] = nil
          list.toAdd[itemID] = nil
        else
          -- Retry parsing until max attempts reached
          local attempts = (parseAttempts[itemID] or 0) + 1
          if (attempts >= MAX_PARSE_ATTEMPTS) then
            parseAttempts[itemID] = nil
            list._sv[itemID] = nil -- remove from sv
            list.toAdd[itemID] = nil -- remove from parsing
            Core:Print(
              L.FAILED_TO_PARSE_ITEM_ID:format(
                DCL:ColorString(itemID, DCL.CSS.Grey)
              )
            )
          else
            parseAttempts[itemID] = attempts
          end
        end
      end
    end

    -- Sort the list once all items have been parsed
    if not next(list.toAdd) then
      list:Sort()

      -- Start auto destroy if the Destroyables list was updated
      if (list == Lists.Destroyables) then
        Destroyer:StartAutoDestroy()
      end
    end
  end
end
