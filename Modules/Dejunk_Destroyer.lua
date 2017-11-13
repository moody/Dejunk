-- Dejunk_Destroyer: handles the process of selling junk items to merchants.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local remove = table.remove

-- Dejunk
local Destroyer = DJ.Destroyer

local Core = DJ.Core
local Consts = DJ.Consts
local DejunkDB = DJ.DejunkDB
local ListManager = DJ.ListManager
local Tools = DJ.Tools

-- Variables
local DestroyerState =
{
  None = 0,
  Destroying = 1
}

local currentState = DestroyerState.None

local ItemsToDestroy = {}
local DestroyedItems = {}

--[[
//*******************************************************************
//                         Destroyer Frame
//*******************************************************************
--]]

local DestroyerFrame = CreateFrame("Frame", AddonName.."DestroyerFrame")

function DestroyerFrame:OnEvent(event, ...)
  if (event == "UI_ERROR_MESSAGE") then
    local _, msg = ...

    if Destroyer:IsDestroying() then
			if (msg == ERR_INTERNAL_BAG_ERROR) then
				--UIErrorsFrame:Clear()
			end
		end
  end
end

DestroyerFrame:SetScript("OnEvent", DestroyerFrame.OnEvent)
DestroyerFrame:RegisterEvent("UI_ERROR_MESSAGE")

--[[
//*******************************************************************
//                        Destroying Functions
//*******************************************************************
--]]

-- Starts the Destroying process.
function Destroyer:StartDestroying()
  assert(currentState == DestroyerState.None)
  --if ListManager:IsParsing() then return end

  local canDestroy, msg = Core:CanDestroy()
  if not canDestroy then
    Core:Print(msg)
    return
  end

  currentState = DestroyerState.Destroying
  --Core:DisableGUI()

  allItemsCached = true

  self:SearchForDestroyableItems()

  if not allItemsCached then
    if (#ItemsToDestroy > 0) then
      Core:Print(L.ONLY_SELLING_CACHED)
    else
      Core:Print(L.NO_CACHED_JUNK_ITEMS)
      self:StopDestroying()
      return
    end
  end

  self:StartDestroying()
end

-- Cancels the Destroying process.
function Destroyer:StopDestroying()
  assert(currentState ~= DestroyerState.None)

  DestroyerFrame:SetScript("OnUpdate", nil)

  currentState = DestroyerState.None

  for k in pairs(ItemsToDestroy) do ItemsToDestroy[k] = nil end
  for k in pairs(DestroyedItems) do DestroyedItems[k] = nil end

  --Core:EnableGUI()
end

-- Checks whether or not the Destroyer is active.
-- @return - boolean
function Destroyer:IsDestroying()
  return (currentState ~= DestroyerState.None)
end

--[[
//*******************************************************************
//                        Destroying Functions
//*******************************************************************
--]]

local SELL_DELAY = 0.25
local sellInterval = 0

-- Starts the selling process.
function Destroyer:StartDestroying()
  assert(currentState == DestroyerState.Destroying)

  if (#ItemsToDestroy <= 0) then
		Core:Print("No items to destroy. (L)")
		self:StopDestroying()
		return
	end

  sellInterval = 0

  DestroyerFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:DestroyableItems(frame, elapsed) end)
end

-- Cancels the selling process and starts the profiting process.
function Destroyer:StopDestroying()
  DestroyerFrame:SetScript("OnUpdate", nil)

  self:StartProfiting()
end

-- Checks whether or not the Destroyer is actively selling items.
-- @return - boolean
function Destroyer:IsDestroying()
  return (currentState == DestroyerState.Destroying)
end

-- Set as the OnUpdate function during the selling process.
function Destroyer:DestroyableItems(frame, elapsed)
	sellInterval = (sellInterval + elapsed)

	if (sellInterval >= SELL_DELAY) then
		sellInterval = 0

		self:DestroyNextItem()

		if (#ItemsToDestroy <= 0) then
      self:StopDestroying() end
	end
end

-- Destroys the next item in the ItemsToDestroy table.
function Destroyer:DestroyNextItem()
	local item = remove(ItemsToDestroy)
	if not item then return end

	UseContainerItem(item.Bag, item.Slot)
  DestroyedItems[#DestroyedItems+1] = item
end

--[[
//*******************************************************************
//                       Profiting Functions
//*******************************************************************
--]]

local totalProfit = 0

-- Starts the profiting process.
function Destroyer:StartProfiting()
  assert(currentState == DestroyerState.Selling)

  if (#DestroyedItems <= 0) then
    self:StopDestroying()
    return
  end

  currentState = DestroyerState.Profiting
  totalProfit = 0
  DestroyerFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:CalculateProfits()
  end)
end

-- Cancels the profiting process.
function Destroyer:StopProfiting()
  assert(currentState == DestroyerState.Profiting)

  DestroyerFrame:SetScript("OnUpdate", nil)

  if (totalProfit > 0) then
    Core:Print(format(L.SOLD_YOUR_JUNK, GetCoinTextureString(totalProfit)))
  end

  self:StopDestroying()
end

-- Set as the OnUpdate function during the profiting process.
function Destroyer:CalculateProfits()
  local profit = Destroyer:CheckForNextDestroyedItem()

  if profit then
    totalProfit = (totalProfit + profit) end

  if (#DestroyedItems <= 0) then
    self:StopProfiting() end
end

-- Checks if the next entry in DestroyedItems has sold and returns the profit.
-- @return - profit if the item was sold, or nil if not
function Destroyer:CheckForNextDestroyedItem()
  local item = remove(DestroyedItems, 1)
  if not item then return nil end

  local _, quantity, locked, _, _, _, itemLink = GetContainerItemInfo(item.Bag, item.Slot)

  if ((itemLink and quantity) and (itemLink == item.Link) and (quantity == item.Quantity)) then
    if locked then -- Item probably being sold, add it back to list and try again later
      DestroyedItems[#DestroyedItems+1] = item
    else -- Item is still in bags, so it may not have sold
      Core:Print(format(L.MAY_NOT_HAVE_SOLD_ITEM, item.Link))
    end

    return nil
  end

  -- Bag and slot is empty, so the item should have sold
  return (item.Price * item.Quantity)
end

--[[
//*******************************************************************
//                        Helper Functions
//*******************************************************************
--]]

-- Searches the player's bags for destroyable items.
function Destroyer:SearchForDestroyableItems()
  for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local itemID = GetContainerItemID(bag, slot)

      if itemID then -- bag slot is not empty (seems to be guaranteed)
        if not GetItemInfo(itemID) then
          allItemsCached = false end

        local item = self:GetDestroyableItemFromBag(bag, slot, itemID)

        if item then -- item is cached
          ItemsToDestroy[#ItemsToDestroy+1] = item

          if ((#ItemsToDestroy == Consts.SAFE_MODE_MAX) and DejunkDB.SV.SafeMode) then
            Core:Print(L.SAFE_MODE_MESSAGE) return end
        end
      end
    end
  end
end

-- Returns the item in the specified bag slot if it is destroyable.
-- @return - a destroyable item, or nil
function Destroyer:GetDestroyableItemFromBag(bag, slot)
  local item = Tools:GetItemFromBag(bag, slot)
  if not item then return nil end

  if item.NoValue or not Tools:ItemCanBeDestroyed(item.Price, item.Quality) then return nil end
  if not self:IsDestroyableItem(item) then return nil end

  return item
end

-- Checks if an item is a junk item based on Dejunk's settings.
-- @param item - an item retrieved using Tools:GetItemFromBag
-- @return - true if the item is considered junk, and false otherwise
function Destroyer:IsDestroyableItem(item)
  -- Add more to this later as we begin to implement destroy options
  return ListManager:IsOnList(ListManager.Destroyables, item.ItemID)
end
